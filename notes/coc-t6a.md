# T6a, propositions in analyze: how it is built

The plan for Prop, indexed families (Even, Equal), Exists and False in analyze, the only typer once unify-typers
lands (user 2026-11-27). Every law that needs one of these is red from the deletion of the theory's reader until
analyze reads it. The order below is by how many of those laws each piece turns green, with
the dependencies first. Counts are statements of data/unify/laws.md (main ccf63462 plus the unify-laws rewrites),
not measured reds: one statement may back several checks, and a check may hold several statements. Line counts are
estimates, `grep -vc '^\s*#'`.

## What the unification gives, and what it takes

With the second typer gone, analyze is the only reader of a law. What T6a builds on:

- **The law as a function.** Analyze types each wap law as a bool function of its binders
  (extensions/law_statements.wap: `law positive(x: int): x > 0` is `law_positive(x: int): bool := x > 0`). Its
  proposition is `Π binders, Equal(bool, body, yes)` (typed_laws.wap `law_statement`). Without binders the verdict
  is the kernel's by computing. With binders it is the provers', the proof declared as a kernel theorem
  (`law_proved`). Where neither proves it, the run's verdict stands (native/driver.wap `verdict_beside`).
- **One environment.** The theory's door works in TYPES.environment, and core's own words sit in a scope of their
  own below every other (kernel/environment.wap `core`).
- **Numbers.** A numeral is int, `of_nat(k)` or `negative_successor(k)`, of `enum int` over nat in wap/types. An
  operator is a host row whose Defined value is int's function in wap/types, and the provers work over int only
  (notes/unify-provers.md). On int, `n + 0` is no longer `n` by computing for an open n, as `add(n, 0)` was on nat.
  A step that leaned on that now needs a prover.
- **Refusals said per law.** A law analyze refuses says why and keeps its run's verdict (typed_laws.wap).

What goes with the theory reader:

- The theory's reading of a law with a proof, of a theorem and of an indexed enum (declare.wap, blocks.wap,
  match.wap) goes in the deletion commit. Each statement that needed it is red until its T6a step. The column
  "deletes from extensions/theory" of the table below is therefore the deletion commit's, not T6a's. Where a step
  ports code (blocks.wap's found fields, match.wap's `motive_made`), read it from unify-typers 384b1e4e.
- The prelude (logic.wap, numbers.wap, operators.wap) goes too. The words T6a1 needs before any family exists —
  `Equal`, `Equal.refl`, `equal_symmetric`, `equal_transitive`, `equal_congruent`, `chosen_decided`,
  `chosen_at_yes` — need a home from that commit on. Recommended: core_environment declares Equal and refl as
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
| elaborate 165 `b: "abc"#2 == "b" := refl` | C | a text's letter as a term: the theory's texts statement goes with the prelude, so a text is a list of letters in wap/types (T5c2) |
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
  (logic.wap's `->`, the prelude's operators.wap `implies`). A law `x > 0 and y > 0 implies x * y > 0` is a bool law;
  one with hypothesis binders is its curried form, and the two are one proposition by `chosen_decided`.
- `not`, `and`, `or` of bool statements stay bool. Of propositions (a binder of type Prop, an indexed family's
  value), they are Not, And, Or, chosen by the operands' sort through the operator table, one row each with the
  sort as its parameter type (no rule, no core branch).

### Indexed families

- An enum whose header is a function type ending in a sort, `enum Even: nat -> Prop { zero: Even(0), step(e:
  Even(n)): Even(n + 2) }`: its indices the header's arguments, each case's result type written per case (the case
  shape of T5b2's block, with indices), a letter of a case (`n`) a field found before the written ones (as
  extensions/theory/elaborate/blocks.wap does: port it, the move decided for T5c). Mutual families (`Even`, `Odd`)
  are one block, as T5b2 groups enums.
- A constructor's call is typed by unifying its result with the type wanted: `Even.step(Even.step(Even.zero))` is
  `Even(0 + 2 + 2)`, computed `Even(4)`; `Even.zero` where `Even(double(n))` is wanted is the kernel's refusal by
  value type, naming both (wiki/proof.md).
- `Equal` is such a family, `enum Equal(a: T): T -> Prop { refl: Equal(a, a) }`, so `==` of two values in a
  proposition's place is Equal, and a bool statement is the Equal of its value with yes: one family, one conversion.

### Proofs by cases and induction

- A match whose type depends on the value matched (the theorem `double_even(n: nat): Even(double(n)) := match n {
  zero => Even.zero; successor(k) => Even.step(double_even(k)) }`) has the motive `n => Even(double(n))`: the type
  wanted with the subject made a binder (elaborate/match.wap `motive_made`, ported: its third part, coc-t5b.md).
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
for laws. The counts are the inventory's statements each step turns green, the unify-laws rewrites included. The
theory's code each step once replaced goes in the deletion commit, so no step deletes from extensions/theory; the
last column says what the unification already gives.

