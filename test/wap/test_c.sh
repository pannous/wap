#!/usr/bin/env bash
# C functions as lib writes them (wiki/c.md; lib/c.warp, `strlen(s: text): i64 from 'c'`), lowered by
# wap/extensions/c/foreign.wap and described for the native warp by wap/extensions/c/functions.wap: a program calls them, its
# texts going to C and coming back. Run it with bash test/wap/test_c.sh; the warp under test is WARP (default the warp
# on PATH)
source "$(dirname "$0")/compile.sh"

check "a program calls C functions written as C has them, texts going in and coming back" "$(ran c_lines "strlen(s: text): i64 from 'c'
setenv(name: text, value: text, overwrite: i32): i32 from 'c'
getenv(name: text): text from 'c'
print(text(strlen(\"hello\")))
print(text(setenv(\"WAP_C_TEST\", \"set from wap\", 1)))
print(getenv(\"WAP_C_TEST\"))")" "5
0
set from wap"
check "a C function of libm takes and gives a double" "$(ran libm_line "fabs(x: f64): f64 from 'm'
print(text(fabs(-2.5)))")" "2.5"
check "a C function of the library its module names, loaded by that name" "$(ran zlib_line "crc32(crc: i64, bytes: text, count: i64): i64 from 'z'
print(text(crc32(0, \"hello\", 5)))")" "907060870"
exit $((failures > 0))
