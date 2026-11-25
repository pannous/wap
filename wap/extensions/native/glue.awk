# The C glue of a native wap program (build.sh), written from wasm2c's header of its module: each function the module
# imports from a module other than WASI, `u64 w2c_c_strlen(struct w2c_c*, u32);`, calls the C function of that name,
# found in the process, with each value as C takes it by one rule over wasm's types: an i32 (u32) is an address in
# the module's memory, given as a pointer to it, an i64 (u64) an int or a host handle as it is, a float a float. A
# u32 result is C's int as it is. Then the instantiation, which takes the imported modules in the header's order.
#   awk -f glue.awk program.h > glue.c
BEGIN { WASI = "w2c_wasi__snapshot__preview1"; module_count = 0 }

# a name as C knows it, wasm2c's escapes decoded: a character no C name takes written 0x and its hex code, `0x5F` `_`
function unescaped(name,    decoded, code) {
	decoded = ""
	while (match(name, /0x[0-9A-F][0-9A-F]/)) {
		code = index("0123456789ABCDEF", substr(name, RSTART + 2, 1)) * 16 + index("0123456789ABCDEF", substr(name, RSTART + 3, 1)) - 17
		decoded = decoded substr(name, 1, RSTART - 1) sprintf("%c", code)
		name = substr(name, RSTART + RLENGTH)
	}
	return decoded name
}
# the C type an argument of this wasm2c type is given to the C function as
function c_type(wasm_type) { return wasm_type == "u32" ? "void*" : wasm_type }
function c_value(wasm_type, name) { return wasm_type == "u32" ? "wasi_memory(library) + " name : name }
# a struct given by value last, its size after the C name (`wgpuInstanceRequestAdapter bytes<40>`,
# extensions/c/foreign.wap c_import_name): the u64 that points to its bytes, given as the struct of that size C takes
function struct_type(size) {
	if (!(size in structs)) { structs[size] = 1; glue = glue sprintf("typedef struct { uint64_t words[%d]; } bytes%d;\n", (size + 7) / 8, size) }
	return "bytes" size
}

# `u64 w2c_c_strlen(struct w2c_c*, u32);`: an import of the module c
/^(void|u32|u64|f32|f64) w2c_[a-z0-9_]+_[A-Za-z0-9_]+\(struct w2c_[a-z0-9_]+\*/ && $0 !~ WASI {
	result = $1
	match($0, /struct w2c_[a-z0-9_]+\*/); module = substr($0, RSTART + 7, RLENGTH - 8)
	match($0, / w2c_[A-Za-z0-9_]+\(/); full = substr($0, RSTART + 1, RLENGTH - 2)
	name = substr(full, length(module) + 2)
	if (!(module in modules)) { modules[module] = 1; order[++module_count] = module }
	listed = $0; sub(/^[^,)]*/, "", listed); sub(/\);.*$/, "", listed)
	count = split(listed, types, /, */)
	name = unescaped(name); size = 0
	if (match(name, / bytes<[0-9]+>$/)) { size = substr(name, RSTART + 7, RLENGTH - 8) + 0; name = substr(name, 1, RSTART - 1) }
	parameters = "struct " module "* library"; c_parameters = ""; arguments = ""
	for (i = 2; i <= count; i++) {
		parameters = parameters ", " types[i] " value" i
		given = i == count && size ? struct_type(size) : c_type(types[i])
		c_parameters = c_parameters (i > 2 ? ", " : "") given
		arguments = arguments (i > 2 ? ", " : "") (i == count && size ? "*(" given "*)(uintptr_t)value" i : c_value(types[i], "value" i))
	}
	if (c_parameters == "") c_parameters = "void"
	call = "function(" arguments ")"
	glue = glue sprintf("%s %s(%s) {\n", result, full, parameters)
	glue = glue sprintf("\tstatic %s (*function)(%s);\n", result, c_parameters)
	glue = glue sprintf("\tif (!function) function = c_function(\"%s\");\n", name)
	glue = glue sprintf("\t%s%s;\n}\n", (result == "void" ? "" : "return "), call)
}
# the program answers host words (main.c wap_host_callback): `void w2c_program_host_word(w2c_program*, u64, …);`
/^void w2c_program_host_word\(/ { glue = glue "#define PROGRAM_HOST_WORD 1\n" }
# the instantiation, the imported modules' instances in the header's order: WASI's, and each other module's wrapping it
/^void wasm2c_[a-z0-9_]+_instantiate\(/ {
	listed = $0; sub(/^[^,]*, */, "", listed); sub(/\);.*$/, "", listed)
	count = split(listed, instances, /, */)
	given = ""
	for (i = 1; i <= count; i++) given = given ", " (instances[i] ~ WASI ? "wasi" : "(" instances[i] ")wasi")
	instantiation = "void instantiate(w2c_program* program, struct " WASI "* wasi) { wasm2c_program_instantiate(program" given "); }"
}
# each imported module's instance wraps WASI's, whose memory its pointers are in (main.c wasi_memory)
END {
	for (i = 1; i <= module_count; i++) printf "struct %s { struct %s wasi; };\n", order[i], WASI
	printf "%s%s\n", glue, instantiation
}
