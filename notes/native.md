# The native wap: what its programs get from the host

The native wap (wap/extensions/native, built by build.sh) runs a module through wasmtime's C API. Owner of the slices:
warp-host-fixer; this file is the inventory.

## Answered
- WASI, by wasmtime.
- .wasm modules a program uses (run.wap imports_linked).
- C functions (host_words.wap, branch native-c-functions): each C import is the C function of its name, from the
  process or the library its module names (lib/native/libraries.h); an i32 is a pointer into the module's memory, an
  i64 as it is, an f64 a double. test/wap/test_c.wap.
- C calling back a function of the program (lib/native/callbacks.h trampolines, host_words.wap callback_answered):
  the export c_callback_fired(slot, a, b, c, d, e, f) of the module whose C call is in progress, during that call;
  its int result C's. test/wap/test_native.sh (qsort).
- Texts in a native program (build.sh): the compiler's `native` option lays a text out as the address of its count and
  bytes in the memory, and the build reads types/memory_texts.wap in the place of types/text_bytes.wap.
  Its memory is never freed: fine for the driver and short programs, not for a long-running native one. When the
  memory cannot grow further (wasm's 4 GiB, or the host's limit), memory.grow fails (core/emit/host.wap memory_grown
  drops its -1) and the first store past the end traps, "Out-of-bounds access in linear memory": the run stops loudly,
  nothing is overwritten; the message does not yet say the texts ran out of memory.
- Lists in a native program likewise: a list is the address of its header in the memory, [count][room][items block],
  the items 8 bytes each (core/emit/primitives.wap item.load/item.store by the item's layout); the build reads
  types/memory_lists.wap in the place of types/list_items.wap, and typing writes a list literal as calls of
  its `reserved` and `extended` under the same switch, the compile's MemoryLayout (core/emit/memory.wap; a native build's is
  extensions/native/memory.wap NATIVE_MEMORY, its built_by). A list grows in place, its block copied to one
  twice as large, every name holding it seeing the item; the old block is never freed, like a text. Maps, `any` and
  enums whose cases have fields stay GC values a native program cannot use yet.
- Enums of cases without fields in a native program: a case is its tag, an i32, compared by i32.eq (core/emit/values.wap
  enum_layout, tagged), as a class's instance is its address.
- An uncaught raise in a native program: its text and a line end on stderr, then exit status 1, no exception thrown
  (core/emit/host.wap raising_function, by the MemoryLayout's `raised`: extensions/native/memory.wap
  raise_written). try/catch stays GC-only.

## Not yet
- A lib module's function as the callback C calls: lib/callbacks.wap's `export c_callback_fired` is no wap form, and a
  used module's functions are not exported (SDL, sqlite, audio need it).
- C structs by value larger than a register, and all-float ones (HFA: raylib's Vector2); out-pointers are answered (native-imports).
- The host words of warp's lib/host/native_host (3400 lines), needed once lib's window, sound, gpu and webview
  modules are wap: window (host_window_layer, host_pixels_shown, host_shader_painted, host_shader_shown,
  host_text_coverage, host_value, host_value_set), sound and MIDI (host_sound_played, host_sound_file_decoded,
  host_sound_file_played, host_sound_voice_joined, host_sound_voice_kept, host_sound_voice_back, host_midi_ports,
  host_midi_sent), gpu (host_gpu_render, host_gpu_show, host_gpu_show_sized, host_gpu_picture,
  host_gpu_picture_sized, host_gpu_computed, host_gpu_fields, host_gpu_fields_format, host_gpu_pass_recorded),
  webview (host_webview_page_text), C calls awaited (host_foreign_call, host_foreign_await, host_foreign_pending),
  the run's life (host_run_ended, host_waited, host_export, host_owns).
- The gpu words are wap (lib/host/native_host/gpu.wap, compiled only, never run: no window, gpu or sound program
  runs). They still need: a guard `{ return }` before a closing assignment (seven functions refused, a typing bug), a
  list of numbers crossing as its cells (`memcpy(…, source: cells<i32>, …)`), window.wap's `global window` seen by
  the modules that use it, and window.wap's value functions (mouse_x, mouse_y, mouse_down, mouse_wheel,
  key_code_held, window_layer). A storage array's numbers cross as cells of the element the shader declares (f32,
  i32, u32, or f16 two to a word): warp's GPU lists are plain typed lists here.
  picture is a `Picture { width, height, pixels }`.

## Parked
- The emitter's text helpers live in types/ (card text-helpers-out): native texts stays at +9 core lines. The helpers
  leave once the emitter's own callers (record and any comparisons, the any cast's raise, main's uncaught catch) are
  types words placed by typing; noted on card wap-prims-mnemonics.
- `import cbrt from "m"`, `import (getenv, strlen) from "c"` (warp's form; parked 2026-11-21 by warp-interviewer, samples
  write `use m`, `use c`). If wanted: declarations.wap phrase_part reads `use <names> from <library>` as `use <library>`
  (about 3 lines) and refuses a named function the module does not declare, naming the module to declare it in (about
  4). samples/native/c_calls.wap keeps the form: warp's @primitive mode reads no `use c`.

## Who needs what
- wap's tests: C functions of 'c' and 'm' only.
- lib/'s C libraries by imports: wgpu_native 66, raylib 32, python 31, sqlite3 26, rs_regex 10, objc 8, mpg123 8, m 8,
  uniscript_c 6, rs_sha2 6, freetype 6, z 5, rs_strsim 2, rs_crc32fast 1, kernel32 1.

## The native wap's driver (wap/extensions/native)
- folder_part (run.wap) walks a path's bytes back to its last slash by hand: one line once native texts have a
  last_index_of.
- Workarounds of native gaps, each to go when its gap closes: the driver reads its arguments by its own loop (prelude's
  arguments() maps and writes from BYTES_AT), joins lists by add (list + is wrong natively), reads files by fopen
  (read() takes an optional), and declares fopen's result i64 (a `handle` result raises, which emits GC helpers).
- Waiting for native optionals (read() reachable natively): a test_native line reading a file over 64K, the proof of
  host.wap's scratch(count); and read() then returning its scratch text cut to the bytes read, not a second copy.