| step | what | core / kernel / types lines (estimate) | turns green (statements) | given by the unification |
|---|---|---|---|---|
| T6a1 proofs of bool laws | `law … := proof` and `theorem` typed by analyze: Prop, the statement's proposition, `refl`, `assume`, `by`, `chain`, a law's call (a fact for the provers where its type is not the statement); the glue laws (`equal_symmetric`, `equal_transitive`, `equal_congruent`, `chosen_decided`, `chosen_at_yes`) in wap/types; `type of` a law shows its statement | core +80 (analyze/laws.wap: the declaration +35, the proofs +35, PROP_TERM and the shown statement +10), kernel +20 (Equal and refl in core_environment, unless the deletion commit gives them a home), types +20 (the glue laws) | the 19 of the table above: 3 at once, 5 with the Fail rule, 9 with the provers over int; hard and uses_hard's `assume` lines once T6a3 has Even | the statement as `Π binders, Equal(bool, body, yes)` (`law_statement`), the provers' call and the theorem's declaration (`law_proved`), the per-law refusal, the run's verdict where none proves it: about 30 of the 90 lines planned here |
| T6a2 hypotheses and connectives | bool-statement binders as hypotheses; `not`/`and`/`or` of propositions by the operands' sort | core +40 (hypothesis binders +25, the law run's skip +5, the sort-chosen rows +10), types +3 (Not, And, Or rows) | 13: connectives 16 implied, 20 smaller, 21 no_is_no_yes, 22, 23; connectives_wanted positive_product; induction 12 positive_product; arithmetic 12 to 16 (five laws with `h:`); verify 32 same_as_given. The arithmetic five with the provers over int | `implies` is a row already (types/operators.wap); hypothesis binders are not M2b's, so they are this step's whole |
| T6a3 indexed families | enums over indices with a result per case, letters found as fields, mutual families one block; constructor calls typed by unifying their result; Equal as a family, replacing T6a1's core declaration, and `==` in a proposition's place | core +110 (header and cases with indices +50, found fields +20, constructor typing +30, Equal's place +10), kernel −20 (T6a1's Equal declaration) | 9: proposition_wanted 15 four_is_even, wap proposition_wanted 10 and 12 (two, mutual), proof_wanted wrong, verify 13 hard, 17 uses_hard, 20 wrong, 26 any_even (Untested), connectives 18, 19 (And, Or as families) | int as an enum over nat in wap/types is the first two-case block analyze declares for the kernel; the found fields are blocks.wap's, ported from 384b1e4e |
| T6a4 proofs by cases and induction | a dependent motive; the theorem's own call on a field its hypothesis; a proof match missing a case refused by covering | core +60 (`motive_made` ported +35, the course with a dependent motive +25, after T5c3) | 7: double_even (test_proof_wanted 8, wap proof_wanted 7, elaborate 50 and 87, verify 12), wap proof_wanted 13 partial, verify 34 multiply_one_left | a nat subject is int's case split with the carrier's induction under it (the provers' step 5), so no nat induction theorem waits; `motive_made` ported from 384b1e4e |
| T6a5 False, Exists, undecidable | `False`; a proof's effects checked pure and total; `exists … where`; `if` on an undecided proposition refused | core +35 (False +8, the effect check +12, Exists +15), types +2 | 5: wap proof_wanted 14 and 15 (loop, raise), effects 15 and 16 (spin, loop), proposition_wanted 8 some_sum; plus the two undecidable-condition checks | the effects are facts on each typed function (T5b1, t5b-effects): the check reads EFFECTS and refuses Fail and Div in a proof |
| T6a6 propositions as values, the logic in wap/types | a type in a value's place compared at Type; Prop binders; False, True, And, Or, Not, Exists, Decidable and the axiom proposition_extensionality in types/logic.wap | core +30 (types as values +20, Prop binders +10), types +35 (the rest of the logic in wap spelling) | 4: elaborate 107, 108, 153 (unions at Type); logic 18 anything; and logic's own checks (10 to 17) read on wap/types | the prelude is gone already (the deletion commit); the glue laws moved in T6a1, Equal in T6a3 |

Order: T6a1 first (it holds most of the laws, and every later step reads a law's declaration through it), then T6a2,
T6a3, then T6a4 after T5c3, T6a5 after T5b1, T6a6 last. T6a1 needs the deletion commit and the int enum; T6a1's
nine prover statements need M2b (notes/unify-provers.md); T6a3 needs T5b2's blocks.

## The estimate

T6a as a whole: core about +355 (+80, +40, +110, +60, +35, +30), kernel 0 net (+20 in T6a1, −20 in T6a3), types
about +60. The extension's −255 and the prelude's logic.wap and operators.wap (92) are the deletion commit's. Against
coc-plan.md's T6 budget (500 analyze, 150 types for laws, effects, instances and tested): T6a takes the logic's
share; instances and protocols (traits) stay T6's.

## Gate

T6a is done when:
- the statements in the table's "turns green" column are green, except those it names as waiting for T5c2, T5c4 or
  T5d;
- the logic's words are declared once, in types/logic.wap, Equal as a family;
- the whole suite has no new red, `--stage 2` is a fixed point; the self-compile and memory are measured and reported.

## Open for the supervisor

- **Equal and the glue laws after the deletion:** who declares `Equal`, `Equal.refl` and the five glue laws from the
  deletion commit on, before any family exists? Recommended: the deletion commit (wap-theory-reads-types) declares
  Equal and refl in core_environment, as the Choice is, and the glue laws in wap/types with their proofs; T6a1 then
  only reads them. Without them the provers and every bool law's proposition have no Equal.
- **Test programs in the prelude's spelling:** measures' FACT and FIB, statements' SUM_TO, SUM_BEFORE and SUM_SKIPPING
  (with their `operator +(a: nat, b: nat)`), and subtypes' ONE_ONLY call prelude functions or write a proposition
  where wap writes a bool. Recommended: rewrite them in wap spelling, beside the 40 granted rewrites, through
  wap-interviewer (an existing test's program changes, its outcome does not).
- **The int laws' names:** verify 36, 37 and 40 name `add_commutative` and `add_zero`. Recommended: wap/types names
  int's laws by the words the tests and wiki/proof.md use (`add_zero`, `add_commutative`, `add_associative`), not
  `sum_*`; notes/unify-provers.md's table follows.
- **test_theory_second:** its laws check the second checker (extensions/theory/second). If the deletion removes that
  checker, its three T6a1 statements leave with it as unpinned, not red.
