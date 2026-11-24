#!/usr/bin/env bash
# The self-build, file by file (notes/backbone.md milestone 2, point 2): wap compiles one of its own
# files, each alone, and the module it makes loads and runs. Source: warp-lead's self-build plan,
# 2026-11-18. Run it with bash test/wap/test_self.sh; its modules run on the native wap on PATH
source "$(dirname "$0")/compile.sh"
root="$(cd -P "$(dirname "$0")/../.." && pwd -P)"
# how many CPU seconds wap1 may take to compile wap's compiler (milestone 2, notes/backbone.md)
SELF_COMPILE_SECONDS=60

# what loading the module wap makes of a file of wap's own says: "loads", or the compiler's or the run's error
loaded() {
	local module="$stage/$(basename "$1" .wap).wasm"
	$wap "$compiler" "$root/$1" "$module" 2>&1 && $wap "$module" >/dev/null 2>&1 && echo loads
}

# every file of wap's own, but the compiler (stage 2 below compiles it whole), the files every program meets beside it
# already, the types module's (compiled as a program, their words would be defined twice, which a program may not:
# wiki/function.md, own-type-overloads, user 2026-11-23), the native extension's programs, which run only built to
# machine code (wap/extensions/native), and the theory's door with its prelude: the door is a program that takes the
# file it checks, and the prelude is that file, written in the explicit spellings only the door reads
# (notes/theory.md "The door"); both run in test/wap/test_theory*.wap
NOT_ALONE=(wap/compiler.wap wap/nodes.wap wap/extensions/theory/check.wap)
NOT_MODULES=(-e '^wap/types/' -e '^wap/extensions/native/' -e '^wap/extensions/theory/prelude/')
files=($(cd "$root" && git ls-files 'wap/*.wap' | grep -v -x -F "${NOT_ALONE[@]/#/-e}" | grep -v "${NOT_MODULES[@]}"))
for file in "${files[@]}"; do
	check "wap compiles $file and the result loads" "$(loaded "$file")" "loads"
done
# Stage 2: the module wap makes of its own compiler, wap1, compiles programs, and they run; it is built once, its
# types beside it (compile.sh compiler_built)
wap1=$(compiler_built "$stage/self" 1)
# wap1 built, or why not
wap1_built() { [ -f "$wap1" ] || { echo "$wap1"; return 1; }; }
# what a program compiled by wap1 prints, or the error of either
self_built_ran() {
	wap1_built || return
	printf '%s\n' "$2" >"$stage/$1.wap"
	$wap "$wap1" "$stage/$1.wap" "$stage/$1.wasm" 2>&1 && $wap "$stage/$1.wasm" 2>&1
}
check "the compiler wap makes of itself compiles a program that runs" "$(self_built_ran hello 'print "hello from wap"')" "hello from wap"
# and compiles wap's compiler in under a minute (milestone 2, notes/backbone.md), its CPU seconds (user and system),
# so the machine's load leaves the measure alone
self_compile_time() {
	wap1_built || return
	local cpu seconds TIMEFORMAT="%U %S"
	cpu=$( { time $wap "$wap1" "$source_compiler" "$stage/self/wap2.wasm" >"$stage/self/compiled.txt" 2>&1; } 2>&1 ) || { cat "$stage/self/compiled.txt"; return; }
	seconds=$(echo "$cpu" | awk '{ printf "%d", $1 + $2 }')
	[ $seconds -lt $SELF_COMPILE_SECONDS ] && echo "under a minute" || echo "$seconds s CPU"
}
check "wap1 compiles wap's compiler in under a minute" "$(self_compile_time)" "under a minute"
exit $((failures > 0))
