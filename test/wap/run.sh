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
# The reds are compared with the baseline test/reds.txt, every check expected red as `<test key>: <check name>` (test_key), one
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
# a test runs headless: whatever it shows is saved, never painted in a window (the native wap's --no-window)
HEADLESS=--no-window
OTHER_SYSTEM=$(printf '%s\n' "${SYSTEMS[@]}" | grep -vx "$SYSTEM")
# two cores stay free for the user's apps
cores=$(( $(getconf _NPROCESSORS_ONLN) - 2 ))
job_slot="$here/../../scripts/job-slot.sh"
# a _wanted program compiles without at most this many of its statements, each red, and how much of one names its red
WANTED_REFUSALS=60
RED_NAME_LENGTH=120
# the last line of a test's output once it ran to its end and its status was judged; an output without it was cut
# short (a signal, a memory or time guard, a crash) and its later checks never printed
ENDED="— ran to its end"
# a test's wall time, the line before ENDED: the next run starts the longest tests first, so none ends the run alone
TOOK="— took"
# a statement starts at the margin; an indented line, a closing bracket or a comment there is none
STATEMENT_START='^[^] \t})#]'

# the outputs of the tests run, each data/wap-tests/<test key>.txt
outputs() { for test in "$@"; do echo "$results/$(test_key "$test").txt"; done; }
# a test's name in the baseline and the outputs: a program's file name, a script's wap/<file name>, so a program and a
# script of one file name (test/test_types.wap, test/wap/test_types.wap) keep their reds apart
test_key() { if in_scripts "$1"; then echo "wap/$(basename "$1")"; else basename "$1"; fi; }
# a test of test/wap/, however its path is written
in_scripts() { [ "$(cd -P "$(dirname "$1")" && pwd -P)" = "$here" ]; }
# the tests' outputs read into one line: checks passed and failed, the tests that failed
summed() {
	local passed failed
	passed=$(outputs "$@" | xargs cat | grep -c '^✓')
	failed=$(outputs "$@" | xargs cat | grep -c '^✗')
	echo "wap tests: $passed ✓, $failed ✗ in $# tests, $(($(date +%s) - started)) s$( [ "$failed" = 0 ] || printf '; failed: %s' "$(outputs "$@" | xargs grep -l '^✗' | sed -e "s|^$results/||" -e 's/\.txt$//' | tr '\n' ' ')")"
}
# the red checks of the tests run, `<test file>: <check name>` each, without the values got and expected
# a test that did not compile and run through read none of its checks after that: each the baseline expects red stays red
reds() {
	for test in "$@"; do
		grep '^✗' "$(outputs "$test")" | sed -e 's/^✗ //' -e 's/: got .*//' -e "s|^|$(test_key "$test"): |"
		! grep -qE "^✗ $(basename "$test") (compiled and ran|ran to its end)" "$(outputs "$test")" || expected_reds "$test"
	done | LC_ALL=C sort -u
}
# the baseline's lines of the tests run (known_reds in <tests>), or of every other test (known_reds out <tests>)
known_reds() {
	local side=$1
	shift
	[ -f "$KNOWN_REDS" ] || return 0
	# the names of the tests run come first, as a file of their own
	awk -v side="$side" '
		FILENAME == ARGV[1] { run[$0]; next }
		{ file = $0; sub(/^\[[^]]*\] /, "", file); sub(/: .*/, "", file) }
		(file in run) == (side == "in")' <(for test in "$@"; do test_key "$test"; done) "$KNOWN_REDS" | LC_ALL=C sort -u
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
		FILENAME == ARGV[1] { red[$0]; next }
		{ tag = ""; check = $0; if (match(check, /^\[[^]]*\] /)) { tag = substr(check, 2, RLENGTH - 3); check = substr(check, RLENGTH + 1) } }
		tag == here { next }
		check in red { print check; seen[check]; next }
		{ print (tag == "" ? "[" other "] " check : $0) }
		END { for (check in red) if (!(check in seen)) print "[" here "] " check }' "$REDS" <(known_reds in "$@"); } | LC_ALL=C sort -u >"$KNOWN_REDS.$$" && mv "$KNOWN_REDS.$$" "$KNOWN_REDS"
	echo "test/reds.txt now holds the $(wc -l <"$REDS" | tr -d ' ') reds of these tests here"
}
# a _wanted program run from $stage/test.wasm without each statement the compiler refuses or the run stops at, that
# statement red with the refusal or the trap, so the forms wap builds still run: a statement is a line at the margin and
# the lines indented or closing under it, blanked so the other lines keep their numbers; a dropped check is red by its
# name, as when it runs
wanted_ran() {
	local program="$stage/$(basename "$1")" dropped=0 start said wanted
	cp "$1" "$(dirname "$1")/check.wap" "$stage/"
	while true; do
		if ! said=$($wap "$compiler" "$program" "$stage/test.wasm" 2>&1); then
			start=$(statement_at "$program" "$(echo "$said" | sed -n "s|^$program line \([0-9]*\):.*|\1|p" | head -1)")
			said=$(echo "$said" | head -1 | sed "s|^$program ||")
			wanted="it compiles"
		elif said=$($wap $HEADLESS "$stage/test.wasm" 2>&1); then
			echo "$said"
			return
		else
			start=$(trapping_statement "$program")
			said=$(echo "$said" | grep -m1 -o 'wasm trap: .*' || echo "$said" | tail -1)
			wanted="it runs"
		fi
		[ -n "$start" ] && [ $((dropped += 1)) -le $WANTED_REFUSALS ] || { echo "$said"; return 1; }
		echo "✗ $(sed -n "${start}p" "$program" | sed 's/^check("\([^"]*\)".*/\1/' | cut -c1-$RED_NAME_LENGTH): got $said, expected $wanted"
		awk -v start="$start" -v statement="$STATEMENT_START" 'NR > start && $0 ~ statement { start = 0 } start && NR >= start { $0 = "" } 1' "$program" >"$program.blanked" && mv "$program.blanked" "$program"
	done
}
# the start of the statement a line of the program belongs to, none for a line no statement holds
statement_at() {
	[ -n "$2" ] && awk -v line="$2" -v statement="$STATEMENT_START" 'NR <= line && $0 ~ statement { start = NR } END { print start }' "$1"
}
# the statement a run of the program stops at: the first one whose program, cut after it, stops too, the statements
# left to try halved by each cut program compiled and run (the whole program stops)
trapping_statement() {
	local starts low=0 high middle
	starts=($(awk -v statement="$STATEMENT_START" '$0 ~ statement { print NR }' "$1"))
	high=$((${#starts[@]} - 1))
	while [ $low -lt $high ]; do
		middle=$(((low + high) / 2))
		if cut_stops "$1" "${starts[$((middle + 1))]}"; then high=$middle; else low=$((middle + 1)); fi
	done
	echo "${starts[$low]}"
}
# whether the program cut before a line compiles and its run stops
cut_stops() {
	awk -v cut="$2" 'NR >= cut { $0 = "" } 1' "$1" >"$stage/cut.wap"
	$wap "$compiler" "$stage/cut.wap" "$stage/cut.wasm" >/dev/null 2>&1 && ! $wap $HEADLESS "$stage/cut.wasm" >/dev/null 2>&1
}
# one test given the compiler under test (one_run <test> <module or "">): a test program, test/test_<area>.wap,
# compiled by it and run; a test script run with it, a wap one, test/wap/test_<area>.wap, compiled by it and given the
# wap binary, it, the script's folder in the tree's data/ and the tree as arguments
one_run() {
	in_scripts "$1" && case $1 in *.wap) set -- "$here/$(basename "$1")" "$2" ;; esac
	case $1 in
		"$here"/*.wap) source "$here/compile.sh" ${2:+--compiler "$2"} && $wap "$compiler" "$1" "$stage/script.wasm" 2>&1 && $wap $HEADLESS "$stage/script.wasm" "$wap" "$compiler" "$stage" "$tree" 2>&1 || echo "✗ $(basename "$1") compiled and ran" ;;
		*_wanted.wap) source "$here/compile.sh" ${2:+--compiler "$2"} && wanted_ran "$1" || echo "✗ $(basename "$1") compiled and ran" ;;
		*.wap) source "$here/compile.sh" ${2:+--compiler "$2"} && $wap "$compiler" "$1" "$stage/test.wasm" 2>&1 && $wap $HEADLESS "$stage/test.wasm" 2>&1 || echo "✗ $(basename "$1") compiled and ran" ;;
		*) bash "$1" ${2:+--compiler "$2"} ;;
	esac
}
# the tests, the longest of their last run first (a test not run before counts as quick)
longest_first() {
	for test in "$@"; do printf '%s\t%s\n' "$(sed -n "s/^$TOOK \([0-9]*\) s$/\1/p" "$(outputs "$test")" 2>/dev/null | tail -1)" "$test"; done | sort -t $'\t' -k1,1nr | cut -f2-
}
# a test whose output does not end with ENDED was cut short: one ✗ says so, whoever killed it
ended() { [ "$(tail -n 1 "$(outputs "$1")" 2>/dev/null)" = "$ENDED" ] || echo "✗ $(basename "$1") ran to its end" >>"$(outputs "$1")"; }
# every test run in a job slot, niced (all_run <module or ""> <all: yes or no> <known: yes or no> <tests>), then the
# summary written, compared with the baseline; a test waiting for its slot says so in its output
all_run() {
	local module=$1 all=$2 record=$3 status
	shift 3
	started=$(date +%s)
	printf '%s\n' "$@" | xargs -P "$cores" -I{} "$job_slot" bash "${BASH_SOURCE[0]}" one_run {} "$module"
	for test in "$@"; do ended "$test"; done
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
	began=$(date +%s)
	# in a subshell, as compile.sh exits when the compiler under test does not build
	(one_run "$@") >"$output" 2>&1; status=$?
	[ $status = 0 ] || grep -q '^✗' "$output" || echo "✗ $(basename "$1") exited $status" >>"$output"
	grep -q '^[✓✗⊘]' "$output" || echo "✗ $(basename "$1") printed no check" >>"$output"
	echo "$TOOK $(($(date +%s) - began)) s" >>"$output"
	echo "$ENDED" >>"$output"
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
mapfile -t ordered < <(longest_first "$@") && set -- "${ordered[@]}"
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
