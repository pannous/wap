#!/usr/bin/env bash
# scripts/job-slot.sh [--alone] <command…>: the command run in one of the machine's job slots, niced, its output and exit status
# its own. Every wap test script and census run goes through it, from every worktree (test/wap/run.sh,
# ratchet_census.sh, vitals.py): it takes the first free slot of <store>/job-slots, job_slots() of them
# (scripts/lib/platform.sh), and waits for one when all are taken, saying so once
set -uo pipefail
RETRY_SECONDS=1
# the integrator's landing trees, warp's and wap's: their runs may take one more slot, which no other run takes, so a
# landing never starves (a tree whose name only starts the same, integrate2, is no landing tree)
INTEGRATION_TREES=(/Volumes/Worktrees/integrate /Volumes/Worktrees/wap-land)
source "$(dirname "$0")/lib/platform.sh"
source "$(dirname "$0")/lib/slots.sh"
[ $# -gt 0 ] || { echo "usage: job-slot.sh [--alone] <command…>" >&2; exit 2; }
# a runaway command, past the memory or time cap, is killed and named (scripts/guarded.sh)
guarded="$(dirname "$0")/guarded.sh"
# without lockf there are no slots: every command runs at once, an --alone one too
command -v lockf >/dev/null || { [ "$1" = --alone ] && shift; exec nice -n 19 "$guarded" "$@"; }
slots=$(job_slots)
for tree in "${INTEGRATION_TREES[@]}"; do [[ " $PWD/ $*/" == *" $tree/"* ]] && { slots=$((slots + 1)); break; }; done
waited=
# the command run in the first slot that frees, its status
slot_waited() {
	while :; do
		slot_tried "$slot_store/job-slots" "$slots" "$@"
		status=$?
		[ $slot_held = no ] || return $status
		[ -n "$waited" ] || { echo "job-slot.sh: all $(job_slots) job slots taken, waiting" >&2; waited=1; }
		sleep $RETRY_SECONDS
	done
}
# --alone: the command runs once every other slot is free, the caller's own aside (a measured run inside a test, whose
# instruction count grows with the machine's load): each slot is held as it frees, so no new job starts meanwhile,
# behind a lock of its own, so two such runs never hold each other's slots
case $1 in
	--alone) shift; exec lockf -s "$slot_store/job-slots/alone" "$0" --holding $((slots - 1)) "$@" ;;
	--holding) left=$2; shift 2; waited=1
		[ "$left" -gt 0 ] || exec nice -n 19 "$guarded" "$@"
		slot_waited "$0" --holding $((left - 1)) "$@"; exit ;;
esac
slot_waited nice -n 19 "$guarded" "$@"
