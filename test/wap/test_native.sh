#!/usr/bin/env bash
# a wap program of no GC value builds to a native executable, which prints what the program prints
# (wap/extensions/native/build.sh, card wap-command-options). Run it with bash test/wap/test_native.sh; the warp under
# test is WARP (default the warp on PATH). Needs wasm2c and a C compiler
source "$(dirname "$0")/compile.sh"
command -v wasm2c >/dev/null || { echo "⊘ no wasm2c: skipped"; exit 0; }
native_ran() {
	printf '%s\n' "$2" >"$stage/$1.wap"
	WARP=$warp "$tree/wap/extensions/native/build.sh" "$compiler" "$stage/$1.wap" "$stage/$1" 2>&1 && "$stage/$1" 2>&1
}
check "a native hello" "$(native_ran hello 'greeting(): int := prim data_address("Hello\n")
set_word(at: int, word: int) := prim i32.store(at, word)
fd_write(file: int, pieces: int, count: int, written: int): int := prim fd_write(file, pieces, count, written)
set_word(0, greeting())
set_word(4, 6)
written = fd_write(1, 0, 1, 8)
set_word(8, written)')" "Hello"
# a C function the program imports, its pointer an address in the program's memory
check "a native program calls C" "$(native_ran strlen 'strlen(s: pointer): int := prim foreign("c", "strlen", s)
exit(code: int) := prim proc_exit(code)
name(): pointer := prim data_address("wap")
exit(strlen(name()))' >/dev/null; echo $?)" "3"
# a statement's value that is dropped is no value: an if or a match as a statement boxes nothing, so no GC type
check "a native program with an if and a match as statements" "$(native_ran dropped 'exit(code: int) := prim proc_exit(code)
c = yes
if c { 5 }
match 3 { 3 => 1; _ => ø }
exit(7)' >/dev/null; echo $?)" "7"
# the native wap (driver.wap, built by wap): `wap <program>` compiles with the wap.wasm beside it and runs the module
native_wap="$stage/bin/wap"
mkdir -p "$stage/bin/wap-seed" && cp -R "$(dirname "$compiler")/preload" "$(dirname "$compiler")/kernel" "$stage/bin/wap-seed/" && cp "$compiler" "$stage/bin/wap-seed/wap.wasm"
wasmtime_library="$(cd -P "$(dirname "$(command -v "$warp")")/lib" && pwd -P)"
WARP=$warp "$tree/wap/extensions/native/build.sh" "$compiler" "$tree/wap/extensions/native/driver.wap" "$native_wap" -L"$wasmtime_library" -lwarp_wasmtime -Wl,-rpath,"$wasmtime_library" >/dev/null 2>&1
printf '%s\n' 'print "Hello"' >"$stage/hello.wap"
check "wap hello.wap prints Hello" "$(cd "$stage" && "$native_wap" hello.wap 2>&1)" "Hello"
printf '%s\n' 'x = 40000000000' 'x + 2' >"$stage/value.wap"
check "a native wap run shows the program's value" "$(cd "$stage" && "$native_wap" value.wap 2>&1)" "40000000002"
# a program named by an absolute path through a link, which WASI alone would not follow
mkdir -p "$stage/real" && cp "$stage/hello.wap" "$stage/real/" && ln -s "$stage/real" "$stage/linked"
check "a native wap run of a program through a link" "$("$native_wap" "$stage/linked/hello.wap" 2>&1)" "Hello"
# `wap test <areas>` runs the folder's test/wap/run.sh on those areas' scripts, its exit status the run's (a stand-in
# run.sh here, so the suite's own results stay untouched)
mkdir -p "$stage/tested/test/wap" && printf '%s\n' 'echo "$@"' 'exit 3' >"$stage/tested/test/wap/run.sh" && chmod +x "$stage/tested/test/wap/run.sh"
check "wap test runs the areas' scripts" "$(cd "$stage/tested" && "$native_wap" test hello raise; echo "exit $?")" "--wait test/wap/test_hello.sh test/wap/test_raise.sh
exit 3"
# an argument that names no program file is code, run as a program is (core/native/warp.warp is_warp_file)
check "wap runs code given in place of a file" "$("$native_wap" '1+1' 2>&1)" "2"
check "a program file stays after its run" "$(cd "$stage" && "$native_wap" hello.wap >/dev/null && ls hello.wap)" "hello.wap"
# `wap` alone, the console: each line a module of its own, linked to the earlier lines' kept instances, so a definition
# stays for the lines after it and an effect happens once
check "the console keeps a definition and runs each line once" "$(printf '%s\n' 'f(x: int) as int := x * 2' 'print "once"' 'f(21)' | "$native_wap" 2>&1)" "once
42"
# a program using a compiled module (use "m.wasm", extensions/wasm/modules.wap): the native wap links its instance
check "a native wap run links a module the program uses" "$(printf '%s\n' 'add(a: int, b: int) as int := a + b' >"$stage/adding.wap" && $warp "$compiler" "$stage/adding.wap" "$stage/adding.wasm" 2>&1 && "$native_wap" "use \"$stage/adding.wasm\"
add(40, 2)" 2>&1)" "42"
exit $((failures > 0))
