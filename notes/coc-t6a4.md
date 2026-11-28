# T6a4: proofs by cases and induction, nat's included

coc-t6a.md's T6a4 row covers a proof written as a match: a dependent motive, the theorem's own call on a field as its
hypothesis, and a match missing a case refused by covering. This plan adds what the types module's nat needs on top:
nat is `int where it >= 0` over int-takes' `int = natural(n: ·count) | negative(n: ·count)`, so a proof over nat
meets int's negative arm, which no program writes. It builds on T5c3 (notes/coc-t5c3.md) and T5c4
(notes/coc-t5c4.md). Read on int-takes 911f0e56.

## Two kinds of nat in the tests

- **A program's own `enum nat { zero, successor(n: nat) }`** (test_theory_elaborate, test_theory_verify). Its match
  is the enum's own split. It needs only the row's three parts: the dependent motive, the own call read from below,
  covering. No condition, no negative arm.
- **The types module's nat** (test_proof_wanted, wap/test_proof_wanted). Its match is T5c4's reading: int's split,
  then count's split in the natural arm, k bound as `natural(c)`. A definition gives the negative arm the zero arm's
  value (T5c4). A proof cannot: its negative arm must prove the goal at `negative(c)`. nat's condition proves it.

## The nat-induction principle, read and not declared

The principle is nat's induction (unify-provers.md "nat's induction"): from P(0), and from P(x) → P(x + 1) for each
0 <= x, P(x) follows for each 0 <= x. No theorem states it. It is what int's split gives with count's recursor under
the natural arm:

- **natural(c)**: count's recursor on c. At zero the goal is P(natural(zero)) = P(0). At successor(c) the hypothesis
  is P(natural(c)) and the goal P(natural(successor(c))), which is P(natural(c) + 1) by computing. `·add` recurses on
  its second count, so `natural(c) + 1` computes to `natural(successor(c))` and the two are one term.
- **negative(c)**: ruled out. The binder's condition hypothesis `n_holds: (n >= 0) == yes` is at `negative(c)` here,
  and `negative(c) >= 0` computes to no. So the hypothesis reads `no == yes`, and apart.wap's proof gives any goal
  from it. That is the existing `by_cases_apart`, which needs no `·yes_is_not_no`.

A declared `nat.induction` over x and x + 1 was weighed and rejected. Its step case has `double(x + 1)` with x an
unknown int, and that is stuck: the + cannot compute on x's case. The count route keeps `double(natural(successor(c)))`
computing to `double(natural(c)) + 2`, which is what both proofs below need.

## The hypothesis a subtype binder brings, in a written proof

verify/laws.wap already states a law without a proof under its binders' conditions. `hypothesized` (laws.wap:153)
puts `Π n_holds: (n >= 0) == yes` after a binder of a subtype. A law with a written proof is a function, and its kernel
type erases nat to int (core/analyze/terms.wap:157 `kernel_type`), so today it takes no hypothesis. T6a4 adds:

1. **The theorem takes the hypothesis.** A function whose result is a proposition takes, after each binder of a
   subtype, that binder's condition hypothesis, as law_statement does. `hypothesized` moves from verify into
   core/analyze/conditions.wap and both use it. A definition (a result that is data) takes none, because its code
   would carry proofs. Its negative arm stays T5c4's zero-arm value.
2. **A call passes it.** A call of such a function on a value passes the condition's proof: `refl` when the
   condition computes to yes (`double_even(3)`: `3 >= 0`; the own call on `natural(c)`: `natural(c) >= 0` computes
   to yes for any count c), else a hypothesis in scope about the same value. This is the caller that
   conditions.wap's `condition_proof` waits for (notes/kernel-length.md "Gaps waiting on a caller").
3. **The match reverts it into the motive.** A match on n under `n_holds` takes the motive
   `n => Π n_holds: (n >= 0) == yes, P(n)`, so each arm gets the hypothesis at its own case. induction.wap's `along`
   does the same with `about`.
4. **The negative arm is filled.** T5c4's `choice_by_cases`, which gives a definition's negative arm the zero arm's
   value, gives a proof's negative arm apart's proof from the arm's hypothesis. When that hypothesis does not compute
   to two different cases (a subtype whose condition does not rule the arm out), the arm is missing and covering
   refuses as for any match.

