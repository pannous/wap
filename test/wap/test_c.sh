#!/usr/bin/env bash
# C functions as lib writes them (wiki/c.md; lib/c.warp, `strlen(s: text): i64 from 'c'`), lowered by
# wap/extensions/c/foreign.wap and described for the native warp by wap/extensions/c/functions.wap: a program calls them, its
# texts going to C and coming back. Run it with bash test/wap/test_c.sh; its modules run on the native wap on PATH
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
print(text(ldexp(0.75, 2)) + " " + text(hypot(3.0, 4.0)))')" "3 5"
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
check "a list of bytes crosses as a pointer to their copy, NULs and all, its count the length after it" "$(ran bytes_line "crc32(start: i64, data: bytes, size: length): i64 from 'z'
print(text(crc32(0, [97, 0, 98])))")" "367556721"
# a function of the program reads a value of the library before any C call gave it one (warp-interviewer 2026-11-22)
check "a function reads the library's value of the C calls' out-pointers" "$(ran library_value 'f() := c_outs
print(text(f()))')" "0"
# wiki/c.md's examples: sqlite3 through its module, a number that is no handle refused, qsort calling back a lambda
check "sqlite3 runs a query: a row, its int and its text" "$(ran sqlite_page 'use sqlite3
db = sqlite3_open(":memory:")
stmt = sqlite3_prepare_v2(db, "select 1+2, '"'"'wap'"'"'", -1)
row = text(sqlite3_step(stmt)) + " " + text(sqlite3_column_int(stmt, 0)) + " " + sqlite3_column_text(stmt, 1)
sqlite3_finalize(stmt); sqlite3_close(db)
print(row)')" "100 3 wap"
check "a number that is no handle of this run is an error" "$(ran no_handle 'use sqlite3
sqlite3_step(42)' 2>&1 | grep -c 'no handle of this run')" "1"
check "qsort calls back a lambda through c_callback" "$(ran qsort_page 'use c
use callbacks
qsort(base: handle, count: i64, size: i64, compare: handle): void from '"'"'c'"'"'
m = calloc(4, 8)
set_field_i64(m, 0, 3); set_field_i64(m, 8, 1); set_field_i64(m, 16, 4); set_field_i64(m, 24, 2)
qsort(m, 4, 8, c_callback((a, b) => field_i64(a, 0) - field_i64(b, 0), ["handle", "handle"]))
print(text([0, 1, 2, 3].map(i => field_i64(m, 8 * i))))')" "[1, 2, 3, 4]"
# an unsigned int and a text the caller owns cross (wap/extensions/c/foreign.wap)
check "an unsigned int and an owned text cross" "$(ran c_words "strdup(s: text): owned_text from 'c'
htonl(n: u32): u32 from 'c'
print(strdup(\"wap\") + \" \" + text(htonl(4278190080)))")" "wap 255"
# a struct given by value, `bytes<40>` (wgpu's callback infos): C reads its copy, and the caller's stays as it was
printf '%s\n' '#include <stdint.h>' '#include <stdlib.h>' 'struct s40 { int64_t a[5]; };' 'int64_t sum40(struct s40 s) { s.a[0] = 0; return s.a[1] + s.a[2] + s.a[3] + s.a[4]; }' 'int64_t first40(struct s40 s) { return s.a[0]; }' 'struct s40* made40(void) { struct s40* s = malloc(sizeof *s); for (int i = 0; i < 5; i++) s->a[i] = i + 1; return s; }' >"$stage/s40.c" && cc -shared -o "$stage/libs40.dylib" "$stage/s40.c"
check "a C struct given by value" "$(ran struct_by_value "sum40(s: bytes<40>): i64 from '$stage/libs40.dylib'
first40(s: bytes<40>): i64 from '$stage/libs40.dylib'
made40(): handle from '$stage/libs40.dylib'
m = made40()
print(text(sum40(m)) + \" \" + text(first40(m)))")" "14 1"
# a typed list as C reads an array of its items (a GPU buffer's floats): C sums them and writes into them
printf '%s\n' '#include <stdint.h>' 'double sum_f32(float* p, int64_t bytes) { double s = 0; for (int64_t i = 0; i < bytes / 4; i++) s += p[i]; return s; }' 'void halved(float* p, int64_t bytes) { for (int64_t i = 0; i < bytes / 4; i++) p[i] /= 2; }' 'int64_t sum_i32(int32_t* p, int64_t bytes) { int64_t s = 0; for (int64_t i = 0; i < bytes / 4; i++) s += p[i]; return s; }' >"$stage/items.c" && cc -shared -o "$stage/libitems.dylib" "$stage/items.c"
check "a list<float32> crosses as C's floats, and C's writes are seen" "$(ran typed_items "sum_f32(xs: list<float32>, size: length): f64 from '$stage/libitems.dylib'
halved(xs: list<float32>, size: length): ø from '$stage/libitems.dylib'
sum_i32(xs: list<int32>, size: length): i64 from '$stage/libitems.dylib'
xs: list<float32> = [float32(0.5), float32(1.25), float32(4.0)]
halved(xs)
print(text(sum_f32(xs)) + \" \" + text(float(xs#2)) + \" \" + text(sum_i32([int32(3), int32(-4)])))")" "2.875 0.625 -1"
exit $((failures > 0))
