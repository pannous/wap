# T6a, propositions in analyze: how it is built

The plan for Prop, indexed families (Even, Equal), Exists and False in analyze, now that the two typers are
being unified (card unify-typers, user 2026-11-27). When the theory's own reader goes, every law that needs one of
these turns red until analyze reads it. The order below is by how many of those laws each piece turns green, with
the dependencies first. Counts are statements of data/unify/laws.md (main ccf63462 plus the unify-laws rewrites),
not measured reds: one statement may back several checks, and a check may hold several statements. Line counts are
estimates, `grep -vc '^\s*#'`.

## What is there to build on

- **A2a, on unify-typers (not on main):** the theory's door has analyze type each wap law without a proof as a bool
  function of its binders (extensions/law_statements.wap: `law positive(x: int): x > 0` is `law_positive(x: int):
  bool := x > 0`), entered into the shared environment by core/analyze/terms.wap; its verdict is the kernel's:
  without binders Proved or FAILED by computing, with binders Open. A law with a proof, every theorem and axiom, and
  every statement analyze has no form for stay the theory's (typed_laws.wap).
- **The proposition a bool law states** is `Equal(bool, law_f(x…), yes)` over its binders, the conversion the
  prelude proves (logic.wap `chosen_decided`, `chosen_at_yes`). That one conversion lets most propositions of the
  tests stay bool code analyze already types: `1 < 2 and 2 < 3`, `not (2 < 1)` and `1 == 1 and 2 == 2` are bool laws.
- **The prelude in the shared environment (A1, on t5a-pure-definitions-door):** the theory's logic, numbers and data
  are read on core's words, so `Equal`, `refl`, `And`, `False` and the rest are declared where analyze's terms live.
  T6a uses them there first and moves their declarations to wap/types last (step T6a6).
- **What analyze has not:** a sort below Type (`DATA_TERM` is Type, nothing is Prop), a declaration whose value is a
  proof, binders whose type is a proposition, an enum whose type takes arguments (`Even: nat -> Prop`) with a result
  per case, and a match whose motive depends on the value matched.
- **Numbers:** numerals are int in both worlds (user 2026-11-27); the provers (extensions/prove: linear arithmetic,
  induction) work on the prelude's nat today. A law with int or nat binders that needs a prover, not computing,
  stays Open until they read int (T6c). Each step below names the laws that wait for that.

## The pieces

### Proofs of bool laws (the most laws)

- `law name(binders): statement := proof` and `theorem` are declarations analyze types: the statement a bool
  expression, its proposition `Equal(bool, statement, yes)` over the binders (a Pi), Prop being `Sort(0)`, one
  constant beside DATA_TERM (type_notation.wap `PROP_TERM`). The proof is read against that type:
  - `refl` is the prelude's `Equal.refl` at the statement's sides; the kernel computes both;
  - `assume` declares the statement as an axiom, reported Assumed;
  - `by a, b` and `by(a, b)` hand the goal to the provers with those laws;
  - `chain` steps, each by its law (wiki/proof.md);
  - a call of a proved law, `add_zero_right(m + 0)`, is that law's constant applied: a law is a function (wiki/proof.md
    "A law proved before is used by calling it").
- The kernel's verdict: the declaration accepted is Proved; refused, the kernel's rule (`refused by value type`).
- `type of double_three` and `type of add_commutes(1, 2)` print the statement (`1 + 2 == 2 + 1`): a law's type shown
  as a bool statement where it is one (test_proof_wanted:19).

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
  induction runs through nat's refinement of int, so this piece needs nat's induction theorem (T6c) for a nat
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
for laws. The counts are the inventory's statements each step turns green, including the unify-laws rewrites.

