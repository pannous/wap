#!/usr/bin/env bash
# lib/os.wap's standard input words (wiki/standard-library.md os): input() a typed line, ø at the input's end, input(prompt)
# shows the prompt first, stdin() all of it. Run it with bash test/wap/test_os.sh
source "$(dirname "$0")/compile.sh"

# a program using os, compiled, then run with the given standard input
typed() { printf '%s\n' 'use os' "$2" >"$stage/$1.wap" && $wap "$compiler" "$stage/$1.wap" "$stage/$1.wasm" 2>&1 && printf "$3" | $wap "$stage/$1.wasm" 2>&1; }

check "input gives a typed line without its line end" "$(typed typed_line 'print input() ?? "none"' 'one\ntwo\n')" "one"
check "input is missing at the input's end" "$(typed typed_none 'print input() ?? "none"' '')" "none"
check "input shows its prompt first" "$(typed typed_prompt 'print input("name? ") ?? "none"' 'ada\n')" "name? ada"
check "stdin gives all of standard input" "$(typed typed_all 'print #stdin().split("\n")' 'a\nb\nc')" "3"
exit $((failures > 0))
