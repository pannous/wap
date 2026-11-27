# Q1: quotients

coc-plan.md's Q1 row: `quotient(T, same)` is a type; `.of` puts a value in; `.lift` takes a function that respects
`same` out; `fraction`, `rational` and `set` are quotients in wap/types. Read on unify-typers 2b0e87be. Q1 waits on C1,
T6a3 and T6a4 (the row) and, as read here, on T4e and V3.

## The wiki passages

All of quotient.md:
- a quotient's `==` is its relation (`half == fraction(2, 4)`);
- `quotient.of(a)`, and a value of T converting to the quotient on its own;
- `lift` with its respect proof, refused without it;
- `lift_of := refl`;
- a rational stored as a fraction at run time;
- `rational`, `set<T>` and `i64` as the library's quotients;
- `function_extensionality` with `axioms of` it `[quotient_sound]`.

## What unify-typers holds

- kernel/quotients.wap (K5) declares `quotient`, `quotient.of`, `quotient.lift` and `quotient.induct` with their
  computation rule, after `quotients(Equal)` (`quotients_declared`). The kernel's lift on a made value computes, so
  `lift_of := refl` is the kernel's.
- No program word reaches them: no `quotient` type word, no `.of`, no `.lift`, no `function_extensionality` and no
  `quotient_sound` axiom by that name.
- test/test_quotient_wanted.wap: all red. Its i64 line is T8a's and T8b's.
- wap/test_theory_quotients_wanted: written in explicit levels through verify's door, and red "until the door reads
  the logic's enums", which is T6a6.

## The plan: a quotient is a type that takes values (T4e) over its carrier

1. **The type.** `quotient(T, same: (T, T) -> bool)` is a types-module type with a value argument, read by T4e's
   applied-alias reading. It is a new type, never a subtype: a value of the quotient holds a T at run time (quotient.md
   "stored as a fraction"), and its kernel term is `quotient(T, r)`, with r the relation as a proposition.
   - The conversions:
     - **up is automatic**: a T where the quotient is wanted becomes `quotient.of(a)`;
     - **down never happens**: a rational is no fraction, or `top` would leak.

     These are c-type-names' declared conversion, in the direction from the carrier to the new type.
   - core +12 (the conversion's direction for a quotient, its kernel term).
2. **`==` is the relation.** `==(a: quotient(T, same), b: quotient(T, same)): bool := same(a, b)` in types/quotients.wap.
   T4e's letters find `same` from the types. types +1.
3. **`quotient.of`.** `of(a: T): quotient(T, same)` takes `same` from the type wanted (`quotient.of(fraction(1, 2)) ==
   half`, where half's type gives it). That is a letter found from the expected type, beside T4e's from the
   arguments. core +5.
4. **`lift` and its obligation.** `lift(q: quotient(T, same), f: (T) -> R): R := f(q)` runs as a plain call
   (quotient.md). The call obliges `for a, b: T, same(a, b) implies f(a) == f(b)`. That is a proposition, so the
   provers take it, as V3's `wap check` takes obligations.
   - It cannot be checked when the program runs, so an unproved one is refused, with the statement named.
   - Unlike every other obligation, a plain compile must decide it. So a program with a `lift` loads the proof
     extension, as T7 says proofs do.
   - core +12 (the obligation built), prove +5.
5. **Kernel terms.** `.of` and `.lift` calls enter the kernel as `quotient.of` and `quotient.lift`, through T5b5's
   lookup and `term_of`. So `law lift_of … := refl` computes by the kernel's rule. core +8.
6. **The library.** In types/quotients.wap, plain wap:
   - `fraction`, `same_value`, `rational`;
   - `set<T> = quotient(list<T>, same_items)`, with `same_items` over sorting or counting;
   - the axiom `quotient_sound` (the kernel's soundness axiom under that name), and
     `function_extensionality` proved from it, a T6a1 theorem in types.

   i64 is T8b's. types about +20.

## The wiki's `sign` lift needs a lemma (decided A)

quotient.md's fine example, `q.lift(f => sign(f.top * f.bottom))`, needs
`a.top * b.bottom == b.top * a.bottom` (with bottoms nonzero) to imply `sign(a.top * a.bottom) == sign(b.top * b.bottom)`.
That is a nonlinear fact about products and signs. The provers are linear plus induction (law.md: "Floats and `/` stay
at Tested"), so as read they would refuse it, and the program the wiki calls fine would be refused.

- A (decided): types/quotients.wap (or wherever sign lives) states and proves the sign law over products once
  (`sign(x * y) == sign(x) * sign(y)` with the multiplication cases), and the provers use it as a lemma (V3). That is
  types +6 and no wiki change. The builder measures whether the provers then find the respect proof.
- B: change the wiki's example to one the provers reach. That is a wiki change.

If the respect proof is still not found, what is missing comes back as a further lemma, never a change to the wiki's example.

## The red lines it turns green

| line | form | part |
|---|---|---|
| test_quotient_wanted:8 | `half == fraction(2, 4)` | 1, 2 |
| test_quotient_wanted:9 | `quotient.of(fraction(1, 2)) == half` | 3 |
| test_quotient_wanted:10-11 | `sign` lifted, `[1, -1]` | 4, with the doubt's A |
| test_quotient_wanted:12 | `lift_of := refl` | 5 |
| test_quotient_wanted:13 | `set([1, 2, 2]) == set([2, 1])` | 6 |
| test_quotient_wanted:15-19 | `same := function_extensionality(…)`; its axioms `[quotient_sound]` | 6, with T6a1 (a law's call) |
| test_quotient_wanted:14 | the i64 line | T8a, T8b |
| wap/test_theory_quotients_wanted | the kernel forms in explicit levels | with T6a6 and T6a7 |

## Estimate

Core about +37 (+12, +5, +12, +8), prove +5, types about +21 (+27 with the doubt's A), kernel 0. The row had core +50
and types +40: T4e's value arguments carry the type form, and `set`'s relation is a few lines over sorting.
Careful path (a new type's conversions), after T4e, V3, T5b5, T6a1 and C1 (Equatable's `==`).
