# wasm-representation

Wap is wasm native: 

Everything is in the language is designed around the capabilities and constraints of WASM, and maps natively and directly wherever it makes sense, without being limited by the current state.

Whatever wasm already expresses, we take by convention from wasm’s standard sections. Only what wasm erases goes into our wap section, and we write that as plain wap [[data]].

By convention, from wasm itself:

- Names: wasm’s standard name section already holds names for functions, locals, types and fields. Tools such as browser devtools and wasm-objdump read it. We use it instead of inventing our own.
- Public versus private: exported means public; anything not exported stays inside the module.
- Dependencies: each module a file uses becomes the module name of its imports, so the import section already lists them.
- Top-level statements: they become the wasm start function.
- Classes: a class’s shape comes from its GC struct type plus the type and field names in the name section.
- Source positions: the existing sourceMappingURL convention, rather than our own scheme.
- Signatures: an export's name is its header line, below. wasm can't tell int from bool, char or an enum case, or text from a list, so the name carries the real types, parameter names, defaults, optional types and the result type.

## Export names

Each overload is exported under its signature written as wap: `add(a: int, b: int = 1) → int`. wasm export names are any UTF-8 text, and the normal reader reads this one, so the name needs no decoding scheme of its own. Generics, unions, function types and optional types are spelled as in any program: `sum(xs: list<int>) → int`, `f(g: (int) -> int) → int`.

- The result type is part of the name, since wap overloads by result too: `sample() → int` beside `sample() → text`.
- An overload set is every export whose name starts with the same word: `+(a: int, b: int) → int` and `+(a: text, b: text) → text` are the set `+`.
- A call whose argument types are known at compile time calls its overload by that full name.

The plain name is reserved for the dispatcher: `+` alone is a function of boxed values that checks each argument's Kind tag and calls the overload that fits. It knows the module's own overloads, and the overloads of modules loaded later join it through a shared dispatch table at instantiation. JavaScript callers and dynamic code call the plain name. When several overloads fit a call at runtime, the dispatcher refuses loudly, naming them, and never guesses. Overloads that differ only in their result give it no argument to check: it picks one only when the caller names the expected type, `sample() → text`, and otherwise refuses with both readings.

Explicit, in the wap section, because neither wasm nor the export names carry it:

- Enum cases and class field defaults.
- Rules, operators and aliases the module declares. A use brings in syntax too, and none of that is in the compiled code.
- Generic or inlinable functions as source. A function over any list can’t be precompiled for every element type, so its body goes along as wap text and the importer compiles a copy for its own types. The same goes for 
- Constants the importer folds in at compile time.
- Facts that change how callers type, such as “never returns”.
- A version wap.build stamp section: the compiler hash, the layout version of values in memory, and the source hash, so a stale module is refused loudly. 
- Doc comments of exported functions, a separate section that a release build can strip.

Format: The wap section is a header file in wap format, plain wap text: the module's rules, enums and the bodies that travel as source. Its exports' declarations need no lines there, since each export's name is its header line, `add(a: int, b: int = 1) → int`. The reader then runs the normal reader and declare stages on it. That needs no new binary format and no second schema, and reading a .wasm reuses about 90% of reading a .wap
TODO: All modules must declare the header in exactly the correct format so that we can just copy it into the module.

A declaration is `export` and a signature without a body: the body is in the module's code. Without the word, `add(a: int, b: int = 1) → int` would read as an expression, so the word keeps the header plain wap that reads one way. `export` is the existing word for what a module shows <!-- decision library-word-visibility -->; what a module does not export is private, so a header needs no `private`. `import` is kept for the other direction: a function a program declares that some module without a header supplies (a foreign call).

A built-in needs no keyword of its own: it is already declared like any function, its body a primitive, `char(code: int): char := prim i32.wrap_i64(code)` (wap/types). Its header line keeps that body, as any inlinable body does, so the importer emits the wasm instruction in place instead of a call.
