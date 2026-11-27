# T5c, recursion that ends: how it is built

notes/coc-t5.md row T5c, after T5b (notes/coc-t5b.md). A function that calls itself is structural where every call is
on a part of a case it took apart, else ends by a measure, else has the effect Div and still runs (coc-plan.md 9.3,
wiki/effects.md "Div"). Line counts are `grep -vc '^\s*#'` on main f749f499.

## What is there to build on

- **After T5b:** a program's enums are kernel blocks with recursors (T5b2), a match on one is its recursor's case
  split with a constant motive (T5b4), and each function has an `effects` fact in which a call of itself, or of a
  function of its group, is Div (T5b1). core/analyze/terms.wap leaves a function that calls itself opaque: while it is
  being entered its own name finds no constant (`s.entering`).
- **The theory's way, to port:**
  - extensions/theory/below.wap (112): from an enum's recursor and the kernel's products (Pair, Unit), two
    definitions per enum, made the first time a recursion asks: `E.below(motive, v)`, the motive's values at every
    value below v as nested pairs ending in Unit, and `E.course(motive, step, v)`, the motive at v made by step from v
    and those values. A recursion may then call itself on any value below, a field's field too (`fib(j)` under two
    successors). Both are ordinary definitions the kernel checks.
  - elaborate/recursion.wap (86): while a definition's value is read its own name is its recursion. A match on one of
    its parameters takes the others into the motive, so they may change between calls (`riding`); a call whose
    argument at the matched place is a value below is that value's hypothesis from the course (`pairs_below`,
    `recursive_call_elaborated`); a call on anything else is refused by `recursion`, or the function is Div.
  - elaborate/match.wap `course_elaborated` (about 20): the match through the course.
  - elaborate/conditions.wap `choice_by_cases` and what it reads (42 of lines 60-113): inside a recursion an `if`
    whose condition waits on a parameter is read as a match on that parameter, so `if equals(n, 0) then 1 else n *
    fact(subtract(n, 1))` calls fact on the value below n (test/wap/test_theory_measures.wap, the "guarded bound").
  - declare.wap `run_body_kept` and `.unfolds`: the theorem that the constant equals its body as written.
- **What core has not:** the products. The kernel binds them (`environment.products`) from a `products(Pair, Unit)`
  statement only the theory's prelude makes.
