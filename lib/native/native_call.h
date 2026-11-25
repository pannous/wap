// A C function called with up to 8 integers and pointers and up to 8 floats in their registers (the ARM64 and x86-64
// conventions keep the two apart, `ldexp(double, int)` takes d0 and x0): it reads only the ones its parameters name.
// Its result is the integer register, or the bits of the float register. Shared by foreign.c and the native wap's
// host words (wap/extensions/native/main.c)
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef uint64_t (*integer_function)(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, double, double, double, double, double, double, double, double);
typedef double (*float_function)(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, double, double, double, double, double, double, double, double);
uint64_t native_call(void* function, uint64_t* i, double* f, int32_t float_result) {
	if (!float_result) return ((integer_function)function)(i[0], i[1], i[2], i[3], i[4], i[5], i[6], i[7], f[0], f[1], f[2], f[3], f[4], f[5], f[6], f[7]);
	double result = ((float_function)function)(i[0], i[1], i[2], i[3], i[4], i[5], i[6], i[7], f[0], f[1], f[2], f[3], f[4], f[5], f[6], f[7]);
	uint64_t bits;
	memcpy(&bits, &result, sizeof bits);
	return bits;
}
// The same with a struct of `size` bytes (17 to 128) given by value after `count` integers (0 to 6) and no floats,
// `bytes` its copy: the carrier is 128 bytes and 16-aligned, the same MEMORY class as any struct over 16 bytes, so the C
// compiler places it as the callee reads its own prefix: on the stack on x86-64, a pointer to it in the next integer
// register on ARM64 (lib/foreign.wap c_struct)
enum { BYVALUE_MOST = 128 };
typedef struct { uint64_t words[BYVALUE_MOST / 8]; } byvalue __attribute__((aligned(16)));
uint64_t native_call_struct(void* function, uint64_t* i, int64_t count, void* bytes, int64_t size) {
	if (count < 0 || count > 6 || size <= 16 || size > BYVALUE_MOST) {
		fprintf(stderr, "native_call_struct: a struct of %lld bytes after %lld integers is outside what this call places\n", (long long)size, (long long)count);
		exit(1);
	}
	byvalue copy;
	memset(&copy, 0, sizeof copy);
	memcpy(&copy, bytes, (size_t)size);
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