The rule is general: any subtype whose condition rules out a case of its carrier gets the same treatment, for
example `int where it > 0` at zero. Nothing names nat.

## What makes each law Proved

- **`law double(n) == n + n`** (proof.md:11, test_proof_wanted:6). This is a law without a proof, so the provers
  find one. Its statement is `Π n: int, Π n_holds, (double(n) == n + n) == yes`.
  - by_induction's `along` on n: int's recursor, with `n_holds` reverted (`about`).
  - The negative case falls to `by_cases_apart`.
  - The natural case goes down again on c (INDUCTION_DEPTH 2 is enough). Zero computes. At the successor, double
    computes (T5c4) to `double(natural(c)) + 2`, and the hypothesis rewrites it. Its premise `h` is answered by
    computing `natural(c) >= 0`.
  - What is left is `natural(c) + natural(c) + 2 == natural(successor(c)) + natural(successor(c))`. linear.wap
    reads `natural(successor(c))` as an atom distinct from `natural(c)`: `integer_value` (linear.wap:314-319) reads
    only a computed count. The one gap: a natural (or negative) of k successors over an unknown count is that count's
    natural plus k (minus k), proved by computing. That is +6.
  - Until then the law is Tested (T5c4 already makes its trial values compute).
- **`double_even`** (proof.md:17-18, test_proof_wanted:8-10, wap/test_proof_wanted:8). A written match. Its parts:
  - the dependent motive `Even(double(n))`;
  - T5c4's nat reading;
  - the own call `double_even(k)`, read from below by T5c3's course and passed its hypothesis by refl (2);
  - the negative arm by apart (4).
  - At zero the arm is `Even.zero : Even(0)`, and `double(natural(zero))` computes to 0. At the successor,
    `Even.step(double_even(k)) : Even(double(k) + 2)`, which is `double(natural(successor(c)))` computed.
- **The own-enum double_even** (test_theory_elaborate, test_theory_verify) needs only the motive, the course and
  covering.

## The red lines it turns green (line numbers on int-takes 911f0e56)

| line | what | needs |
|---|---|---|
| test_proof_wanted:8-10 | `type of double_even(3)` is `Even(6)` | all four parts, T5c4 |
| test_proof_wanted:21 | `axioms of double_even` is `[]` | the same; apart's proof uses no axiom |
| wap/test_proof_wanted:8 | `double_even: Proved` | the same |
| wap/test_proof_wanted:13 | a match missing `successor` refused by covering | the reading of nat's cases (zero and successor, never negative) in covering; the negative arm is not a case a program writes |
| wap/test_theory_elaborate:48, :82 | the own-enum double_even, with the products bound | the motive, the course |
| wap/test_theory_verify:14, :17 | the own-enum double_even Proved; its axioms | the same |
| wap/test_theory_verify:32 | `multiply_one_left` by match, `equal_congruent` in the successor arm | the dependent motive over Equal |

No line pins `law double(n) == n + n` Proved. A builder adds this line to wap/test_proof_wanted (proof.md:11):
`check("wap verify: a law over nat is proved by induction", wap_said(["verify", written("doubled", double + "law doubled(n: nat): double(n) == n + n\n")]), "doubled: Proved")`.

wap/test_proof_wanted:12 (a wrong proof refused by value type) may be green already. The builder reads it before
counting it.

## Estimates

| part | core | kernel |
|---|---|---|
| `motive_made` ported from 384b1e4e (the row) | +35 | |
| the course with a dependent motive (the row) | +25 | |
| (1) the theorem takes its binders' condition hypotheses; `hypothesized` moved from verify | +4 | |
| (2) a call passes the condition's proof, through `condition_proof` | +8 | |
| (3) the match reverts the hypothesis into its motive | +8 | |
| (4) `choice_by_cases` fills a proof's negative arm by apart | +6 | |
| linear reads a natural of successors over an unknown count | +6 | |
| **total** | **about +92** | **0** |

(4) needs apart's term builder (apart.wap:31-55) in reach of core's match reading. Today it sits in
extensions/prove. Two ways:
- **A (recommended):** move the builder into wap/kernel/, beside recursors.wap. That is kernel +25 and prove −25,
  net 0. The prover stays in apart.wap and calls it. It goes to warp-interviewer, since kernel is semi-frozen.
