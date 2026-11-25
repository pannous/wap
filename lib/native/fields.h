#include <stdint.h>
#include <stdlib.h>
#include <string.h>
// A field of a C struct a program holds as a handle, by its offset (lib/c.wap: SDL_Event's union, FreeType's glyph
// slot): its bytes as the C type is, a signed integer widened, a float as a double, a pointer as a handle; set_field_*
// writes one (an AudioStreamBasicDescription, an AudioBufferList pointing at memory of the program's)
#define FIELD_READER(name, type, result) result name(const uint8_t* address, int64_t offset) { type value; memcpy(&value, address + offset, sizeof value); return (result)value; }
#define FIELD_WRITER(name, type, given) void name(uint8_t* address, int64_t offset, given value) { type field = (type)value; memcpy(address + offset, &field, sizeof field); }
FIELD_WRITER(set_field_i32, int32_t, int64_t)
FIELD_WRITER(set_field_i64, int64_t, int64_t)
FIELD_WRITER(set_field_f64, double, double)
FIELD_WRITER(set_field_pointer, void*, void*)
FIELD_READER(field_u8, uint8_t, int32_t)
FIELD_READER(field_i16, int16_t, int32_t)
FIELD_READER(field_i32, int32_t, int32_t)
FIELD_READER(field_u32, uint32_t, int64_t)
FIELD_READER(field_i64, int64_t, int64_t)
FIELD_READER(field_f32, float, double)
FIELD_READER(field_f64, double, double)
FIELD_READER(field_pointer, void*, void*)
const char* field_text(const uint8_t* address, int64_t offset) { return (const char*)(address + offset); }
// count bytes of a struct or buffer at once, a `bytes` result: {length, bytes} in memory the driver copies into a text
// and frees; set_field_bytes writes a text's bytes there (a mapped GPU buffer read back, a vertex array filled)
struct bytes_result { int64_t length; uint8_t bytes[]; };
struct bytes_result* field_bytes(const uint8_t* address, int64_t offset, int64_t count) {
	struct bytes_result* result = malloc(sizeof *result + (size_t)count);
	result->length = count;
	memcpy(result->bytes, address + offset, (size_t)count);
	return result;
}
void set_field_bytes(uint8_t* address, int64_t offset, const uint8_t* data, int64_t size) { memcpy(address + offset, data, (size_t)size); }
