#!/usr/bin/env bash
# all of wap's tests, test/wap/run.sh [--wait] [--stage <n>] [--known] [<tests>] (default every test program test/test_*.wap and
# script test/wap/test_*.wap and test_*.sh; a test is a path or an area, `run.sh nodes`): first wap's compiler compiled and run once,
# or its error, the first signal a worker waits for; then the tests run detached, niced, as many at once as the
# machine's job slots allow (scripts/job-slot.sh, shared by every worktree), each one's output in
# data/wap-tests/<test file>.txt (a script's in data/wap-tests/wap/) and one summary line in data/wap-tests/summary.txt, read later; a run of all tests
# writes its line to data/wap-tests/full-summary.txt too, which a run of some leaves alone (vitals reads it). --wait
# runs them in the foreground and prints the summary. Its modules run on the native wap on PATH. The self-build ratchet,
# ratchet_census.sh (about 4 min), is no default script: run it by name, test/wap/run.sh --wait
# test/wap/ratchet_census.sh, after each wap landing.
# The reds are compared with the baseline test/reds.txt, every check expected red as `<test file>: <check name>`, one
# red on one system only led by its name, `[Linux] test_png.wap: …`: the summary names only the regressions, red checks
# the baseline lacks here, and the fixed ones, the baseline's checks of the tests run that went green here; a run is
# green when it has no regression. --known writes this system's reds of the tests run into the baseline instead, after
# a fix (the fixed lines leave it) or a new _wanted program, leaving what it knows of the other system as it is
here="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
results="$here/../../data/wap-tests"
SUMMARY="$results/summary.txt"
FULL_SUMMARY="$results/full-summary.txt"
KNOWN_REDS="$(cd -P "$here/.." && pwd -P)/reds.txt"
REDS="$results/reds.txt"
# the systems a baseline line may be red on alone, by uname's name: this one and the other
SYSTEMS=(Darwin Linux)
SYSTEM=$(uname -s)
OTHER_SYSTEM=$(printf '%s\n' "${SYSTEMS[@]}" | grep -vx "$SYSTEM")
# two cores stay free for the user's apps
cores=$(( $(getconf _NPROCESSORS_ONLN) - 2 ))
job_slot="$here/../../scripts/job-slot.sh"

