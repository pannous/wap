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
set_word(0, greeting())
set_word(4, 6)
written = fd_write(1, 0, 1, 8)
set_word(8, written)')" "Hello"
# a C function the program imports, its pointer an address in the program's memory
check "a native program calls C" "$(native_ran strlen 'strlen(s: int32): int := prim foreign("c", "strlen", s)
name(): int32 := prim data_address("wap")
exit(strlen(name()))' >/dev/null; echo $?)" "3"
# a statement's value that is dropped is no value: an if or a match as a statement boxes nothing, so no GC type
check "a native program with an if and a match as statements" "$(native_ran dropped 'c = yes
if c { 5 }
match 3 { 3 => 1; _ => ø }
exit(7)' >/dev/null; echo $?)" "7"
check "a native program with an if as a while body's last statement" "$(native_ran dropped_loop 'k = 0
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
# the native wap's commands and options, one table (wap/extensions/native/commands.wap; card wap-help)
check "wap help lists the commands and the options" "$("$native_wap" help | grep -c -e '^  wap run ' -e '^  wap repl ' -e '^  wap test ' -e '^  wap version ' -e '^  --memory-gb ' -e '^  --seconds ')" "6"
check "wap --help and wap -h are wap help" "$([ "$("$native_wap" --help)" = "$("$native_wap" help)" ] && [ "$("$native_wap" -h)" = "$("$native_wap" help)" ] && echo same)" "same"
check "wap version shows wap's version, when the native wap was built and the compiler's stamp, as warp version does" "$("$native_wap" version | grep -c -e '^🌀 Wap [0-9.]* (/.*wap.wasm)$' -e '^the native wap · built 20[0-9][0-9]-[01][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]$' -e '^wap.wasm ')" "3"
check "wap help starts with the version line" "$("$native_wap" help | head -1 | grep -c '^🌀 Wap ')" "1"
check "wap run runs a program" "$(cd "$stage" && "$native_wap" run hello.wap 2>&1)" "Hello"
check "wap repl is the console" "$(printf '%s\n' '20 + 22' | "$native_wap" repl 2>&1)" "42"
check "an unknown option is refused with the options, never run as code" "$("$native_wap" --nope 2>&1 | head -1; "$native_wap" --nope >/dev/null 2>&1; echo $?)" "wap: no option --nope; the options, before the command or file:
2"
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
check "wap build makes a program a native executable named as it" "$(cd "$tree" && "$native_wap" build "$stage/hello.wap" >/dev/null 2>&1 && "$stage/hello" 2>&1)" "Hello"
# an argument that names no program file is code, run as a program is (core/native/warp.warp is_warp_file)
check "wap runs code given in place of a file" "$("$native_wap" '1+1' 2>&1)" "2"
# code given runs without a TMPDIR too, as under cron: its files go to the user's temporary folder
# no window under --no-window: a program calling a C function annotated `@Device` (wiki/c.md) stops at the call
check "wap --no-window refuses a program that opens a window" "$(cd "$stage" && printf '%s\n' "@Device InitWindow(width: i64, height: i64, title: text): ø from 'no_such_library'" 'InitWindow(8, 8, "shown")' >window.wap && "$native_wap" --no-window window.wap 2>&1; echo $?)" "wap: InitWindow from no_such_library opens a window or a sound device: refused under --no-window
1"
check "wap runs code given in place of a file without a TMPDIR" "$(env -u TMPDIR "$native_wap" '1+1' 2>&1)" "2"
check "a program file stays after its run" "$(cd "$stage" && "$native_wap" hello.wap >/dev/null && ls hello.wap)" "hello.wap"
# `wap` alone, the console: each line a module of its own, linked to the earlier lines' kept instances, so a definition
# stays for the lines after it and an effect happens once
check "the console keeps a definition and runs each line once" "$(printf '%s\n' 'f(x: int) as int := x * 2' 'print "once"' 'f(21)' | "$native_wap" 2>&1)" "once
42"
# a line that only prints defines nothing, though its module exports the exception tag: no later line runs it again
check "the console runs a line that only prints once, after a value" "$(printf '%s\n' 'x = 5' 'print "a"' 'x + 1' | "$native_wap" 2>&1)" "5
a
6"
# a program using a compiled module (use "m.wasm", extensions/wasm/modules.wap): the native wap links its instance
check "a native wap run links a module the program uses" "$(printf '%s\n' 'add(a: int, b: int) as int := a + b' >"$stage/adding.wap" && $wap "$compiler" "$stage/adding.wap" "$stage/adding.wasm" 2>&1 && "$native_wap" "use \"$stage/adding.wasm\"
add(40, 2)" 2>&1)" "42"
# a module the program uses gone before the run: said once, however many of its words the program calls
printf '%s\n' 'add(a: int, b: int) as int := a + b' 'twice(a: int) as int := a * 2' >"$stage/gone.wap" && $wap "$compiler" "$stage/gone.wap" "$stage/gone.wasm" >/dev/null 2>&1
printf '%s\n' "use \"$stage/gone.wasm\"" 'print add(1, 2)' 'print twice(3)' >"$stage/using_gone.wap" && $wap "$compiler" "$stage/using_gone.wap" "$stage/using_gone.wasm" >/dev/null 2>&1 && rm "$stage/gone.wasm"
check "a missing module is said once" "$("$native_wap" "$stage/using_gone.wasm" 2>&1 | grep -c 'no module')" "1"
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
# and it finds the tree's standard library, the nearest folder lib at or above its own (core/paths.wap library_of)
check "wap's compiler run from its source uses a library module" "$(cd "$stage" && printf '%s\n' 'use version' 'print version 1.9 < version 1.10.0' >library_source.wap && "$native_wap" "$tree/wap/compiler.wap" library_source.wap library_source.wasm && "$native_wap" library_source.wasm 2>&1)" "yes"
# a compiler with no lib beside it nor one folder above it refuses a program that uses the library, saying so
printf '%s\n' 'use version' >"$stage/uses_library.wap"
check "a compiler with no library beside it nor above it says so where a program uses it" "$(rm -rf "$stage/lonely" && mkdir -p "$stage/lonely" && cp -R "$tree/wap" "$stage/lonely/" && : >"$stage/lonely/wap/warm.packed" && : >"$stage/lonely/wap/types.wasm" && cd "$stage" && "$native_wap" "$stage/lonely/wap/compiler.wap" uses_library.wap uses_library.wasm 2>&1 | grep -c 'no standard library: no folder lib beside .*/lonely/wap or above it')" "1"
# the provers (wap/extensions/proof) are no part of the compiler: a tree without them compiles and runs a hello
check "a tree without extensions/proof compiles a hello" "$(rm -rf "$stage/proofless" && mkdir -p "$stage/proofless" && cp -R "$tree/wap" "$stage/proofless/" && rm -rf "$stage/proofless/wap/extensions/proof" && cd "$stage" && "$native_wap" "$stage/proofless/wap/compiler.wap" hello.wap proofless.wasm && "$native_wap" proofless.wasm 2>&1)" "Hello"
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
# lists in a native program, held in its memory (types/memory_lists.wap): literals, #, items, add, a loop,
# lists of texts and of ints passed between functions
check "a native program's lists" "$(native_ran lists 'total(xs: list<int>) as int := {
	sum = 0
	for x in xs { sum = sum + x }
	sum
}
names = ["ada", "bo"]
names.add("cy")
numbers = [3, 4]
for at in 1 to 10 { numbers.add(at) }
print "${#names} names, the last ${names#3}"
print "${#numbers} numbers, total ${total(numbers)}, the third ${numbers#3}"')" "3 names, the last cy
12 numbers, total 62, the third 1"
check "a native program's lists joined and copied" "$(native_ran joined 'xs = ["a"] + ["b", "c"]
ys = copy(xs)
ys.add("d")
print xs.join("+") + " " + ys.join("+")')" "a+b+c a+b+c+d"
# records in a native program, held in its memory (types/memory_lists.wap): a class's instance, its fields read and
# written, a Range's slices
check "a native program's records" "$(native_ran records 'class Point { x: int; label: text }
p = Point{x: 3, label: "a"}
p.x = p.x + 4
print "${p.label} ${p.x}"')" "a 7"
# maps in a native program, held in its memory (types/memory_lists.wap): a literal, an entry read, changed and added,
# a count, a walk of its keys and values, and enough keys that it finds them by their hash
check "a native program's maps" "$(native_ran maps 'ages = {ada: 36, bo: 7}
ages["bo"] = 8
ages["cy"] = 1
for at in 1 to 10 { ages["k${at}"] = at }
for name, age in ages { if age > 5 { print "${name} ${age}" } }
print "${#ages} ages, k7 is ${ages["k7"]}, has zed: ${ages.has("zed")}"')" "ada 36
bo 8
k6 6
k7 7
k8 8
k9 9
k10 10
13 ages, k7 is 7, has zed: no"
check "a native program's slices" "$(native_ran slices 'xs = ["a", "b", "c"]
print xs[.. 2].join("+") + " " + xs.drop(1).join("+")')" "a+b b+c"
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
# a run within caps, as scripts/guarded.sh's (warp-supervisor 2026-11-22, after a runaway wap took 90 GB): one past
# its time cap stops and names the cap and the program
printf 'n = 0\nwhile yes { n = n + 1 }\n' >"$stage/spinning.wap"
check "a run past its time cap stops, naming the cap and the program" "$(cd "$stage" && "$native_wap" --seconds 1 spinning.wap 2>&1 | grep -o 'wap: spinning.wap ran past the time cap of 1 s')" "wap: spinning.wap ran past the time cap of 1 s"
# the console on a terminal edits its line (wap/extensions/native/editing.wap): each line typed with the keys' escape
# sequences as macOS Terminal, iTerm and xterm send them, on a pseudo terminal, HOME the stage so the history is the
# session's; what the console shows for each line, one a line
console_typed() {
	HOME="$stage" python3 - "$native_wap" "$@" <<'EOF'
import os, pty, re, select, signal, sys, time
# a line's run is over when the prompt starts a new line (each key redraws it after a carriage return)
PROMPT, NEXT_PROMPT, WAIT_SECONDS = "› ".encode(), "\n› ".encode(), 60
child, terminal = pty.fork()
if child == 0:
    os.execv(sys.argv[1], [sys.argv[1]])
output = b""
def read_until(mark: bytes, count: int) -> None:
    global output
    end = time.time() + WAIT_SECONDS
    while output.count(mark) < count and time.time() < end:
        if select.select([terminal], [], [], 0.2)[0]:
            output += os.read(terminal, 4096)
read_until(PROMPT, 1)
for typed in sys.argv[2:]:
    start = len(output)
    os.write(terminal, os.fsencode(typed) + b"\r")
    read_until(NEXT_PROMPT, output.count(NEXT_PROMPT) + 1)
    lines = [part.rstrip("\r").split("\r")[-1].strip() for part in re.sub(rb"\x1b\[[0-9;]*[A-Za-z]", b"", output[start:]).decode(errors="replace").split("\n")]
    print(" ".join(line for line in lines if line and not line.startswith("›")))
os.write(terminal, b"\x04")
end = time.time() + WAIT_SECONDS
while os.waitpid(child, os.WNOHANG)[0] == 0:
    if time.time() > end:
        print("the console did not end on Ctrl+D")
        os.kill(child, signal.SIGKILL)
        break
    # (read on: a terminal's process ends only once what it wrote is read)
    if select.select([terminal], [], [], 0.2)[0]:
        try:
            os.read(terminal, 4096)
        except OSError:
            pass
EOF
}
LEFT=$'\e[D' RIGHT=$'\e[C' UP=$'\e[A' HOME_KEY=$'\e[H' END_KEY=$'\e[F' DELETE=$'\e[3~' BACKSPACE=$'\x7f' CTRL_A=$'\x01' CTRL_E=$'\x05'
ALT_LEFT=$'\e[1;3D' ALT_DELETE=$'\e[3;3~' ALT_BACKSPACE=$'\e\x7f'
check "the console edits its line: arrows, Home/End, Ctrl+A/E, deletes, word moves, the lines before" "$(console_typed \
	"50+1" "+1${HOME_KEY}41${END_KEY}*1" "+1${CTRL_A}44${CTRL_E}*1" "4196${LEFT}${LEFT}${LEFT}${DELETE}" "4${LEFT}3${RIGHT}0" \
	"foo bar 47${HOME_KEY}${ALT_DELETE}${ALT_DELETE}" "49 foo bar${ALT_BACKSPACE}${ALT_BACKSPACE}" "2 * 2${ALT_LEFT}${ALT_LEFT}${ALT_LEFT}1" \
	"print \"aé\"${LEFT}${LEFT}${BACKSPACE}" "${UP}${UP}" 2>&1)" "51
