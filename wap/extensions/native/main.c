// The C entry of a native wap program (wap/extensions/native/build.sh): wasm2c's module of the program, named program,
// run by lib/native/wasi.c, which answers its WASI calls over libc and holds main(); the glue build.sh writes with
// glue.awk calls the C functions the program imports. A program of no GC value (no text, list or raise), as wasm2c
// takes no GC type
#include "program.h"
#include "native/wasi.c"

// the module's memory, where an address the program gives C points
#define wasi_memory(library) (((struct w2c_wasi__snapshot__preview1*)(library))->memory->data)
#include "native/libraries.h"
// the C function of that name in the process (libc, the executable's, a library it links); a missing one stops here
static void* c_function(const char* name) { return native_function("c", name); }
#include "glue.c"
#include "native/native_call.h"
#include "native/callbacks.h"

// the host words of a module the program runs through wasmtime (the native wap's host_words.wap): wasmtime calls this
// with an import's record, and the program's exported host_word answers it (glue.awk defines PROGRAM_HOST_WORD for a program exporting one)
#ifdef PROGRAM_HOST_WORD
void* wap_host_callback(void* word, void* caller, const void* given, size_t count, void* results, size_t results_count) {
	w2c_program_host_word(running_wasi->program, (u64)word, (u64)caller, (u64)given, count, (u64)results, results_count);
	return NULL;
}
#endif

// the native wap's clock (run.wap engine_made): a thread ticking the engine's epoch once a second, so a store's epoch
// deadline counts seconds; a thread wap cannot start, as the program's code runs on one only. wasmtime is found by name,
// so a program that links no wasmtime builds as before
#include <pthread.h>
#include <unistd.h>
static void* epoch_ticking(void* engine) {
	void (*epoch_incremented)(void*) = (void (*)(void*))native_function("c", "wasmtime_engine_increment_epoch");
	for (;;) { sleep(1); epoch_incremented(engine); }
	return NULL;
}
void epoch_ticker_started(int64_t engine) {
	pthread_t ticker;
	pthread_create(&ticker, NULL, epoch_ticking, (void*)(intptr_t)engine);
	pthread_detach(ticker);
}

void run_main(w2c_program* program) { w2c_program_main(program); }
