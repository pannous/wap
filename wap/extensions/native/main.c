// The C entry of a native wap program (wap/extensions/native/build.sh): wasm2c's module of the program, named program,
// run by lib/native/wasi.c, which answers its WASI calls over libc and holds main(); the glue build.sh writes with
// glue.awk calls the C functions the program imports. A program of no GC value (no text, list or raise), as wasm2c
// takes no GC type
#include <limits.h>
#include <string.h>
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
#include "native/fields.h"

// the host words of a module the program runs through wasmtime (the native wap's host_words.wap): wasmtime calls this
// with an import's record, and the program's exported host_word answers it (glue.awk defines PROGRAM_HOST_WORD for a program exporting one)
#ifdef PROGRAM_HOST_WORD
void* wap_host_callback(void* word, void* caller, const void* given, size_t count, void* results, size_t results_count) {
	w2c_program_host_word(running_wasi->program, (u64)word, (u64)caller, (u64)given, count, (u64)results, results_count);
	return NULL;
}
#endif

// WASI's path_readlink for a module the native wap runs (run.wap imports_linked), as POSIX's: wasmtime's refuses a link
// to an absolute path, which a path through a linked folder needs (types/host.wap real_path). The path is the root
// folder's from "/", else the current folder's, the process's own; a wasmtime value's number is past its kind
enum { ROOT_FOLDER = 4, READLINK_VALUES = 6, WASMTIME_VALUE_BYTES = 32, WASMTIME_NUMBER_AT = 8, WASMTIME_EXTERN_BYTES = 32, WASI_INVALID = 28 };
void* wap_path_readlink(void* data, void* caller, const uint8_t* given, size_t count, uint8_t* results, size_t results_count) {
	(void)data, (void)count, (void)results_count;
	uint32_t value[READLINK_VALUES];
	for (int i = 0; i < READLINK_VALUES; i++) memcpy(&value[i], given + i * WASMTIME_VALUE_BYTES + WASMTIME_NUMBER_AT, 4);
	uint8_t memory_extern[WASMTIME_EXTERN_BYTES];
	((bool (*)(void*, const char*, size_t, void*))c_function("wasmtime_caller_export_get"))(caller, "memory", strlen("memory"), memory_extern);
	void* context = ((void* (*)(void*))c_function("wasmtime_caller_context"))(caller);
	uint8_t* memory = ((uint8_t* (*)(void*, void*))c_function("wasmtime_memory_data"))(context, memory_extern + WASMTIME_NUMBER_AT);
	char path[PATH_MAX + 2] = "/";
	uint32_t length = value[2] < PATH_MAX ? value[2] : PATH_MAX;
	memcpy(path + 1, memory + value[1], length);
	path[length + 1] = 0;
	ssize_t used = readlink(value[0] == ROOT_FOLDER ? path : path + 1, (char*)memory + value[3], value[4]);
	uint32_t answer = used < 0 ? WASI_INVALID : 0;
	if (used >= 0) memcpy(memory + value[5], &(uint32_t){(uint32_t)used}, 4);
	memset(results, 0, WASMTIME_VALUE_BYTES);
	memcpy(results + WASMTIME_NUMBER_AT, &answer, 4);
	return NULL;
}

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
// the library folder the native wap found beside its compiler (linking.wap), which the programs it runs read
// (lib/host/native_host/platform.wap library_folder); NULL till it is told
static const char* library_folder = NULL;
void wap_library_folder_set(const char* folder) { library_folder = strdup(folder); }
const char* wap_library_folder(void) { return library_folder; }
// when this executable was built (commands.wap version)
const char* wap_built(void) { return __DATE__ " " __TIME__; }
void epoch_ticker_started(int64_t engine) {
	pthread_t ticker;
	pthread_create(&ticker, NULL, epoch_ticking, (void*)(intptr_t)engine);
	pthread_detach(ticker);
}

void run_main(w2c_program* program) { w2c_program_main(program); }
