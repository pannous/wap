# The compiler runtime

The runtime is the Wap code that implements operations used by compiled programs. It is part of the compiler in `core/runtime.wap` and `core/runtime/`, distinct from the modules programs import from `lib/`. The value representation is described in the main repository's `warp's notes/self_hosting.md`, under “Value layout”.

## Roots and the split

`core/compiler.wap` names two runtime roots. `core/runtime.wap` collects the core runtime: text, lists, maps, arithmetic, equality, ordering, conversion, nodes and related operations. `core/runtime/extended.wap` collects the extended runtime: big integers and ratios, exact arithmetic and rounding, times and durations, powers and WASI file operations. These are compiler implementation modules; internal words are not necessarily public library functions.

Core generic operations reach extended values through the typed hooks declared in `core/runtime/bridge.wap`; their bodies are defined in `extended.wap`. Core runtime files do not import or name extended implementation words. `scripts/self-check.sh` checks this boundary. When building `runtime.wasm`, the compiler lowers the roots together. A normal compile takes that runtime, links it with the program and shakes unused runtime code; see `core/compiler.wap` for the linking path. Runtime words are Wap code lowered through the compiler pipeline, with emitter intrinsics for low-level operations.

## Examples

These are user-visible operations, not calls to internal runtime functions. On the installed native compiler, the following expressions produced the shown results:

```wap
numerator(1/3)                  // 1
denominator(2/3)                // 3
(1/6) as decimal                // "0.16̅"
12345678901234567890 + 1        // 12345678901234567891
"café".starts_with("ca")       // yes
```

The [standard library](standard-library.md) describes the modules and public words; runtime source files describe the implementation and its internal contracts.
