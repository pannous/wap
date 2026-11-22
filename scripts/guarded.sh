#!/usr/bin/env bash
# scripts/guarded.sh [--memory-gb <n>] [--seconds <n>] <command…>: the command run, its output and exit status its own,
# unless it runs away: its processes together past the memory cap or the command past the time cap, every one of them
# is killed, and stderr names the cap and the largest process's command line (the input it was given). macOS enforces
# no memory rlimit (`ulimit -v` and `-d` are refused), so a watcher samples the command's process tree. Every job slot
# runs its command through it (scripts/job-slot.sh): on 2026-11-22 one runaway wap reached 90 GB on this 32 GB Mac
# and the out-of-memory killer took the terminal down with it
set -uo pipefail
MEMORY_CAP_GB=12        # a wap test, compile or census peaks under 2 GB
TIME_CAP_SECONDS=1800   # the longest job, a whole census, takes about ten minutes
SAMPLE_SECONDS=1
RUNAWAY_STATUS=137      # as if killed by SIGKILL, which it was

while [ $# -gt 0 ]; do
	case $1 in
		--memory-gb) MEMORY_CAP_GB=$2; shift 2 ;;
		--seconds) TIME_CAP_SECONDS=$2; shift 2 ;;
		*) break ;;
	esac
done
[ $# -gt 0 ] || { echo "usage: guarded.sh [--memory-gb <n>] [--seconds <n>] <command…>" >&2; exit 2; }

# the process tree under <root>, two lines: its resident kilobytes in all and its pids; the largest one's command line
tree_of() {
	ps -A -o pid=,ppid=,rss=,command= | awk -v root="$1" '
		{ pid = $1; parent[pid] = $2; resident[pid] = $3; sub(/^ *[0-9]+ +[0-9]+ +[0-9]+ /, ""); line[pid] = $0 }
		END {
			if (!(root in parent)) exit
			inside[root] = 1
			do { grown = 0; for (p in parent) if (!(p in inside) && (parent[p] in inside)) { inside[p] = 1; grown = 1 } } while (grown)
			for (p in inside) { total += resident[p]; pids = pids " " p; if (resident[p] >= most) { most = resident[p]; largest = line[p] } }
			print total, pids; print largest
		}'
}

"$@" &
command_pid=$!
started=$SECONDS
while :; do
	sleep "$SAMPLE_SECONDS" & sleeper=$!
	wait -n -p ended "$command_pid" "$sleeper"
	status=$?
	[ "$ended" = "$command_pid" ] && { kill "$sleeper" 2>/dev/null; exit $status; }
	{ read -r kilobytes pids_line; read -r largest; } < <(tree_of "$command_pid")
	read -r -a pids <<<"${pids_line:-}"
	runaway=
	[ "${kilobytes:-0}" -gt $((MEMORY_CAP_GB * 1024 * 1024)) ] && runaway="took $(awk "BEGIN { printf \"%.1f\", $kilobytes / 1024 / 1024 }") GB, past the cap of $MEMORY_CAP_GB GB"
	[ $((SECONDS - started)) -gt "$TIME_CAP_SECONDS" ] && runaway="ran past the cap of $TIME_CAP_SECONDS s"
	[ -n "$runaway" ] || continue
	kill -9 "${pids[@]}" 2>/dev/null
	echo "guarded.sh: killed a runaway: it $runaway. Its largest process: $largest" >&2
	wait "$command_pid" 2>/dev/null
	exit $RUNAWAY_STATUS
done
