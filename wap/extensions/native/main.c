// The C entry of a native wap program (wap/extensions/native/build.sh): wasm2c's module of the program, named program,
// run by lib/native/wasi.c, which answers its WASI calls over libc and holds main(); a program of no GC value (no text,
// list or raise), as wasm2c takes no GC type
#include "program.h"
#include "native/wasi.c"

void instantiate(w2c_program* program, struct w2c_wasi__snapshot__preview1* wasi) { wasm2c_program_instantiate(program, wasi); }
void run_main(w2c_program* program) { w2c_program_main(program); }
