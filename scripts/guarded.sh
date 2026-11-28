#!/usr/bin/env bash
# scripts/guarded.sh [--memory-gb <n>] [--seconds <n>] <command…>: the command run, its output and exit status its own,
# unless it runs away: its processes together past the memory cap, or one of them, which waits on none of the others,
# past the time cap, every one of them is killed, and stderr names the cap and the culprit's command line (the input it
# was given). The time cap is a process's own, so a script of many short runs (test_self.sh) may take longer. macOS enforces
# no memory rlimit (`ulimit -v` and `-d` are refused), so a watcher samples the command's process tree. Every job slot
# runs its command through it (scripts/job-slot.sh): on 2026-11-22 one runaway wap reached 90 GB on this 32 GB Mac
# and the out-of-memory killer took the terminal down with it
set -uo pipefail
MEMORY_CAP_GB=12        # a wap test, compile or census peaks under 2 GB
TIME_CAP_SECONDS=1800   # one process's: the longest, wap1 compiling wap's compiler, takes about two minutes
SAMPLE_SECONDS=1
RUNAWAY_STATUS=137      # as if killed by SIGKILL, which it was
MIN_BASH_MAJOR=5        # `wait -n -p` is bash 5's; macOS's /bin/bash is 3.2, found first on a bare PATH (cron's holds /opt/homebrew/bin)
[ "${BASH_VERSINFO[0]}" -ge "$MIN_BASH_MAJOR" ] || { echo "guarded.sh needs bash $MIN_BASH_MAJOR (brew install bash), found $BASH_VERSION" >&2; exit 2; }

while [ $# -gt 0 ]; do
	case $1 in
		--memory-gb) MEMORY_CAP_GB=$2; shift 2 ;;
		--seconds) TIME_CAP_SECONDS=$2; shift 2 ;;
		*) break ;;
	esac
done
[ $# -gt 0 ] || { echo "usage: guarded.sh [--memory-gb <n>] [--seconds <n>] <command…>" >&2; exit 2; }

# the process tree under <root>, three lines: its resident kilobytes in all, the seconds of its oldest process that waits
# on none of the others, its pids; the largest one's command line; the oldest one's
tree_of() {
	ps -A -o pid=,ppid=,rss=,etime=,command= | awk -v root="$1" '
		# ps writes an elapsed time as [[days-]hours:]minutes:seconds
		function seconds_of(elapsed,   parts, count, days) {
			days = 0
			if (index(elapsed, "-")) { split(elapsed, parts, "-"); days = parts[1]; elapsed = parts[2] }
			count = split(elapsed, parts, ":")
			return days * 86400 + (count == 3 ? parts[1] * 3600 + parts[2] * 60 + parts[3] : parts[1] * 60 + parts[2])
		}
		{ pid = $1; parent[pid] = $2; resident[pid] = $3; age[pid] = seconds_of($4); sub(/^ *[0-9]+ +[0-9]+ +[0-9]+ +[0-9:-]+ /, ""); line[pid] = $0 }
		END {
			if (!(root in parent)) exit
			inside[root] = 1
			do { grown = 0; for (p in parent) if (!(p in inside) && (parent[p] in inside)) { inside[p] = 1; grown = 1 } } while (grown)
			for (p in inside) if (p != root) waiting[parent[p]] = 1
			for (p in inside) {
				total += resident[p]; pids = pids " " p
				if (resident[p] >= most) { most = resident[p]; largest = line[p] }
				if (!(p in waiting) && age[p] >= oldest_age) { oldest_age = age[p]; oldest = line[p] }
			}
			print total, oldest_age, pids; print largest; print oldest
		}'
}

"$@" &
command_pid=$!
while :; do
	sleep "$SAMPLE_SECONDS" & sleeper=$!
	wait -n -p ended "$command_pid" "$sleeper"
	status=$?
	[ "$ended" = "$command_pid" ] && { kill "$sleeper" 2>/dev/null; exit $status; }
	{ read -r kilobytes oldest_seconds pids_line; read -r largest; read -r oldest; } < <(tree_of "$command_pid")
	read -r -a pids <<<"${pids_line:-}"
	runaway=
	[ "${kilobytes:-0}" -gt $((MEMORY_CAP_GB * 1024 * 1024)) ] && runaway="took $(awk "BEGIN { printf \"%.1f\", $kilobytes / 1024 / 1024 }") GB, past the cap of $MEMORY_CAP_GB GB. Its largest process: $largest"
	[ "${oldest_seconds:-0}" -gt "$TIME_CAP_SECONDS" ] && runaway="ran a process past the cap of $TIME_CAP_SECONDS s: $oldest"
	[ -n "$runaway" ] || continue
	kill -9 "${pids[@]}" 2>/dev/null
	echo "guarded.sh: killed a runaway: it $runaway" >&2
	wait "$command_pid" 2>/dev/null
	exit $RUNAWAY_STATUS
done
