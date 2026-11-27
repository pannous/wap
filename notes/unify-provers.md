# The provers over int (unify-typers M2b)

A program's whole numbers reach the kernel as int, and int is the only number structure the provers work in. nat is
`int where it >= 0`, so no law reaches them over nat.

int is `enum int { of_count(n: count); below_zero(n: count) }`, its payload the kernel's count (next section). A
numeral is `of_count(k)` or `below_zero(k)`, k a count literal. An operator is a row constant,
`prim i64.add int -> int -> int`, whose Defined value is its meaning in wap/types: sum, minus, times,
equal_integers, not_above, and the other comparisons. The count is only the payload of int's two cases. The
provers never state a program's law over it; only the reader of an int numeral and the int lemmas' own proofs use it.

## int's payload: the kernel's count, not nat

nat is `int where it >= 0`, a refinement of int, so int's cases cannot carry nat: that would be circular. Their
payload is a kernel object of its own with no wap name, the **count**:

```
count: Type            the kernel block   enum count { none; one_more(c: count) }
                       its literals the kernel's Numeral (a count literal k is one_more applied k times to none,
                       computed by the numbers binding's shortcuts, kernel/numbers.wap, so 10^12 costs nothing)
count_add, count_subtract, count_equals, count_at_most     by count's recursor
count_equals_sound, count_equals_itself, count_add_zero …  theorems by count's recursor
```

- **Where it is declared.** core_environment declares it, as it declares Equal (type_notation.wap
  `equality_declared` beside it, a `count_declared`). The kernel code to bind it, `numbers_declared` and the
  shortcuts, already exists. It was bound by the deleted prelude's `numbers(nat, bool.yes, Equal)`. Now core binds
  it to the count block: kernel +about 40 lines of declarations, no new kernel mechanism. wap/types never names it.
  `enum int` in wap/types writes its cases' payload with the word `count`, a core word (CORE_WORDS), seen from every
  scope as the Choice is. It is not a type a program uses: a program writing `count` meets the list's `count` word,
  so the kernel word needs a name no program can write. Recommended: core keys it with a mark, as row constants are
  keyed `prim …`, e.g. `·count`.
- **Not a second number type.** A program's numerals, its operators and its laws are int. nat is the refinement with
  its condition. The count is to int what the bits of a machine word are to i64: its representation, which only the
  kernel and the int lemmas' proofs see.
- **nat's induction.** A theorem over `int where it >= 0`: from `0 <= x`, x is `of_count(k)`. The case
  `below_zero(k)` computes `0 <= x` to no, ruled out by apart over bool. P(of_count(k)) then follows by count's
  recursor. It is stated and proved once, and induction.wap uses it for a nat binder. A law is `Π binders, Equal(bool, body, yes)` (typed_laws.wap `law_statement`).

The provers are 9 files, 937 lines. Only linear.wap (416) reads a number structure, today nat's through
kernel/numbers.wap's Numbers record. apart, induction, rewriting, facts, introduction and computing take any enum by
its recursor (`case_recursor`), so int's two cases reach them unchanged.

Proved today: small, neg, square_minus. Open: `law regrouped(a: int, b: int): a + 1 + b == b + a + 1` and
`law lt(x: int): x < x + 1`.

## linear.wap over int only

The nat structure and the nat LAWS list go. `Sums` holds int's functions, found as the Defined values of the rows
`i64.add`, `i64.le_s` and `i64.eq` at `int -> int -> int` (core/analyze/terms.wap `row_name`), so no function name is
written twice.

- **Numbers read.** `of_count(k)` is k and `below_zero(k)` is −k−1, k a count literal or built from count's none and
  one_more. This is the one place the count appears in linear.wap, and only because it is int's payload. Numbers are
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
  `a + d == b` (`sum_difference`) and `0 <= d` (`difference_nonnegative`). An equation's d is `of_count(0)`.
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
                  of_count m, of_count n → count_at_most(m, n);   of_count m, below_zero n → no;
                  below_zero m, of_count n → yes;   below_zero m, below_zero n → count_at_most(n, m)
