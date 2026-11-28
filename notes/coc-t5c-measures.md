# T5c5, recursion that ends by a measure: how it is built

coc-plan.md 9.3 step 2. A recursive function that is not structural (coc-t5c3.md) and follows no guard on its count
(coc-t5c4.md) ends where a natural number computed from its arguments falls at every call. The default is the sum of
the arguments' sizes; `decreasing m` after the body names another. That it falls is an obligation for the provers. The
term recurses structurally on a bound for the measure, so it computes in the kernel as fast as the function
recurses. Where no measure falls, or the provers find no proof, the function stays Div and runs as written (9.3
step 4).

## What is there to build on

- **Courses** (core/analyze/courses.wap): `E.below` and `E.course` made from an enum's recursor the first time a
  recursion asks; the same pattern makes the sizes.
- **The recursion's reading** (core/analyze/recursion.wap): `course_defined` reads a match or a guard as a course,
  `recursive_called` reads a call of the function as a hypothesis among the values below, `Recursion` holds what the
  reading is inside of.
- **The count** (kernel/counting.wap): `·count` with zero and successor, `·at_most(m, n)` a bool, and the laws on it
  the provers declare (extensions/prove/integer_laws.wap): `·at_most_below` (succ i ≤ j → i ≤ j), `·at_most_add`,
  `·at_most_split`, `·at_most_step`. int is natural | negative of a count (int-takes).
- **The provers** (`hole_term(laws, goal, x)`): a proof of a goal under the reading's binders, or ø.
- **Logic** (kernel/logic.wap): `·false_elim`, `·no_is_not_yes`, `·bool_cases`.

## The parts

1. **Sizes.** Each enum taken apart into any universe gets `E·size(v): ·count` from its recursor, made the first time
   a measure asks (as below and course): a case is one plus the sizes of its fields of a type of the block, a
   container's (list<Tree>) one plus its items' sizes, through the nested motives (nested-inductive). int's size is
   its count's (natural(n) is n, negative(n) is n + 1), a count's itself, any other type's zero. courses.wap +25.
2. **The default measure.** The sum of the parameters' sizes, `·add` over them. recursion.wap +6.
3. **The term.** With μ the measure as a function of the parameters P and R the result:
   - `F = ·count.recursor(k => (P) -> at_most(successor(μ(P)), k) == yes -> R, zero_arm, step_arm)`
   - `zero_arm(P, h)`: h says `at_most(successor(μ), zero) == yes`, which computes to `no == yes`:
     `false_elim(R, no_is_not_yes(h))`.
   - `step_arm(k, ih, P, h)`: the body read with the function's own name standing for ih: a call `f(A)` is
     `ih(A, ·at_most_trans(successor(μ(A)), μ(P), k, o, h'))`, h' being h at `successor(k)`, which computes to
     `at_most(μ(P), k) == yes`, and o the provers' proof of `at_most(successor(μ(A)), μ(P)) == yes`.
   - the function: `(P) => F(successor(μ(P)), P, ·at_most_same(successor(μ(P))))`.
   recursion.wap +40 (`measured_defined`, the call read in `recursive_called` from a `Measured` beside `Recursion`).
4. **What the provers see.** A call's obligation is proved under the conditions of the `if` arms around it: inside a
   measured recursion an `if` on a bool is read by `·bool_cases` with its premise bound (as `cases_term` reads a
   proof's choice), its motive the constant result type. terms.wap +10.
5. **Two count laws** (extensions/prove/integer_laws.wap, by paired_law): `·at_most_same(n): at_most(n, n) == yes`
   and `·at_most_trans(a, b, c): at_most(a, b) == yes -> at_most(b, c) == yes -> at_most(a, c) == yes`. prove +12.
6. **`decreasing m`.** After the body, `f(n, m) := … decreasing m + n`: the measure written, a count or an int (its
   size), read under the parameters. A wiki passage first (wiki/effects.md "Div" names the measure; the spelling
   goes to the interviewer with this plan), then a sugar rule writing it as a fact on the Define. sugar +2, recursion
   +3.
7. **Recursion through map** (nested-courses' second half). `xs.map(f)` with xs a container field of the case taken
   apart, inside f's own body: the call `f(x)` for each item needs `size(x) < size(v)`. The library's map gets a twin
   that hands each item with the proof it is a member, `xs.attach()` (Lean's List.attach): list<(x: T, x ∈ xs)>; the
   reader writes `xs.map(f)` in a measured recursion as `xs.attach().map(((x, h)) => f(x))`, and the obligation
   `size(x) < size(v)` from `x ∈ xs` and xs a field of v is a law of sizes, `·member_smaller`, by induction on the
   list. types +8 (attach), prove +10, recursion +8.

## The estimate

core about +75 (courses +25, recursion +57 with the call reading, terms +10, minus the sharing), sugar +2, prove +22,
types +8.

## Outcome lines

- `gcd(a: nat, b: nat): nat := if b == 0 then a else gcd(b, a % b)` with `law g: gcd(12, 18) == 6 := refl` proved
  and `effects of gcd` Pure: a measure (the default, a + b falls since a % b < b) the provers prove with the arm's
  premise `b != 0`. wiki/effects.md "Div".
- `ackermann` by `decreasing` a pair is out of reach (a tuple measure, 9.3's lexicographic order): Div, runs.
- A function moving away keeps Div and runs (test_effects, from T5c1).
- A tree of a list of trees counted through `children.map(count)` is Pure and `law` computes it (part 7).

## Open

- The spelling `decreasing m` and where it stands (after the body, as `! Pure` does) is the interviewer's.
- A tuple measure (lexicographic) is left to a later step; a written tuple is refused until then.
