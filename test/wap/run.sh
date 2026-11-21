#!/usr/bin/env bash
# all of wap's tests, test/wap/run.sh [--wait] [--stage <n>] [<tests>] (default every test program test/test_*.wap and
# script test/wap/test_*.sh; a test is a path or an area, `run.sh nodes`): first wap's compiler compiled and run once,
# or its error, the first signal a worker waits for; then the tests run detached, niced, as many at once as the
# machine's job slots allow (scripts/job-slot.sh, shared by every worktree), each one's output in
# data/wap-tests/<test file>.txt and one summary line in data/wap-tests/summary.txt, read later; a run of all tests
# writes its line to data/wap-tests/full-summary.txt too, which a run of some leaves alone (vitals reads it). --wait
# runs them in the foreground and prints the summary. The warp under test is WARP (default the warp on PATH). The self-build ratchet,
# ratchet_census.sh (about 4 min), is no default script: run it by name, test/wap/run.sh --wait
# test/wap/ratchet_census.sh, after each wap landing
here="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
results="$here/../../data/wap-tests"
SUMMARY="$results/summary.txt"
FULL_SUMMARY="$results/full-summary.txt"
cores=$(getconf _NPROCESSORS_ONLN)
job_slot="$here/../../scripts/job-slot.sh"

# the outputs of the tests run, each data/wap-tests/<test file>.txt
outputs() { for test in "$@"; do echo "$results/$(basename "$test").txt"; done; }
# the tests' outputs read into one line: checks passed and failed, the tests that failed
summed() {
	local passed failed
	passed=$(outputs "$@" | xargs cat | grep -c '^✓')
	failed=$(outputs "$@" | xargs cat | grep -c '^✗')
	echo "wap tests: $passed ✓, $failed ✗ in $# tests, $(($(date +%s) - started)) s$( [ "$failed" = 0 ] || printf '; failed: %s' "$(outputs "$@" | xargs grep -l '^✗' | xargs -n1 basename | sed 's/\.txt$//' | tr '\n' ' ')")"
}
# one test given the compiler under test (one_run <test> <module or "">): a test program, test/test_<area>.wap,
# compiled by it and run; a test script run with it
one_run() {
	case $1 in
		*.wap) source "$here/compile.sh" ${2:+--compiler "$2"} && $warp "$compiler" "$1" "$stage/test.wasm" 2>&1 && $warp "$stage/test.wasm" 2>&1 || echo "✗ $(basename "$1") compiled and ran" ;;
		*) bash "$1" ${2:+--compiler "$2"} ;;
	esac
}
# every test run in a job slot, niced (all_run <module or ""> <all: yes or no> <tests>), then the summary written; a
# test waiting for its slot says so in its output
all_run() {
	local module=$1 all=$2
	shift 2
	started=$(date +%s)
	printf '%s\n' "$@" | xargs -P "$cores" -I{} "$job_slot" bash "${BASH_SOURCE[0]}" one_run {} "$module"
	summed "$@" | tee "$SUMMARY"
	[ "$all" = no ] || cp "$SUMMARY" "$FULL_SUMMARY"
	# the run's exit status: 0 only when no check failed
	grep -q ' 0 ✗' "$SUMMARY"
}

[ "$1" = one_run ] && { shift; one_run "$@" >"$(outputs "$1")" 2>&1; exit; }
[ "$1" = all_run ] && { shift; all_run "$@"; exit; }
wait=no
built=
while [ $# -gt 0 ]; do
	case $1 in
		--wait) wait=yes; shift ;;
		--stage) built=$2; shift 2 ;;
		*) break ;;
	esac
done
# the tests named: each a path, or an area, its test programs test/test_<area>.wap and test_<area>_<part>.wap and
# its script test/wap/test_<area>.sh; default all of them
programs="$(cd -P "$here/.." && pwd -P)"
shopt -s nullglob
tests=()
for test in "$@"; do
	case $test in
		*/*) tests+=("$test") ;;
		*) found=${#tests[@]}
			for file in "$programs/test_$test.wap" "$programs/test_$test"_*.wap "$here/test_$test.sh"; do [ -f "$file" ] && tests+=("$file"); done
			[ ${#tests[@]} -gt "$found" ] || { echo "no test of $test" >&2; exit 2; } ;;
	esac
done
if [ $# -gt 0 ]; then all=no; set -- "${tests[@]}"; else all=yes; set -- "$programs"/test_*.wap "$here"/test_*.sh; fi
for test in "$@"; do [ -f "$test" ] || { echo "no test $test" >&2; exit 2; }; done
mkdir -p "$results" && rm -f $(outputs "$@") "$SUMMARY"
source "$here/compile.sh"
# --stage <n>: the compiler under test is wap<n>, wap built by itself n times (milestone 2: the tests pass with wap2)
module=
if [ -n "$built" ]; then
	rm -rf "$results/stage"
	module=$(compiler_built "$results/stage" "$built") || { echo "wap$built: $module"; exit 1; }
	compiler=$module
fi
# the first signal: wap's compiler compiles and runs, reading an empty program
said=$(ran empty '') || { echo "wap compiler: $said"; exit 1; }
echo "wap compiler OK; the checks of $# tests run$( [ $wait = yes ] || echo " in the background: summary in $SUMMARY")"
if [ $wait = yes ]; then all_run "$module" "$all" "$@"; else nohup bash "${BASH_SOURCE[0]}" all_run "$module" "$all" "$@" >/dev/null 2>&1 & fi
