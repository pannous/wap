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

- **A guard reads by the count's equations.** Lean's `n - 1` at natural(successor(c)) is subNatNat(c + 1, 1),
  whose definition waits on c. The guard reader computes with a checker that also rewrites a shortcut's function by
  its fixing statements (kernel equating, numbers.wap equation_fired), so it computes to natural(c). The terms it
  makes are checked by the ordinary kernel, which never rewrites so.
- **Dependent motives are not read.** In a recursion proving P(n), c's hypothesis is a P(c), and the call it
  stands for is a P(subNatNat(c + 1, 1)). The ordinary kernel does not convert the two, so such a declaration is
  refused. A function into data, `fact(n): int`, has one motive at every case and reads.

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
| `·difference` by its second count | kernel/counting.wap:162 (0), extensions/prove/integer_laws.wap difference_parts and its uses | kernel about +5 |
| nat's recursor | types/integers.wap; T5b5's lookup for a subtype's word | types +3, core +3 |

Net: core about +83, kernel about +5, types +3. coc-t5c.md's row counted +45 for (3) alone. (1) and (2) are new: the
row was written when nat was an enum with its own zero and successor.

## Order

After T5c3 (the course term and the below reading), int-takes (the two cases), T5b4 (a match's term) and T5b5 (the
recursor's name lookup). T6c in coc-t5c.md's row is int-takes. Careful path: the reshape of `·difference` changes the
kernel's int, and the census and the provers' test lines (test_theory_arithmetic, test_induction, wap/test_law_runs)
must not drop.

## How nat's arms come into the language

`match n { zero => …; successor(k) => … }` on `n: nat`, with `type nat = int where it >= 0` (proof.md:10,
enum.md:100-113). Read on t5c4 554c1afd. There `match_term` (analyze/terms.wap:154) reads a match on a defined
enum's cases, and no nat is declared in wap/types yet.

Programs never see count. `zero` and `successor` must be words of nat, not of int's kernel enum.

| | (a) a sugar rewrite into a guard | (b) a typed reading on int's cases | (c) zero and successor as functions with inverse patterns |
|---|---|---|---|
| what it is | `match n { zero => A; successor(k) => B }` becomes `if n == 0 then A else { k = n - 1; B }` | the arms are int's split, then count's split under natural, k bound as `natural(c)` (this note's (1)-(2)) | types/integers.wap declares `zero: nat := 0` and `successor(k: nat): nat := k + 1`, each with its inverse. An arm whose pattern names a function with an inverse matches where the inverse gives a value, its fields bound to it |
| core | a rule cannot see types, so it needs a typed rewrite stage: a new mechanism, about +20, plus the rule (+3). It replaces (1)-(2) (−35) | +35, as estimated above | the arm's guard and binding from an inverse, about +12. It replaces (1)-(2) (−35). `zero` is a value arm, T5b4's literal arms |
| words of nat | the rule names `zero` and `successor`: a nat word in sugar | core names count's cases as nat's patterns: a library word in core, which the layers forbid | plain wap words in wap/types, with nothing in core or sugar naming them |
| siblings (`even(k)`/`odd(k)`, `xs.first`/`rest`) | a rule each | none | the same mechanism: `even(k: int): int := 2 * k` with its inverse `n ÷ 2` where `n % 2 == 0` |
| the kernel | the guard goes through (3), `choice_by_cases` | its own path, (1)-(2) | the same guard as (a), through (3) |
| proofs (T6a4) | the negative arm through (3)'s split, filled by apart from `n_holds` (coc-t6a4.md (4)) | coc-t6a4.md as written | as (a) |
| a new form | the typed rewrite stage | none | the inverse's declaration, which needs the user |

**Recommended: (c).** It is the general mechanism the arms ask for:
- the words stay library;
- the siblings come free;
- core is smaller than (b) by about 23 lines;
- the kernel needs one path, (3), for guards and arms alike.

It is a new form, so the spelling of the inverse goes to the user. The candidates:
1. `successor⁻¹(n: nat): nat? := if n > 0 then n - 1`, the inverse as a function named with ⁻¹, giving ø where the
   pattern does not match (recommended: plain wap, one function);
2. a `pattern` declaration, `pattern successor(k) of n: nat where n > 0 := k = n - 1`, beside the node patterns of
   pattern-matching.md:148-163.

**Until the user decides**, T5c4 builds (3) (guards) and the plain-wap `nat.recursor` as a guard (coc-t5b4.md). These
lines go green without arms: test_proof_wanted:23-25 and test_laws_wanted:9-11. The arms' lines stay red:
test_proof_wanted:5, and through it :6 and :8-10. (1)-(2) are not built: under (c) they would be deleted, and (c)'s
guard reuses (3).

**A finding on the run today.** A bare name in a pattern fits any value and holds it (kernel/forms.wap:56-59). So
`zero => 0` on an int binds a new `zero` and always matches. Under (c), a pattern name that is a defined value of the
subject's type (nat's `zero`) is that value. A name that might be either is refused with both readings named. That
refusal is part of (c)'s +12.