- **B:** leave the arm open and let verify's provers fill it. That keeps a written proof's check split across two
  layers, so a program's `type of double_even(3)` would fail without verify.

kernel-length drops `·yes_is_not_no` and `·bool_cases` (no caller). T6a4 needs neither: apart proves from
`no == yes` by bool's recursor.

## Order

T6a4 lands after T5c3 and T5c4, and after unify-dedup. The own-enum part (motive, course, covering) can land first, on
T5c3 alone, and turns the theory tests green. The nat part (1)-(4) and the linear reading follow on T5c4.

## Read on t5c4-fix ed626a2c: what stands between the row and its red lines

The row's "own-enum part lands first on T5c3 alone" does not hold for the red lines: each is a `law … := match` over an
indexed family (`Even(double(n))`), which needs T6a1 (a law with a written proof typed by analyze) and T6a3 (found
fields and indices; inductives.wap:56 declares every enum at DATA_TERM). Neither is an ancestor of this base. The source
`motive_made` is gone with the extension elaborator, so the "+35 ported" row is stale: the work sits in analyze.

Where the dependency lives, each a guess until built:
1. matching.wap `arm_typed` gives every arm the same expected type; an arm must be expected at the result type with the
   subject replaced by that case's value. terms.wap `match_term` then only abstracts a typed node (the check at :170
   cannot move: the case's value exists inside `minor_of`).
2. Three gates compare syntactically and want the kernel's `equal` under substitution: `kernel_signature` (:72, folds
   `pi("_", …)`, so a result cannot name a parameter), `definition_of` (:78) and `called_term` (:125).
3. Levels: `recursor_applied` and the course and below constants hardcode `[TYPE_LEVEL]`; a Prop-valued motive needs the
   result's sort (courses.wap:70-71 says the pairs' level is never Prop). Possibly a kernel question.
4. course_applied (recursion.wap:109) abstracts the recursed value in the motive, `riding` and the other parameters'
   types as a telescope; one parameter is trivial, `others` is a guess. `abstracted` works only when the subject is a
   bare binder; otherwise the constant motive stays.
5. Covering: matching.wap:24 refuses a missing case already; only the rule word "covering" (kernel/environment.wap:16)
   is missing, a line or two.

## The substitutions, read on 5285eb86 and on this branch's base

**Where a parameter stands inside a written result type.**
- On 5285eb86 it stands nowhere. `law even_double(n: nat): Even(double(n))` gets its result at calls.wap:595
  (`written = substituted(written_type(declared_type(name)), letters)`). type_term (type_notation.wap:386) reads
  `Even(double(n))` as a Call: not a written part, not `⋅`, so it raises "… is no type".
- It is not a letter: is_letter takes one capital (letters.wap:15-16), and `n` is a value.
- It is no key of Entering either: on 5285eb86 Entering keys bound indices (terms.wap:110, `bound(#binders - at)`), and
  only the body is read through it, never the result.
- The one parameter that does stand inside a type is a universe binder (type_notation.wap:441-451): a kernel Free
  variable, `hypothesis` on a checker, handed to type_term as a TYPE fact on the name and abstracted after.
