# C4: generic dispatch

coc-plan.md's C4 row: a generic definition called on a boxed value takes the value's instance, and dispatch.wap's rounds
go (generic_choices, generic_results, taken, dispatches_completed, deeper_type, fits_generic, boxed_known,
dispatcher_retyped: "about 90 lines"). Read on 5285eb86 with C2's A decided (notes/coc-c2.md). The finding: the
instances of C2's A never reach the rounds, so the row's −90 does not hold. A smaller C4 does.

## What the rounds do (core/analyze/dispatch.wap)

- A dispatcher is the chain of `is` tests a call writes where an argument is an any or a union (dispatching, :31).
- The rounds serve one case: a **generic collection definition** of the word, `text(xs: list<T>)` or `keys(m: map<K,
  V>)`, taking an any. generic_place (:107) asks for a parameter of a collection word that writes letters.
- For such a definition the chain has one choice per **collection type boxed into an any anywhere in the program**:
  `x is list<int>` gives `text(x as list<int>)`.
  - Those types are gathered at boxing (fits.wap:170, `s.boxed`): generic_choices (:114), taken (:138) and boxed_known
    (:173).
  - Each choice is the generic definition specialised at that type, as wiki/wasm-representation.md:33 says generic
    bodies are ("the importer compiles a copy for its own types").
- The set grows as typing goes on, since a later statement, or a dispatcher's own body, boxes a new type. So
  dispatches_completed (:150) retypes the dispatchers whose word fits a new type, round after round, until no new type
  is boxed. It refuses a round that boxes ever deeper types (deeper_type).
- A dispatcher's result is the join of its choices' results, so `keys(m)` of an any holding a map<text, int> gives
  list<text> (dispatch_results, generic_results, generic_result, :124-136). When a retyped dispatcher's result
  changes (dispatcher_retyped, :179), **the whole program is typed again**: types.wap:217, `if
  dispatches_completed(s) { return typed_among(…) }`.

Measured, in code lines without comments and blanks:

| function | lines |
|---|---|
| generic_place, held_boxed | 4, 1 |
| generic_choices | 7 |
| dispatch_results, generic_results, generic_result | 13 |
| taken | 4 |
| dispatches_completed | 15 |
| deeper_type, fits_generic, boxed_known | 1, 4, 5 |
| dispatcher_retyped | 11 |
| outside: dispatching :33 and :54-56, dispatch_body :87, fits.wap:170, types.wap:104, :196, :217, Dispatch's `covered`, TypingState's `dispatches` | about 10 |
| **all** | **about 75** |

## Why instances do not reach them

- C2's A gives a value an instance where it is boxed into a **trait**: held_shape carries shape_words, built by the
  boxing `shape(x: T)`.
- A generic definition called on a held value is typed at T = held_shape, as any static call is, and its trait words
  go through the forwarders. It needs no dispatcher at all, so C2's A already gives what the row's sentence "takes the
  value's instance" describes.
- The rounds serve an any. An any is the trait of no words: boxing a list<int> into an any cannot know which generic
  words will later be called on it, so it has no instance to build.
- The per-type choices are monomorphisation over a set that grows while typing runs. That needs a fixed point whatever
  the box carries. A witness table indexed by the any's tag (trait.md "Dispatch", "later optimization") is the same set
  computed the same way.
- The other way out, one choice per generic definition typed at T = any with the list read as a list<any>, needs a
  view of a list<int> as boxed items. Under the wasm layout that is a copy, and mutation through it would be lost: a
  wrong value. Refused.

So all 75 lines stay as a mechanism.

## The C4 that holds: a generic choice's result is no longer joined

The costly part is not the rounds but their reach.
- A dispatcher's result follows its choices, so a new boxed type can change it, and then **every function is typed
  again** (types.wap:217).
- If a dispatcher of a word with a generic choice gives the result its definitions write with their letters read as
  any (`keys(m: map<K, V>): list<K>` gives list<any> from an any), its result never changes with a round.
  - Its callers never need retyping.
  - The rounds then retype the dispatchers alone.

What goes:
- generic_results and generic_result (:128-136, 9 lines);
- dispatcher_retyped's result compare (:186-189, 4 lines), which leaves it a function that retypes a dispatcher and
  returns nothing;
- dispatches_completed's `grown` (2 lines);
- types.wap:217's whole-program retype (1 line), with typed_among's `before` state that exists for it (:190-196: the
  unknowns, el and boxed carried over; about 4 lines once nothing calls it twice).

dispatch_results keeps the plain definitions' results and adds, for each generic definition, its written result with
letters as any (+2).

Net: **core about −18**, and a speedup: a program that boxes collections is typed once, not once per round that changes a
result. That counts as "standing OK speed" only once measured, and the lines go either way.

## What a generic call on a boxed value compiles to

- **On a trait value, held_shape (C2's A):** the definition specialised at held_shape, a static call. Its trait words are
  the forwarders `area(h: held_shape) := h.words.area(h.value)`, a field read and a call_ref. No dispatcher.
- **On an any:** a dispatcher, unchanged. First the tested plain definitions, then for a generic definition one choice
  per boxed collection type (`x is list<int>` → the definition at list<int>), then the untested one, else the raise.
  - Its static result is the written result with letters as any, so `keys(any_map)#1` is an any, dispatched again where
    it is used. It is no longer list<text>.
  - The test that would notice is a program using such a result as a text without a dispatch, which then needs `as
    text`. Builder: run test_operators, test_protocols, test_dispatch-like lines in test_any*, and test_self.
    test_self shows whether the compiler's own source relies on a joined result.
- **On a union:** as on an any. Its parts are known, so its choices are already the union's parts (taken over
  `union_parts`). It is unchanged.

## Before the builder starts: the precision check

Unjoined results are a precision loss programs can see: `keys(any_map)` was list<text> and becomes list<any>.
- Before building, the builder greps the wiki and the tests for a collection read through an any whose element type is
  then used as written: a generic word's result on an any-held list or map, used where a text, int or record is
  wanted with no `as`.
- Places to read first: wiki/map.md:51 (`map<any, any>`), wiki/trait.md:120, test/test_dynamic.wap, test/test_json.wap
  (parsed JSON is any-held maps and lists), test/test_conversion*.wap and test/test_types.wap.
- Each hit goes to wap-interviewer with its example (code, today's type, the unjoined type) before any code changes.
  None found: build.

## Gap lines (trait.md "Dispatch")

- test_trait_wanted:
  ```
  describe(x: T): int := area(x)
  shapes: list<shape> = [square(2), circle(1)]
  check("a generic call on mixed boxed values picks each type's area", shapes.map(describe), [4, 3])
  ```
  It is C2's A and C4's sentence together, with no dispatcher in it.
- The row's "the rounds' nests-without-end refusal is never reached" does not hold: deeper_type stays, since an any can
  still box ever deeper types. That line is dropped from the row.

## Estimate and order

core about −18, kernel 0, emit 0. After C2's A, which makes trait values static. Careful path: a dispatcher's result
type changes for every program with an any-held collection. The census and test_self are the check. The row in
coc-plan.md says −90 at T5g; it becomes "−18, the rounds' reach; the rounds themselves are monomorphisation and stay".
