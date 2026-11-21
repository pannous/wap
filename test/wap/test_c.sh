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
check "a C function takes and gives C's float" "$(ran float_line "sqrtf(x: f32): f32 from 'm'
print(text(sqrtf(2.25)))")" "1.5"
# div gives its div_t {quot, rem} by value, in one register: quot in the low half
check "a C struct given back by value, packed in its register" "$(ran struct_line "div(numerator: i32, denominator: i32): i64 from 'c'
print(text(div(7, 2)))")" "4294967299"
check "a C truth value given back as a bool" "$(ran bool_line "isatty(file: i32): bool from 'c'
print(text(isatty(-1)))")" "no"
exit $((failures > 0))
