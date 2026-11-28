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
   - The relation is a proposition: the kernel's quotient takes `r: T → T → Prop`. `same` may be a bool function,
     read as `same(a, b) == yes`, or a proposition, as function_extensionality's pointwise
     `(p, q) => for a: A, p(a) == q(a)` must be (a function's values need no decidable `==`). quotient_sound takes
     either. `==` of a quotient (2) exists only for a bool relation.
   - `sign(x: int)` lives once, here, and lib/math.wap keeps only its float overload. The lemma the provers use for
     the wiki's `sign` lift is in the obligation's shape, applied by instantiation:
     `sign_respects(a, b, c, d: int) where b != 0 and d != 0: a * d == c * b implies sign(a * b) == sign(c * d)`, proved
     by int's cases. Rewriting with `sign(x * y) == sign(x) * sign(y)` alone leaves a product of sign atoms, which is
     beyond the linear provers.

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

## Re-read on 5285eb86: what stands of q1-library, the functions, the cost

**What 5285eb86 holds.**
- kernel/quotients.wap declares `quotient`, `quotient.of`, `quotient.lift` and `quotient.induct` (:28-60), with the
  relation `r: (a: T) -> (b: T) -> Prop` and lift's `respects` premise. That is unchanged since unify.
- No type reading of a value argument: type_term (type_notation.wap:386) raises "… is no type" on `quotient(fraction,
  same_value)`, as it does on T6a4's `Even(double(n))` (notes/coc-t6a4.md "The substitutions").
- T4e is still planned, not landed. Its "applied-alias reading", T6a3's indices and T6a4's dependent results are one
  reader, a value inside a type read by `term_of` under `typed.reading`, so Q1's part 1 is that reader's third user, not
  a mechanism of its own.
- **A name clash:** types/floats.wap:12 declares `quotient(a: int, b: int): int`, the truncated division, and
  prelude.wap:63's `÷` calls it.
  - Its own DEBT note (:8-10) says the name is to stay hidden for warp's exact division, but programs see it, and
    `quotient(T, same)` is the kernel's type former of the same name.
  - Before Q1: rename it `truncated_quotient`, beside its sibling `truncated_remainder`. It is a types-only rename with
    four callers in floats.wap and one in prelude.wap, no form, net 0, so a standing OK small fix.

**What of origin/q1-library f6cbee70 stands** (one file, types/quotients.wap, +34, on unify-typers 323ba86a, not
included by types.wap):
- **Stands:** `fraction` (with `bottom: int where it != 0`), `same_value`, `type rational = quotient(fraction,
  same_value)`, `same_items` and `type set<T>`. These are plain wap, written as the wiki writes them.
- **Stands:** `axiom quotient_sound(a: T, b: T, same: (T, T) -> Prop, h: same(a, b)): (quotient.of(a) as quotient(T,
  same)) == quotient.of(b)`. It uses the program spelling `axiom …` that unify-axioms' rule reads, and its `as` gives
  `of` its expected type (part 3).
- **Stands:** function_extensionality as a `chain` theorem (wiki/proof.md:56). Its relation, `(p, q) => for a: A, p(a) ==
  q(a)`, is a proposition, as the plan says it must be.
- **Goes when the file is included:** the second `sign(x: int)`. lib/math.wap:134 still has it, and the commit keeps both
  until the include. Whoever adds the include deletes math.wap's line in the same commit, so it is never written
  twice.
- **Doubtful:** `law sign_product` and `law sign_respects` have no written proof.
  - Under V3's part 5 a law that is only Tested proves nothing, so the `sign` lift's respect obligation would be
    refused.
  - sign_respects (`a * d == c * b` implies `sign(a * b) == sign(c * d)`) is nonlinear, beyond the provers.
  - It needs a proof by cases on the signs (T6a4), over `positive_product`, the helper law.md:36-44 proves (`x > 0 and y >
    0 implies x * y > 0`).
  - So the decided A stands, with this order: positive_product first, then sign_product by sign's cases, then
    sign_respects from sign_product. Each is Proved or written with `by`. The builder checks each verdict with `wap
    verify` before the lift line is expected green.
  - sign_product is not dead: it is sign_respects' lemma.

**The parts as functions.**
1. **The type:** T4e's reader in type_term: a Call whose head is a kernel type former with value parameters (here
   `quotient`, whose declaration says `(T: Sort u) -> (r: …) -> Sort u`) reads its value arguments by
   `term_of(argument, reading)`.
   - A bool relation is read as a proposition by T6a6's `Prop(b: bool)` conversion, adapted over the function value
     (fits.wap:108, Adapted). So `same_value` needs no `== yes` wrapper written.
   - The term is `apply_all(constant_of(e, QUOTIENT, [level]), [T, r])`.
   - The up conversion, a T where the quotient is wanted, is `quotient.of`: a Read conversion found as a function named
     as the type (reads_as), `of(a: T): quotient(T, same)`. Never down.
   - core +8 on top of T4e's reader (the former's value parameters, the bool relation's adaptation, the up direction).
