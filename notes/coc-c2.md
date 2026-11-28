# C2: a trait as a value's type

coc-plan.md's C2 row: a value whose type is not known at the call carries its instance, a record of its type's
function references, and C1b's structure (notes/coc-c1.md) joins it. Read on unify-typers 2b0e87be. This plan sets the
row's instance mechanism beside a smaller one that the wiki describes, and recommends the smaller one now.

## The wiki passages

- trait.md "Declaring a trait": "Each type defines its own `area`; a call picks the one of its argument's type."
- trait.md "Dispatch": "Where the type of a value is known at compile time the call goes straight to the type's
  operation. Where it is not (the items of a list sorted at run time), Comparable dispatches through runtime match
  cases, or as a later optimization through a witness table in the module."
- trait.md "Constraints" (a text block, so not a sample that runs): `smallest(xs: Comparable list) := (sort xs)#1`.
  It is fine on persons with `compare`, and refused on dots with C1's message.

The wiki names run-time match cases as the dispatch, and the witness table (the row's instance) as a later
optimization.

## What unify-typers holds

- A function of a protocol parameter is typed anew for each type given (calls.wap:402-415, "Protocols"). A static
  call never needs an instance.
- A union's value is held as an any's (fits.wap:116, T5u). A call whose argument is an any or a union dispatches by a
  chain of `is` tests over the word's definitions (dispatch.wap:1-8). Those are the wiki's "runtime match cases".
- calls.wap's DEBT (:409-412): a list of mixed protocol values, `x is shape` when the program runs, and a class's field
  counting as a word are not there.
- Function values exist (core/emit/function_values.wap, call_ref), so a record of function references is possible
  without new emit code.

## Two mechanisms

**A, the row: instances.**
- A trait value is the pair of the value and its instance, the record of its type's function references, built where
  a value is boxed into the trait (`x as shape`, a `list<shape>` literal).
- A word called on it reads its field (call_ref).
- Cost: core +110, emit +20.
- It pays C4: dispatch.wap's per-type retyping rounds go, core −90, net about +40.
- It is the only way across a module boundary: a compiled library (T5g) taking a `shape` from a program it has never
  seen.

**B (recommended now): a trait in a value's place is the union of the program's types that do its words.**
- `list<shape>`, `x as shape`, or a mixed list's items is the union `square or circle` of the records that conform
  (C1's `conforms`, over the program's records once typing knows them).
- A call on it dispatches by the existing `is` chain, the wiki's match cases.
- No new value layout, no instance, no emit change. A trait used only statically (every C1 and test_protocols line)
  is untouched.
- Cost: core +15. The trait read as the union in a value's place is +10, in type_notation.wap or fits.wap's
  `conversion`. `x is shape` at run time is the union test, +5.
- It needs the whole program, which every wap compile has today. A trait parameter of a separately compiled module
  has no conformers to union over, and that is where A becomes needed.

Decided: B as C2 now, at core +15. A, with C4's −90, comes with T5g, compiled libraries: the first place a
trait value crosses a module boundary. It is the wiki's "later optimization", and it is measured then, against B's
`is` chains.

## C1b, the structures

Under A, the instance is C1b's structure at run time, so the two land together (the supervisor's earlier call).
Under B nothing at run time reads the structure. Its readers are laws over a trait, which V3 (proved laws as facts)
and Q1 (a quotient's `same`, over Equatable) need. C1b then lands with the first of those, at the same core about +22.

## Gap lines

No line pins a trait value today. For a builder, both from trait.md "Declaring a trait" and "Dispatch":
- test_trait_wanted:
  ```
  class circle {r: int}
  area(c: circle) := 3 * c.r * c.r
  check("each item of a mixed list takes its own type's word", [square(2), circle(1)].map(area), [4, 3])
  ```
  It reuses the file's `trait shape` and `square`, with circle's area in whole numbers.
- test_trait_wanted: `ranked: list<Comparable> = [aged("Ann", 40), aged("Bob", 30)]`, then
  `check("a list of a trait sorts by each item's compare", (sort ranked)#1.name, "Bob")`. The file's `aged`, with its
  `compare`, stands in for the page's person.

## Estimate

| part | B | A |
|---|---|---|
| the trait as a value's type | core +10 (the union of conformers) | core +40 (the instance built at boxing) |
| a word called on it | 0 (dispatch.wap's `is` chain) | core +30 (its field read) |
| the layout | 0 (a union is held as an any) | core +20 (a row of T1's table), emit +20 |
| defaults where a type has none | 0 (typed per type, as today) | core +20 |
| `x is shape` when the program runs | core +5 | in the instance |
| C1b's structure | with V3 or Q1, core +22 | here, core +22 |
| C4 | not reached: the rounds stay | core −90 |
| **total now** | **core +15** | **core +132, emit +20, then C4 −90** |

Kernel 0 for both. B: normal path, test_trait_wanted and test_protocols, after C1a. A: careful path (value layout).

Decided B: it is trait.md's dispatch by run-time match cases, at core +15 on the normal path. A comes back with C4 and T5g's compiled libraries, measured against B's chains. C1b's structure lands with its first law reader.

## Re-read on 5285eb86 and c1-traits eefc9b94: C1b, then instances at boxing (A)

wap-supervisor asked for A's plan with its functions and cost, beside B's "decided" above. The reading below makes A
much smaller than the +132 this note estimated, because the trait's own class rule can write it in plain wap.

**What stands of origin/c2-trait-values da60505e (option B, unbuilt, on unify-typers 323ba86a, not on c1-traits).**
- The gap line stands: test_trait_wanted's mixed list `[square(2), circle(1)].map(area)` is `[4, 3]`. It is the
  spec line for either mechanism, and its reds.txt line goes with it.
- `conformers_recorded` (types.wap's typed_among, after globals_declared) stands only as the run-time answer of `x is
  shape` on an any (part A4 below). It should keep types, not names: it writes `symbol(type_text(type))` and reads them
  back with `word_term(text(name))`, which mixes up two records of one name (the same nit as c1-traits' cache key).
- B's fits.wap hunk, a value where a protocol is wanted converted to the union, goes under A. A boxes instead.
- On c1-traits, converted_at already says a protocol parameter is typed per type and never converted. The static
  path is untouched by both B and A.

**C1b: a trait as a structure, a type's instance as the record of its overloads.**
- On 5285eb86 only enums enter the kernel as blocks (inductives.wap:24, `cases_of(record) is not empty`). No class
  does.
- C1b is the general step: a class is a one-case block, its constructor taking its fields. The same EnumRead path takes
  a class as an enum whose one case is named by the class and its fields are the class's.
  - inductives.wap: the filter takes every non-protocol record, and enum_cases reads a class's fields as its one case.
  - Projections come from the kernel's structure reading (compute.wap:115, field_of), which already takes a one-case
    block.
  - core about +8. It is a mechanism, not a trait feature, so every class's laws gain it.
- The trait's structure is then the words class of A1 below: a class like any other, so it enters by the same path.
  There is no trait-specific kernel code.
- A type's instance is that class's constructor applied to the type's overloads, the value A2 builds. In the kernel it
  is the constant applied to the overloads' instance constants (analyze/terms.wap's instance_entered).
- C1b's readers (V3's laws over a trait, Q1's `same`) take it from there.

**A: instances passed at boxing, written by the trait's class rule.**
The protocol rule (sugar/records.wap:28, `rule instances $name [… ($word($parameters...): $type) …] => @protocol
Record(…)`) already walks the required words. It writes three more things per trait, in plain wap.

1. **The words class:** `class shape_words { area: (any) -> int; perimeter: (any) -> int }`, one field per required word,
   with the protocol's place in the word's type made any.
   - Also the held class: `class held_shape { value: any; words: shape_words }`.
   - One template each over `$members...`, as `member_as` does. sugar +3.
2. **The boxing:**
   ```
   shape(x: T): held_shape := held_shape(x, shape_words((v: any) => area(v as T), (v: any) => perimeter(v as T)))
   ```
   - It is typed anew for each T, as a protocol parameter is (calls.wap "Protocols"). Each lambda reaches T's own
     word, or the trait's default body, by the existing overload choice.
   - A function named as the protocol is already its conversion (calls.wap:498, reads_as). So `x as shape`, a
     `list<shape>` literal's items (calls.wap:245) and `s: shape = square(1)` all box through it, with no new site.
   - claim_checked (calls.wap:469-) reads a one-parameter function named as the protocol as a claim. It must skip a
     letter parameter: core +1.
   - A type that lacks a word is refused while `area(v as T)` is typed. That refusal goes through c1-traits' lacks_text
     so it reads `dot is not shape: … needs area(a: dot)`; the boxing's name is the caller. core +2.
   - sugar +2.
3. **The word called on a boxed value:** `area(h: held_shape) := h.words.area(h.value)`, one forwarder per required
   word. A held value's own type is more specific than the protocol parameter, so the existing ranking picks the
   forwarder. sugar +2.
4. **The protocol in a value's place:**
   - `list<shape>` and a field or variable of type shape read the protocol word as its held class. type_notation's
     word_named: a word whose record is a protocol, met where a value's type is written, is `held_<name>`.
   - A parameter keeps the protocol, so static calls stay specialised and fast.
   - This is the one core reading, the same place B needed. core +5.
   - `x is shape` on an any at run time: `x is held_shape`, or x's type among the conformers (da60505e's
     conformers_recorded, kept as types). core +3.

**Functions touched:** sugar/records.wap's protocol rule (three templates), calls.wap claim_checked (letter skip),
lacks_text's caller, type_notation.wap word_named (the value-place reading), conditions.wap type_test_typed (`is`
at run time), inductives.wap enums_entered and enum_cases (classes as one-case blocks, C1b). Emit 0: function values
and call_ref exist (core/emit/function_values.wap).

**Cost.**

| part | lines |
|---|---|
| C1b, classes as one-case blocks | core +8 |
| A1-A3, the trait rule's words class, held class, boxing and forwarders | sugar +7 |
| A2's claim skip and refusal text | core +3 |
| A4, the value-place reading and `is` at run time | core +8 |
| **total** | **core +19, sugar +7, emit 0** |

This is against this note's A at core +132 and emit +20, and B at core +15. A now costs B's core and also gives what B
could not:
- a trait value crossing a module boundary (T5g), since the boxing travels with the value;
- C4's per-type rounds, whose −90 can follow.

Recommended: A in this form. It is plain wap except the one reading of a protocol in a value's place.

**Risks for the builder.**
- (a) `v as T` of an any, with T bound at specialisation.
- (b) The forwarder's ranking against a default body that takes the protocol.
- (c) The census: every trait now writes three classes and a function per word. The seven built-in traits add about
  21 small definitions to every compile; measure the self-compile. If it costs, write the three only for traits a
  value place names: the rule stays, and the boxing is typed only when called.

**Green.**
- test_trait_wanted: the mixed list line (da60505e's), and the `list<Comparable>` sort line above.
- test/wap/test_trait_wanted: "a parameter asks for a list of values that conform to a trait", c1-traits' red line,
  through A4's `Comparable list`.

Path: careful. A value layout is new: held values cross emit as plain class values, but their first use is in every
mixed list.
