# T6a, propositions in analyze: how it is built

The plan for Prop, indexed families (Even, Equal), Exists and False in analyze, the only typer once unify-typers
lands (user 2026-11-27). Every law that needs one of these is red until
analyze reads it. The order below is by how many of those laws each piece turns green, with
the dependencies first. Counts are statements of data/unify/laws.md (main ccf63462 plus the unify-laws rewrites),
not measured reds: one statement may back several checks, and a check may hold several statements. Line counts are
estimates, `grep -vc '^\s*#'`.

## What the unification gives, and what it takes

Analyze is the only reader of a law. What T6a builds on:

- **The law as a function.** Analyze types each wap law as a bool function of its binders
  (extensions/law_statements.wap: `law positive(x: int): x > 0` is `law_positive(x: int): bool := x > 0`). Its
  proposition is `Π binders, Equal(bool, body, yes)` (extensions/verify/laws.wap `law_statement`). Without binders the verdict
  is the kernel's by computing. With binders it is the provers', the proof declared as a kernel theorem
  (`law_proved`). Where neither proves it, the run's verdict stands (native/driver.wap `verdict_beside`).
- **One environment.** The verify door works in TYPES.environment, and core's own words sit in a scope of their
  own below every other (kernel/environment.wap `core`).
- **Numbers.** A numeral is int, `int.natural(k)` or `int.negative(k)` (Lean's shape, card int-takes), of core's int over its hidden
  count (int_declared). An operator is a host row whose Defined value is int's function there, and the provers work over int only
  (notes/unify-provers.md). On int, `n + 0` is no longer `n` by computing for an open n, as `add(n, 0)` was on nat.
  A step that leaned on that now needs a prover.
- **Refusals said per law.** A law analyze refuses says why and keeps its run's verdict (extensions/verify/laws.wap).

What no longer exists:

- A reading of a law with a proof, of a theorem and of an indexed enum other than analyze's. Each statement that
  needs one is red until its T6a step; no step deletes from extensions/theory.
- The prelude's words (logic.wap, numbers.wap, operators.wap) are gone. The words T6a1 needs before any family exists —
  `Equal`, `Equal.refl`, `equal_symmetric`, `equal_transitive`, `equal_congruent`, `chosen_decided`,
  `chosen_at_yes` — need a home. Recommended: core_environment declares Equal and refl as
  kernel terms, as it already declares the Choice (kernel +about 20). The glue laws move to wap/types once a law
  with a proof is typed (T6a1). The family form follows in T6a3. The open question below asks who owns this.
- Test programs that still call the prelude's functions by name (`equals`, `multiply`, `subtract`, `at_most`,
  `add`, a `nat` operator of their own) lose them. They read in wap spelling, `n == 0`, `n * fact(n - 1)`: test
  edits beyond the granted 40, so wap-interviewer first.

## The pieces

### Proofs of bool laws (the most laws)

- `law name(binders): statement := proof` and `theorem` are declarations analyze types: the statement a bool
  expression, its proposition `Equal(bool, statement, yes)` over the binders (a Pi), Prop being `Sort(0)`, one
  constant beside DATA_TERM (type_notation.wap `PROP_TERM`). The proof is read against that type:
  - `refl` is `Equal.refl(bool, yes)`: the kernel computes the law's function to yes;
  - `assume` declares the statement as an axiom, reported Assumed;
  - `by a, b` and `by(a, b)` hand the goal to the provers with those laws;
  - `chain` steps, each by its law (wiki/proof.md);
  - a call of a proved law, `add_zero_right(m + 0)`, is that law's constant applied: a law is a function (wiki/proof.md
    "A law proved before is used by calling it"). Where its type is not the statement by computing (on int, `m + 0`
    is no longer `m` for an open m), the instance goes to the provers as a fact, as `by` hands them laws. This is one
    rule for both: a proof the kernel does not accept as it is becomes the provers' goal with what it names.
- The kernel's verdict: the declaration accepted is Proved; refused, the kernel's rule (`refused by value type`).
- `type of double_three` and `type of add_commutes(1, 2)` print the statement (`1 + 2 == 2 + 1`): a law's type shown
  as a bool statement where it is one (test_proof_wanted:19).

#### The 19 statements T6a1 holds, on the unified typer