- **What runs needs nothing:** the emitter runs a recursive function by its statements as written (coc-plan.md 9.7,
  coc-t5.md T5f). The kernel's term over the course is what types and proofs compute with; the equation between the
  two is believed and tested by the law run (T5f's rule), so T5c builds no `.unfolds` theorem.

## How a recursion is read

- **Its group:** functions that call each other are one group, found from the calls analyze chose (a strongly
  connected part of the call graph, callees first, as `instances_entered` already orders them). A group of one that
  calls itself is a recursion; a group of several is mutual recursion, Div (wiki/effects.md: "mutual recursion"),
  until mutual blocks of courses are wanted.
- **Structural:** the body is a match on a parameter of a filled enum (directly, or after lets), and every call of
  itself has, at that parameter's place, a value bound by an arm of that match or of a match nested in it on such a
  value (a field, a field's field). The term is `E.course(motive, step, v)`: the motive the function's type at v with
  the other parameters riding, step the match with each call read as its hypothesis among the values below. Every
  other argument may be anything.
- **A guarded bound on a whole number:** wiki/effects.md calls Pure a "self-recursion that shrinks toward a guarded
  base case", and wiki/law.md's `fact(n) := if n <= 0 then 1 else n * fact(n - 1)` is one. On an `int`, whose kernel
  definition comes with T6c, this is decided as an effect only: in the arm where the condition `p <= c`, `p < c` or
  `p == c` (or its mirror, `p >= c` with `p + k`) does not hold, every call has `p - k` at p's place, k a literal above
  0. Then the measure `p - c` falls at each call and is a nat in that arm, `int where it >= 0`, so the function is no
  Div. Its kernel term waits for T6c, where int is the numerals' type and nat's induction a theorem of wap/types:
  `choice_by_cases`' reading, ported, takes p apart by the nat cases its condition waits on (`zero` and
  `successor(k)`, the shapes of nat), and the function enters as a definition. Until then it stays assumed, counted
  with that reason.
- **Anything else** (a call on no smaller value, a `decreasing` measure nothing proves, recursion through a function
  value) keeps Div and runs as written. Div is never an error (9.3 step 4).

## The migration in landable sub-steps

All track T steps (coc-plan.md 14: measured, no limits). T5c2 and T5c3 change what the kernel holds for every
compile, so they take the careful path; T5c1 changes only the effects fact, the normal path.

| step | what | core / kernel / types lines (estimate) | deletes from extensions/theory | outcome lines |
|---|---|---|---|---|
| T5c1 ending as an effect | groups from the chosen calls; a recursion is no Div when it is structural or shrinks toward a guarded bound; mutual recursion and the rest stay Div | core +70 (analyze/ending.wap: groups +20, the structural test +25, the guarded bound +25); effects.wap −5 (its "a call of itself is Div" becomes the call of ending.wap) | none: the theory's `effects of` on its own spelling stays until A2 reads the fact (coc-t5b.md, decided) | wiki/law.md's `fact` with `effects of fact` printing Pure (coc-t5.md T5c row, test_effects_wanted); `f(n) := if n == 0 then 1 else f(n + 1)` and `effects of f` printing Div (wiki/effects.md "Div", the wap spelling of test_theory_measures' "moving away" line); a Div function still runs: `f(0)` is 1 |
| T5c2 products and courses | core declares the kernel's products itself (Pair and Unit as two blocks beside the literals, type_notation.wap `core_environment`); below.wap moves into core as analyze/courses.wap, `E.below` and `E.course` made the first time a recursion asks | core +100 (courses.wap +85: below.wap less its shape checks of a written Pair, since core builds them; products +15) | below.wap (112) moves, its readers (recursion.wap, match.wap, bindings.wap, erase.wap) import core's; the prelude's `products(Pair, Unit)` statement and bindings.wap's products binding go (about −30) | every test as before (test_theory_measures and test_theory_induction read core's courses) |
| T5c3 structural terms (plan: notes/coc-t5c3.md; the theory's recursion reading is ported from main's history, since unify-typers deletes it) | a structural recursion enters the kernel as a definition: its term the course of its match, calls read as hypotheses, the other parameters riding | core +80 (terms.wap: a function entered while it is being entered gives its recursion +15; `course_term`, the riding parameters and the calls read from the values below +65) | elaborate/recursion.wap's reading of a program's recursion: `place_of`, `riding`, `course_below`, `pairs_below`, `below_of`, `recursive_call_elaborated` move into core and the theory calls them (about −60 there, +0 twice); match.wap `course_elaborated` (about −20) | an enum of the program, `enum Tree { leaf, node(left: Tree, right: Tree) }`, `leaves(t: Tree): int := match t { leaf => 1; node(l, r) => leaves(l) + leaves(r) }`, `law four_leaves: leaves(node(node(leaf, leaf), node(leaf, leaf))) == 4` printing `four_leaves: Proved` (test_law_runs, new; wiki/law.md "Checking a law" and wiki/proof.md "A proof computes and ends"); the census counts the compiler's structural recursions as defined (a list walked by its cases); `effects of leaves` is Pure |
| T5c4 guarded bounds as terms (plan: notes/coc-t5c4.md; T6c is int-takes) | after T6c (int the numerals' type, nat `int where it >= 0` with its induction in wap/types): `choice_by_cases` ported into core, so `fact` and `fib` over whole numbers enter as definitions | core +45 (analyze/ending.wap's guard as a match by the cases the condition waits on) | elaborate/conditions.wap `choice_by_cases` and its helpers (about −42) | test_proof_wanted's `law double_three: double(3) == 6 := refl`; test_theory_measures' `fact(4) == 24` and `fib(10) == 55` lines in wap spelling, `law r: fact(4) == 24` Proved |

Order: T5c1 right after T5b1 (it needs only the effects fact and the chosen calls, no enum); T5c2 and T5c3 after
T5b4; T5c4 after T6c. The measures by `decreasing m` and accessibility (9.3 steps 2 and 3) need the provers for their
obligations, so they come with T6's laws; until then such a function is Div.

## The estimate

T5c as a whole: core about +290 (+65, +100, +80, +45), kernel 0, types 0; the extension about −150 (−30, −80, −42)
with below.wap (112) and most of recursion.wap moved into core rather than written twice. Against coc-t5.md's T5c
row (+120, recursion.wap −117): the courses (+85) were not counted there, being the theory's; T5c4 (+45) is the
guarded bound, which the row's `effects of fact` line implies; T5c1's ending test is new, since the effects are new
in T5b.

## Gate

T5c is done when:
- the outcome lines of T5c1 to T5c3 are green (T5c4's lines with T6c);
- the census counts every recursion of wap's source as defined, Div with a reason, or assumed waiting for T6c (a
  guarded whole-number bound), each counted, and the defined instances ratchet does not fall;
- below.wap and the reading of a program's recursion exist once, in core, and the theory imports them;
- the whole suite has no new red, `--stage 2` is a fixed point; the self-compile and memory are measured and reported.

## Open for the supervisor

- **Moving theory code into core** (below.wap and recursion.wap's reading) rather than writing it again in core and
  deleting the theory's later: recommended, because the two typers then share one implementation from T5c on, and
  T7 deletes nothing twice. Core cost the same; the extension shrinks at once. The moved code reads Elaborating, the
  theory's state: the move makes it read analyze's typed nodes and the kernel's checker, and the theory hands those in.
- **The guarded bound on int before T6c:** recommended, as above, an effect only (Pure), the kernel term at T5c4. The
  other reading, int's kernel definition and nat's induction before T5c, moves T6c's work forward.
