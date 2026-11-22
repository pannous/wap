#!/usr/bin/env bash
# a wap program of no GC value builds to a native executable, which prints what the program prints
# (wap/extensions/native/build.sh, card wap-command-options). Run it with bash test/wap/test_native.sh; its
# modules run on the native wap on PATH. Needs wasm2c and a C compiler
source "$(dirname "$0")/compile.sh"
command -v wasm2c >/dev/null || { echo "⊘ no wasm2c: skipped"; exit 0; }
native_ran() {
	printf '%s\n' "$2" >"$stage/$1.wap"
	"$tree/wap/extensions/native/build.sh" "$compiler" "$stage/$1.wap" "$stage/$1" 2>&1 && "$stage/$1" 2>&1
}
check "a native hello" "$(native_ran hello 'greeting(): int := prim data_address("Hello\n")
set_word(at: int, word: int) := prim i32.store(at, word)
fd_write(file: int, pieces: int, count: int, written: int): int := prim fd_write(file, pieces, count, written)
set_word(0, greeting())
set_word(4, 6)
written = fd_write(1, 0, 1, 8)
set_word(8, written)')" "Hello"
# a C function the program imports, its pointer an address in the program's memory
check "a native program calls C" "$(native_ran strlen 'strlen(s: int32): int := prim foreign("c", "strlen", s)
exit(code: int) := prim proc_exit(code)
name(): int32 := prim data_address("wap")
exit(strlen(name()))' >/dev/null; echo $?)" "3"
# a statement's value that is dropped is no value: an if or a match as a statement boxes nothing, so no GC type
check "a native program with an if and a match as statements" "$(native_ran dropped 'exit(code: int) := prim proc_exit(code)
c = yes
if c { 5 }
match 3 { 3 => 1; _ => ø }
exit(7)' >/dev/null; echo $?)" "7"
check "a native program with an if as a while body's last statement" "$(native_ran dropped_loop 'exit(code: int) := prim proc_exit(code)
k = 0
n = 0
while n < 5 {
	n = n + 1
	if n > 2 { k = k + 1 }
}
exit(k)' >/dev/null; echo $?)" "3"
# the native wap (driver.wap, built by wap): `wap <program>` compiles with the wap.wasm beside it and runs the module
native_wap=$(native_wap_built "$stage/bin")
printf '%s\n' 'print "Hello"' >"$stage/hello.wap"
check "wap hello.wap prints Hello" "$(cd "$stage" && "$native_wap" hello.wap 2>&1)" "Hello"
printf '%s\n' 'x = 40000000000' 'x + 2' >"$stage/value.wap"
check "a native wap run shows the program's value" "$(cd "$stage" && "$native_wap" value.wap 2>&1)" "40000000002"
# a program named by an absolute path through a link, which WASI alone would not follow
mkdir -p "$stage/real" && cp "$stage/hello.wap" "$stage/real/" && ln -s "$stage/real" "$stage/linked"
check "a native wap run of a program through a link" "$("$native_wap" "$stage/linked/hello.wap" 2>&1)" "Hello"
# `wap test <areas>` runs the folder's test/wap/run.sh on those areas, its exit status the run's (a stand-in
# run.sh here, so the suite's own results stay untouched)
mkdir -p "$stage/tested/test/wap" && printf '%s\n' 'echo "$@"' 'exit 3' >"$stage/tested/test/wap/run.sh" && chmod +x "$stage/tested/test/wap/run.sh"
check "wap test runs the areas' tests" "$(cd "$stage/tested" && "$native_wap" test hello raise; echo "exit $?")" "--wait hello raise
exit 3"
# an argument that names no program file is code, run as a program is (core/native/warp.warp is_warp_file)
check "wap runs code given in place of a file" "$("$native_wap" '1+1' 2>&1)" "2"
check "a program file stays after its run" "$(cd "$stage" && "$native_wap" hello.wap >/dev/null && ls hello.wap)" "hello.wap"
# `wap` alone, the console: each line a module of its own, linked to the earlier lines' kept instances, so a definition
# stays for the lines after it and an effect happens once
check "the console keeps a definition and runs each line once" "$(printf '%s\n' 'f(x: int) as int := x * 2' 'print "once"' 'f(21)' | "$native_wap" 2>&1)" "once
42"
# a program using a compiled module (use "m.wasm", extensions/wasm/modules.wap): the native wap links its instance
check "a native wap run links a module the program uses" "$(printf '%s\n' 'add(a: int, b: int) as int := a + b' >"$stage/adding.wap" && $wap "$compiler" "$stage/adding.wap" "$stage/adding.wasm" 2>&1 && "$native_wap" "use \"$stage/adding.wasm\"
add(40, 2)" 2>&1)" "42"
# a console value is the line's exported global, one x every later line reads and its functions use
check "the console keeps a value for the lines after it" "$(printf '%s\n' 'x = 2' 'x + 1' 'f(a: int) as int := a * x' 'f(21)' 't = "ab"' 't + t' | "$native_wap" 2>&1)" "2
3
42
\"ab\"
\"abab\""
# the compiler's machine code, written beside wap.wasm by the first run, read by the next ones
check "the native wap keeps the compiler's machine code beside it" "$(ls "$stage/bin/wap-seed/" | grep -c '^wap-[0-9a-f]*\.cwasm$')" "1"
# a program run again unchanged runs from its machine code kept beside the compiler, never compiled; a change to a file
# it uses compiles it again
check "a program runs again from its kept machine code, compiled anew when a file it uses changes" "$(cd "$stage" && printf '%s\n' 'word() as text := "hi"' >used.wap && printf '%s\n' 'use "used.wap"' 'print word()' >using.wap && "$native_wap" using.wap && "$native_wap" using.wap && printf '%s\n' 'word() as text := "ho"' >used.wap && "$native_wap" using.wap 2>&1)" "hi
hi
ho"
# a compiled module given in place of a program runs as it is, with its arguments (as the compiler runs)
check "wap runs a compiled module with its arguments" "$(printf '%s\n' 'print args#2' >"$stage/arguments.wap" && "$native_wap" "$compiler" "$stage/arguments.wap" "$stage/arguments.wasm" && "$native_wap" "$stage/arguments.wasm" first second 2>&1)" "second"
# a module rebuilt without a word a program it runs imports: the run names that word and the module
check "a run names the word its module no longer exports" "$(cd "$stage" && printf '%s\n' 'one() as int := 1' 'two() as int := 2' >words.wap && "$native_wap" "$compiler" words.wap words.wasm && printf '%s\n' 'use "words.wasm"' 'print text(two())' >wording.wap && "$native_wap" "$compiler" wording.wap wording.wasm && printf '%s\n' 'one() as int := 1' >words.wap && "$native_wap" "$compiler" words.wap words.wasm && "$native_wap" wording.wasm 2>&1)" "wap: no two() → int in words.wasm"
# a used module's finished() runs when the run ends, after the program's own output (host.wap: the sound heard out)
check "a used module's finished runs at the run's end" "$(cd "$stage" && printf '%s\n' 'finished() := print "done"' 'word() as int := 1' >ending.wap && "$native_wap" "$compiler" ending.wap ending.wasm && printf '%s\n' 'use "ending.wasm"' 'print text(word())' >ended.wap && "$native_wap" ended.wap 2>&1)" "1
done"
# a link to the native wap (as a package manager installs one) finds the wap-seed/ beside the file itself
check "a link to the native wap runs a program" "$(ln -sf "$native_wap" "$stage/linked-wap" && "$stage/linked-wap" 'print "linked"' 2>&1)" "linked"
# a program's folder is its source's, wherever its module was written: wap's compiler run from source finds its types
check "the native wap runs wap's compiler from its source" "$(cd "$stage" && printf '%s\n' 'print "Hello"' >hello_source.wap && "$native_wap" "$tree/wap/compiler.wap" hello_source.wap hello_source.wasm && "$native_wap" hello_source.wasm 2>&1)" "Hello"
# C calling back a function of the program run (lib/native/callbacks.h, extensions/native/host_words.wap): qsort
# compares by the program's c_callback_fired
cat >"$stage/sorted.wap" <<'PROGRAM'
qsort(base: int32, count: int, size: int, compare: int) := prim foreign("c", "qsort", base, count, size, compare)
memcpy(destination: int32, source: int, count: int): int := prim foreign("c", "memcpy", destination, source, count)
c_callback_pointer(slot: int): int := prim foreign("c", "c_callback_pointer", slot)
address(at: int): int32 := prim i32.wrap_i64(at)
set_word(at: int, w: int) := prim i32.store(at, w)
word(at: int): int := prim i32.load(at)
ARRAY_AT := 2048
SCRATCH_AT := 3072
# C's compare of the two ints it points at
c_callback_fired(slot: int, a: int, b: int, c: int, d: int, e: int, f: int): int := {
	memcpy(address(SCRATCH_AT), a, 4)
	memcpy(address(SCRATCH_AT + 4), b, 4)
	word(SCRATCH_AT) - word(SCRATCH_AT + 4)
}
set_word(ARRAY_AT, 3)
set_word(ARRAY_AT + 4, 1)
set_word(ARRAY_AT + 8, 2)
qsort(address(ARRAY_AT), 3, 4, c_callback_pointer(0))
print "${word(ARRAY_AT)} ${word(ARRAY_AT + 4)} ${word(ARRAY_AT + 8)}"
PROGRAM
check "C calls back a function of the program the native wap runs" "$(cd "$stage" && "$native_wap" sorted.wap 2>&1)" "1 2 3"
# texts in a native program, held in its memory (types/memory_texts.wap): literals, + and interpolation,
# equality, print, and a text passed to C
check "a native program's texts" "$(native_ran texts 'strlen(s: text): i64 from '"'"'c'"'"'
name = "wap"
greeting = "hello " + name
print greeting
print "${greeting} has ${strlen(greeting)} bytes"
print(if name == "wap" then "same" else "other")')" "hello wap
hello wap has 9 bytes
same"
# a module's `export` is exported by the program that uses it too, under its plain name: C calls back the module's
# c_callback_fired though the program defines none
cat >"$stage/comparing.wap" <<'MODULE'
memcpy(destination: int32, source: int, count: int): int := prim foreign("c", "memcpy", destination, source, count)
word(at: int): int := prim i32.load(at)
SCRATCH_AT := 3072
export c_callback_fired(slot: int, a: int, b: int, c: int, d: int, e: int, f: int): int := {
	memcpy(prim i32.wrap_i64(SCRATCH_AT), a, 4)
	memcpy(prim i32.wrap_i64(SCRATCH_AT + 4), b, 4)
	word(SCRATCH_AT) - word(SCRATCH_AT + 4)
}
MODULE
cat >"$stage/sorting.wap" <<'PROGRAM'
use "comparing.wap"
qsort(base: int32, count: int, size: int, compare: int) := prim foreign("c", "qsort", base, count, size, compare)
c_callback_pointer(slot: int): int := prim foreign("c", "c_callback_pointer", slot)
set_word(at: int, w: int) := prim i32.store(at, w)
item(at: int): int := prim i32.load(at)
ARRAY_AT := 2048
set_word(ARRAY_AT, 2)
set_word(ARRAY_AT + 4, 3)
set_word(ARRAY_AT + 8, 1)
qsort(prim i32.wrap_i64(ARRAY_AT), 3, 4, c_callback_pointer(0))
print "${item(ARRAY_AT)} ${item(ARRAY_AT + 4)} ${item(ARRAY_AT + 8)}"
PROGRAM
check "C calls back the export of a module the program uses" "$(cd "$stage" && "$native_wap" sorting.wap 2>&1)" "1 2 3"
exit $((failures > 0))
