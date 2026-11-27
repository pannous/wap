#!/usr/bin/env bash
# The self-build, file by file (notes/backbone.md milestone 2, point 2): wap compiles one of its own
# files, each alone, and the module it makes loads and runs. Source: warp-lead's self-build plan,
# 2026-11-18. Run it with bash test/wap/test_self.sh; its modules run on the native wap on PATH
source "$(dirname "$0")/compile.sh"
root="$(cd -P "$(dirname "$0")/../.." && pwd -P)"
# how many CPU seconds wap1 may take to compile wap's compiler (milestone 2, notes/backbone.md)
SELF_COMPILE_SECONDS=60
# the instructions wap1 retires compiling wap's compiler, main's as measured (notes/speed.md), and how many percent
# more a change may take: lower the ceiling when a landing measures less, raise it only with the change's OK
SELF_COMPILE_INSTRUCTIONS=187278247059
SLOWER_PERCENT=1

# what loading the module wap makes of a file of wap's own says: "loads", or the compiler's or the run's error
loaded() {
	local module="$stage/$(basename "$1" .wap).wasm"
	$wap "$compiler" "$root/$1" "$module" 2>&1 && $wap "$module" >/dev/null 2>&1 && echo loads
}

# every file of wap's own, but the compiler (stage 2 below compiles it whole), the files every program meets beside it
# already, the types module's (compiled as a program, their words would be defined twice, which a program may not:
# wiki/function.md, own-type-overloads, user 2026-11-23) and the native extension's programs, which run only built to
# machine code (wap/extensions/native)
NOT_ALONE=(wap/compiler.wap wap/nodes.wap)
MET_OR_NATIVE=(-e '^wap/types/' -e '^wap/extensions/native/')
files=($(cd "$root" && compiler_sources | grep -v -x -F "${NOT_ALONE[@]/#/-e}" | grep -v "${MET_OR_NATIVE[@]}"))
for file in "${files[@]}"; do
	check "wap compiles $file and the result loads" "$(loaded "$file")" "loads"
done
# Stage 2: the module wap makes of its own compiler, wap1, compiles programs, and they run; wap1's build of the
# compiler, wap2, is the same bytes, a fixed point; both are built once, their types beside them (compile.sh
# compiler_built)
wap2=$(compiler_built "$stage/self" 2)
wap1=${wap2%2.wasm}1.wasm
# wap1 built, or why not
wap1_built() { [ -f "$wap1" ] || { echo "$wap2"; return 1; }; }
# what a program compiled by wap1 prints, or the error of either
self_built_ran() {
	wap1_built || return
	printf '%s\n' "$2" >"$stage/$1.wap"
	$wap "$wap1" "$stage/$1.wap" "$stage/$1.wasm" 2>&1 && $wap "$stage/$1.wasm" 2>&1
}
check "the compiler wap makes of itself compiles a program that runs" "$(self_built_ran hello 'print "hello from wap"')" "hello from wap"
check "wap built by itself is a fixed point: wap2 is wap1's bytes" "$(wap1_built && { cmp -s "$wap1" "$wap2" && echo same || echo differs; })" "same"
# and compiles wap's compiler in under a minute (milestone 2, notes/backbone.md), its CPU seconds (user and system),
# so the machine's load leaves the measure alone
# what the run retires is measured too, by the system's time
measured="$stage/self/measured.txt"
self_compile_time() {
	wap1_built || return
	"$tree/scripts/job-slot.sh" --alone /usr/bin/time -lp $wap "$wap1" "$source_compiler" "$stage/self/compiled.wasm" >"$stage/self/compiled.txt" 2>"$measured" || { cat "$stage/self/compiled.txt" "$measured"; return; }
	seconds=$(awk '$1 == "user" || $1 == "sys" { cpu += $2 } END { printf "%d", cpu }' "$measured")
	[ $seconds -lt $SELF_COMPILE_SECONDS ] && echo "under a minute" || echo "$seconds s CPU"
}
check "wap1 compiles wap's compiler in under a minute" "$(self_compile_time)" "under a minute"
# the instructions that run retired, at most main's and the slack (a machine whose time counts none says so)
self_compile_instructions() {
	retired=$(awk '$2 == "instructions" && $3 == "retired" { print $1 }' "$measured" 2>/dev/null)
	[ -n "$retired" ] || { echo "no instructions counted"; return; }
	# the count beside the check, green or red, so a landing reads its speed off this run
	echo "— wap1 retired $retired instructions compiling wap's compiler" >&2
	[ $((retired * 100)) -le $((SELF_COMPILE_INSTRUCTIONS * (100 + SLOWER_PERCENT))) ] && echo "as fast as main" || echo "$retired instructions, main's $SELF_COMPILE_INSTRUCTIONS"
}
check "wap1 compiles wap's compiler at most $SLOWER_PERCENT% slower than main" "$(self_compile_instructions)" "as fast as main"
exit $((failures > 0))
