# The provers over int (unify-typers M2b)

A program's whole numbers reach the kernel as int. A numeral is `int.of_nat(k)` or `int.negative_successor(k)`
(kernel/numbers.wap `integer_numeral`). An operator is a row constant, `prim i64.add int -> int -> int`, whose
Defined value is its meaning in prelude/numbers.wap: sum, subtracted, times, equal_integers, below, above,
not_above, not_below. A law is `Π binders, Equal(bool, body, yes)` (typed_laws.wap `law_statement`).

The provers are 9 files, 937 lines. Only linear.wap (416) reads nat, through kernel/numbers.wap's Numbers record: zero,
successor, the Add/AtMost/Equal/Subtract shortcuts, truth, yes_case, no_case and equality. Its atoms are typed nat.
apart, induction, rewriting, facts, introduction and computing take any enum by its recursor
(`case_recursor`), so int's two cases reach them unchanged.

Proved today: small, neg, square_minus. Open: `law regrouped(a: int, b: int): a + 1 + b == b + a + 1` and
`law lt(x: int): x < x + 1`.

## The design: one linear prover, two number structures

linear.wap keeps one elimination and one proof builder. Its `Sums` record becomes the structure it works in, and
gets two instances: nat (as today) and int. Nothing in linear.wap is copied for int. Each place that reads `s.n.*`
or `s.nat` reads the structure instead:

| Sums field | nat | int |
|---|---|---|
| type | `number_type(n)` | `n.integers.type` |
| add, at_most, equals | the shortcuts | the Defined value of the row `i64.add`, `i64.le_s`, `i64.eq` at `int -> int -> int` (core/analyze/terms.wap `row_name`), so no function name is written twice |
| subtract | the shortcut, a difference kept as an atom with its bounds (`with_differences`) | none: `subtracted(a, b)` unfolds to `sum(a, minus(b))` |
| a number read | Numeral, zero, successor | `of_nat(k)` → k, `negative_successor(k)` → −k−1, with k read as nat's |
| a number written | `numeral(k)` | `integer_numeral(e, k)` |
| atoms at least 0 | yes: one unit row per unknown | no unit rows |
| the laws | LAWS today | the int table below, in the same order, so `law(s, ADD_SWAPPED, …)` picks the structure's |

The table of laws is one list of pairs, one row per role, e.g. `["add_swapped", "sum_swapped"]`, read by the role
constants. Choose the int instance where the goal's equation type, or the compared values' type, computes to
`n.integers.type`. `sums_of` takes that type.

### What changes for int in the elimination

- **Negation.** `minus(t)` over a sum is pushed inward by `minus_sum`, and a literal is computed. `minus(atom)` is an
  unknown of its own, with the equation `atom + minus(atom) == 0` (`sum_minus`) added as a bound, read both ways like
  any equation (`equal_bounds`). Fourier–Motzkin then cancels the pair, and Normal needs no negative coefficients.
  `Normal.number` may be negative.
- **The gap.** A hypothesis `a <= b` is `Bound(a, of_nat(gap(a, b)), b)` by `not_above_difference`, where
  `gap(a, b) := size(subtracted(b, a))`. An equation's difference is `of_nat(0)`. `eliminated` builds the gap as
  `of_nat(Σ nat parts)`. That equals the int sum of the `of_nat` parts by conversion, since `sum(of_nat m, of_nat n)`
  computes to `of_nat(add(m, n))` on open m and n. The kept number is at least 0, so it is an `of_nat` literal too.
  `at_most_from` uses `not_above_add(t, k: nat): not_above(t, sum(t, of_nat k)) == yes`.
- **`not (a <= b)`.** It is read through `beyond_not_above` as `b + 1 <= a`, as nat reads `beyond_at_most`.

### The comparisons, one function by cases

Redefine in prelude/numbers.wap (each `runs(...)` line stays as it is):

```
not_above(a, b)   by int.recursor on a and b, the way equal_integers is:
                  of_nat m, of_nat n → at_most(m, n);   of_nat m, neg n → no;
                  neg m, of_nat n → yes;                neg m, neg n → at_most(n, m)
below(a, b)       := not_above(sum(a, of_nat(1)), b)
above(a, b)       := below(b, a)
not_below(a, b)   := not_above(b, a)
```

