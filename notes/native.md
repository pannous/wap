# The native wap: what its programs get from the host

The native wap (wap/extensions/native, built by build.sh) runs a module through wasmtime's C API. Owner of the slices:
warp-host-fixer; this file is the inventory.

## Answered
- WASI, by wasmtime.
- .wasm modules a program uses (run.wap imports_linked).
- C functions (host_words.wap, branch native-c-functions): each C import is the C function of its name, from the
  process or the library its module names (lib/native/libraries.h); an i32 is a pointer into the module's memory, an
  i64 as it is, an f64 a double. test/wap/test_c.sh.

## Not yet
- Texts in a native program itself (the driver's own code): wasm2c takes no GC type (next slice, warp-wap-operators).
- A C function calling back into the program (lib/callbacks.warp c_callback): SDL, sqlite, audio.
- C structs by value (lib/native/foreign.c native_call_struct); f32 parameters.
- The host words of warp's lib/host/native_host (3400 lines), needed once lib's window, sound, gpu and webview
  modules are wap: window (host_window_layer, host_pixels_shown, host_shader_painted, host_shader_shown,
  host_text_coverage, host_value, host_value_set), sound and MIDI (host_sound_played, host_sound_file_decoded,
  host_sound_file_played, host_sound_voice_joined, host_sound_voice_kept, host_sound_voice_back, host_midi_ports,
  host_midi_sent), gpu (host_gpu_render, host_gpu_show, host_gpu_show_sized, host_gpu_picture,
  host_gpu_picture_sized, host_gpu_computed, host_gpu_fields, host_gpu_fields_format, host_gpu_pass_recorded),
  webview (host_webview_page_text), C calls awaited (host_foreign_call, host_foreign_await, host_foreign_pending),
  the run's life (host_run_ended, host_waited, host_export, host_owns).

## Who needs what
- wap's tests: C functions of 'c' and 'm' only.
- lib/'s C libraries by imports: wgpu_native 66, raylib 32, python 31, sqlite3 26, rs_regex 10, objc 8, mpg123 8, m 8,
  uniscript_c 6, rs_sha2 6, freetype 6, z 5, rs_strsim 2, rs_crc32fast 1, kernel32 1.
