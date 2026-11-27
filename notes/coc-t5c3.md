# T5c3: a structural recursion enters the kernel as a definition

coc-t5c.md's T5c3 row covers a function that matches on a parameter of a program's enum and calls itself on that
value's fields (a field's field too). It is entered as the definition the course of its match gives, so the kernel
computes it, instead of an opaque constant. Read on unify-typers b4cda95e and fix-core-name-shadowing 3bca53e2.

## Where it stands

- `instance_entered` (analyze/terms.wap:43-60 on unify-typers) marks a function as entering. A call back to the
  function inside its own body finds no constant, so a recursive function stays an axiom (`TYPES.assumed`).
- `term_of` (terms.wap:87-98) has no `Case`: a `match` gives no term. That is T5b4 (coc-t5b.md, the recursor's case
  split), which no branch holds yet.
- courses.wap moved into core with T5c2 (e86988d2). `products_declared` has a caller (type_notation.wap:135). From
  `Way` on, the file has none: the theory reader that asked for courses (elaborate/recursion.wap, match.wap's
  `course_elaborated`) is deleted on unify-typers. The reading of a recursion therefore no longer moves from the
  theory, as coc-t5c.md's row says. It is ported from main's copy (25046c0f:wap/extensions/theory/elaborate/
  recursion.wap, 117 lines, and match.wap:157-170, 240-246) into core, onto analyze's typed nodes.
- 3bca53e2 marks core's products `·Pair` and `·Unit`, so a program's own Pair is its own word. T5c3 builds on it.

## The 76 lines of courses.wap that wait (courses.wap:45-139 on unify-typers)

| lines | what | T5c3 |
|---|---|---|
| :45-49 `Way` | a course, or why there is none | uses as is |
| :50-69 `course_of` | below and course declared the first time a recursion asks | uses as is, except :51: every compile's environment is core's and holds the products (explicit.wap is gone on unify-typers), so `?? return Without(…)` becomes `!`, −1. The three other `Without` reasons (Prop only, mutual enums, a function field) stay, and T5c3 prints them as the reason the function stays opaque |
| :23-24 `BELOW_SUFFIX`, `COURSE` | the two definitions' names, `Tree.below`, `Tree.course` | reshaped: marked `·` (`Tree·below`), as 3bca53e2 marks the products, so a program's own `below` meets none. 0 lines |
| :71-99 `Built`, `pair_type`, `pair_made`, `the_motive`, `motive_at`, `course_value_type`, `below_at`, `recursor_into`, `Major`, `major_entered`, `major_binders`, `made_of_binders` | what below and course are built of | uses as is |
| :101-115 `below_made`, :117-137 `course_made`, :139 `Chain` | the two definitions | uses as is |
| kernel/environment.wap:326, :338 (`e.courses` in mark and back_to) | courses are undone with a refused declaration | uses as is |

None is dropped beyond :51. The file stays 138 lines, and all of them get callers.

## The step

| part | what | files | lines |
|---|---|---|---|
| a recursion's entry | `instance_entered` hands the function's own key to `definition_of` while entering. A call of it inside the body is read as a hypothesis, not left ø | analyze/terms.wap | core +15 |
| the course term | A Define whose body is a `match` on parameter p of an enum that `course_of` takes becomes `λ params. T·course(parameters, motive, step, p)`. The motive is `λ p. Π other parameters. result`: the other parameters ride, so a call may change them. The step is `λ indices, value, below. (T5b4's case split of the arms)`, and an arm's fields are bound as T5b4 binds them | analyze/terms.wap `course_term` (ported from recursion.wap `riding`, match.wap `course_elaborated`) | core +35 |
| calls read from below | A call `f(a, others)` with `a` a field, or a field's field, of the value matched is the first of the pair found in `below` for that field, applied to the other arguments (`pairs_below`, `course_below`, `place_of`, `recursive_call_elaborated`). A call on anything else leaves the function opaque, and `effects of` says Div (T5c1's fact) | analyze/terms.wap or a new analyze/recursion.wap | core +30 |
| :51 | products always held | analyze/courses.wap | core −1 |

Net: core about +80 (coc-t5c.md's estimate holds), kernel 0, types 0. The kernel checks the course definitions as
it checks any declaration. Nothing in the trust base changes.

## The program forms it unlocks

- A program's enum walked by its own cases, the field calls direct or deeper, with other parameters riding:

  ```wap
  enum Tree { leaf, node(left: Tree, right: Tree) }
  leaves(t: Tree): int := match t { leaf => 1; node(l, r) => leaves(l) + leaves(r) }
  law four_leaves: leaves(node(node(leaf, leaf), node(leaf, leaf))) == 4      // four_leaves: Proved
  ```

  wiki/law.md "Checking a law" (Proved by computing), wiki/proof.md "Ways to prove" (by computing, `refl`) and
  "A proof computes and ends". enum.md:100-114 shows the recursor and the match as one function.
- Such a function computes where a type or a condition needs it: in a subtype's condition (T4d1 decides
  `t: Tree where leaves(it) == 4 = node(…)`), and as a value argument of a type alias (T4e).
- The census counts these functions as defined, not assumed.

Not unlocked, each waiting on its own step:
- Recursion over whole numbers: proof.md's and enum.md's `double` over nat, test_proof_wanted:5, :11, :23-25, and
  test_laws_wanted:309-310 (`fact`). nat is `int where it >= 0`, so its zero and successor cases are T5c4's.
- Mutual enums: `Without`, until a course is made for a block.
- Recursion through a list field: wap's own Node holds `list<Node>`, which courses do not reach. Most of the
  compiler's recursions stay assumed, so T5c's gate line on the census counts them as "assumed, waiting" with the
  reason.

## Red lines and gaps

No red line today is T5c3's alone: every recursion in a red test is over nat or int (T5c4). Gap lines, given to a
builder since this session writes notes only:
- wap/test_law_runs: the Tree program above → `four_leaves: Proved` (pins law.md "Checking a law" for a recursive
  function of a program's enum).
- test/test_laws_wanted.wap: `type four = Tree where leaves(it) == 4` with `t: four = node(node(leaf, leaf),
  node(leaf, leaf))` accepted. Together with T4d1 this pins type.md:177 item 1 for a recursive condition.

## Order

T5c3 needs:
- T5b4 (a match's term; the arms' fields bound by the case split), and T5b2 (an enum is a kernel block, on t5b-enums);
- unify-typers (terms.wap's `instance_entered` and `term_of`, as above);
- 3bca53e2 (the products marked).

T5c1 is not needed for the definition, only for the Div line of a call that is not structural. Careful path: it
changes what the kernel holds for the compiler's own functions, and the census and the self-compile time are
measured.
