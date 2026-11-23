// The C functions a primitive program imports (`import getenv from "c"`), in a native build: each import wasm2c calls
// is written by extensions/primitive.warp c_function_glue, which finds the function by name in the process and
// passes the module's values over with these. Included behind lib/native/wasi.c.
#include "system.h"

// the libraries native_function looks in: the process's own (libc, the executable's), warp's wasmtime C API
static const char PROCESS[] = "c";
static const char WASMTIME[] = "warp_wasmtime";
enum { ARENA_ALIGNMENT = 8, TEXT_RECORD = 8, PAGE_BYTES = 65536 }; // primitive.warp ARENA_ALIGNMENT, text_layout's size

#include "libraries.h"
// an address of the module's memory as a C pointer, the null address NULL; and back
static void* native_address(struct w2c_wasi__snapshot__preview1* wasi, uint32_t address) { return address ? at(wasi, address) : NULL; }
static uint32_t module_address(struct w2c_wasi__snapshot__preview1* wasi, void* pointer) {
	return pointer ? (uint32_t)((uint8_t*)pointer - wasi->memory->data) : 0;
}
// an address of the module's memory as the C pointer it is, for a program to hold as a handle (`native_pointer(address:
// pointer): handle from "c"`): the glue made it the pointer already
void* native_pointer(void* address) { return address; }
#include "callbacks.h"
// the process's environment, for the children it starts (core/native/driver.warp words_run)
char** process_environment(void) { return environ; }
// the error number of the C call that failed last (core/native/driver.warp os_failure)
int32_t last_error(void) { return errno; }
// the terminal's rows, else its columns, on standard output; 0 outside a terminal (ioctl is variadic: called here, not
// through native_call)
int32_t terminal_size(int32_t rows) {
	struct winsize size;
	return ioctl(STDOUT_FILENO, TIOCGWINSZ, &size) == 0 ? (rows ? size.ws_row : size.ws_col) : 0;
}
// a text of the module, the address of its (address, length) pair, as a NUL-terminated copy the caller frees
static char* native_text(struct w2c_wasi__snapshot__preview1* wasi, uint32_t text) {
	return strndup((char*)at(wasi, load32(wasi, text)), load32(wasi, text + 4));
}
// bytes taken from the module's arena (primitive.warp arena_taken), its memory grown when they pass its end
static uint32_t arena_bytes(struct w2c_wasi__snapshot__preview1* wasi, uint32_t size) {
	uint32_t* top = w2c_program_arena(wasi->program);
	uint32_t taken = *top;
	*top = (taken + size + ARENA_ALIGNMENT - 1) & -ARENA_ALIGNMENT;
	if (*top > wasi->memory->size) wasm_rt_grow_memory(wasi->memory, (*top - wasi->memory->size + PAGE_BYTES - 1) / PAGE_BYTES);
	return taken;
}

// a C text copied into the module's arena as a text, its bytes behind its pair; NULL the null address
static uint32_t module_text(struct w2c_wasi__snapshot__preview1* wasi, const char* text) {
	if (!text) return 0;
	uint32_t length = (uint32_t)strlen(text);
	uint32_t pair = arena_bytes(wasi, TEXT_RECORD + length);
	store32(wasi, pair, pair + TEXT_RECORD);
	store32(wasi, pair + 4, length);
	memcpy(at(wasi, pair + TEXT_RECORD), text, length);
	return pair;
}

// a C function's address by its name, for a program to hand to a C library as a callback
void* c_function(char* name) { return native_function(PROCESS, name); }