below(a, b)       := not_above(a + 1, b)
above(a, b)       := below(b, a)
not_below(a, b)   := not_above(b, a)
```

Each row keeps its meaning (`i64.le_s` is not_above, `i64.lt_s` below, and so on). Every comparison is then the one
`<=` the prover reads. A `<` goal or hypothesis is a `<=` of `a + 1`, which makes `lt` (`x < x + 1`) a gap of 0. The
count_at_most inside the cases is part of the payload: it appears only in the proofs of the int lemmas below.

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

Recommended proof route: an int is a difference of two counts.
- `of_count m == difference(m, none)` and `below_zero m == difference(none, one_more(m))`, by computation.
- `difference_shift`: `difference(a + k, b + k) == difference(a, b)`, by induction on k.
- `difference_sum`: `difference(a, b) + difference(c, d) == difference(a + c, b + d)`.
- `difference_equal`: `difference(a, b) == difference(c, d)` where `a + d == c + b`.

Then the sum laws become: rewrite each binder by its cases into differences, apply `difference_sum`, and finish with
the count's add laws. The comparison laws are case splits on a and b, ending in the count's at_most laws. These
count lemmas are proved by computing and induction, not by linear, which never reads the count. Never let the
linear prover prove a lemma it uses itself.

## Between bool laws and Equal, hypotheses, and the binders' conditions

### The bridge, both ways

A wap law states bool: `a == b` is `Equal(bool, eq(a, b), yes)`, eq being `i64.eq`'s meaning, `equal_integers`. The
linear prover chains `Equal(int, a, b)` with the kernel's glue laws (kernel/equality.wap). Two kernel theorems join
the two forms, and the role table names them (EQUALS_SOUND, and EQUALS_COMPLETE, new):

```
equals_sound(a: int, b: int, h: Equal(bool, equal_integers(a, b), yes)): Equal(int, a, b)
equals_complete(a: int, b: int, h: Equal(int, a, b)): Equal(bool, equal_integers(a, b), yes)
```

Neither can be written in wap spelling: a law's `==` is always the bool one, so `Equal(int, …)` has no wap form
before T6a3 puts `==` in a proposition's place. So linear.wap declares both itself, the first time `sums_of` meets
int. It hands each statement, as a kernel term, to `proof_found`, and keeps the proof through `lemma_declared`. They
are checked theorems, never axioms. The same function serves any enum whose `==` decides it (bool's own `==`
included), so it is written once over the type and its equality function.

- **complete** is Equal's recursor: rewrite b to a in the goal (`rewritten`), leaving `equal_integers(a, a) == yes`,
  which is `equal_integers_itself`. That law is proved by int's cases and `count_equals_itself` (count's recursor).
- **sound** is induction on a, then on b, over int's cases:
  - In the two mixed cases (`of_count m` against `below_zero n`), `equal_integers` computes to no. The
    hypothesis becomes `Equal(bool, no, yes)`, and apart.wap proves the goal from it. This is the step that needs bool
    as a block (t5b-enums): apart's chooser is the recursor of the equation's type, `case_recursor(bool)`, choosing
    the goal at no and anything at yes. While bool is the kernel's Choice, it has no recursor, and `no == yes`
    cannot be told apart.
  - In the two like cases, `equal_integers` computes to `count_equals(m, n)`. `count_equals_sound` (count's recursor on m
    and n, the mismatched cases again by apart over bool) gives `Equal(count, m, n)`. `equal_congruent` with `of_count`,
    or with `below_zero`, carries it to `Equal(int, …)`.

Where the prover reads a hypothesis `h: (a == b) == yes`, `equal_bounds` gets `equals_sound(a, b, h)`. Where a law
it calls takes an int equation (add_cancel's h, gap_bound's k), it passes `equals_complete(…, proof)`.

### A nat binder's condition as a hypothesis

`law p(n: nat): n + 1 > 0` reaches the kernel as `law_p: int -> bool`. kernel_type erases the subtype, because a
kernel function of int is what runs. The condition must therefore be put back into the statement:

- laws_typed records, for each binder, the condition of its written type where the type is a subtype:
  `subset_condition` on the binder's settled type, before kernel_type erases it. The condition is a function value
  `it => it >= 0`, entered into the environment like any other (terms.wap's `instances_entered` takes conditions as
  function values), so it has a constant c.
- law_statement puts a hypothesis binder after each conditioned binder: `Π n: int, Π n_holds: Equal(bool, c(n), yes),
  Equal(bool, law_p(n), yes)`. The law's function still takes only n: `beta` gets frees for the value binders only,
  and the hypotheses' frees are abstracted in place. A later binder's condition may name an earlier binder; the order
  Π x, Π x_holds, Π y, Π y_holds keeps that.
- The provers read `n_holds` like any hypothesis. With the comparisons by cases, `n >= 0` is `not_above(0, n)`, so
  `bounds_of` gives it one row, `n - 0 >= 0`. That is the "atom at least 0 from a hypothesis" of the int-only design.
- The run gives a conditioned binder only trial values its condition holds for (law_runs already does this for a
  `where` type; no change).

This changes core's typing not at all; laws.wap gains about 15 lines (the conditions recorded, the hypothesis binders
built). It closes the stale comment on terms.wap:145.

### integers.wap's laws that need hypothesis binders (T6a2)

A binder whose type is a bool statement is a proof of `Equal(bool, statement, yes)`. Until T6a2 builds that, analyze
reads it as a plain parameter, so these 7 of the file's 14 laws (at 3a0742ef) can neither be stated nor proved as
meant:

| law | hypotheses |
|---|---|
| `add_cancel(a, b, c)` | `h: a + c == b + c` (the prover passes `equals_complete` of its int equation) |
| `difference_nonnegative(a, b)` | `h: a <= b` |
| `nonnegative_add(a, b)` | `h: 0 <= a`, `k: 0 <= b` |
| `gap_bound(t, g, u)` | `h: 0 <= g`, `k: t + g == u` (k by `equals_complete`) |
| `beyond_not_above(a, b)` | `h: not (a <= b)` |
| `both_first(a, b: bool)` | `h: a and b` |
| `both_second(a, b: bool)` | `h: a and b` |

The other 7 (zero_add, add_commutative, add_associative, add_swapped, add_minus, minus_add, add_difference), and
`equal_integers_itself` once it is added, have value binders only and wait for nothing but int's cases. A hypothesis binder
is the same Π that a nat binder's condition gets above. So T6a2's first part is that function in law_statement: one
Π per hypothesis, built once for both uses. Recommended: build it in M2b, beside the conditions, since the prover
needs these 7 laws to prove anything with a bound.

## Steps, each with its outcome

1. **int's meaning in wap/types.** wap-theory-reads-types writes the enum and the rows' meanings. The comparisons by
   cases above come with it, or follow at once. Gate: `lt` and `small`, `neg`, `square_minus` prove.
2. **The int lemmas.** Gate: each is accepted by the kernel.
3. **linear.wap over int.** The reader, minus atoms, bounds with their two proofs, the gap's nonnegativity; nat's
   instance and LAWS out. Gate: `regrouped` proves, law_runs 11–15 hold, and test_theory_arithmetic, test_induction
   and test_verify show no line that was green going red.
4. **Bool equality goals.** Gate: test_connectives and a `==` law over int.
5. **Induction and apart over int.** The recursor gives two cases, each with a count field. A law over one int binder
   that needs induction under a case takes depth 2, which INDUCTION_DEPTH allows. Check one such law, and raise the
   depth only if a target line needs it.

Measures to report (track T has no limits): linear.wap's net lines (nat's parts out, int's in; about +20 net),
wap/types' lemmas (about +90), the rest of prove/ 0, and prover time on the target tests before and after.

## Not part of M2b

typed_laws.wap, file.wap, read.wap, the front, `type nat = int where it >= 0`, and hypothesis binders.
