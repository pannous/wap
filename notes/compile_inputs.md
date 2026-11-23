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

## When a program adds cases to a library word

A program may extend a library's overloads, for example `==(a: Side, b: Grouping)`. The precompiled dispatcher
does not know that case. The general mechanism (user 2026-11-21) adds cases to dispatch at compile time or at run
time. Signatures are enough for the compile-time way: the compiler writes the program's own dispatcher for that word
from all its cases (the library's from their export names, the program's own). The dispatcher calls the precompiled
bodies and the program's new ones. Bodies stay compiled once; only the small dispatcher is per program. A word no
program extends keeps the library's dispatcher. Open: whether some cases need run-time dispatch (values whose type is
known only at run time), and how much of today's semi-typed code exists only for this.

## Where it stands

The library compiles once into types.wasm, which each compiler holds in its own bytes (compiler.wap LIBRARY, the
build writes wap/types.wasm before it builds); a program reads its export names, never library source, and a program
calling it imports its one linear memory. The compiler writes the library once beside itself as types-<hash>.wasm, and
a module links it by that path; the native wap looks up a module by one rule (that path, or beside its importer) and
says a missing one. So a program never links another compiler's library, at a price: a compiled module names its
compiler's folder, so moving or deleting that folder (or copying the module to another machine) breaks modules compiled
earlier, which then have to be compiled again.
Generic words: one body per overload plus one general fallback for run-time dispatch (user), after the non-generic
words.
