# T5: definitions, statements and inductive types, in landable steps

coc-plan.md's T5 row is the goal. analyze already types every function of wap's source. What it does not do yet is give the kernel what it typed: a function enters the kernel as an opaque constant by its signature, and the census counts it as assumed. T5 turns analyze's typed nodes into kernel declarations and terms. It does this step by step, each step for one family of forms, and each step deletes the files of wap/extensions/theory/elaborate whose job analyze takes over, so the two typers never both do one job.

T5u (unions, coc-plan.md's T5u row) comes first. Every step after it is measured as T4's were: core lines, the census, test_self's instructions. Each step takes the careful path, since each one changes what the census and the self-build count.

## The steps

| step | what works after it | core lines (estimate) | deletes | outcome lines |
|---|---|---|---|---|
| T5a pure definitions | a function whose body is a pure expression enters the kernel as a definition with its body as a term, checked by the kernel; its body unfolds when a type or a condition computes with it (T4d's need). Pure expressions are literals, calls of known definitions, `if`, `let` blocks, `and`/`or`, and the number and text primitives by their T1 row. Items, Entries and Instance (a list's items, a map's entries, a record's instance) become kernel forms, built with the elaborator (user 2026-11-27: kernel +6, core about +2) A function with any other form stays opaque, as today. The theory's door reads analyze's typed nodes, so read.wap takes analyze's choice in place of `nearest`, TRIAL_LIMIT and the numeral special cases. The door names only what the kernel accepted, a definition or a T1 row (notes/audit/2026-11-27.md R3): a law, a proof or a type argument naming a function still opaque (an assumed constant) is refused by that function's name. Effects stay out of T5a | +180 analyze (terms.wap: typed node to term, the declaration entered and checked), +2 core and +6 kernel (the three forms), −40 extension | the expression half of elaborate/read.wap; letters.wap, ROUNDS_LIMIT | `type of` a type alias whose argument calls a pure function computes, `vector(int, double(2))` is `vector(int, 4)`; the census counts the compiler's pure functions as defined, not assumed; a function giving a wrong type refused by the kernel, naming its line; a law naming a function that writes its parameter, `grow(xs) := { xs.add(1); 0 }`, refused naming grow |
| T4d computed | an obligation whose value and predicate compute is decided when compiling (notes/coc-t4.md) | +30 | | test_subtype_wanted's two compile-time refusal lines |
| T5b enums and match | an enum is an inductive declaration, its cases its constructors; `match` is the recursor's case split, and a `match` that misses a case is refused by `covering`; analyze's matching.wap replaced | +220 analyze, −191 (matching.wap) | elaborate/match.wap (256) | a `match` over an enum missing a case refused by `covering` (a theory refusal test, exempt); `effects of` a match over every case is Pure |
| T5c recursion | a recursive function is structural where an argument shrinks by a case, else needs a measure, else has the effect Div and still runs | +120 | elaborate/recursion.wap (117) | `effects of fact` is Pure; `effects of` a `while` without a measure is Div and it still runs |
| T5d statements | blocks, variables, loops and exits as terms: a variable's new value a new binding (T3), a loop a recursion over its state, an exit a jump out of it | +200 | elaborate/statements.wap (210) | test_effects_wanted's "a function reading a constant free variable is pure"; a loop's sum computed when compiling |
| T5e classes, generic records, extends | a class is a structure, its fields projections; `class Pair<A, B>` takes type arguments (wiki/type.md:111); `extends` is the closed sum analyze builds from the class declarations, the `inherited` rule still copying the fields: a record others extend is typed as the union of itself and its extensions, so a Dog given where an Animal is wanted is boxed as any union part is, and a call on the parent picks each value's method when the program runs (T5u's dispatch over unions, no case of its own; today `[Animal("Kitty"), Dog("Rex")]` is a list<Animal> and Animal's speak is chosen when compiling, so "Rex makes a sound": test_functions_wanted, wiki/function.md). About +10 core: the written name's type is the union, read where a type name is resolved | +150 analyze; the value layout of a generic record (card wap-native-no-layout-any): +40 to +80 | elaborate/sums.wap (140) | test_type_wanted's "a class takes type arguments" (`Pair(1, "a").second` is "a"); test_functions_wanted's `for pet in [Animal("Kitty"), Dog("Rex")] { print speak(pet) }` prints "Rex barks" |
| T5f erasure | the emitter reads the statements and their checked facts, types, levels and proofs emitting nothing (coc-plan.md 9.7); the translation of statements to terms (9.5) is believed, and the law run tests it; the erasure stage chooses the build's strategies (GC structs or memory structs, call_ref or a table, struct.get or a load), the branches on a build keeping its values in the memory | +200 emit, −150 emit (shape guessing) | | every test as before; the memory build's branches gone from the emitter |
| T5g compiled libraries | a compiled library carries its declarations as the kernel accepted them, with their erased bodies (decision 2026-11-25), about 60 lines in extensions/wasm, outside the compiler's count | 0 core | about 150 in extensions/wasm (the warm state, one section reader) | a program using a compiled library computes with its definitions' bodies |

## The estimate

T5 as a whole: about +1,100 core added and −340 deleted, against coc-plan's +1,059 net. The difference is the generic record layout (+40 to +80) and T4d's +30, which coc-plan counts in T4. The extension loses its elaborate/ files as each step takes their job: about 950 lines, outside the compiler's count.

## Order and dependencies

T5u, then T5a (pure definitions: everything later builds on terms), then T4d (it needs T5a's bodies), then T5b to T5e in that order (match before recursion, since structural recursion is over cases; statements before classes, since a method's body is statements), then T5f and T5g. T4c and T4e follow T4d as notes/coc-t4.md says, beside T5b.

## Gate

T5 is done when:
- the T5 row's lines are green;
- the census counts every function of wap's source as defined or Div, none assumed;
- the theory's elaborate/ holds no file whose job analyze does;
- `--stage 2` is a fixed point;
- the self-compile grows by at most a fifth over T5u's, measured on the same machine.

## Open for the user (through the supervisor)

- **Generic records' layout:** a `Pair<A, B>` value as one struct whose fields are anyref (boxed, as an any is), or one struct type for each instance. The boxed layout is the one card wap-native-no-layout-any estimates at 40 to 80 core. Recommended: boxed, as unions are.
- **T5a's size:** pure definitions first, and statements in T5d, is the recommendation, so that T4d can land after T5a. One step for all definitions would land about +700 at once.
