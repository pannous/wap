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
check "a native program picks and compares an enum's cases" "$(native_ran coins 'exit(code: int) := prim proc_exit(code)
enum Coin { Penny, Dime }
pick(x: int): Coin := if x > 0 then Dime else Penny
exit(if pick(1) == Dime then 3 else 4)' >/dev/null; echo $?)" "3"
check "a native program's uncaught raise says its text and exits with 1" "$(native_ran raising 'raise "out of coins"'; echo "exit $?")" "out of coins
exit 1"
exit $((failures > 0))