# the outputs of the tests run, each data/wap-tests/<test file>.txt, a script's data/wap-tests/wap/<test file>.txt
outputs() {
	for test in "$@"; do
		if in_scripts "$test"; then echo "$results/wap/$(basename "$test").txt"; else echo "$results/$(basename "$test").txt"; fi
	done
}
# a test of test/wap/, however its path is written
in_scripts() { [ "$(cd -P "$(dirname "$1")" && pwd -P)" = "$here" ]; }
# the tests' outputs read into one line: checks passed and failed, the tests that failed
summed() {
	local passed failed
	passed=$(outputs "$@" | xargs cat | grep -c '^✓')
	failed=$(outputs "$@" | xargs cat | grep -c '^✗')
	echo "wap tests: $passed ✓, $failed ✗ in $# tests, $(($(date +%s) - started)) s$( [ "$failed" = 0 ] || printf '; failed: %s' "$(outputs "$@" | xargs grep -l '^✗' | xargs -n1 basename | sed 's/\.txt$//' | tr '\n' ' ')")"
}
# the red checks of the tests run, `<test file>: <check name>` each, without the values got and expected
reds() {
	for test in "$@"; do grep '^✗' "$(outputs "$test")" | sed -e 's/^✗ //' -e 's/: got .*//' -e "s|^|$(basename "$test"): |"; done | LC_ALL=C sort -u
}
# the baseline's lines of the tests run (known_reds in <tests>), or of every other test (known_reds out <tests>)
known_reds() {
	local side=$1
	shift
	[ -f "$KNOWN_REDS" ] || return 0
	# the names of the tests run come first, as a file of their own
	awk -v side="$side" '
		NR == FNR { run[$0]; next }
		{ file = $0; sub(/^\[[^]]*\] /, "", file); sub(/: .*/, "", file) }
		(file in run) == (side == "in")' <(for test in "$@"; do basename "$test"; done) "$KNOWN_REDS" | LC_ALL=C sort -u
}
# the checks of the tests run expected red here: those red everywhere and this system's own, without its name
expected_reds() {
	known_reds in "$@" | awk -v here="[$SYSTEM] " '/^\[/ { if (index($0, here) == 1) print substr($0, length(here) + 1); next } { print }' | LC_ALL=C sort -u
}
# the reds of the tests run against the baseline: the fixed checks and the regressions named, green without a regression
compared() {
	local fixed regressions
	reds "$@" >"$REDS"
	fixed=$(expected_reds "$@" | LC_ALL=C comm -13 "$REDS" -)
	regressions=$(expected_reds "$@" | LC_ALL=C comm -23 "$REDS" -)
	[ -z "$fixed" ] || printf 'fixed, green now (test/wap/run.sh --known records them in test/reds.txt):\n%s\n' "$fixed"
	[ -z "$regressions" ] || printf 'regressions, red and not in test/reds.txt:\n%s\n' "$regressions"
	[ -z "$regressions" ]
}
# the baseline with this system's reds of the tests run in place of what it knew of them here: a check red here and
# known red on the other system is red everywhere; one red everywhere before and green here now is the other system's;
# a red only here is this system's; the other system's own lines stay
known() {
	{ known_reds out "$@"; awk -v here="$SYSTEM" -v other="$OTHER_SYSTEM" '
		NR == FNR { red[$0]; next }
		{ tag = ""; check = $0; if (match(check, /^\[[^]]*\] /)) { tag = substr(check, 2, RLENGTH - 3); check = substr(check, RLENGTH + 1) } }
		tag == here { next }
		check in red { print check; seen[check]; next }
		{ print (tag == "" ? "[" other "] " check : $0) }
		END { for (check in red) if (!(check in seen)) print "[" here "] " check }' "$REDS" <(known_reds in "$@"); } | LC_ALL=C sort -u >"$KNOWN_REDS.$$" && mv "$KNOWN_REDS.$$" "$KNOWN_REDS"
	echo "test/reds.txt now holds the $(wc -l <"$REDS" | tr -d ' ') reds of these tests here"
}
# one test given the compiler under test (one_run <test> <module or "">): a test program, test/test_<area>.wap,
# compiled by it and run; a test script run with it, a wap one, test/wap/test_<area>.wap, compiled by it and given the
# wap binary, it, the script's folder in the tree's data/ and the tree as arguments
one_run() {
	in_scripts "$1" && case $1 in *.wap) set -- "$here/$(basename "$1")" "$2" ;; esac
	case $1 in
		"$here"/*.wap) source "$here/compile.sh" ${2:+--compiler "$2"} && $wap "$compiler" "$1" "$stage/script.wasm" 2>&1 && $wap "$stage/script.wasm" "$wap" "$compiler" "$stage" "$tree" 2>&1 || echo "✗ $(basename "$1") compiled and ran" ;;
		*.wap) source "$here/compile.sh" ${2:+--compiler "$2"} && $wap "$compiler" "$1" "$stage/test.wasm" 2>&1 && $wap "$stage/test.wasm" 2>&1 || echo "✗ $(basename "$1") compiled and ran" ;;
		*) bash "$1" ${2:+--compiler "$2"} ;;
	esac
}
# every test run in a job slot, niced (all_run <module or ""> <all: yes or no> <known: yes or no> <tests>), then the
# summary written, compared with the baseline; a test waiting for its slot says so in its output
all_run() {
	local module=$1 all=$2 record=$3 status
	shift 3
	started=$(date +%s)
	printf '%s\n' "$@" | xargs -P "$cores" -I{} "$job_slot" bash "${BASH_SOURCE[0]}" one_run {} "$module"
	summed "$@" >"$SUMMARY"
	compared "$@" >>"$SUMMARY"; status=$?
	cat "$SUMMARY"
	[ "$all" = no ] || cp "$SUMMARY" "$FULL_SUMMARY"
	[ "$record" = no ] || { known "$@"; return; }
	# the run's exit status: 0 only when no check outside the baseline failed
	return $status
}

# a test that fails without a ✗ of its own, by its exit status or by printing no check at all, fails as one ✗ (a script
# that printed its ✗ lines exits 1 and is counted by them)
[ "$1" = one_run ] && {
	shift
	output=$(outputs "$1")
	# in a subshell, as compile.sh exits when the compiler under test does not build
	(one_run "$@") >"$output" 2>&1; status=$?
	[ $status = 0 ] || grep -q '^✗' "$output" || echo "✗ $(basename "$1") exited $status" >>"$output"
	grep -q '^[✓✗⊘]' "$output" || echo "✗ $(basename "$1") printed no check" >>"$output"
	exit
}
[ "$1" = all_run ] && { shift; all_run "$@"; exit; }
wait=no
built=
record=no
while [ $# -gt 0 ]; do
	case $1 in
		--wait) wait=yes; shift ;;
		--stage) built=$2; shift 2 ;;
		--known) record=yes; shift ;;
		*) break ;;
	esac
done
# the tests named: each a path, or an area, its test programs test/test_<area>.wap and test_<area>_<part>.wap and
# its scripts test/wap/test_<area>.wap and test_<area>.sh; default all of them
programs="$(cd -P "$here/.." && pwd -P)"
shopt -s nullglob
tests=()
for test in "$@"; do
	case $test in
		*/*) tests+=("$test") ;;
		*) found=${#tests[@]}
			for file in "$programs/test_$test.wap" "$programs/test_$test"_*.wap "$here/test_$test.wap" "$here/test_$test.sh"; do [ -f "$file" ] && tests+=("$file"); done
			[ ${#tests[@]} -gt "$found" ] || { echo "no test of $test" >&2; exit 2; } ;;
	esac
done
if [ $# -gt 0 ]; then all=no; set -- "${tests[@]}"; else all=yes; set -- "$programs"/test_*.wap "$here"/test_*.wap "$here"/test_*.sh; fi
for test in "$@"; do [ -f "$test" ] || { echo "no test $test" >&2; exit 2; }; done
mkdir -p "$results/wap" && rm -f $(outputs "$@") "$SUMMARY"
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
if [ $wait = yes ]; then all_run "$module" "$all" "$record" "$@"; else nohup bash "${BASH_SOURCE[0]}" all_run "$module" "$all" "$record" "$@" >/dev/null 2>&1 & fi