Rules: **C**, computing (the kernel computes the law's function to yes; int literals fold through the rows'
`row_step`); **P**, the provers over int (notes/unify-provers.md: case split on int's recursor, linear, the bool
equality branch by `equal_integers_itself`); **R**, rewriting by named int laws through the bool route
(`equal_integers_sound` to an int equation, then `equal_integers_itself`); **H**, a law's call as a fact for the
provers (above).

| statement | rule | what else it needs |
|---|---|---|
| elaborate 121 `nine: 3 * 4 - 3 == 9 := refl` | C | nothing: green with T6a1 |
| second 21, 36 `four: 2 + 2 == 4 := refl` | C | nothing; they stand or fall with extensions/theory/second, which is the second checker under test |
| elaborate 96 `divided: 7 ÷ 2 == 3 := refl` | C | a division by a literal other than 0 brings no Fail (core/analyze/effects.wap: the divisor's value read), else the law's function is not pure and enters only as an axiom |
| second 23 `divided: 1000001 % (1000 ÷ 7) == 37 := refl` | C | the same Fail rule; second as above |
| elaborate 150 `counted: #[1, 2, 3] == 3 := refl` | C | a list literal and `#` as terms (T5c2) |
| elaborate 165 `b: "abc"#2 == "b" := refl` | C | a text's letter as a term: a text is a list of letters in wap/types (T5c2) |
| measures 11 `r: fact(4) == 24 := refl`, 12 `r: fib(10) == 55 := refl` | C | the recursion as a definition: on int `fact(n - 1)` is guarded by `n == 0` over `int where it >= 0`, no structural recursion (T5c4); the program in wap spelling (`n == 0`, `n * fact(n - 1)`) |
| statements 20, 21 `sum_to(3) == 6`, `sum_to(0) == 0`; 25 `sum_before(5, 3) == 3`; 26 `sum_skipping(4, 2) == 8`, each `:= refl` | C | a range walk as the recursor over its rounds (T5d, parked), the program in wap spelling |
| subtypes 38 `one_is: (1 is one_only) == yes`, `two_is_not: (2 is one_only) == no`, each `:= refl` | C | `is` against a subtype as the term of its condition at the value (TYPES.conditions); the declaration in wap spelling, `type one_only = int where it == 1` |
| verify 31 `twice_zero(m: nat): m + 0 + 0 == m := add_zero_right(m + 0)` | H, P | add_zero_right (verify 30) proved by P; the call's type `m + 0 + 0 == m + 0` is a fact, the provers finish |
| verify 36 `turned(a: nat, b: nat): a + b == b + a := by add_commutative` | R | wap/types' int law named `add_commutative`, the test's word |
| verify 37 `swap(a: nat, b: nat): a + b + 0 == b + a := by add_zero, add_commutative`, 40 the same `by(…)` | R | int laws `add_zero` and `add_commutative`; `by(…)` is a call of `by`, one form |

Green with T6a1 alone: 3 (nine, four twice). With the Fail rule: 5. With the provers over int: 9. The other 10 wait
for T5c2 (2), T5c4 (2), T5d (4) and a subtype's `is` as a term (2). A binder `n: nat` is `int where it >= 0`; its
condition is a hypothesis these laws never need.

### Hypotheses and the connectives

- A binder whose type is a bool statement, `h: a <= b`, is a proof of `Equal(bool, a <= b, yes)`: the law's
  proposition is a Pi over it. In the law run it takes no trial value; a trial where it computes to no is skipped.
- `A implies B` on bools is a row of types/operators.wap, `not A or B` as a bool; as a proposition it is `A -> B`
  (logic.wap's `->`). A law `x > 0 and y > 0 implies x * y > 0` is a bool law;
  one with hypothesis binders is its curried form, and the two are one proposition by `chosen_decided`.
- `not`, `and`, `or` of bool statements stay bool. Of propositions (a binder of type Prop, an indexed family's
  value), they are Not, And, Or, chosen by the operands' sort through the operator table, one row each with the
  sort as its parameter type (no rule, no core branch).

### Indexed families

- An enum whose header is a function type ending in a sort, `enum Even: nat -> Prop { zero: Even(0), step(e:
  Even(n)): Even(n + 2) }`: its indices the header's arguments, each case's result type written per case (the case
  shape of T5b2's block, with indices), a letter of a case (`n`) a field found before the written ones. Mutual families (`Even`, `Odd`)
  are one block, as T5b2 groups enums.
- A constructor's call is typed by unifying its result with the type wanted: `Even.step(Even.step(Even.zero))` is
  `Even(0 + 2 + 2)`, computed `Even(4)`; `Even.zero` where `Even(double(n))` is wanted is the kernel's refusal by
  value type, naming both (wiki/proof.md).
- `Equal` is such a family, `enum Equal(a: T): T -> Prop { refl: Equal(a, a) }`, so `==` of two values in a
  proposition's place is Equal, and a bool statement is the Equal of its value with yes: one family, one conversion.

### How wap source states a proposition (T6a3a, before the families)

The spelling of a proposition needs no family. Core's Equal (kernel/equality.wap, declared by core_environment) is
enough. It is therefore its own step, split from the families, and small.

**What the wiki already shows.**
- wiki/proposition.md: `type of (2 + 2 == 4)` is `Prop`, and `a == b` is the proposition that a and b are equal.
  Its table gives `A and B`, `A or B`, `A implies B`, `not A`, `for x: T` and `exists`.
- wiki/proof.md: `theorem name(parameters): statement := proof`, with `refl`, `by`, `chain`, `assume`, and a law's
  call as a proof (`add_commutes(a, b)` proves `a + b == b + a`).
- wiki/law.md: `law x > 0 and y > 0 implies x * y > 0`.
- wiki/proposition.md "Conditions": the same `#line == 1` in an `if` is a bool, decided.

So `==` reads by its place. A hypothesis parameter, `law widened(a: nat, b: nat, h: a <= b): a <= b + 1`, is in
test_theory_arithmetic 12–15 but on no wiki page. It is the named form of `implies` (a function from proofs). A wiki
passage for it goes to the interviewer (old text: none; new: "a parameter whose type is a statement is a
hypothesis: `h: a <= b` is a proof of `a <= b` the law may use").

**The mechanism: one reading of a proposition's place.** A proposition's place is:
- a theorem's or law's statement;
- a parameter's type that types as a bool value rather than a type;
- each side of `implies` there.

In such a place analyze writes the kernel proposition by one function, `proposition_of(n)`:

| written in a proposition's place | kernel proposition |
|---|---|
| `l == r`, l's type T having a bridge in the environment | `Equal(T, l, r)`, at T's sort |
| `P implies Q` | `Π _: proposition_of(P), proposition_of(Q)` |
| any other bool `b` (`x < y`, `l == r` of a T with no bridge, `p(x)`) | `Equal(bool, b, yes)`, today's `truth_stated` |

The operands themselves stay in value places, so `(a == b) == yes` is `Equal(bool, eq(a, b), yes)`. That is the
bridge's own spelling, needing no new word.
- **Why the guard is a bridge.** wiki/equality.md says `==` is equality for enums, classes, lists, texts and whole
  numbers, but not for floats (`y == y` is no at NaN), nor for a class with its own `==`. `Equal(float, y, y)` would
  be proved by refl while the run fails at NaN: a plausible wrong verdict. A type's bridge (`equals_sound`,
  `equals_complete` for it) is the proof that its `==` decides Equal. Where it exists the two readings are one
  proposition, so the reading is a choice of form, never a guess. Today int has one (int_declared,
  notes/unify-provers.md "The bridge"). bool has none: its `==` is a host row no function defines, so a bridge for
  it needs bool's equality function, its two theorems and a row meaning for bools (core/analyze/terms.wap gives one
  only to ints), about +15 where `b == yes` already states the same; it waits for a law that needs it. An
  enum's derived `==` gets one when its `==` is derived (a later step, per type, never by hand).
- **No special case.** `==` is not singled out in core by name: its row's Defined value is the type's equality
  function, and the bridge is found as `e.integers.equals_sound` is, by the row's type. The `implies` row already
  exists (types/operators.wap). `and`, `or` and `not` of propositions stay T6a2's sort-chosen rows.
- **law_statement uses it.** `law_statement` (extensions/verify/laws.wap) builds `Π binders, proposition_of(body)`
  in place of `truth_stated(body)`. The law's bool function stays what the run computes, and the bridge joins the
  two. The subtype hypotheses (2af0a649) are bools in a proposition's place and stay `Equal(bool, c(x), yes)`.

**Core lines.**
- analyze: `proposition_of` with its three arms, about +12.
- the parameter's type in a proposition's place, read as a hypothesis binder: T6a2's +25, shared, not counted again.
- bool's bridge beside its block, about +6 (type_notation.wap).
- law_statement's switch, ±0.
- Kernel 0. Total about +18 over T6a1 and T6a2. coc-t6a's T6a3 row had "Equal's place +10" for the same reading
  without the guard.

**The draft, read against unify-typers 2af0a649.** Reading the code makes the step smaller than the mechanism
above says, in two ways:
- **It reads the statement's term, not its node.** law_statement gets the law function's kernel value, and
  `beta(value, frees)` gives the body as a term (verify/laws.wap:85–90). In that term `a == b` is the row constant
  `prim i64.eq int -> int -> bool` applied to a and b, and the row is Defined as int's equality function. So
  proposition_of works on terms, beside `equated` in kernel/equality.wap. Analyze needs no branch. A T6a1 theorem's
  statement reaches it through `term_of`, the same way.
- **There is no `implies` arm.** `implies` lowers to an `if`, so its term is bool's case split. Recognising it would
  mean matching a lowering's shape. The bool reading `Equal(bool, a implies b, yes)` is the same proposition as
  `Π _: a == yes, b == yes` by bool's cases, and the provers already read it (`both_*`, the choice reading). The named
  form, an `h:` parameter, is T6a2's hypothesis binder. The table's middle row is dropped.

```
# a type whose == decides Equal: its equality function and the two theorems joining them (int_declared, bool's block)
class Bridge { type: Term; equality: Term; sound: Term; complete: Term }
# what a statement says: `l == r` of a type with a bridge is Equal at that type, any other truth is `b == yes`
proposition_of(e: Environment, statement: Term): Term := {
	bridge = bridge_of(e, head(statement)) ?? return truth_stated(e, statement)
	sides = arguments_of(statement)
	equated(e, DATA_LEVEL, bridge.type, sides#1, sides#2)
}
# the bridge whose equality a head is: the function itself, or a row Defined as it
bridge_of(e: Environment, head: Term): Bridge? := e.bridges.find(bridge => same(head, bridge.equality) or same(defined_value(e, head) ?? head, bridge.equality))
```

- `e.bridges: list<Bridge>` sits beside `e.literals`. int_declared adds int's, and `Integers` holds its bridge in
  place of its own equal_integers, equals_sound and equals_complete fields (notes/unify-provers.md "What replaces
  e.numbers"), so the three are named once; e.bridges holds it, the one place it is kept.
- truth_stated moves from verify/laws.wap to kernel/equality.wap beside `equated`. Every place that states a
  statement calls proposition_of: law_statement's body, `hypothesized` and T6a2's hypothesis binders. A subtype's
  condition (`it >= 0`) has no bridged head, so it comes out as today.
- A bridged type sits at Type, so its Equal is at DATA_LEVEL, the level truth_stated uses (TRUTH_LEVEL there, the same
  `Successor(Zero)`: one constant, not two).
- **A refusal shows wap's spelling.** A refused proof shows the statement it proves (wiki/proof.md), so T6a1, which
  checks a law's proof, shows Equal at a bridged type as `l == r`: a `shown` case for Equal whose type has a bridge.
  Until T6a1 a law with a proof gets nothing (`law($head := $proof) => ()`), so no refusal reaches the output yet.
- **Lines.**
  - kernel/equality.wap: Bridge, proposition_of, bridge_of and truth_stated moved in, about +7.
  - environment.wap: the field, +1.
  - int_declared: Integers' three fields become one, −2.
  - verify/laws.wap: truth_stated out, −1, and two calls switched, ±0.
  - Net about +11, all kernel, none in analyze. The +18 above becomes +11.
- **What it needs before it can be built.** `e.integers` and int's bridge (M2b step 1) and bool's block (t5b-enums). On
  unify-typers today neither exists, so the code cannot be drafted there until M2b step 1 lands. Before that, the sketch
  above is the draft.
- **Its outcome test.** `law sum_commutes(a: int, b: int): a + b == b + a` stays Proved through linear's own
  equal_proof with M2b step 5 never built (test_theory_connectives' `==` laws). `law nan_free(y: float): y == y`
  keeps its run's FAILED at NaN and is never Proved.

**What moves to wap afterwards, and what cannot.**

| hand-declared today (or in M2b's plan) | after T6a3a |
|---|---|
| linear.wap's `law_equal` (equals_sound on each int law's conclusion) | goes: integers.wap's `==` laws conclude `Equal(int, l, r)` themselves |
| M2b step 5 (bool `==` goals by equals_complete, linear.wap +6) | not built: an `==` goal is `Equal(int, l, r)`, linear's own equal_proof |
| integers.wap's 7 laws with hypotheses (add_cancel, difference_nonnegative, …) | spelled in wap with `h:` parameters or `implies`, e.g. `law add_cancel(a: int, b: int, c: int, h: a + c == b + c): a == b`, in place of hand-built Π terms |
| `equals_sound`, `equals_complete` for int | statements writable (`theorem equals_sound(a: int, b: int, h: (a == b) == yes): a == b`), but their proofs go through the hidden count (count_equals_sound, difference_equal, parts_back). They stay int_declared's |
| `successor_sum`, `predecessor_sum`, the two step theorems | the same: the statements are writable, the proofs need count's cases, so they stay core's. integers.wap's `next_previous` and `previous_next` are wap laws already, proved by `by` with them |
| kernel/equality.wap's `equal_symmetric`, `equal_transitive`, `equal_congruent` | writable once a theorem may take a type parameter and match on `h` (T6a4's dependent motive). They move then, not in T6a3a |
| count_declared's 31 theorems | never: the count has no wap name |

So the gain is the laws' side: the int laws, the hypotheses and every program's own `theorem … : a == b` read
directly as Equal. The bridge and the count lemmas stay core's, because their proofs reach below int.

**Order relative to M2b.**
- **Needs:** M2b step 1 (int_declared's bridge) and T6a1's theorem declarations. The hypothesis binder is T6a2's.
- **M2b step 3** (Sums over int) is independent. Build it in parallel.
- **M2b step 4** (bounds, the role table) as planned. If T6a3a lands first, step 4 builds no `law_equal`. Otherwise
  step 4 builds it (3 lines) and T6a3a removes it.
- **M2b step 5 is dropped.** Its gate, test_theory_connectives' `==` laws, moves to T6a3a.
- Recommended order: M2b 1 → 3 → 4 → T6a1 → T6a2 → T6a3a, then the families (T6a3b). T6a3a is the last step to
  touch linear.wap.

### Proofs by cases and induction

- A match whose type depends on the value matched (the theorem `double_even(n: nat): Even(double(n)) := match n {
  zero => Even.zero; successor(k) => Even.step(double_even(k)) }`) has the motive `n => Even(double(n))`: the type
  wanted with the subject made a binder (`motive_made`, coc-t5b.md's third part).
- A call of the theorem itself on a field is its induction hypothesis: T5c3's structural recursion through the course,
  the same code (coc-t5c.md), with a dependent motive.
- A match that misses a case is refused by `covering` (analyze's own refusal, matching.wap).
- `zero` and `successor(k)` on a nat are its shapes (`it == 0`; `it > 0`, `k = it - 1`, coc-t5b.md's T6 table): the
  induction runs through nat's refinement of int, so this piece needs int's case split with induction on the carrier's nat under it (notes/unify-provers.md step 5) for a nat
  subject, and works at once for a family over a program's own enum.

### False, Exists and effects

- `False` is the empty enum of Prop, `enum False: Prop {}`; a law stating it needs a proof, and a proof by `raise` or
  by a function that may not end is refused by `effect` (T5b1's Fail and Div facts: a proof uses pure, total code
  only, coc-plan.md 9.6).
- `exists n: nat where p` is `Exists(nat, n => p)`, its proof a witness and the proof that it holds; the law run
  tries values until one holds.
- `if` on a proposition nothing decides is refused by `undecidable condition` (test_proposition_wanted:8,
  test_theory_elaborate:75): a choice needs a bool or a `Decidable`.

### Types and propositions as values

- `Equal(Type, int or bool or int, bool or int)` is `(int or bool or int) == (bool or int)` at Type: analyze types a
  type in a value's place (T3's deferred "types as values"), and the kernel compares the two union terms, which T5u
  keeps flat and without repeats.
- `law anything(a: Prop): a := …` takes a proposition as a binder: a binder of type Prop, its uses propositions.

## The migration in landable sub-steps

All are track T steps (coc-plan.md 14: measured, no limits), on the careful path: each changes what the kernel holds
for laws. The counts are the inventory's statements each step turns green, the unify-laws rewrites included. No step deletes from extensions/theory; the
last column says what the unification already gives.

| step | what | core / kernel / types lines (estimate) | turns green (statements) | given by the unification |
|---|---|---|---|---|
| T6a1 proofs of bool laws | `law … := proof` and `theorem` typed by analyze: Prop, the statement's proposition, `refl`, `assume`, `by`, `chain`, a law's call (a fact for the provers where its type is not the statement); the glue laws (`equal_symmetric`, `equal_transitive`, `equal_congruent`, `chosen_decided`, `chosen_at_yes`) in wap/types; `type of` a law shows its statement | core +80 (analyze/laws.wap: the declaration +35, the proofs +35, PROP_TERM and the shown statement +10), kernel +20 (Equal and refl are declared in core beside int; the glue laws are in kernel/equality.wap), types +20 (the glue laws) | the 19 of the table above: 3 at once, 5 with the Fail rule, 9 with the provers over int; hard and uses_hard's `assume` lines once T6a3 has Even | the statement as `Π binders, Equal(bool, body, yes)` (`law_statement`), the provers' call and the theorem's declaration (`law_proved`), the per-law refusal, the run's verdict where none proves it: about 30 of the 90 lines planned here |
| T6a2 hypotheses and connectives | bool-statement binders as hypotheses; `not`/`and`/`or` of propositions by the operands' sort | core +40 (hypothesis binders +25, the law run's skip +5, the sort-chosen rows +10), types +3 (Not, And, Or rows) | 13: connectives 16 implied, 20 smaller, 21 no_is_no_yes, 22, 23; connectives_wanted positive_product; induction 12 positive_product; arithmetic 12 to 16 (five laws with `h:`); verify 32 same_as_given. The arithmetic five with the provers over int | `implies` is a row already (types/operators.wap); hypothesis binders are not M2b's, so they are this step's whole |
| T6a3a propositions in wap spelling | `proposition_of`: `==` of a type with a bridge is `Equal(T, l, r)`, `implies` a Π, any other bool `b == yes`; law_statement through it; bool's bridge (section "How wap source states a proposition") | core +18 | test_theory_connectives' `==` laws (M2b step 5's gate); every `theorem … : a == b` reads as Equal | Equal in core_environment, int's bridge in int_declared, T6a2's hypothesis binders |
| T6a3 indexed families | enums over indices with a result per case, letters found as fields, mutual families one block; constructor calls typed by unifying their result; Equal as a family, replacing T6a1's core declaration (`==`'s place is T6a3a's) | core +100 (header and cases with indices +50, found fields +20, constructor typing +30), kernel −20 (T6a1's Equal declaration) | 9: proposition_wanted 15 four_is_even, wap proposition_wanted 10 and 12 (two, mutual), proof_wanted wrong, verify 13 hard, 17 uses_hard, 20 wrong, 26 any_even (Untested), connectives 18, 19 (And, Or as families) | int as an enum over nat in wap/types is the first two-case block analyze declares for the kernel; the found fields are written in analyze |
| T6a4 proofs by cases and induction (plan: notes/coc-t6a4.md, core about +92 with the types module's nat) | a dependent motive; the theorem's own call on a field its hypothesis; a proof match missing a case refused by covering | core +60 (`motive_made` +35, the course with a dependent motive +25, after T5c3) | 7: double_even (test_proof_wanted 8, wap proof_wanted 7, elaborate 50 and 87, verify 12), wap proof_wanted 13 partial, verify 34 multiply_one_left | a nat subject is int's case split with the carrier's induction under it (the provers' step 5), so no nat induction theorem waits |
| T6a5 False, Exists, undecidable | `False`; a proof's effects checked pure and total; `exists … where`; `if` on an undecided proposition refused | core +35 (False +8, the effect check +12, Exists +15), types +2 | 5: wap proof_wanted 14 and 15 (loop, raise), effects 15 and 16 (spin, loop), proposition_wanted 8 some_sum; plus the two undecidable-condition checks | the effects are facts on each typed function (T5b1, t5b-effects): the check reads EFFECTS and refuses Fail and Div in a proof |
| T6a6 propositions as values, the logic in wap/types | a type in a value's place compared at Type; Prop binders; False, True, And, Or, Not, Exists, Decidable and the axiom proposition_extensionality in types/logic.wap | core +30 (types as values +20, Prop binders +10), types +35 (the rest of the logic in wap spelling) | 4: elaborate 107, 108, 153 (unions at Type); logic 18 anything; and logic's own checks (10 to 17) read on wap/types | the prelude is gone already (the deletion commit); the glue laws moved in T6a1, Equal in T6a3 |

Order: T6a1 first (it holds most of the laws, and every later step reads a law's declaration through it), then T6a2,
T6a3, then T6a4 after T5c3, T6a5 after T5b1, T6a6 last. T6a1 needs the int enum; T6a1's
nine prover statements need M2b (notes/unify-provers.md); T6a3 needs T5b2's blocks.

## The estimate

T6a as a whole: core about +355 (+80, +40, +110, +60, +35, +30), kernel 0 net (+20 in T6a1, −20 in T6a3), types
about +60. Against
coc-plan.md's T6 budget (500 analyze, 150 types for laws, effects, instances and tested): T6a takes the logic's
share; instances and protocols (traits) stay T6's.

## Gate

T6a is done when:
- the statements in the table's "turns green" column are green, except those it names as waiting for T5c2, T5c4 or
  T5d;
- the logic's words are declared once, in types/logic.wap, Equal as a family;
- the whole suite has no new red, `--stage 2` is a fixed point; the self-compile and memory are measured and reported.

## Open for the supervisor

- **Test programs in the prelude's spelling:** measures' FACT and FIB, statements' SUM_TO, SUM_BEFORE and SUM_SKIPPING
  (with their `operator +(a: nat, b: nat)`), and subtypes' ONE_ONLY call prelude functions or write a proposition
  where wap writes a bool. Recommended: rewrite them in wap spelling, beside the 40 granted rewrites, through
  wap-interviewer (an existing test's program changes, its outcome does not).
- **The int laws' names:** verify 36, 37 and 40 name `add_commutative` and `add_zero`. Recommended: wap/types names
  int's laws by the words the tests and wiki/proof.md use (`add_zero`, `add_commutative`, `add_associative`), not
  `sum_*`; notes/unify-provers.md's table follows.
- **test_theory_second:** its laws check the second checker (extensions/theory/second).

## T6a3, T6a5 and T6a6 re-read on unify-typers 2b0e87be

- **T6a3 indexed families.**
  - analyze/inductives.wap (T5b2) declares an enum's block with no indices: every case's result is the enum
    itself. T6a3's header and cases with indices (+50), the found fields (+20) and constructor typing by unifying
    their result (+30) are all still to do.
  - Two parts of the row are gone:
    - "int as an enum over nat in wap/types": core declares int on unify-typers, in Lean's shape on int-takes.
    - "Equal as a family, replacing T6a1's core declaration (kernel −20)": Equal is kernel/equality.wap's, beside
      refl and its laws, and a program's family would be a second Equal. Equal stays the kernel's.
  - Estimate: core +100, kernel 0.
- **T6a5 False, Exists, undecidable.**
  - kernel/logic.wap has `·False`, `·True`, `·True.intro` and `·false_elim`, marked as the kernel's. `False` for
    programs is the types word naming it (T6a6's types/logic.wap), so it costs +2 here, not +8.
  - The effect check reads T5b1's EFFECTS fact (+12).
  - Exists is a family with one case (+15, on T6a3's indices).
  - Estimate: core about +29, types +2. Lands after T5b1 and T6a3.
- **T6a6 the logic in wap/types.** The prelude is gone, and the kernel's logic is internal (`·`).
  - types/logic.wap declares False and True (the kernel's), And, Or, Not, Exists (T6a5), Decidable, and the axiom
    proposition_extensionality.
  - A comparison is a proposition where a type is wanted, and is decided to a bool where a bool is wanted
    (proposition.md:55): T6a3a's `proposition_of`, read the other way at `type of`.
  - T6a2's Not, And and Or rows over propositions land here (coc-t6a12.md).
  - Estimate: core +30 (types as values +20, Prop binders +10), types +38 (+35, and T6a2's +3).
