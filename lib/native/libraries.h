// Where a C function a program imports lies: the process (libc, libm, the executable's), else the library of the name
// it is imported from (`sqlite3`), loaded now. Shared by foreign.c and the native wap (wap/extensions/native/main.c)
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// a symbol of the process: the executable's, a library's it links or one opened RTLD_GLOBAL. POSIX's dlopen(NULL)
// handle, not RTLD_DEFAULT, which glibc declares only under _GNU_SOURCE, and this file comes behind the header wasm2c
// writes, too late to define it (the v1.8.0 Linux release jobs, card release-linux-bootstrap)
static void* process_symbol(const char* name) {
	static void* process;
	if (!process) process = dlopen(NULL, RTLD_LAZY);
	return dlsym(process, name);
}
// The C calls of a module the driver runs (core/native/driver.warp c_called), as the Rust stub makes them (c_calls.rs)
// where a library lies by the name a program imports it under (`sqlite3`); libc's and libm's are the process's
// libraries beside the executable first (libwgpu_native), as libwarp_wasmtime is
// Fixed short folders per platform (user 2026-11-06 library-search-paths): no scan/sort/computed from.
// macOS: homebrew + local + opt/<name>/Frameworks/<Name>.framework/<Name> + the system's frameworks. Linux:
// /usr/lib(+triple) + local, lib<name>.so / .so.0 / -2.0.so.0 / .so.1 / .so.6 (usual versioned sonames, FreeType's
// .so.6; odd ones like libpython3.13.so.1.0 still
// need a symlink, WARP path, or a computed `from`). Windows: LoadLibrary System32+PATH (not this dlopen list).
static const char* LIBRARY_PATHS[] = {
	"%s.dll",
	"@executable_path/lib%s.dylib",
	"$ORIGIN/lib%s.so",
	"lib%s.dylib",
	"lib%s.so",
	"lib%s.so.0",
	"lib%s-2.0.so.0",
	"lib%s-2.so.0",
	"lib%s.so.1",
	"lib%s.so.1.0",
	"lib%s.so.6",
	"lib%s3.so",
	"/opt/homebrew/lib/lib%s.dylib",
	"/usr/local/lib/lib%s.dylib",
	"/usr/local/lib/lib%s.so",
	"/usr/local/lib/lib%s-2.0.so.0",
	"/usr/local/lib/lib%s3.so",
	"/usr/lib/lib%s.so",
	"/usr/lib/lib%s-2.0.so.0",
	"/usr/lib/lib%s3.so",
	"/usr/lib/x86_64-linux-gnu/lib%s.so",
	"/usr/lib/x86_64-linux-gnu/lib%s.so.0",
	"/usr/lib/x86_64-linux-gnu/lib%s-2.0.so.0",
	"/usr/lib/x86_64-linux-gnu/lib%s.so.1",
	"/usr/lib/x86_64-linux-gnu/lib%s3.so",
	"/usr/lib/aarch64-linux-gnu/lib%s.so",
	"/usr/lib/aarch64-linux-gnu/lib%s.so.0",
	"/usr/lib/aarch64-linux-gnu/lib%s-2.0.so.0",
	"/usr/lib/aarch64-linux-gnu/lib%s.so.1",
	"/usr/lib/aarch64-linux-gnu/lib%s3.so",
};
static const char* PROCESS_LIBRARIES[] = {"c", "m", "libc", "libm"};
// a library's function, NULL when the library has none of that name: never another library's
void* library_function(const char* library, const char* name) {
	for (size_t i = 0; i < sizeof PROCESS_LIBRARIES / sizeof *PROCESS_LIBRARIES; i++)
		if (!strcmp(library, PROCESS_LIBRARIES[i])) return process_symbol(name);
	// global: a library's own plugins (python's extension modules) find its symbols; dlsym on the handle still answers
	// from this library alone
	int flags = RTLD_NOW | RTLD_GLOBAL;
	// path as given: contains '/', dlopen that file
	if (strchr(library, '/')) {
		void* loaded = dlopen(library, flags);
		return loaded ? dlsym(loaded, name) : NULL;
	}
	char path[4096];
	for (size_t i = 0; i < sizeof LIBRARY_PATHS / sizeof *LIBRARY_PATHS; i++) {
		snprintf(path, sizeof path, LIBRARY_PATHS[i], library);
		void* loaded = dlopen(path, flags);
		if (loaded) return dlsym(loaded, name);
	}
#ifdef __APPLE__
	// Homebrew framework: /opt/homebrew/opt/<name>/Frameworks/<Name>.framework/<Name>
	{
		char Name[256];
		size_t n = strlen(library);
		if (n > 0 && n < sizeof Name) {
			memcpy(Name, library, n + 1);
			if (Name[0] >= 'a' && Name[0] <= 'z') Name[0] = (char)(Name[0] - 32);
			snprintf(path, sizeof path, "/opt/homebrew/opt/%s/Frameworks/%s.framework/%s", library, Name, Name);
			void* loaded = dlopen(path, flags);
			if (loaded) return dlsym(loaded, name);
		}
	}
	// a system framework by its name: `from 'CoreFoundation'`
	snprintf(path, sizeof path, "/System/Library/Frameworks/%s.framework/%s", library, library);
	void* framework = dlopen(path, flags);
	if (framework) return dlsym(framework, name);
#endif
	return NULL;
}

// the C function of that name the executable or a library it links has, else the library's own, loaded now (Windows
// loads no library the executable names but never calls by its import table); a program calling one none has stops here
void* native_function(const char* library, const char* name) {
	void* found = process_symbol(name);
	if (!found) found = library_function(library, name);
	if (!found) {
		fprintf(stderr, "no C function %s in this executable or the libraries it links (%s)\n", name, library);
		exit(1);
	}
	return found;
}