| step | what | core / kernel / types lines (estimate) | deletes from extensions/theory | turns green (statements) |
|---|---|---|---|---|
| T6a1 proofs of bool laws | `law … := proof` and `theorem` typed by analyze: Prop, the statement's proposition, `refl`, `assume`, `by`, `chain`, a law called as a function; the verdict the kernel's; `type of` a law shows its statement | core +90 (analyze/laws.wap: the declaration +40, the proofs +40, PROP_TERM and the shown statement +10), types +5 | typed_laws.wap's "a law with a proof is the theory's" branch; declare.wap's reading of a program's `law`/`theorem` with a bool statement (about −60) | 19 rewritten laws with a proof (elaborate 96, 121, 150, 165; measures 11, 12; second 21, 23, 36; statements 20, 21, 25, 26; subtypes 38 twice; verify 31 twice_zero, 36, 37, 40), hard and uses_hard's `assume` lines once T6a3 has Even; the `by` and law-call lines need the provers on int (T6c) where their goal does not compute |
| T6a2 hypotheses and connectives | bool-statement binders as hypotheses; `implies` a row; `not`/`and`/`or` of propositions by the operands' sort | core +40 (hypothesis binders +25, the law run's skip +5, the sort-chosen rows +10), types +6 (implies, Not/And/Or rows) | the theory's reading of hypotheses in a wap law (about −20) | 13: connectives 16 implied, 20 smaller, 21 no_is_no_yes, 22, 23; connectives_wanted positive_product; induction 12 positive_product; arithmetic 12 to 16 (five laws with `h:`); verify 32 same_as_given. Proved for those the provers decide once they read int (arithmetic's five, T6c); Assumed and computed ones at once |
| T6a3 indexed families | enums over indices with a result per case, letters found as fields, mutual families one block; constructor calls typed by unifying their result; Equal as a family and `==` in a proposition's place | core +110 (analyze/inductives.wap's header and cases with indices +50, found fields +20, constructor typing +30, Equal's place +10) | blocks.wap's indexed path moves into core (about −70) | 9: proposition_wanted 15 four_is_even, wap proposition_wanted 10 and 12 (two, mutual), proof_wanted wrong, verify 13 hard, 17 uses_hard, 20 wrong, 26 any_even (Untested), connectives 18, 19 (And, Or as families) |
| T6a4 proofs by cases and induction | a dependent motive; the theorem's own call on a field its hypothesis; a proof match missing a case refused by covering | core +60 (`motive_made` ported +35, the course with a dependent motive +25, after T5c3) | match.wap's dependent half and `course_elaborated` (about −90, the last of the file) | 7: double_even (test_proof_wanted 8, wap proof_wanted 7, elaborate 50 and 87, verify 12), wap proof_wanted 13 partial, verify 34 multiply_one_left; the nat subject's lines after T6c (nat's induction), a program enum's at once |
| T6a5 False, Exists, undecidable | `False`; a proof's effects checked pure and total; `exists … where`; `if` on an undecided proposition refused | core +45 (False and the effect check +20, Exists +15, the refusal +10), types +2 | the theory's effect refusal of proofs (about −15) | 5: wap proof_wanted 14 and 15 (loop, raise), effects 15 and 16 (spin, loop), proposition_wanted 8 some_sum; plus the two undecidable-condition checks |
| T6a6 propositions as values, the logic in wap/types | a type in a value's place compared at Type; Prop binders; logic.wap's False, True, And, Or, Not, Equal, Exists, Decidable and the axiom proposition_extensionality declared in types/logic.wap, the prelude file gone | core +30 (types as values +20, Prop binders +10), types +45 (types/logic.wap, the laws with their proofs in wap spelling) | prelude/logic.wap (63), prelude/operators.wap (29) | 4: elaborate 107, 108, 153 (unions at Type); logic 18 anything; and logic's own checks (10 to 17: And.intro, Not, Or's and Exists' elimination into Prop only) read on wap/types |

Order: T6a1 first (it holds most of the laws, and every later step reads a law's declaration through it), then T6a2
(no new form beyond a binder and a row), T6a3, then T6a4 after T5c3, T6a5 after T5b1, T6a6 last. T6a1 and T6a2 need
only A2a and A1; T6a3 needs T5b2's blocks.

## The estimate

T6a as a whole: core about +375 (+90, +40, +110, +60, +45, +30), kernel 0 (the kernel has Prop, families, recursors
and K already), types about +58; the extension about −255 plus the prelude's logic.wap and operators.wap (92).
Against coc-plan.md's T6 budget (500 analyze, 150 types for laws, effects, instances and tested): T6a takes the
logic's share; instances and protocols (traits) stay T6's.

## Gate

T6a is done when:
- the statements in the table's last column are green, except those it names as waiting for T6c (a prover over int)
  or for nat's induction;
- prelude/logic.wap and prelude/operators.wap are gone, their words declared once in types/logic.wap;
- the theory reads no program's law, theorem or indexed enum: its blocks.wap and match.wap have no file left whose
  job analyze does;
- the whole suite has no new red, `--stage 2` is a fixed point; the self-compile and memory are measured and reported.

## Open for the supervisor

- **The bool route for propositions:** a law whose statement is bool code is the proposition `Equal(bool, s, yes)`,
  so `and`, `or`, `not`, `implies` and comparisons stay bool and need no Prop form; only a statement over a
  proposition (a family's value, a Prop binder) uses And, Or, Not. Recommended: it keeps most laws in code analyze
  types today, and the prelude already proves the conversion. The other reading, every law statement a Prop with
  `==` as Equal throughout, needs every operator twice.
- **Provers on int:** the laws that need a prover, not computing (`by add_commutative`, the arithmetic hypotheses,
  `zero_add` by induction), stay Open or Tested until the provers read int terms (T6c). Moving the provers' port
  before T6a3 would turn about 10 more green sooner; recommended after T6a2, since T6a1 and T6a2 decide the goals'
  shape the provers read.
