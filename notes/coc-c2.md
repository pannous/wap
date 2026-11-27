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
