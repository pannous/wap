# The provers over int (unify-typers M2b)

A program's whole numbers reach the kernel as int, and int is the only number structure the provers work in. nat is
`int where it >= 0`, so no law reaches them over nat.

wap/types declares `enum int { of_nat(n: nat); negative_successor(n: nat) }`. A numeral is `of_nat(k)` or
`negative_successor(k)` (kernel/numbers.wap `integer_numeral`). An operator is a row constant,
`prim i64.add int -> int -> int`, whose Defined value is its meaning in wap/types: sum, minus, times,
equal_integers, not_above, and the other comparisons. The kernel's nat inductive is only the carrier of int's two
cases. The provers never state anything over it. Only the reader of an int numeral and the int lemmas' own proofs
use it. A law is `Π binders, Equal(bool, body, yes)` (typed_laws.wap `law_statement`).

The provers are 9 files, 937 lines. Only linear.wap (416) reads a number structure, today nat's through
kernel/numbers.wap's Numbers record. apart, induction, rewriting, facts, introduction and computing take any enum by
its recursor (`case_recursor`), so int's two cases reach them unchanged.

Proved today: small, neg, square_minus. Open: `law regrouped(a: int, b: int): a + 1 + b == b + a + 1` and
`law lt(x: int): x < x + 1`.

## linear.wap over int only

The nat structure and the nat LAWS list go. `Sums` holds int's functions, found as the Defined values of the rows
`i64.add`, `i64.le_s` and `i64.eq` at `int -> int -> int` (core/analyze/terms.wap `row_name`), so no function name is
written twice.

- **Numbers read.** `of_nat(k)` is k and `negative_successor(k)` is −k−1, k a nat literal or built from nat's zero and
  successor. This is the one place nat appears in linear.wap, and only because it is of_nat's argument. Numbers are
  written by `integer_numeral`. `Normal.number` may be negative.
- **Subtraction is `sum(a, minus(b))` everywhere.** `subtracted` unfolds to it. `with_differences`, the difference
  atoms and the Subtract shortcut go. `minus` over a sum is pushed inward by `minus_sum`, and a literal is computed.
  `minus(atom)` is an unknown of its own, with the equation `atom + minus(atom) == 0` (`sum_minus`) added as a bound
  and read both ways like any equation (`equal_bounds`). Fourier–Motzkin cancels the pair, so Normal needs no negative
  coefficients.
- **No unit rows.** An atom is bounded below only by a hypothesis. A binder of `int where it >= 0` (nat) brings its
  condition `0 <= x` as one, and any `a <= b` in scope is another, each read by `bounds_of` as a row. No flag on the
  structure says an atom is at least 0.
- **A hypothesis `a <= b`.** It is `Bound(a, d, b)`, with `d = sum(b, minus(a))` and two proofs:
  `a + d == b` (`sum_difference`) and `0 <= d` (`difference_nonnegative`). An equation's d is `of_nat(0)`.
- **The gap.** `eliminated` returns `t + gap == u` as today, the gap a sum of the used bounds' d's and a literal
  of at least 0. With it comes `0 <= gap`, built by `nonnegative_sum` from each d's proof and the literal's
  computation. `at_most_from` uses `not_above_add(t, g, h: 0 <= g): t <= t + g`.
- **`not (a <= b)`.** It is read through `beyond_not_above` as `b + 1 <= a`.
- **Equality goals through bool.** `proved()` reads a `made_yes` goal only as at_most. Add one branch:
  `equal_integers(l, r) == yes` is `equal_proof(l, r)` carried to `equal_integers(l, l) == yes` by
  `equal_integers_itself`. `regrouped` needs this.

The law names stay one list (LAWS), checked present by `sums_of` as today.

## The comparisons, one function by cases (wap/types)

```
not_above(a, b)   by int's cases on a and b, the way equal_integers is:
                  of_nat m, of_nat n → at_most(m, n);   of_nat m, neg n → no;
                  neg m, of_nat n → yes;                neg m, neg n → at_most(n, m)
below(a, b)       := not_above(a + 1, b)
above(a, b)       := below(b, a)
not_below(a, b)   := not_above(b, a)
```

