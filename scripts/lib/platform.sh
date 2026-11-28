# scripts/lib/platform.sh: where the machine-wide job slots live and how many there are (sourced by job-slot.sh); the
# store is the one warp's sessions share on this machine, so wap's and warp's runs take slots from one count
if [ "$(uname)" = Darwin ]; then slot_store=${WARP_COMPILER_STORE:-/Volumes/Build/compilers}
elif [ -d /workspace/warp-store ]; then slot_store=${WARP_COMPILER_STORE:-/workspace/warp-store}  # the box's, shared by its agents
else slot_store=${WARP_COMPILER_STORE:-$HOME/.cache/warp/compilers}; fi
# how many test and census jobs run at once machine-wide, from every worktree: all cores but FREE_CORES, and no more
# than the memory left after MEMORY_RESERVED holds at JOB_PEAK_MEMORY each (a compile of wap peaks at 3.2 GB), or
# <store>/job-slots/count when present (43 parallel test runs of ten workers drove the load to 106)
FREE_CORES=2
JOB_PEAK_MEMORY=$((3584 * 1024 * 1024))
MEMORY_RESERVED=$((8 * 1024 * 1024 * 1024))
# by full path: cron's PATH has no /usr/sbin
memory_bytes() { /usr/sbin/sysctl -n hw.memsize 2>/dev/null || awk '$1 == "MemTotal:" { print $2 * 1024 }' /proc/meminfo; }
job_slots() {
	cat "$slot_store/job-slots/count" 2>/dev/null && return
	local by_cores=$(( $(getconf _NPROCESSORS_ONLN) - FREE_CORES )) by_memory=$(( ($(memory_bytes) - MEMORY_RESERVED) / JOB_PEAK_MEMORY ))
	local slots=$(( by_cores < by_memory ? by_cores : by_memory ))
	[ "$slots" -ge 1 ] || { echo "job_slots: $slots job slots (cores $by_cores, memory $by_memory): memory_bytes or getconf read nothing; write a count to $slot_store/job-slots/count" >&2; return 1; }
	echo "$slots"
}