42
45
496
340
47
49
24
é
24"
# an enum of cases without fields in a native program, each case its tag (notes/native.md); an uncaught raise its text on
# stderr and exit status 1
check "a native program picks and compares an enum's cases" "$(native_ran coins 'enum Coin { Penny, Dime }
pick(x: int): Coin := if x > 0 then Dime else Penny
exit(if pick(1) == Dime then 3 else 4)' >/dev/null; echo $?)" "3"
check "a native program's uncaught raise says its text and exits with 1" "$(native_ran raising 'raise "out of coins"'; echo "exit $?")" "out of coins
exit 1"
# a typed list in a native program hands C its own items, packed at their width: C sums them and writes into them
printf '%s\n' '#include <stdint.h>' 'double sum_f32(float* p, int64_t bytes) { double s = 0; for (int64_t i = 0; i < bytes / 4; i++) s += p[i]; return s; }' 'void halved(float* p, int64_t bytes) { for (int64_t i = 0; i < bytes / 4; i++) p[i] /= 2; }' >"$stage/native_items.c"
check "a native list<float32> crosses as C's floats, and C's writes are seen" "$(printf '%s\n' "sum_f32(xs: list<float32>, size: length): f64 from 'c'" "halved(xs: list<float32>, size: length): ø from 'c'" 'xs: list<float32> = [float32(0.5), float32(1.25), float32(4.0)]' 'halved(xs)' 'print(text(sum_f32(xs)) + " " + text(float(xs#2)))' >"$stage/native_items.wap" && "$tree/wap/extensions/native/build.sh" "$compiler" "$stage/native_items.wap" "$stage/native_items" "$stage/native_items.c" 2>&1 && "$stage/native_items" 2>&1)" "2.875 0.625"
# code given in place of a file, on the command line or to the console, is read in the current folder and its errors
# name its line alone, as no file holds it (wiki/cli.md)
check "wap names the line of code given in place of a file" "$("$native_wap" 'x = "abc' 2>&1 | grep -c '^line 1:5: this text is never closed')" "1"
check "the console names the line of an error" "$(printf '%s\n' 'x = "abc' | "$native_wap" 2>&1 | grep -c '^line 1:5: this text is never closed')" "1"
printf '%s\n' 'twice(x: int) as int := x * 2' >"$stage/helper.wap"
check "code given uses a file of the current folder" "$(cd "$stage" && "$native_wap" 'use "helper.wap"; twice(21)' 2>&1)" "42"
check "wap - runs the program standard input gives" "$(printf '%s\n' 'print 1 + 1' | "$native_wap" - 2>&1)" "2"
# a compiler run from source with no library beside it and no warm state yet, as from wap's own tree, still compiles
check "a compiler with no library beside it compiles hello" "$(rm -rf "$stage/bare" && mkdir -p "$stage/bare" && cp -R "$tree/wap" "$stage/bare/" && : >"$stage/bare/wap/warm.packed" && : >"$stage/bare/wap/types.wasm" && cd "$stage" && printf '%s\n' 'print "Hello"' >bare_hello.wap && "$native_wap" "$stage/bare/wap/compiler.wap" bare_hello.wap bare_hello.wasm 2>&1 && "$native_wap" bare_hello.wasm 2>&1)" "Hello"
# an option before the program is told to it (the user: every run of a painting program headless, --no-window): `--no-window` makes it windowless, a program without it is not
printf '%s\n' 'use os' 'print windowless()' >"$stage/windowless.wap"
check "wap --no-window runs the program windowless" "$(cd "$stage" && "$native_wap" --no-window windowless.wap 2>&1; "$native_wap" windowless.wap 2>&1)" "yes
no"
# `wap verify <file>` runs the verify program beside its compiler on the file, from any folder
printf '%s\n' 'axiom choice: Prop' >"$stage/axiom_only.wap"
check "wap verify gives each axiom and law its verdict, from any folder" "$(cd "$stage" && "$native_wap" verify axiom_only.wap 2>&1)" "choice: Axiom"
# a native wap built standalone holds its seed (build.sh --standalone): it runs with no seed folder beside it, its seed
# unpacked into the cache folder of the user's home once
native_wap_built "$stage/standalone" --standalone >/dev/null && rm -rf "$stage/standalone/wap-seed"
check "a standalone wap runs a program and verifies a file with no seed folder beside it" "$(cd "$stage" && HOME="$stage/home" "$stage/standalone/wap" hello.wap 2>&1 && HOME="$stage/home" "$stage/standalone/wap" verify axiom_only.wap 2>&1)" "Hello
choice: Axiom"
# and wasmtime's static library beside the shared one (warp's scripts/wasmtime-c-api.sh) is linked into it whole
# the libraries an executable loads beyond the system's own
libraries_beyond_system() {
	case $(uname -s) in
	Darwin) otool -L "$1" | tail -n +2 | grep -v libSystem ;;
	MINGW* | MSYS*) llvm-objdump -p "$1.exe" | sed -n 's/.*DLL Name: //p' | grep -viE '^(kernel32|ntdll|ucrtbase|msvcrt|advapi32|user32|ws2_32|bcrypt|bcryptprimitives|userenv|shell32|ole32|oleaut32|psapi|dbghelp|crypt32|secur32|synchronization|api-ms-win-.*)\.dll$' ;;
	*) ldd "$1" | grep -vE 'linux-vdso|ld-linux|lib(c|m|dl|rt|pthread|gcc_s)\.so' ;;
	esac
}
check "a standalone wap needs no library but the system's" "$(libraries_beyond_system "$stage/standalone/wap")" ""
# `wap format <file>` prints the program in canonical spelling, by the compiler beside it
printf '%s\n' 'x = 1+2' 'f(a)= a*2' >"$stage/unformatted.wap"
check "wap format prints the program in canonical spelling" "$(cd "$stage" && "$native_wap" format unformatted.wap 2>&1)" "x = 1 + 2
f(a) = a * 2"
# a record's instance is the C struct of its fields: C reads each at C's offset, and sees a field the program sets
check "a native record crosses to C as the struct its fields make" "$(native_ran record_struct 'class Pair { tag: int32; weight: float; label: text }
field_i32(at: Pair, offset: int): int32 := prim foreign("c", "field_i32", at, offset)
field_f64(at: Pair, offset: int): float := prim foreign("c", "field_f64", at, offset)
pair = Pair(tag: int32(3), weight: 2.5, label: "seven")
pair.weight = 4.5
print "${field_i32(pair, 0)} ${field_f64(pair, 8)} ${pair.label}"')" "3 4.5 seven"
# a function value is held in the memory: a closure keeps what it captures, and a function is given by its name
check "a native function value runs, its captures kept and a function given by name" "$(native_ran function_values 'step = 3
moved: (int) -> int = x => x + step
twice(f: (int) -> int, x: int): int := f(f(x))
negated(x: int): int := 0 - x
print "${twice(moved, 1)} ${twice(negated, 5)} ${moved(10)} ${[1, 2, 3].contains(2)}"')" "7 5 13 yes"
# an optional is held in the memory: a plain value in its box, a record as itself, ø told apart from both
check "a native optional holds a number, a record or ø" "$(native_ran optionals 'class Pair { left: int; right: int }
paired(n: int): Pair? := if n > 0 then Pair(left: n, right: n * 2) else ø
half(x: float): float? := if x > 0.0 then x / 2.0 else ø
b: int? = 4
c: int? = 4
d: int? = ø
print "${half(5.0) ?? 0.0} ${half(-1.0) ?? 9.5} ${paired(3)!.right} ${if paired(0) then "some" else "none"} ${b == c} ${b == d} ${d is ø}"')" "2.5 9.5 6 none yes no yes"
# an enum's first case is a value, never ø
check "a native optional holds an enum's first case" "$(native_ran present 'enum Color { Red, Green }
seen(c: Color?) := if c == ø then "none" else "some"
print "${seen(Color.Red)} ${seen(ø)}"')" "some none"
# a record taken after a text starts where C's struct would, its float read
check "a native record after a text reads its float" "$(native_ran aligned 'class Wide { x: float }
name = "hello"
w = Wide(2.5)
print "${name} ${w.x}"')" "hello 2.5"
# C calling back a wap function a natively built program hands it (lib/callbacks.wap c_callback, lib/native/callbacks.h)
check "a native program's C calls back a function value" "$(native_ran called_back 'use c
use callbacks
qsort(base: list<int32>, count: i64, size: i64, compare: handle): void from '"'"'c'"'"'
xs: list<int32> = [int32(3), int32(1), int32(4), int32(2)]
qsort(xs, 4, 4, c_callback((a, b) => int(field_i32(a, 0)) - int(field_i32(b, 0)), ["handle", "handle"]))
print "${xs#1} ${xs#2} ${xs#3} ${xs#4}"')" "1 2 3 4"
# a record handed to C as the struct of its fields, C's writes into them read back once the call returns
# (extensions/c/foreign.wap c_record_laid): mktime turns the 31st of February 2024 into the 2nd of March, day 61
check "a record crosses to C as its struct and comes back as C wrote it" "$(native_ran record_crossed 'class Tm { second: int32; minute: int32; hour: int32; day: int32; month: int32; year: int32; weekday: int32; yearday: int32; dst: int32; offset: int; zone: int }
mktime(t: Tm): i64 from '"'"'c'"'"'
t = Tm(int32(0), int32(0), int32(12), int32(31), int32(1), int32(124), int32(0), int32(0), int32(-1), 0, 0)
mktime(t)
print "${t.month} ${t.day} ${t.yearday}"')" "2 2 61"
# a class extending another, its instance passed where the class it extends is taken (wiki/class.md), run by the native wap
printf '%s\n' 'class Shape { x: int; twice() := x * 2 }' 'class Square extends Shape { side: int }' 'shape_x(s: Shape) := s.x' 'print shape_x(Square(3, 4)) + Square(3, 4).twice()' >"$stage/extends.wap"
check "wap runs a class extending another" "$(cd "$stage" && "$native_wap" extends.wap 2>&1)" "9"
# a C function from a library named by its path (card native-other-platforms), which the executable loads when the program calls it
printf '%s\n' 'long doubled(long x) { return 2 * x; }' >"$stage/doubled.c" && cc -shared -o "$stage/libdoubled.dylib" "$stage/doubled.c"
check "a native program calls C from a library named by its path" "$(native_ran doubled_by_path "doubled(x: i64): i64 from '$stage/libdoubled.dylib'
exit(doubled(21))" >/dev/null; echo $?)" "42"
# wap format keeps an else-if chain written over lines as it reads, and the formatted program runs (card format-else-if)
printf '%s\n' 'x = 2' 'if x == 1 { print 1 }' 'else if x == 2 { print 2 }' 'else { print 3 }' >"$stage/else_if.wap"
check "wap format keeps an else-if chain over lines" "$(cd "$stage" && "$native_wap" format else_if.wap >else_if_formatted.wap && cat else_if_formatted.wap)
$(cd "$stage" && "$native_wap" else_if_formatted.wap 2>&1)" "x = 2
if x == 1 { print 1 }
else if x == 2 { print 2 }
else { print 3 }
2"
# wap format writes a function's result type after a colon, the canonical spelling; `as` is its alias (card format-colon-result)
printf '%s\n' 'f(x: int) as int := x + 1' 'g(x: int): int := x * 2' >"$stage/result_type.wap"
check "wap format writes a result type after a colon" "$(cd "$stage" && "$native_wap" format result_type.wap 2>&1)" "f(x: int): int := x + 1
g(x: int): int := x * 2"
# a program compiled by a compiler named by a path from the current folder runs from any folder: its library is named
# from the root (the user's rule 2026-11-26: a compiler's modules are found through its own folder)
printf '%s\n' 'print "relative"' >"$stage/relative.wap"
check "a program compiled by a compiler named by a relative path runs from any folder" "$(cd "$(dirname "$(dirname "$compiler")")" && "$native_wap" "$(basename "$(dirname "$compiler")")/$(basename "$compiler")" "$stage/relative.wap" "$stage/relative.wasm" && cd / && "$native_wap" "$stage/relative.wasm" 2>&1)" "relative"
# a class without fields shows as its constructor form; an enum beside a class builds too (wiki/class.md, wiki/enum.md)
check "a native program shows a class without fields" "$(native_ran flag 'class Flag {}
print Flag()')" "Flag{}"
check "a native program with an enum beside a class" "$(native_ran enum_beside 'enum Color { Red, Green }
class Wide { x: float }
print "${Color.Green} ${Wide(2.5).x}"')" "Green 2.5"
# an error in a used module names that module by its full path, as it names the program (core/errors.wap place_of)
mkdir -p "$stage/erring" && printf '%s\n' 'broken(): int := "ab"' >"$stage/erring/part.wap" && printf '%s\n' 'use "part.wap"' 'print broken()' >"$stage/erring/main.wap"
check "an error in a used module names its full path" "$("$native_wap" "$stage/erring/main.wap" 2>&1 | grep -c "^$stage/erring/part.wap line 1:")" "1"
# runs at the same moment each get a temporary file of their own, never another's (lib/file.wap temp_file)
TEMP_RUNS=48
# (compiled once: each run then only runs the module, so they start together and stay light)
printf '%s\n' 'use file' 'print temp_file()' >"$stage/temp_name.wap" && $wap "$compiler" "$stage/temp_name.wap" "$stage/temp_name.wasm" >/dev/null 2>&1 && mkdir -p "$stage/temp_names"
for run in $(seq $TEMP_RUNS); do "$native_wap" "$stage/temp_name.wasm" >"$stage/temp_names/$run.txt" 2>&1 & done; wait
check "runs at the same moment get $TEMP_RUNS temporary files of their own" "$(cat "$stage/temp_names"/*.txt | grep '^/' | sort -u | wc -l | tr -d ' ')" "$TEMP_RUNS"
# `wap format check <file>` lists what the format would change, `file:line: layout: …`, and exits 1 if anything would
# (wiki/cli.md "Other programs")
printf '%s\n' 'x = 1' >"$stage/formatted.wap"
check "wap format check exits 0 when nothing would change" "$(cd "$stage" && "$native_wap" format check formatted.wap 2>&1; echo $?)" "0"
check "wap format check lists each line that would change and exits 1" "$(cd "$stage" && "$native_wap" format check unformatted.wap 2>&1; echo $?)" "unformatted.wap:1: layout: x = 1 + 2
unformatted.wap:2: layout: f(a) = a * 2
1"
# a word before the program picks the build mode (wiki/cli.md "Build modes")
check "wap release runs the program" "$(cd "$stage" && "$native_wap" release hello.wap 2>&1)" "Hello"
# wap format reads a program in its own grammar, the operators of the modules it uses known (wiki/operator.md), and a
# used module's refusal leaves it reading the same (card refusal-partway)
for refused in no yes; do
	mkdir -p "$stage/format_$refused" && printf '%s\n' 'infix operator ⊕ := left + right' "$([ $refused = yes ] && echo 'to move piece from a to b := piece + a - b')" >"$stage/format_$refused/m.wap" && printf '%s\n' 'use "m.wap"' 'x = 1⊕2' >"$stage/format_$refused/p.wap"
	check "wap format spaces an operator of a used module$([ $refused = yes ] && echo ' that refuses a form')" "$(cd "$stage/format_$refused" && "$native_wap" format p.wap 2>&1)" 'use "m.wap"
