// C functions a program's function is handed to C as (lib/callbacks.wap c_callback): included behind lib/native/wasi.c
// (running_wasi) and libraries.h, by foreign.c and the native wap (wap/extensions/native/main.c), whose own
// c_callback_answered each trampoline calls
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

// a pointer C passed to a callback (lib/callbacks.wap), returned as a handle, which the driver makes its id
void* pointer_handle(int64_t address) { return (void*)(intptr_t)address; }
// The C functions a warp function behind lib/callbacks.wap c_callback is passed to C as, one a slot: each calls the
// driver's c_callback_answered(slot, its six integer arguments), which calls the program's c_callback_fired; float
// arguments never reach one (they come in other registers)
typedef uint64_t (*callback_answer_t)(w2c_program*, u64, u64, u64, u64, u64, u64, u64);
static uint64_t callback_answered(uint64_t slot, uint64_t a, uint64_t b, uint64_t c, uint64_t d, uint64_t e, uint64_t f) {
	static callback_answer_t answer;
	if (!answer) answer = (callback_answer_t)native_function("c", "w2c_program_c_callback_answered");
	return answer(running_wasi->program, slot, a, b, c, d, e, f);
}
#define TRAMPOLINE(n) static uint64_t trampoline_##n(uint64_t a, uint64_t b, uint64_t c, uint64_t d, uint64_t e, uint64_t f) { return callback_answered(n, a, b, c, d, e, f); }
TRAMPOLINE(0) TRAMPOLINE(1) TRAMPOLINE(2) TRAMPOLINE(3) TRAMPOLINE(4) TRAMPOLINE(5) TRAMPOLINE(6) TRAMPOLINE(7)
TRAMPOLINE(8) TRAMPOLINE(9) TRAMPOLINE(10) TRAMPOLINE(11) TRAMPOLINE(12) TRAMPOLINE(13) TRAMPOLINE(14) TRAMPOLINE(15)
static void* trampolines[] = {trampoline_0, trampoline_1, trampoline_2, trampoline_3, trampoline_4, trampoline_5, trampoline_6, trampoline_7,
	trampoline_8, trampoline_9, trampoline_10, trampoline_11, trampoline_12, trampoline_13, trampoline_14, trampoline_15};
void* c_callback_pointer(int64_t slot) {
	if (slot < 0 || slot >= (int64_t)(sizeof trampolines / sizeof *trampolines)) {
		fprintf(stderr, "c_callback: at most %zu callbacks a run\n", sizeof trampolines / sizeof *trampolines);
		exit(1);
	}
	return trampolines[slot];
}
