# What the compiler needs to compile a program

User decision, 2026-11-21: **priority layout**. Kept clean until it is implemented.

To compile a user program, the compiler needs three things only:
- **the library's signatures**: names, parameter types, result types;
- **the types' declarations**;
- **the rule tables** (sugar and the other rewrite rules).

Everything else is compiled to WebAssembly exactly once: every library function body, the runtime and the types'
methods. A program links to those modules and never makes the compiler read or analyse library code again.

Where the three inputs come from:
- **Signatures come mostly from the demangled export names** of the compiled library modules: the header lines
  `add(a: int, b: int = 1) → int` (wiki wasm-representation). The plain name is the dispatcher.
- **Type declarations come mostly from the WebAssembly type declarations** of those modules: the GC struct, array and
  enum types. Names and whatever wasm cannot say travel in the module's name and custom sections.
- **The rule tables** are the only state with no wasm form. They travel packed (module `packed`, decision
  wap-packed-library).

So the compiler's warm state is small: rules plus whatever the modules' own wasm does not already say. It is no copy
of the library's analysed source. This matches the C++ wasp compiler, which compiled programs with only its built-in
signatures, except that here the signatures come from the library's own compiled modules instead of being
hard-coded.

Measurements and the options considered: warp notes/gc_snapshot.md. Today's full warm state (424k nodes, library
bodies included) is the layout this note replaces.