x = 1 ⊕ 2'
done
# `wap build --wasm app.wap` links the program and the modules it uses, its own compiled ones too, into one module that
# plain wasmtime runs without wap's loader: app.full.wasm as linked, app.wasm trimmed (wiki/cli.md)
WASMTIME_RUN="wasmtime -W gc,exceptions,function-references --invoke main"
mkdir -p "$stage/linked" && printf '%s\n' 'add(a: int, b: int) as int := a + b' >"$stage/linked/adding.wap" && $wap "$compiler" "$stage/linked/adding.wap" "$stage/linked/adding.wasm" >/dev/null 2>&1
printf '%s\n' 'use "adding.wasm"' 'print "Hello ${add(1, 2)}"' >"$stage/linked/app.wap" && (cd "$stage/linked" && "$native_wap" build --wasm app.wap >/dev/null 2>&1)
for linked in app.full.wasm app.wasm; do
	check "wap build --wasm links a program and its modules into $linked, which runs alone" "$(cd "$stage" && $WASMTIME_RUN "linked/$linked" 2>&1)" "Hello 3"
done
# --trim=none keeps app.wasm as linked, as big as app.full.wasm, where the default trim drops what nothing reaches
module_bytes() { wc -c <"$stage/linked/$1" | tr -d ' '; }
trimmed=$(module_bytes app.wasm)
(cd "$stage/linked" && "$native_wap" build --wasm --trim=none app.wap >/dev/null 2>&1)
check "wap build --wasm --trim=none keeps the linked module whole, the default trims it" "$([ "$(module_bytes app.wasm)" -ge "$(module_bytes app.full.wasm)" ] && [ "$trimmed" -lt "$(module_bytes app.full.wasm)" ] && $WASMTIME_RUN "$stage/linked/app.wasm" 2>&1)" "Hello 3"
check "a linked module names no folder to find modules in" "$(grep -c wap.library "$stage/linked/app.full.wasm")" "0"
# a seed folder holding no wap source (notes/coc-plan.md "Modules without source"): the compiler reads none, its warm
# state holds what it reads, and a library module compiled once is used by its name
check "a seed folder holding no wap source compiles hello and a program using a library module" "$(rm -rf "$stage/sourceless" && cp -R "$stage/bin" "$stage/sourceless" && (cd "$stage/sourceless/wap-seed/lib" && "$native_wap" ../wap.wasm math.wap math.wasm >/dev/null 2>&1) && find "$stage/sourceless/wap-seed" -name '*.wap' -delete && cd "$stage" && printf '%s\n' 'print "Hello"' >sourceless_hello.wap && printf '%s\n' 'use math' 'print(gcd(12, 18))' >sourceless_math.wap && "$stage/sourceless/wap" sourceless_hello.wap 2>&1 && "$stage/sourceless/wap" sourceless_math.wap 2>&1)" "Hello
6"
# and builds a native executable: the types module's files as a native build reads them come from its warm state too
check "a seed folder holding no wap source builds a native executable" "$(cd "$tree" && "$stage/sourceless/wap" build "$stage/sourceless_hello.wap" >/dev/null 2>&1 && "$stage/sourceless_hello" 2>&1)" "Hello"
exit $((failures > 0))