So every comparison is the one at_most the prover reads. A `<` goal or hypothesis is a `<=` of `a + 1`, which makes
`lt` (`x < x + 1`) the gap 0 of `x + 1 <= x + 1`. On `of_nat` the cases compute to nat's at_most, which is what the
nat proofs below rest on.

### Equality goals through bool

`proved()` reads a `made_yes` goal only as at_most. Add one branch: `equals(l, r) == yes` is `equal_proof(l, r)`
carried to `equals(l, l) == yes`, using `equals_itself` (nat) and `equal_integers_itself` (int, already in the
prelude). This is what `regrouped` needs, and nat's bool `==` laws gain it too.

## The int lemmas (prelude/numbers.wap)

| Role | int law | Statement |
|---|---|---|
| zero_add | `zero_sum` (in the prelude already) | `sum(of_nat 0, y) == y` |
| add_associative | `sum_associative` | `sum(sum(a, b), c) == sum(a, sum(b, c))` |
| add_swapped | `sum_swapped` | `sum(sum(x, a), b) == sum(sum(x, b), a)` (from associative and commutative) |
| add_cancel | `sum_cancel` | `sum(a, c) == sum(b, c) → a == b` (add `minus c`, then `sum_minus`) |
| at_most_add | `not_above_add` | `not_above(t, sum(t, of_nat k)) == yes`, k: nat |
| at_most_difference | `not_above_difference` | `not_above(a, b) == yes → sum(a, of_nat(gap(a, b))) == b` |
| equals_sound | `equal_integers_sound` | `equal_integers(a, b) == yes → a == b` |
| beyond_at_most | `beyond_not_above` | `negated(not_above(a, b)) == yes → not_above(sum(b, of_nat 1), a) == yes` |
| (int only) | `sum_commutative`, `sum_minus`, `minus_sum` | `sum(a, b) == sum(b, a)`; `sum(x, minus x) == of_nat 0`; `minus(sum(a, b)) == sum(minus a, minus b)` |

Recommended proof route: every int is a nat difference.
- `of_nat m == difference(m, 0)` and `negative_successor m == difference(0, succ m)`, both by computation.
- `difference_shift`: `difference(a + k, b + k) == difference(a, b)`, by induction on k, its step `subtract_successors`.
- `difference_sum`: `sum(difference(a, b), difference(c, d)) == difference(a + c, b + d)`.
- `difference_equal`: `difference(a, b) == difference(c, d)` where `a + d == c + b`.

Then commutativity, associativity, cancellation and the sum_minus laws each become: rewrite each binder by its cases
into differences, apply `difference_sum`, and finish with nat's add laws, which nat's linear prover proves. That is
about four helper lemmas instead of eight-way case splits per law. The comparison lemmas are case splits on a and
b, ending in nat's at_most laws (`at_most_add`, `at_most_difference`, `beyond_at_most`). Where a statement can be
written `law … := by linear` once the int instance is in, prove it that way, but never use the int instance to prove a
law it itself needs.

## Steps, each with its outcome

1. **Comparisons by cases.** The prelude only. Gate: `lt` proves, and every int law that proves today still proves.
2. **The int lemmas.** The prelude only, the difference route. Gate: each lemma is accepted by the kernel.
3. **Sums as a structure.** linear.wap reads the record and the law table. The nat instance alone, with no behaviour
   change. Gate: test_theory_arithmetic, test_induction and test_verify unchanged.
4. **The int instance.** The reading, minus atoms and gaps. Gate: `regrouped` proves, and law_runs 11–15 hold.
5. **Bool equality goals.** Gate: test_connectives, and a `==` law over nat and over int.
6. **Induction and apart over int.** The recursor gives two cases, each with a nat field. A law over one int binder
   that needs nat induction under a case takes depth 2, which INDUCTION_DEPTH already allows. Check one law of that
   kind, and raise the depth only if a target line needs it.

Measures to report (track T has no limits): linear.wap about +60, prelude about +90 (lemmas and comparisons), the
rest of prove/ 0. Prover time on the target tests, before and after.

## Not part of M2b

typed_laws.wap, file.wap, read.wap, the front, `type nat = int where it >= 0`, and hypothesis binders.
