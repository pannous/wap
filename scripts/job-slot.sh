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
slots=$(job_slots) || exit 2
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
# how many slots are taken by runs doing something: all taken but those up the process chain of this run or of a run
# asleep on the alone lock (its lockf with no child yet)
slots_busy() {
	ps -axo pid=,ppid=,command= | awk -v slot="lockf -s -t 0 $slot_store/job-slots/" -v alone="lockf -s $slot_store/job-slots/alone " -v me=$$ '
		{ pid = $1; parent[pid] = $2; $1 = $2 = ""; command[pid] = substr($0, 3); has_child[parent[pid]] = 1 }
		END {
			for (pid in command) if (index(command[pid], slot) == 1 && substr(command[pid], length(slot) + 1, 1) ~ /[0-9]/) taken[pid] = 1
			for (pid in command) if (pid == me || index(command[pid], alone) == 1 && !(pid in has_child)) for (up = pid; up > 1; up = parent[up]) delete taken[up]
			busy = 0; for (pid in taken) busy++; print busy
		}'
}
# whether a process this one runs under holds a job slot: a slot's lockf up the parent chain
slot_above() {
	local pid=$PPID
	while [ "$pid" -gt 1 ]; do
		case $(ps -o command= -p "$pid") in "lockf -s -t 0 $slot_store/job-slots/"*) return 0 ;; esac
		pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
	done
	return 1
}
# --alone: the command runs once every slot is free but those held around idle runs (a measured run inside a test,
# whose instruction count grows with the machine's load), behind a lock of its own: each slot is taken as it frees, so
# no new job starts meanwhile, and once none is free it runs when every slot still taken is held by its own process
# ancestry or by that of a run asleep waiting for the alone lock, which does nothing meanwhile
case $1 in
	--alone) shift; exec lockf -s "$slot_store/job-slots/alone" "$0" --holding "$@" ;;
	--holding) shift
		while :; do
			slot_tried "$slot_store/job-slots" "$slots" "$0" --holding "$@"
			status=$?
			[ $slot_held = no ] || exit $status
			[ "$(slots_busy)" -gt 0 ] || exec nice -n 19 "$guarded" "$@"
			sleep $RETRY_SECONDS
		done ;;
esac
# a run inside one that holds a slot runs in that slot
! slot_above || exec nice -n 19 "$guarded" "$@"
slot_waited nice -n 19 "$guarded" "$@"
