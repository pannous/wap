# The provers over int (unify-typers M2b)

A program's whole numbers reach the kernel as int, and int is the only number structure the provers work in. nat is
`int where it >= 0`, so no law reaches them over nat.

int is `enum int { natural(n: count); negative(n: count) }` (Lean's), where `natural(n)` is n and `negative(n)`
is −(n + 1), so each number has one form. Its payload is the kernel's count (next section). A numeral is
`natural(k)` or `negative(k)`, k a count literal. An operator is a row constant, `prim i64.add int -> int -> int`,
whose Defined value is its meaning: sum, minus, times, equal_integers, not_above, and the other comparisons. The count
is only the payload of int's two signed cases. The provers never state a program's law over it; only the reader of an
int numeral and the int lemmas' own proofs use it.

## int's payload: the kernel's count, not nat

nat is `int where it >= 0`, a refinement of int, so int's cases cannot carry nat: that would be circular. Their
payload is a kernel object of its own with no wap name, the **count**:

```
count: Type            the kernel block   enum count { zero; successor(c: count) }
                       its literals the kernel's Numeral (a count literal k is successor applied k times to zero,
                       computed by the numbers binding's shortcuts, kernel/numbers.wap, so 10^12 costs nothing)
                       — below 2^63 only: the shortcuts and row_step refuse a result past it (LARGEST,
                       ROW_OVERFLOW), so exact int past 2^63 needs the kernel's literals exact, a step of its own
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
- **nat's induction.** A theorem over `int where it >= 0`: from P(zero), from P(x) → P(x + 1) for each `0 <= x`, and
  from `0 <= x`, P(x). It goes by int's cases on x:
  - `negative(k)` computes `0 <= x` to no, ruled out by apart over bool.
  - `natural(k)` goes by count's recursor on k. At `·count.zero`, `natural(·count.zero)` is the base. At
    `·count.successor(k)`, the step from `natural(k)` gives it, carried by `successor_sum`
    (`x + 1 == int.successor(x)`, section "int's step functions"), since `int.successor(natural(k))` computes to
    `natural(·count.successor(k))`.

  It is stated and proved once, and induction.wap uses it for a nat binder. A law is `Π binders, Equal(bool, body, yes)` (typed_laws.wap `law_statement`).

The provers are 9 files, 937 lines. Only linear.wap (416) reads a number structure, today nat's through
kernel/numbers.wap's Numbers record. apart, induction, rewriting, facts, introduction and computing take any enum by
its recursor (`case_recursor`), so int's two cases reach them unchanged.

Proved today: small, neg, square_minus. Open: `law regrouped(a: int, b: int): a + 1 + b == b + a + 1` and
`law lt(x: int): x < x + 1`.

## count_declared and int_declared: what core declares

Both are kernel terms that core_environment declares after `equality_declared`, in core's scope. Every name below
carries the mark `·`, so no program can write it or meet it. The proofs are those of the deleted prelude, copied with
a rename. Source: `git show 384b1e4e:wap/extensions/theory/prelude/numbers.wap` (N) and `…/prelude/logic.wap` (L),
line numbers as cited.

Rename: `nat` → `·count`, `nat.zero` → `·count.zero`, `nat.successor` → `·count.successor`,
`nat.recursor` → `·count.recursor`, and every function and law `f` → `·f`. The prelude's case names stay, as
the user chose (Lean's): `zero | successor(count)`, and its inverse `·predecessor`, where `·predecessor(·count.successor(n))`
computes to n by count's recursor, so it needs no theorem. bool, Equal and their recursors keep their
names, which are core's.

**Needs first:** bool as a block (T5b3, t5b-enums), because numbers_declared refuses a yes case that is no case of a
block, and the proofs use `bool.recursor`. Also `False` and `True` as blocks. Until T5b3, count_declared cannot run.

### Logic support (L), before the count

| name | statement | proof by |
|---|---|---|
| `·False`, `·True` | `enum False: Prop {}`, `enum True: Prop { intro }` (L7, L8) | blocks |
| `·false_elim` | `(c: Sort(u), h: False): c` (L38) | False's recursor |
| `·no_is_not_yes` | `Equal(bool, no, yes) → False` (L55) | Equal's recursor, motive by bool's recursor into Prop (True at no, False at yes) |
| `·yes_is_not_no` | `Equal(bool, yes, no) → False` (N67) | `equal_symmetric`, then `·no_is_not_yes` |
| `·bool_cases` | `(b, p: bool → Prop, if_no, if_yes): p(b)` (N65) | bool's recursor |
| `·negated` | `bool → bool` (L68) | bool's recursor (definition) |

### The count (N6–N180)

| name | kind | by |
|---|---|---|
| `·count` | `enum count: Type { zero; successor(c: count) }` (N6) | block, then `numbers_declared(e, ·count, bool.yes, Equal)` (N10) |
| `·predecessor`, `·is_zero` (N13–14), `·add` (N16), `·subtract` (N23), `·multiply` (N33), `·compared` (N42), `·equals` (N46), `·at_most` (N57), `·remainder`, `·divide` (N156–157) | definitions | `·count.recursor` at level 1 |
| `·chosen` (N154), `·wraps` (N155) | definitions | bool's recursor; `·equals` |
| `·add_zero`, `·add_successor` (N18–19); `·subtract_zero` (N24); `·multiply_zero`, `·multiply_successor` (N35–36); `·equals_zeros`, `·equals_successor_zero`, `·equals_zero_successor`, `·equals_successors` (N48–51); `·zero_at_most`, `·successor_at_most_zero`, `·at_most_successors` (N58–60) | theorems | `Equal.refl` (computing) |
| `·zero_subtract` (N25), `·subtract_successors` (N28) | theorems | `·count.recursor` at level 0, `equal_congruent` with `·predecessor` |
| shortcuts add, subtract, multiply, equal, at_most (N21, 31, 38, 53, 62) | `shortcut_bound` | the theorems just above |
| `·equals_itself` (N54) | theorem | `·count.recursor` at level 0 |
| `·equals_sound` (N74, helper `·sound_at` N73) | theorem | `·count.recursor` at level 0 twice, nested; mismatched cases by `·false_elim` and `·no_is_not_yes` |
| `·at_most_step` (N84, `·steps_up` N83), `·beyond_at_most` (N95, `·beyond` N94) | theorems | `·count.recursor` at level 0 twice; `·false_elim`, `·no_is_not_yes`, `·yes_is_not_no` |
| `·zero_add` (N103), `·successor_add` (N106), `·add_associative` (N113), `·zero_multiply` (N143) | theorems | `·count.recursor` at level 0, `equal_congruent` with `·count.successor` |
| `·add_commutative` (N109), `·add_swapped` (N116), `·successor_multiply` (N146) | theorems | `·count.recursor` at level 0 and the glue laws; add_swapped from add_associative and add_commutative alone |
| `·at_most_add` (N123), `·at_most_difference` (N129, `·difference_at` N128), `·add_cancel` (N139) | theorems | `·count.recursor` at level 0; at_most_add rewrites by Equal's recursor, add_cancel by `·predecessor` |
| `·divide_and_remainder` (N160, `·divides_back` N159), `·divide_by_zero` (N171), `·remainder_below` (N174) | theorems | `·count.recursor` at level 0, `·bool_cases`, `·equals_sound`, `·at_most_step` |
| shortcut divide (N180) | `shortcut_bound` | the three theorems above |

That is 12 definitions, 5 helper propositions (sound_at, steps_up, beyond, difference_at, divides_back) and 31
theorems. All are checked as declared, and none is an axiom.

### int (N184–N232, recast)

| name | kind | by |
|---|---|---|
| `int` | fills core's `int` word (A1's fill in place) with `enum int { natural(n: ·count); negative(n: ·count) }`; its cases are core's, named `int.natural`, `int.negative` (not bare as bool's truths, so no program's `natural` or `negative` meets them) | block |
| `·ups`, `·downs` | definitions, new: an int's two counts, `x == ups(x) − downs(x)`: natural(n) → n, 0; negative(n) → 0, successor(n) | int's recursor at level 1, two arms each |
| `·difference` (N191, rewritten) | definition: m − n of two counts in its one form: `subtract(n, m)` is successor(k) → negative(k); else `subtract(m, n)` is zero → natural(zero), successor(k) → natural(successor(k)) | count's recursor twice |
| `·minus` (N193, rewritten) | definition: natural(n) → `0 − n` (zero → natural(zero), successor(k) → negative(k)), negative(n) → natural(successor(n)) | int's recursor, two arms, one through the count's recursor |
| `·sum`, `·times` (N197, N210, rewritten) | definitions by the two counts: `sum(a, b) := difference(ups(a) + ups(b), downs(a) + downs(b))`, `times(a, b) := difference(ups(a)·ups(b) + downs(a)·downs(b), ups(a)·downs(b) + downs(a)·ups(b))` | `·add`, `·multiply`; no case arms. `·size`, `·negative`, `·turned` (N206–209) are not needed and go |
| `·equal_integers` (N213, rewritten), `·not_above` (new) | definitions: `count_equals(ups(a) + downs(b), ups(b) + downs(a))` and `count_at_most(` the same two `)` | no case arms (section "The comparisons") |
| `·subtracted` (N218), `·unequal` (N220) | definitions, as in the prelude | `·sum`, `·minus`, `·negated` |
| `·below`, `·above`, `·not_below` | definitions, new: `not_above(a + 1, b)`, `below(b, a)`, `not_above(b, a)` | `·not_above` |
| the rows' meanings | each row constant `prim i64.<op> int -> … ` declared Defined as its function: add ·sum, sub ·subtracted, mul ·times, sub(0, x) ·minus, eq ·equal_integers, ne ·unequal, le_s ·not_above, lt_s ·below, gt_s ·above, ge_s ·not_below | core/analyze/terms.wap's `row_term` then finds them declared |
| a numeral | `term_of` writes k ≥ 0 as `int.natural(k)` and k < 0 as `int.negative(−1 − k)`, the payload a count literal | replaces today's bare `numeral(value)` |
| `·parts_back` (new) | theorem: `difference(ups(x), downs(x)) == x` | int's recursor at level 0, two arms, each by computation |
| `·difference_equal` (new) | theorem: `m + q == p + n → difference(m, n) == difference(p, q)` | count's recursor, `·zero_subtract`, `·subtract_successors`, `·add_cancel` |
| `·equal_integers_itself` (N230, rewritten) | theorem | `·equals_itself(ups(x) + downs(x))`, no case split |
| `int.successor`, `int.predecessor`, `·successor_sum`, `·predecessor_sum` and the two step theorems | definitions and theorems by cases (section "int's step functions") | int's recursor, count's recursor in one arm |
| `·equals_sound`, `·equals_complete` for int | theorems (section "The bridge") | as there |

Division on int (`i64.div_s`, `rem_s`) gets no meaning yet: the prelude had none for int. Those rows stay opaque,
so a law dividing an int computes only on literals, which `row_step` folds.

**One change to the decided placement.** int cannot be declared in wap/types: its cases' payload `·count` has no
name wap can write. So int, its functions and the rows' meanings are core_environment's (int_declared), and wap/types
keeps only types/integers.wap's laws, stated in wap over int's operators. Cost: kernel and core about +95 lines of
declarations (count_declared about 45, copied; int_declared about 50, rewritten for the two cases and with the step functions). No new
mechanism.

### int's two cases: the cost

The deleted prelude's int had Lean's two cases, `of_nat(n) | negative_successor(n)`, as the kernel's now has
(`natural | negative`). Written **by cases**, each binary function goes from 2 arms to 2×2 and its proofs to 4 cases.
The kernel's functions go **by the two counts** instead, so every binary function is one line over `ups` and `downs`:
`sum(a, b) := difference(ups(a) + ups(b), downs(a) + downs(b))`, `times`, `equal_integers` and `not_above` likewise.
Only `ups`, `downs`, `minus`, `difference` and `parts_back` see the cases, two arms each.

- equals_sound's proof is a double split of 4 cases: 2 mixed by apart, 2 like by `count_equals_sound` (natural) or
  `count_equals_sound` after the shift by zero's add (negative), each mapped under the case.
- **What it costs in computing.** A sum of two literals computes through `difference` and the count's shortcuts,
  since the payloads are count literals. A sum over a variable does not compute to a case by itself:
  `natural(k) + 1` needs `successor_sum`.
- **What does not change.** linear.wap reads `sum`, `minus`, `not_above` and `equal_integers` as opaque Defined
  constants and never their arms.

### int's step functions: successor and predecessor

int has the step functions `successor` and `predecessor`, with `next` and `previous` as aliases: `next(3)` is 4 and
`previous(0)` is −1. Their kernel meanings are int_declared's definitions by cases:

```
int.successor(x)    natural(n) → natural(·count.successor(n))
                    negative(n) → n by count's cases: ·count.zero → natural(zero); ·count.successor(k) → negative(k)
int.predecessor(x)  negative(n) → negative(·count.successor(n))
                    natural(n) → n by count's cases: ·count.zero → negative(zero); ·count.successor(k) → natural(k)
```

- **The two step theorems** are proved by cases, not given as constructor rules:
  `int.successor(int.predecessor(n)) == n` and `int.predecessor(int.successor(n)) == n`.
  - Each goes by int's recursor at level 0, with count's recursor at level 0 in the one arm that steps across zero
    (negative for the first, natural for the second).
  - Every arm then computes to n, so each arm's proof is refl.
  - No induction hypothesis is used, so the provers' apart and computing find them as they are.
- **The program's words.** types/integers.wap writes them as plain wap:
  ```
  successor(x: int): int := x + 1
  predecessor(x: int): int := x - 1
  next(x: int): int := successor(x)
  previous(x: int): int := predecessor(x)
  ```
  Each runs as one i64 operation. Their kernel values are `sum(x, natural(·count.successor(·count.zero)))` and the like.
  - Two theorems join them to the definitions by cases: `·successor_sum: x + 1 == int.successor(x)` and
    `·predecessor_sum: x + −1 == int.predecessor(x)`, each by int's cases. The natural arm of successor_sum is
    `natural(k) + 1 == natural(·count.successor(k))`, through `·zero_subtract`.
  - The wap laws `law next_previous(n: int): next(previous(n)) == n` and `law previous_next(n: int): …` go into
    integers.wap's list. Each is proved by the two join theorems and the step theorem.
  - The definitions by cases are what the theorems and nat's induction are about, and the wap function is what runs.
- **The names never meet.**
  - The count's constructor is `·count.successor`, and its inverse is `·predecessor`. Both carry the mark `·`, so no
    program can write them.
  - int's step functions are `int.successor` and `int.predecessor`, dotted under int as its cases are.
  - The program's words `successor`, `predecessor`, `next` and `previous` are types functions.
  - In the kernel these are three different names, so none is found in place of another. A program that writes
    `successor(3)` meets only the types function. wap/types and lib hold no other `successor`, `predecessor`, `next`
    or `previous` word today.
  - Open, decided by the plan's default here: the wap words are not core's case definitions themselves. Giving a
    core definition a runtime body would need a mechanism that does not exist (only `prim` rows join a host
    operation to a kernel meaning). So the join theorems carry the link, with no new mechanism.
- **Lines.**
  - int_declared: about +16 (the two definitions 2 each, the two step theorems 3 each, the two join theorems 3 each).
    Net about +16.
  - types/integers.wap: +4 functions and +2 laws.

## linear.wap over int only

The nat structure and the nat LAWS list go. `Sums` holds int's functions, found as the Defined values of the rows
`i64.add`, `i64.le_s` and `i64.eq` at `int -> int -> int` (core/analyze/terms.wap `row_name`), so no function name is
written twice.

- **Numbers read.** `natural(k)` is k and `negative(k)` is −k−1, k a count literal or built
  from count's zero and successor. This is the one place the count appears in linear.wap, and only because it is int's payload. Numbers are
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
  `a + d == b` (`sum_difference`) and `0 <= d` (`difference_nonnegative`). An equation's d is `int.zero`.
- **The gap.** `eliminated` returns `t + gap == u` as today, the gap a sum of the used bounds' d's and a literal
  of at least 0. With it comes `0 <= gap`, built by `nonnegative_sum` from each d's proof and the literal's
  computation. `at_most_from` uses `not_above_add(t, g, h: 0 <= g): t <= t + g`.
- **`not (a <= b)`.** It is read through `beyond_not_above` as `b + 1 <= a`.
- **Equality goals through bool.** `proved()` reads a `made_yes` goal only as at_most. Add one branch:
  `equal_integers(l, r) == yes` is `equal_proof(l, r)` carried to `equal_integers(l, l) == yes` by
  `equal_integers_itself`. `regrouped` needs this.

The law names stay one list (LAWS), checked present by `sums_of` as today.

## The comparisons, one function over the two counts (int_declared)

```
not_above(a, b)   := count_at_most(ups(a) + downs(b), ups(b) + downs(a))      a − b <= 0, over the two counts
equal_integers(a, b) := count_equals(ups(a) + downs(b), ups(b) + downs(a))
below(a, b)       := not_above(a + 1, b)
above(a, b)       := below(b, a)
not_below(a, b)   := not_above(b, a)
```

Each row keeps its meaning (`i64.le_s` is not_above, `i64.lt_s` below, and so on). Every comparison is then the one
`<=` the prover reads. A `<` goal or hypothesis is a `<=` of `a + 1`, which makes `lt` (`x < x + 1`) a gap of 0. The
count_at_most and count_equals inside are part of the payload: they appear only in the proofs of the int lemmas
below. On literals both compute through the count's shortcuts, the same as a case split would.

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

Recommended proof route: an int is a difference of its two counts, which is how the functions are defined.
- `parts_back`: `difference(ups(x), downs(x)) == x`, by int's cases, each by computation.
- `difference_parts`: `ups(difference(m, n)) + n == downs(difference(m, n)) + m`, by count's recursor.
- `difference_equal`: `m + q == p + n → difference(m, n) == difference(p, q)`.

Then the sum laws become: unfold sum to `difference(ups … , downs …)` and rewrite the inner sums' counts by
`difference_parts`. A goal `difference(m, n) == difference(p, q)` then goes by `difference_equal` to a count
equation, which the count's add laws finish. The comparison laws go the same way to the count's at_most laws, with no
case split on a or b. These
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

Their proofs go through the hidden count (count_equals_sound, difference_equal, parts_back), so int_declared
declares both, as checked theorems, never axioms, and `e.integers` names them. T6a3a (notes/coc-t6a.md "How wap
source states a proposition") gives the statements a wap spelling, `h: (a == b) == yes` against `a == b`, but
the proofs stay core's. The same function serves any enum whose `==` decides it (bool's own `==`
included), so it is written once over the type and its equality function.

- **complete** is Equal's recursor: rewrite b to a in the goal (`rewritten`), leaving `equal_integers(a, a) == yes`,
  which is `equal_integers_itself`. That law is `count_equals_itself(ups(x) + downs(x))`, with no case split.
- **sound** needs no case split on a or b. `equal_integers(a, b)` is `count_equals(ups(a) + downs(b), ups(b) + downs(a))`.
  `count_equals_sound` (count's recursor on both, the mismatched cases by apart over bool) gives the count
  equation. `difference_equal` turns it into `difference(ups(a), downs(a)) == difference(ups(b), downs(b))`, and
  `parts_back` on each side gives `Equal(int, a, b)`.
  - The mismatched cases inside count_equals_sound are the step that needs bool as a block (t5b-enums). There the
    hypothesis is `Equal(bool, no, yes)`, and apart's chooser is the recursor of the equation's type,
    `case_recursor(bool)`, choosing the goal at no and anything at yes.
  - By int's cases instead, sound takes 4 cases: 2 mixed by apart and the 2 like cases by `count_equals_sound` and
    `equal_congruent` with `int.natural` or `int.negative`. See "int's two cases".

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
- The provers read `n_holds` like any hypothesis. With the comparisons as one function, `n >= 0` is `not_above(0, n)`, so
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

## The rest of M2b: linear.wap onto int, name by name

Everything linear.wap reads of nat today (unify-typers 3a0742ef), with what replaces it. All of it rests on
core's int_declared (section "count_declared and int_declared").

### What replaces e.numbers

int_declared sets `e.integers`, a kernel record beside `e.literals`, as numbers_declared set `e.numbers`:
`Integers { type; zero; natural; negative; sum; minus; not_above; equal_integers; equals_sound; equals_complete }`,
each a constant (kernel +about 8 lines). `sums_of` builds Sums from it:

```
class Sums { c: Checker; i: Integers }      # was: c, n: Numbers, nat, add, at_most, equals, subtract
```

The row constants a law's body holds (`prim i64.add int -> int -> int`) are Defined as these functions, so
`unfolded_until` reaches `sum`, `not_above` and `equal_integers` from them as it reaches `add` today.

| linear.wap today | after |
|---|---|
| `s.nat` (11 places: hypotheses' types, equations, congruences) | `s.i.type` |
| `s.n.zero`, `zero_of(s)` | `s.i.zero`, `natural(·count.zero)` |
| `s.n.successor` (normal :303, beyond :147) | gone: `b + 1` is `added(s, b, int_numeral(s, 1))` |
| `numeral(v)` (:252, :345–349, :383) | `int_numeral(s, v)`: `natural(v)` for v ≥ 0, else `negative(−1 − v)` |
| `normal`'s Numeral, zero and successor cases, `is_sum_part` (:300–303, :326–327) | `natural(lit)` → lit, `negative(lit)` → −lit−1, a sum, and `minus(t)` → t's Normal with each atom's minus and the number negated, by `minus_add` and computing |
| `s.subtract`, `with_differences`, `differences_in`, `difference_bounds`, `linked`'s difference branch (:180–205, :316) | gone: `a - b` unfolds to `sum(a, minus(b))` |
| the unit rows `0 <= atom` in `eliminated` (:248) | gone: an atom's lower bound comes from a hypothesis only |
| `s.n.truth`, `yes_case`, `no_case`, `equality`, `equation()`, `truth_stated()` | `e.literals` and core's `equated` (kernel/equality.wap) |

### The laws, role by role

A law of integers.wap concludes with a bool `==` or `<=`. Its kernel theorem states `Equal(bool, …, yes)`. A
comparison's conclusion is already the `truth_stated` form linear.wap reads. An equation's is carried to
`Equal(int, l, r)` by `equals_sound` from `e.integers`, and an int equation going into a hypothesis goes back by
`equals_complete`. One helper does both, `law_equal(s, name, given)` = `equals_sound(l, r, law(s, name, given))`.

| role in linear.wap | nat law | int replacement | how it is used |
|---|---|---|---|
| ZERO_ADD | zero_add | integers.wap `zero_add` | through `law_equal` |
| ADD_ASSOCIATIVE | add_associative | `add_associative` | through `law_equal` |
| ADD_SWAPPED | add_swapped | `add_swapped` | through `law_equal` |
| ADD_CANCEL | add_cancel | `add_cancel` | its h is `equals_complete(chain.proof)`; its conclusion through `law_equal` |
| AT_MOST_DIFFERENCE | at_most_difference (a <= b → a + (b − a) == b) | `add_difference` (a + (b + −a) == b, no hypothesis) and `difference_nonnegative` (a <= b → 0 <= b + −a) | `bounds_of` for `a <= b`: `Bound(a, b + −a, b, law_equal(add_difference), nonnegative: difference_nonnegative(a, b, h))`, a new Bound field |
| AT_MOST_ADD | at_most_add (t <= t + k) | `gap_bound` (0 <= g → t + g == u → t <= u) and `nonnegative_add` | `at_most_from`: `gap_bound(t, gap, u, nonnegative, equals_complete(gap.equated.proof))`, where nonnegative folds the used bounds' `nonnegative` proofs and the kept literal's (computed) by `nonnegative_add`; `carried` is no longer needed there |
| EQUALS_SOUND | equals_sound | `e.integers.equals_sound`, core's | `bounds_of` for `(a == b) == yes`, and `law_equal` |
| BEYOND_AT_MOST | beyond_at_most | `beyond_not_above` (not (a <= b) → b + 1 <= a) | `bounds_of` for a negation, as today |
| CHOSEN_DECIDED, CHOSEN_AT_YES | chosen_* (a choice between propositions) | `both_first`, `both_second` (h: a and b) | a hypothesis `(a and b) == yes`, read where `made_yes` meets a choice whose part at no is `no`: replaces `chosen_bounds`'s Prop reading. `chosen_proof` for a goal `(a and b) == yes` proves a and b, then builds it by computing (a and b computes to b once a is yes) |
| SYMMETRIC, TRANSITIVE, CONGRUENT | equal_* | kernel/equality.wap's, same names | unchanged, at `s.i.type` |
| (new) | — | `add_minus` (x + −x == 0) | the bound `atom + minus(atom) == 0` for each minus atom, through `law_equal` |
| (new) | — | `minus_add` (−(a + b) == −a + −b) | `normal` pushing minus inward, through `law_equal` |

The law names are looked up as theorems. law_proved declares a law's proof as `name + LAW_HOLDS` (laws.wap:30), so
declare it under the law's own name instead, as a law is used by calling it (wiki/proof.md). Then
`law(s, "zero_add", …)` finds it.

### Where integers.wap's laws get proved

verify types the program's laws, not the types module's. The provers prove integers.wap's 14 laws once per run,
before the program's (laws.wap: the library's `law_` functions taken like the program's, about +8 lines). They do it
by computing, apart and induction over int's cases with the count's theorems, never by linear. A law the provers do
not prove is no theorem, and the linear prover's `sums_of` refuses with the missing names (today's
`missing`-check), loudly. The 7 with hypotheses need the hypothesis Π first (section "A nat binder's condition…").

### Steps and line counts

| step | what | lines | gate |
|---|---|---|---|
| 1 | bool's block, count_declared, int_declared with `e.integers` (wap-theory-reads-types) | core and kernel +about 105 | test_hello, test_law_runs unchanged |
| 2 | hypothesis Π and binder conditions in law_statement; integers.wap's laws proved first, declared by name | laws.wap +about 25 | the 14 laws Proved by verify on integers.wap alone |
| 3 | Sums over int: reading, writing, minus atoms, no differences, no unit rows | linear.wap about −40 +35 | `regrouped` Proved |
| 4 | bounds: the role table, the Bound's nonnegative proof, gap_bound, both_* | linear.wap about −15 +30 | `lt` Proved; test_theory_arithmetic's five with `h:`; law_runs 11–15 |
| 5 | bool equality goals by `equals_complete` and `equal_integers_itself` | linear.wap +about 6 | test_theory_connectives' `==` laws |

linear.wap net about +15 (416 → about 430); laws.wap about +25; core and kernel about +105 (step 1). No reds are
expected along the way. Since the deletion, linear.wap proves nothing (`sums_of` finds no `e.numbers`), so nothing
green depends on it.

## Exact int literals past 2^63: a kernel step after M2b

### What stops at 2^63 today, and where

The limit sits in three layers. The kernel alone would not turn `4294967296 * 4294967296 == 18446744073709551616`
green:

| layer | what it does past 2^63 |
|---|---|
| the reader, core/parse/atoms.wap:134 `whole` | a literal past `LARGEST_INT` reads as a `number`, a float: the law's right side is no int at all |
| the runtime | int is i64 and wraps (`lib/exact.wap`'s header: "int(x) … wraps as ints do"); exact runtime int is T8 |
| the kernel | `Numeral(value: int)` (terms.wap:95) holds an i64; the count's shortcuts fire only while the result fits (numbers.wap:24 `LARGEST`, :220–222, :273 `successor_of`); a row's fold refuses past it (compute.wap:72 `ROW_OVERFLOW`, primitives.wap:76–94) |

The kernel held unbounded numbers once, through lib/magnitude.wap. 452176cb moved it to i64 ("magnitude leaves the
kernel"). The second checker still reads magnitude, and magnitude's header still says the kernel trusts it.

### The kernel's part

- **A numeral holds a count, so it is never negative.** A program's negative int is `int.negative(k)` with k ≥ 0
  (int_declared). So the unbounded value needs no sign: lib/magnitude.wap's `Magnitude` (limbs of 10^9, one spelling
  per number; sum, difference of a ≥ b, product, divided, compared, digits) is exactly what a count literal needs.
- **The representation, recommended: small stays small.** `Numeral(value: int)` stays the shape for every count below
  2^63, which is every count a program and the census meet today, and keeps today's speed, which is why 452176cb left
  magnitude. A new shape `Large(value: Magnitude)` holds a count at or past 2^63, and only there, so each number has
  one spelling. `whole_of(t): Magnitude?` reads either shape, and `count_literal(m)` writes a Numeral where m fits,
  else a Large.
  - The other options: (a) every Numeral a Magnitude, which is simpler but slows every literal; (b) a Large built from
    small numerals as a term (`q · 2^62 + r`), which needs its own normal form and is a magnitude spelled worse.
- **What changes:**
  - terms.wap: the shape, its constructor and its hash (+4).
  - equal.wap and terms.wap's `same`: Large against Large by `compared` (+3).
  - show.wap: `digits` (+1).
  - typing.wap `numeral_rule`: a Large is a count (+1).
  - numbers.wap: the Add, Multiply, Subtract, Equal, AtMost and Divide shortcuts compute through
    `whole_of`/`count_literal` when a result passes 2^63, instead of returning ø, and `LARGEST`'s guards and
    `successor_of`'s limit go (+18 −8).
  - `use magnitude` in numbers.wap: a library module the compiler already compiles, as core uses `folder`. No copy of
    its arithmetic.
  - Kernel about +30 net. magnitude.wap itself unchanged (121 lines, already trusted).
- **ROW_OVERFLOW stays until T8.** A row is the host's i64 operation. While the runtime wraps, a kernel that computed
  a row exactly past 2^63 would prove what the run then breaks. After int_declared the rows that matter are Defined
  as int's functions over the count, which are exact. For those, the kernel's meaning is the wiki's exact int, and the
  runtime's wrap is T8's own red. The fold of an opaque row (int division) keeps its guard until T8.

### Its order

- **After M2b step 1, not before.** count_declared and int_declared work with counts below 2^63, and nothing in M2b
  needs a larger literal: the provers' coefficients and the tests' laws are small. A Large first would only add a
  shape the count block's literals must also handle, before that block exists.
- **With T8, or after it.** The kernel step makes the kernel exact, but `big` stays red until the reader keeps the
  digits (atoms.wap `whole` → an int, not a float) and the runtime int is exact. Recommended: one T8 card holding all
  three layers, the kernel's part being the +30 above. The `big` test line's red names that card.

## Steps, each with its outcome

1. **int's meaning in wap/types.** wap-theory-reads-types writes the enum and the rows' meanings. The comparisons by
   cases above come with it, or follow at once. Gate: `lt` and `small`, `neg`, `square_minus` prove.
2. **The int lemmas.** Gate: each is accepted by the kernel.
3. **linear.wap over int.** The reader, minus atoms, bounds with their two proofs, the gap's nonnegativity; nat's
   instance and LAWS out. Gate: `regrouped` proves, law_runs 11–15 hold, and test_theory_arithmetic, test_induction
   and test_verify show no line that was green going red.
4. **Bool equality goals.** Gate: test_connectives and a `==` law over int.
5. **Induction and apart over int.** The recursor gives two cases, natural and negative,
   each with a count field. A law over one int binder
   that needs induction under a case takes depth 2, which INDUCTION_DEPTH allows. Check one such law, and raise the
   depth only if a target line needs it.

Measures to report (track T has no limits): linear.wap's net lines (nat's parts out, int's in; about +20 net),
wap/types' lemmas (about +90), the rest of prove/ 0, and prover time on the target tests before and after.

## Not part of M2b

typed_laws.wap, file.wap, read.wap, the front, `type nat = int where it >= 0`, and hypothesis binders.
