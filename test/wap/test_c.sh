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
check "libm's C functions come from its own module, use m" "$(ran libm_module 'use m
print(text(cbrt(27.0)) + " " + text(hypot(3.0, 4.0)))')" "3 5"
check "an out-pointer is no argument, a slot C fills" "$(ran out_line "strtod(s: text, end: out): f64 from 'c'
print(text(strtod(\"2.5kg\")))")" "2.5"
check "a handle result is the pointer C put in the first out-pointer" "$(ran out_handle_line "posix_memalign(memory: out, alignment: i64, size: i64): handle from 'c'
free(pointer: handle): void from 'c'
memory = posix_memalign(16, 64)
print(text(memory > 0))
free(memory)")" "yes"
check "a list of texts crosses as C's NULL-ended array of strings" "$(ran texts_line "posix_spawnp(process: out, file: text, actions: handle, attributes: handle, arguments: texts, environment: texts): handle from 'c'
waitpid(process: handle, status: handle, options: i32): void from 'c'
child = posix_spawnp(\"echo\", 0, 0, [\"echo\", \"spawned\", \"by C\"], [])
waitpid(child, 0, 0)")" "spawned by C"
exit $((failures > 0))