#include "fields.h"
#include "native_call.h"
// One trailing aggregate, after `count` integer arguments (0 to 6) and no floats. `bytes` is `size` bytes, 17 to 128.
// The carrier is 128 bytes and 16-aligned, which is the same MEMORY class as any aggregate over 16 bytes: on x86-64
// SysV the C compiler puts it on the stack, and the callee reads its own prefix; on AAPCS64 the compiler passes a
// pointer to this copy in the next integer register. A pointer in a register is not that aggregate.
enum { BYVALUE_MOST = 128 };
typedef struct { uint64_t words[BYVALUE_MOST / 8]; } byvalue __attribute__((aligned(16)));
uint64_t native_call_struct(void* function, uint64_t* i, int32_t count, void* bytes, int32_t size) {
	if (!function || count < 0 || count > 6 || size <= 16 || size > BYVALUE_MOST) {
		fprintf(stderr, "native_call_struct: %d bytes after %d integers is outside what this call places\n", size, count);
		exit(1);
	}
	byvalue copy;
	memset(&copy, 0, sizeof copy);
	if (bytes) memcpy(&copy, bytes, (size_t)size);
	switch (count) {
	case 0: return ((uint64_t (*)(byvalue))function)(copy);
	case 1: return ((uint64_t (*)(uint64_t, byvalue))function)(i[0], copy);
	case 2: return ((uint64_t (*)(uint64_t, uint64_t, byvalue))function)(i[0], i[1], copy);
	case 3: return ((uint64_t (*)(uint64_t, uint64_t, uint64_t, byvalue))function)(i[0], i[1], i[2], copy);
	case 4: return ((uint64_t (*)(uint64_t, uint64_t, uint64_t, uint64_t, byvalue))function)(i[0], i[1], i[2], i[3], copy);
	case 5: return ((uint64_t (*)(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, byvalue))function)(i[0], i[1], i[2], i[3], i[4], copy);
	default: return ((uint64_t (*)(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, byvalue))function)(i[0], i[1], i[2], i[3], i[4], i[5], copy);
	}
}
// the C pointers a run got, handed to the module as ids: id n is the n-th pointer, 0 is NULL, the same pointer keeps
// its id, found again through a table of ids by pointer (open addressing, at most half full)
static void** handles;
static int32_t* handle_ids;
static uint32_t handle_count, handle_room, slot_count;
static int32_t* slot_of(void* pointer) {
	uint32_t mask = slot_count - 1;
	for (uint32_t slot = (uint32_t)(((uintptr_t)pointer * 0x9E3779B97F4A7C15ull) >> 32) & mask;; slot = (slot + 1) & mask)
		if (!handle_ids[slot] || handles[handle_ids[slot] - 1] == pointer) return &handle_ids[slot];
}
int32_t handle_id(void* pointer) {
	if (!pointer) return 0;
	if (handle_count * 2 >= slot_count) {
		slot_count = slot_count ? slot_count * 2 : 64;
		free(handle_ids);
		handle_ids = calloc(slot_count, sizeof *handle_ids);
		for (uint32_t id = 1; id <= handle_count; id++) *slot_of(handles[id - 1]) = (int32_t)id;
	}
	int32_t* slot = slot_of(pointer);
	if (*slot) return *slot;
	if (handle_count == handle_room) handles = realloc(handles, (handle_room = handle_room * 2 + 16) * sizeof *handles);
	handles[handle_count++] = pointer;
	return *slot = (int32_t)handle_count;
}
int32_t handle_known(int32_t id) { return id >= 0 && (uint32_t)id <= handle_count; }
void* handle_pointer(int32_t id) { return id > 0 && (uint32_t)id <= handle_count ? handles[id - 1] : NULL; }

// what a host word allocated given back, zeroed: the arena past its top stays as fresh memory is, so an allocate after
// a host word (warp test's slots after test-list ran) never starts with an earlier word's bytes. What arena_kept
// kept stays: a module the driver links on a host word's question (driver.warp lazily_linked) keeps its records
static uint32_t arena_floor;
void arena_kept(void) { arena_floor = *w2c_program_arena(running_wasi->program); }
static void arena_given_back(struct w2c_wasi__snapshot__preview1* wasi, uint32_t before) {
	uint32_t* top = w2c_program_arena(wasi->program);
	uint32_t kept = before > arena_floor ? before : arena_floor;
	if (*top > kept) memset(at(wasi, kept), 0, *top - kept);
	*top = kept;
}
// A host word a program defines for a module it runs through wasmtime's C API (core/native/driver.warp
// host_words_defined): a wasmtime_func_callback_t whose data is the word's number. The values (wasmtime_val_t, VALUE_BYTES
// each) cross through the program's arena to its exported host_word(word, caller, values, count, results, count),
// whose arena is given back after
enum { VALUE_BYTES = 32 };
typedef void (*host_word_t)(w2c_program*, u64, u64, u32, u64, u32, u64);
void* warp_host_callback(void* word, void* caller, const void* values, size_t count, void* results, size_t results_count) {
	static host_word_t answer;
	if (!answer) answer = (host_word_t)native_function(PROCESS, "w2c_program_host_word");
	struct w2c_wasi__snapshot__preview1* wasi = running_wasi;
	uint32_t* top = w2c_program_arena(wasi->program);
	uint32_t before = *top;
	uint32_t given = arena_bytes(wasi, (uint32_t)(count * VALUE_BYTES));
	uint32_t answered = arena_bytes(wasi, (uint32_t)(results_count * VALUE_BYTES));
	memcpy(at(wasi, given), values, count * VALUE_BYTES);
	answer(wasi->program, (u64)(uintptr_t)word, (u64)(uintptr_t)caller, given, count, answered, results_count);
	memcpy(results, at(wasi, answered), results_count * VALUE_BYTES);
	arena_given_back(wasi, before);
	return NULL;
}

// Ctrl+C in the console (core/native/warp.warp console): a SIGINT ends the running line, never the console. It moves
// the engine's epoch on, and the line's store, whose deadline is the next epoch, traps with an interrupt. The handler
// only calls wasmtime_engine_increment_epoch, found before (dlsym is not safe in a signal handler). With no line
// running it leaves the epoch alone, so no Ctrl+C is kept for the next line (the prompt's own Ctrl+C is a key there)
static void* interrupted_engine;
static void (*epoch_increment)(void*);
static volatile sig_atomic_t line_running;
static void engine_interrupted(int signal) {
	(void)signal;
	if (line_running) epoch_increment(interrupted_engine);
}
// whether a console line (its compile or its run) is running, which a Ctrl+C then stops
void interrupts_running(int32_t running) {
	line_running = running;
}
void interrupts_engine(void* engine) {
	struct sigaction action = { 0 };
	interrupted_engine = engine;
	epoch_increment = (void (*)(void*))native_function(WASMTIME, "wasmtime_engine_increment_epoch");
	action.sa_handler = engine_interrupted;
	action.sa_flags = SA_RESTART;
	sigemptyset(&action.sa_mask);
	sigaction(SIGINT, &action, NULL);
}