- terms-nameless (e27109d1, carried by this branch's base through T5c3) makes Entering hold Free variables
  (`variables`, `c`). A binder is opened with `entered` and closed with `lambdas` and `pis` (kernel/recursors.wap:28-33).
  So a parameter is a Free variable in the body, but definition_of (terms.wap:80-81) enters fresh Locals on a fresh
  checker of its own. A result type read anywhere else would name other ids.

**The one decision underneath all four.**
- Each TypedFunction gets its parameters' Locals once, on one checker, where its result is read (calls.wap:549-550 here):
  `typed.reading: Entering`, built by one `parameters_reading(typed, s)`.
- The result type is read under them: a value inside a type (T6a3's indices) goes through `term_of` with that Entering
  and comes back holding the parameters' Free variables.
- definition_of, kernel_signature, arm_typed and course_applied all take `typed.reading` instead of entering their own.
- Every substitution below is then the kernel's `replaced_by(t, id, value)` (kernel/terms.wap:262), or `instantiated` and
  `instantiated_all`, on Free ids that are the same everywhere. No renaming, no index arithmetic.
- A function whose result names no parameter gives the same terms as today, equal up to binder names, which are hints.

1. **matching.wap arm_typed (:42), the per-arm expected type.**
   - Only when the subject is a bare parameter (`is_variable(subject)`, its definer one of `typed.reading`'s keys) and
     the arm's pattern is a case.
   - The case's fields enter as Locals on `typed.reading.c` (the pattern's names, through pattern_typed's `remembered`).
   - The arm is expected at `replaced_by(expected, variable_id(subject_local.variable), case_value)`, where
     `case_value = apply_all(constant(case id), type parameters + variables(field_locals))`.
   - Any other subject keeps the one expected type, as today; that is Lean's match without generalising.
   - case_typed's `joined` (:31) then compares each arm with its own expected, by `equal`, not with one joined type.
   - match_term (terms.wap :163-) reads the same field Locals through `under`, so its minors and the arms' expected
     types name one variable.
2. **kernel_signature (terms.wap:66-73), the named binders.**
   - `pis(typed.reading locals, result)` replaces `parameters.reverse.fold(result, pi("_", …))`.
   - pis (kernel/recursors.wap:32) abstracts each Free in turn, so `(n: nat) -> Even(double(n))` closes with the result
     naming its binder.
   - Each Local's domain is `settled_type(typed.arguments#at, s)`, as today. The has_letters and has_unknowns gate
     stays.
3. **The gates by `equal`.**
   - definition_of (:78): `kernel_value(body) != kernel_settled(typed.result)` becomes
     `not equal(typed.reading.c, kernel_value(body)!, result)` (kernel/equal.wap:15).
     - The body's type and the result name the same Free variables, so `Even(n + n)` against `Even(double(n))` is
       equal by unfolding double. That needs double entered first, which instance_entered's callees-first order gives.
     - Then `lambdas(locals, term)` over `typed.reading`, not over fresh Locals.
   - called_term (:125): the callee's parameter and result types under the arguments.
     - `callee = type_of(x.c, function)`.
     - Argument at: `equal(x.c, kernel_value(arguments#at)!, domain_at)`, where `domain_at` is the at-th Pi's domain of
       `instantiated_all(peeled(callee, at - 1), earlier argument terms)` (kernel/recursors.wap:127-128, as
       with_parameters does).
     - Result: `equal(x.c, kernel_value(n)!, instantiated_all(peeled(callee, #arguments), argument terms))`.
     - So the argument terms are read before the gate: term_of each, then check, then `terms_applied`.
   - Cost: one `equal` per gate where there was a `!=`. A same-term pair returns at once (equal.wap:16), so the plain
     functions pay a hash compare as today.
4. **course_applied (recursion.wap:105), the telescope.**
   - motive:
     ```
     m = entered(x.c, "x", domain)
     lambdas([m], pis(others' locals, replaced_by(result, id(place's local), m.variable)))
     ```
     Here `result` is read under `typed.reading`, and the others' Locals are `typed.reading`'s, their domains replaced
     the same way when they name the recursed parameter.
   - riding: `lambdas([y], pi("below", below_of(y), apply(motive, y)))`. One spelling of the motive, so riding never
     restates `result`.
   - step_others (:115): `entered(x.c, "_", replaced_by(domain_at, place id, step_value.variable))`.
   - inside (:118): the step's Locals keyed as today.
   - The final `apply_all(course, others.map(at => x.variables#at))` (:123) stays.
   - A subject that is not a bare parameter keeps the constant motive, as now.

**Covering (wap-supervisor's ruling).**
- A program's match keeps matching.wap's compile-error form (:24, "match on … misses …: add the missing arm or `_`"),
  with only the rule word "covering" added. The kernel's "refused by" form stays internal.
- test_proof_wanted:13 reads through `refused_by` (test/wap/scripted.wap:62). It keeps only lines that contain
  "refused by ", so the line goes green only if the word lands as "refused by covering" inside that error's text.
  Builder: place the word so that it does.

Estimate: the shared reading is analyze +8 (parameters_reading, `typed.reading`, definition_of and condition_entered
taking it). The four sites are about +6, +2, +6 and +5. That is about +27 core, on top of T6a3's value reader inside
type_term.
