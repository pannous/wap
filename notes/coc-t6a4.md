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
- **A (decided, track T):** move the builder into wap/kernel/, beside recursors.wap. That is kernel +25 and prove
  −25, net 0. The prover stays in apart.wap and calls it. The builder only makes a proof term: the kernel's checker
  judges it like any other value (typing.wap `declared`), so the trust base stays where it is.
- **B:** leave the arm open and let verify's provers fill it. That keeps a written proof's check split across two
  layers, so a program's `type of double_even(3)` would fail without verify.

kernel-length drops `·yes_is_not_no` and `·bool_cases` (no caller). T6a4 needs neither: apart proves from
`no == yes` by bool's recursor.

## Order

T6a4 lands after T5c3 and T5c4, and after unify-dedup. The own-enum part (motive, course, covering) can land first, on
T5c3 alone, and turns the theory tests green. The nat part (1)-(4) and the linear reading follow on T5c4.
