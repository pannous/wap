# scripts/lib/platform.sh: where the machine-wide job slots live and how many there are (sourced by job-slot.sh); the
# store is the one warp's sessions share on this machine, so wap's and warp's runs take slots from one count
if [ "$(uname)" = Darwin ]; then slot_store=${WARP_COMPILER_STORE:-/Volumes/Build/compilers}
elif [ -d /workspace/warp-store ]; then slot_store=${WARP_COMPILER_STORE:-/workspace/warp-store}  # the box's, shared by its agents
else slot_store=${WARP_COMPILER_STORE:-$HOME/.cache/warp/compilers}; fi
# how many test and census jobs run at once machine-wide, from every worktree: all cores but FREE_CORES, or
# <store>/job-slots/count when present (43 parallel test runs of ten workers drove the load to 106)
FREE_CORES=2
job_slots() { cat "$slot_store/job-slots/count" 2>/dev/null || echo $(( $(getconf _NPROCESSORS_ONLN) - FREE_CORES )); }