2. **`==`:** types/quotients.wap's `==(a: quotient(T, same), b: quotient(T, same)): bool := same(a, b)`. It holds only
   for a bool `same`; a Prop relation has no `==`, and its call is refused as no overload. types +1.
3. **`of` from the expected type:** a letter found from the type wanted, beside letters_bound's from the arguments
   (letters.wap:131: `denoted` already passes types in). It is the expected type's parts unified with the result's.
   core +5.
4. **`lift` and its obligation:**
   - The call `q.lift(f)` builds the respect statement as V3 builds an obligation's: a law of the enclosing function,
     `law_statement(e, …, value, [])` with value `lambdas([a, b, joined], Equal(R, f(a), f(b)))`, through
     `typed.reading`. proof_found proves it with laws_of.
   - An unproved one is refused with the statement shown. It cannot be checked at run time.
   - A program calling lift loads the prove extension (T7's rule for proofs).
   - core +10, prove 0 (V3's door does the proving).
5. **Kernel terms:** `of` and `lift` calls enter as QUOTIENT_OF and QUOTIENT_LIFT through called_term's lookup (T5b5)
   with the found relation as an argument. So `law lift_of … := refl` computes by compute.wap's quotient rule.
   core +6.
6. **The library:** q1-library's file as above, plus `==` (2), the include in types.wap, and math.wap's `sign(x: int)`
   deleted. types +3 over the branch.

**Cost.** core +29 (+8, +5, +10, +6), on top of T4e's reader, which T6a3 and T6a4 share; types about +37 (the
branch's 34 and 3); prove 0; kernel 0. That is against the old estimate of core +37 and prove +5, because V3's
obligation-as-law does part 4's proving.

**Order.** The `truncated_quotient` rename (any time). Then T4e's reader (with T6a3/T6a4), V3 (part 4), T6a6 (`Prop(b)`
and the logic for the theory lines), C1a (Equatable's `==` reaches the quotient's), and T6a4 (the sign lemmas by
cases). Careful path: a new type's conversions.

**Green.** The table above, unchanged. The `sign` lift lines (test_quotient_wanted:10-11) hold only once the three sign
laws are Proved.

## Lift read on q1 (3b58de53 library, c389ee1c M1, dacfb13a M2)

**The shape.** `lift(q: quotient(T, S), f: (T) -> R, respected: respects(f, S) = by): R := f(prim as_is(q))` is
Lean's `Quot.lift f h q` with the respect proof a hypothesis parameter the provers fill.
- The kernel's `quotient.lift(T, r, B, f, respects, q)` (kernel/quotients.wap:65) takes `respects: Π a b (joined: r a
  b), Equal(B, f a, f b)`. `respects(f, S)`'s for-lines read `same(a, b) implies f(a) == f(b)` as exactly that, once
  `r` is the bool relation's adaptation `(a, b) => S(a, b) == yes`, the one `quotient(T, S)` itself is read with.
  The quotient type, quotient_sound and lift share that one adaptation.
- The body `f(prim as_is(q))` is the run's only. In the kernel, a call of lift is `quotient.lift` with the found
  relation (part 5 above), never lift's body. `as_is` is not a folded row (terms.wap row_term), so the body has no
  kernel value: lift alone would be an axiom, consistent because quotient.lift inhabits it, but `lift_of := refl`
  computes only through part 5.
- `as_is` never gets a kernel meaning. With `as_is(of(a)) ≡ a`, quotient_sound gives `a == b` for any joined a and b:
  `fraction(1, 2) == fraction(2, 4)`, then False.

**M1, a value letter.** S of `quotient(T, S)` is a letter as T is, bound from the argument's type at the former's
value place. Sound: the letter is the relation the argument's type holds, so lift reads the quotient's own relation and
no other.

**M2, a hypothesis's `by` default.** Each argument is read against `next_domain(after_arguments(callee, given))`, the
callee's Π instantiated with the arguments before it, which is the kernel's application rule (B[a/x]). The proof found
for that domain is checked with the whole term, so a wrong one is refused by the kernel. Two places change under the
obligation ruling (coc-plan.md "A call's proof hole"):
- proof_given refuses every hole in a compile without provers. A decidable goal (`nonzero: b != 0 = by`) is an
  obligation and is checked when the program runs, as the subtype `b: int where it != 0` is. Only an undecidable one
  (respects, a for-line) is refused.
- M2b, a call never read into the kernel (the top level, an acting function), is recorded at typing as an
  obligation, so it is never left undecided.

## Hashing a constant by its id (wap-annotation-attachment-fix 71dee881)

kernel/terms.wap:110 hashes a constant by its id, what `same` compares (:308), so core's word and the kernel's key of
one id are one term. Its readers:
- hash_rank (integer_laws.wap:78, linear.wap:371) orders a sum's terms. Each reordering is proved by commutativity,
  so the order is free; it follows declaration order now.
- linear.wap:210 names a lemma by a type's hash, within one compile.
- union_type sorts its parts by type_text (type_notation.wap:288), not by hash, so nothing depends on a name's hash.
  The old comment at :109 ("orders by hash (a union's parts)") was stale.
- A prover's failure message that shows a sum may show its terms in another order.
