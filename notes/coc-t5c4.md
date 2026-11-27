# T5c4: recursion over whole numbers

coc-t5c.md's T5c4 row covers a recursion over nat or int that enters the kernel as a definition: by nat's two cases
in a `match`, by `nat.recursor`, or by a guard (`if n <= 0 then … else … f(n - 1)`). It builds on T5c3
(notes/coc-t5c3.md) and on int-takes' Lean shape, `int = natural(n: ·count) | negative(n: ·count)`. Read on
int-takes b75d1257.

## What T5c3 already gives, and what is new

- **count's recursion is T5c3's enum case, unchanged.** `·count` is a kernel enum with one recursive field.
  `course_of(·count)` makes `·count·below` and `·count·course` as for any program enum, the calls are read from below
  by T5c3's rule, and the other parameters ride as there.
- **New is the int layer above it.** A program never holds a count; it holds an int. T5c4 reaches the count inside a
  subject in three ways, each a reading in core, none a kernel form:
  1. nat's cases in a match. On a `nat` subject (`int where it >= 0`), the arms `zero` and `successor(k)` are int's
     split, then count's split in the natural arm, with k bound as `natural(c)`, c the count's field.
     - The negative arm is ruled out by nat's condition, so a definition gives it the zero arm's value.
     - A proof needs that arm proved instead: that is nat's induction theorem (unify-provers.md "nat's induction"),
       which is T6a4's.
  2. Calls through `natural(field)`. A call `f(k)` with k `natural(c)` and c a field below is the hypothesis for c.
     This is T5c3's rule seeing through the one constructor.
  3. Guards (`choice_by_cases`, ported from main's history: 25046c0f:wap/extensions/theory/elaborate/conditions.wap
     :65-104, `choice_by_cases`, `within_parameter`, `waiting_on`). Inside a recursion, an `if` whose condition's
     computing waits on a parameter becomes a split of that parameter, with the `if` again in every arm, until the
     condition computes. `n <= 0` on an int splits n by int's cases, then the natural arm's count by count's cases.
     The condition then computes in every arm:
     - negative → yes;
     - natural(zero) → yes;
     - natural(successor(c)) → no.
     In the last arm, `n - 1` must compute to `natural(c)`, so that `fact(n - 1)` is read as c's hypothesis.
- **One kernel reshape for (3).** `·difference` (counting.wap:162) splits its first count first (`paired(…, x#1)`), so
  `difference(successor(c), successor(zero))` waits on c and `n - 1` is stuck. Splitting the second count first,
  `difference(m, zero)` is `natural(m)` at once and `n - 1` computes to `natural(c)`. The definition stays one line
  (the zero arm `m => natural(m)`, the first arm `negative(k)`, both arms in place of from_zero). integer_laws.wap's
  `difference_parts` (:230-236) and the laws over difference are restated over the second count. It is Lean's
  `subNatNat` order.

## The forms, wiki passages and red lines

| form | wiki | red line today | after |
|---|---|---|---|
| `double(n: nat): nat := match n { zero => 0; successor(k) => double(k) + 2 }` | proof.md:10, enum.md:100-114 (the match is the recursor) | test_proof_wanted:5 (the definition the file's laws read) | a kernel definition by (1) and (2) |
| `law double_three: double(3) == 6 := refl` | proof.md:38-39 ("By computing") | test_proof_wanted:11 | green: `double(3)` computes, and numeral 3 opens to successors (numbers.wap `opened`) |
| `nat.recursor(0, (k, double_k) => double_k + 2, 3)` is 6, and `recursive_double(n) := nat.recursor(…, n)` | enum.md:100-111 "The recursor" | test_proof_wanted:23, :24-25 | green: nat's recursor is plain wap in types/integers.wap, `recursor(base: T, step: (nat, T) -> T, n: nat): T := if n == 0 then base else step(n - 1, recursor(base, step, n - 1))`, a guard, so it runs before T5c4 (notes/coc-t5b4.md), found as `nat.recursor` by T5b5's dotted lookup of an enum's recursor, extended to a subtype's word |
| `fact(n) := if n <= 0 then 1 else n * fact(n - 1)`, `law fact(n) > 0`, `fact(4)` is 24 | law.md:35-44 (fact with its helper law) | test_laws_wanted:9-11 | `fact` a definition by (3). The line's value check `fact(4) == 24` is expected green; the builder confirms what makes it red today first. `law fact(n) > 0` stays Tested until V3 and the product law |
| `law double(n) == n + n` | proof.md:11 | test_proof_wanted:6 | Tested at once (the binders' trial values compute); Proved needs nat's induction (T6a4) |
| `double_even` by match with its own call | proof.md:17-18 | test_proof_wanted:8-10 | T6a4: the proof's negative arm needs nat's condition as a hypothesis |

## Estimate

| part | files | lines |
|---|---|---|
| (1) nat's cases in a match: the arm names read as count's under int's natural arm, k bound as `natural(c)`, the negative arm | analyze/terms.wap (beside T5c3's `course_term`) | core +25 |
| (2) a call through `natural(field)` | the same | core +10 |
| (3) choice_by_cases, waiting_on, within_parameter | analyze/terms.wap or analyze/recursion.wap | core +45 |
| `·difference` by its second count | kernel/counting.wap:162 (0), kernel/integer_laws.wap difference_parts and its uses | kernel about +5 |
| nat's recursor | types/integers.wap; T5b5's lookup for a subtype's word | types +3, core +3 |

Net: core about +83, kernel about +5, types +3. coc-t5c.md's row counted +45 for (3) alone. (1) and (2) are new: the
row was written when nat was an enum with its own zero and successor.

## Order

After T5c3 (the course term and the below reading), int-takes (the two cases), T5b4 (a match's term) and T5b5 (the
recursor's name lookup). T6c in coc-t5c.md's row is int-takes. Careful path: the reshape of `·difference` changes the
kernel's int, and the census and the provers' test lines (test_theory_arithmetic, test_induction, wap/test_law_runs)
must not drop.
