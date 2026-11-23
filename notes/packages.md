# Packages: how wap could reach other ecosystems' libraries

1. Rust crates compiled to wasm, linked like our own modules (the closest thing to “crates as packages”)

Wap is wasm-first and already reads WIT. A crate built for wasm32-wasip2 as a component, with a WIT interface, is just another module to link, and the Rust API’s instability doesn’t matter because the WIT interface is the contract.
This suits pure-computation crates: parsers, regex, image and audio decoders (symphonia for MP3/FLAC/OGG), compression, crypto, fonts, physics (rapier). They would run in the browser playground too.
It can’t reach OS devices, so it won’t play sound or open windows.

2. Rust crates behind a C interface (the “black magic” part)

This is the pattern we already use for wasmtime, through our own libwarp_wasmtime. A small shim crate exports extern "C" functions and builds a dynamic library, which wap calls through FFI.
Tools like uniffi, cbindgen or diplomat generate that shim, so we don’t write it by hand per crate.
This suits crates that need OS access, such as cpal (audio on every OS) or winit (windows).
The cost is one dynamic library per platform, built in CI the way wasmtime-bundled already is.

3. Plain C libraries, called through FFI

Wap can already call these directly, as it does with sqlite and raylib.
For sound this is the best fit: miniaudio is a single C file covering CoreAudio, ALSA, PulseAudio and WASAPI. It runs its own audio thread and mixer, so wap writes samples into its ring buffer or plays sounds through its engine, and never needs C to call back into wap. So no C callback into wap is needed, which macOS audio would otherwise require. It’s also low latency and covers Windows for free.