Each row keeps its meaning (`i64.le_s` is not_above, `i64.lt_s` below, and so on). Every comparison is then the one
`<=` the prover reads. A `<` goal or hypothesis is a `<=` of `a + 1`, which makes `lt` (`x < x + 1`) a gap of 0. The
nat-side at_most inside the cases is part of the carrier: it appears only in the proofs of the int lemmas below.

## The int lemmas (wap/types, wap-unify-provers')

| Law | Statement |
|---|---|
| `zero_sum` | `0 + y == y` |
| `sum_commutative` | `a + b == b + a` |
| `sum_associative` | `(a + b) + c == a + (b + c)` |
| `sum_swapped` | `(x + a) + b == (x + b) + a`, from the two above |
| `sum_cancel` | `a + c == b + c → a == b`, adding `-c` and using `sum_minus` |
| `sum_minus` | `x + -x == 0` |
| `minus_sum` | `-(a + b) == -a + -b` |
| `sum_difference` | `a + (b + -a) == b` |
| `difference_nonnegative` | `a <= b → 0 <= b + -a` |
| `nonnegative_sum` | `0 <= a → 0 <= b → 0 <= a + b` |
| `not_above_add` | `0 <= g → t <= t + g` |
| `equal_integers_sound` | `equal_integers(a, b) == yes → a == b` |
| `equal_integers_itself` | `equal_integers(x, x) == yes` (exists today in the prelude; moves with it) |
| `beyond_not_above` | `not (a <= b) → b + 1 <= a` |

The laws the proofs are glued with, `equal_symmetric`, `equal_transitive`, `equal_congruent`, `chosen_decided` and
`chosen_at_yes`, are about any type and stay as they are.

Recommended proof route: an int is a difference of the carrier's nats.
- `of_nat m == difference(m, 0)` and `negative_successor m == difference(0, m + 1)`, by computation.
- `difference_shift`: `difference(a + k, b + k) == difference(a, b)`, by induction on k.
- `difference_sum`: `difference(a, b) + difference(c, d) == difference(a + c, b + d)`.
- `difference_equal`: `difference(a, b) == difference(c, d)` where `a + d == c + b`.

Then the sum laws become: rewrite each binder by its cases into differences, apply `difference_sum`, and finish with
the carrier's add laws. The comparison laws are case splits on a and b, ending in the carrier's at_most laws. These
carrier lemmas are proved by computing and induction, not by linear, which no longer reads nat. Never let the
linear prover prove a lemma it uses itself.

## Steps, each with its outcome

1. **int's meaning in wap/types.** wap-theory-reads-types writes the enum and the rows' meanings. The comparisons by
   cases above come with it, or follow at once. Gate: `lt` and `small`, `neg`, `square_minus` prove.
2. **The int lemmas.** Gate: each is accepted by the kernel.
3. **linear.wap over int.** The reader, minus atoms, bounds with their two proofs, the gap's nonnegativity; nat's
   instance and LAWS out. Gate: `regrouped` proves, law_runs 11–15 hold, and test_theory_arithmetic, test_induction
   and test_verify show no line that was green going red.
4. **Bool equality goals.** Gate: test_connectives and a `==` law over int.
5. **Induction and apart over int.** The recursor gives two cases, each with a carrier field. A law over one int binder
   that needs induction under a case takes depth 2, which INDUCTION_DEPTH allows. Check one such law, and raise the
   depth only if a target line needs it.

Measures to report (track T has no limits): linear.wap's net lines (nat's parts out, int's in; about +20 net),
wap/types' lemmas (about +90), the rest of prove/ 0, and prover time on the target tests before and after.

## Not part of M2b

typed_laws.wap, file.wap, read.wap, the front, `type nat = int where it >= 0`, and hypothesis binders.
