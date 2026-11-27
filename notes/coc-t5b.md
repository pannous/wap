# T5b, enums, match and effects: how it is built

notes/coc-t5.md row T5b, after T5a. An enum becomes a kernel inductive block, its cases its constructors; `match` on
an enum becomes the case split of its recursor; the recursor is a value a program may call (wiki/enum.md "The
recursor"). Effects become facts in this step too (user 2026-11-27, notes/audit/2026-11-27.md R3): each typed
function carries the effects wiki/effects.md names, and `effects of f` prints them. Structural recursion is T5c's,
statements T5d's, classes T5e's. Line counts are `grep -vc '^\s*#'` on main f749f499.

## What is there to build on

- **T5a, the model:** core/analyze/terms.wap (112 lines) turns a typed pure body into a kernel term and enters the
  function as a definition the kernel checks (`instance_entered`), any other as an assumed constant; `term_of` takes
  numbers, texts, truths, parameters, lets, calls of defined functions, the host rows the kernel folds
  (kernel/primitives.wap FOLDED_ROWS) and `if` (the kernel's Choice). Every other node gives ø, so its function stays
  assumed. The census counts both (`TYPES.defined`, `TYPES.assumed`; ratchet DEFINED_INSTANCES).
- **The fill, in flight (branch t5a-pure-definitions-door, A1, not on main):** an axiom is filled in place where a
  declaration of its name and type arrives (kernel/environment.wap `filled_id`, `added`, `back_to`), so every term
  naming the assumed word means the definition from then on. Every type word analyze meets is such an axiom today
  (core/type_notation.wap `word_declared`): a record's word `Shape 12` of type `Type`, bool, its two truths. This is
  the mechanism T5b needs: an enum's word stays the term every typed node already holds, and the block fills it.
- **The kernel has the rest:** kernel/inductive.wap (219) checks a block (checks 1 to 5), kernel/recursors.wap (177)
  makes its recursors, kernel/nested.wap (105) nested types, compute.wap's `iota` computes a recursor on a case.
  Nothing in core calls `inductive_declared` yet.
- **Covering is analyze's already:** core/analyze/matching.wap (144) refuses "match on Coin misses Dime", the
  wiki's message (wiki/enum.md "Matching", wiki/pattern-matching.md "Every case"), green today. It also types list,
  shape, literal and record patterns, which are no recursor's. It stays: T5b adds a term for a match, it replaces
  no typing.
- **The Choice:** the kernel's `if` is DeclarationKind.Choice, computed by compute.wap `choice_step`, declared by
  type_notation.wap `literals_declared` over an opaque bool and two opaque truths. Once bool is an enum it is bool's
  recursor, and the Choice goes.
- **`type of` is the model for `effects of`:** sugar/types.wap `rule type of $x => type_of($x)`, and calls.wap
  answers the call by TYPE_OF_WORD with a text literal (`type_of_typed`).
- **No effects in core:** nothing in wap/core or wap/kernel says effect. The only inference is the theory's own,
  extensions/theory/elaborate/effects.wap (191), on its own reading of programs, with the computation types `T ! e`.
- **The theory's twins of this step:** elaborate/blocks.wap (111, enums and classes into blocks), elaborate/match.wap
  (216: arms to minor premises, dependent motives, the course of a recursion), elaborate/effects.wap (191: inference
  and computation types). Each serves two readers: a program read through the door, and the explicit theory spelling
  (`enum Equal(a: T): T -> Prop`, `Equal[1](bool, …)`, a theorem by `match` with a dependent motive), which analyze
  cannot type until propositions and indexed families move to wap/types (section "T6 and T7" below).

## Enums as inductive blocks

- **The block:** at an enum's declaration (a record with cases, `cases_of`), analyze writes an InductiveBlock: the
  enum's own word (its `declared_word`) its one type, `Type` its sort, each case a WrittenCase whose type is the pi of
  its fields' settled types ending in the enum's word. `enum list<T>` takes its letters as the block's parameters.
  Enums that name each other are one block (7, "Mutual types"), grouped by the declarations' order of reading. The
  block goes to `inductive_declared`, which fills the enum's word: no typed node changes, and from then on the word
  has constructors and a recursor.
- **What stays assumed:** an enum whose field types are open (`enum Shape { Circle(r), Dot }`, `r` untyped) or that
  the kernel refuses (a field of the enum under a function's argument, a subset of itself) stays the axiom it is
  today, counted. A refusal by strict positivity at an enum the program wrote is the kernel's message with the fix
  (7, "Where two rules of this plan meet").
- **A case's value:** `Dime`, `Circle(2)` are the constructor applied to the fields (terms.wap `term_of` for a case
  call and a case name). The case's shape word (core/analyze/shapes.wap, `Circle` as a type) stays a narrowing; it
  becomes `Subset(Shape, is Circle)` only where T4's narrowing test needs it.
- **Cases with values:** `enum Valued { Penny = 1 }` is three constructors without fields; the number is a function
  of the case (`as int`), not part of the block.

## bool is an enum

- wap/types declares `enum bool { no, yes }` (types/types.wap, beside the core words), filling core's bool and its
  two truths in place, so BOOL_TERM and `literals.yes_case` stay the terms they are. The layout is unchanged: the
  emitter runs the statements (9.7) and never reads the block.
- `if c then a else b` is bool's recursor with a constant motive: terms.wap `choice_term` names the recursor in place
  of CHOICE_WORD. DeclarationKind.Choice, `choice_step` and the choice in `literals_declared` go: the kernel computes
  an `if` by iota, the one rule every case split uses.
- The truth rows (`i64.eq` giving a truth, compute.wap `row_step`) keep giving the two cases.

## match as the recursor's case split

- **The term:** a Case node on a subject whose type is a filled enum, each arm a case pattern (the case name, its
  fields named or `_`) or a catch-all, is the enum's recursor applied to the constant motive `_ => T` (T the match's
  type), one minor premise per case in the block's order (the arm's result as a function of the case's fields, then
  of the results at its recursive fields, unused until T5c), and the subject. A case no arm names takes the
  catch-all's result. terms.wap `match_term`.
- **Literal arms:** an arm whose pattern is a whole number, a text or a truth on a subject of that type is a choice on
  the row's equality: `match n { 0 => a; _ => b }` is `if n == 0 then a else b` as a term. Any other pattern (lists,
  ranges, records, shapes, nested cases, guards) gives ø, so its function stays assumed, as T5a's rule says.
- **Covering:** analyze's own refusal, as today; a match that reaches its term covers, so the minor premises are
  always all there.

## The recursor as a value

- `nat.recursor(0, (k, double_k) => double_k + 2, n)` (wiki/enum.md) is a call of a filled enum's recursor: analyze
  types `E.recursor` where E is a filled enum, with the motive left out and found from the type wanted or the first
  minor premise's result (non-dependent: the motive is constant), each minor premise typed by its case's fields plus
  one result per recursive field.
- **It runs** by an ordinary definition analyze adds to the enum's declarations, the match over its cases calling
  itself at each recursive field, typed and emitted like any function (coc-plan.md 8, "for each block the elaborator
  adds ordinary definitions"); its term is the kernel's recursor constant, so the kernel never reads the body.

## Effects as facts

The audit's R3, migration steps 2 to 4.
- **The roots:** kernel/primitives.wap gives each row group its effect: the WASI imports IO, `i64.div_s`,
  `i64.rem_s` and `unreachable` Fail, the stores a write of their first operand. Nothing else in the kernel changes.
- **The fact:** core/analyze/effects.wap writes `effects` on each typed instance: the join of its body's prims, of
  the forms that carry one (`raise` Fail, `global` and a read of a main-level global State, `emit` the event, a
  `while` Div until T5d gives loops measures, a call of itself Div until T5c), and of each call's chosen instance; a
  function value of its own key `fn<key>` its instance's, one typed by a signature what that writes, else all. A
  recursive group is joined until it holds. `try` removes Fail. A write through a parameter, a capture or a global
  is State until the memory model decision (audit R2) says what a write means. Allocation is reported, no effect.
- **The question:** `effects of f` is a sugar rule beside `type of`, `rule effects of $f => effects_of($f)`, and calls.wap
  answers it as it answers `type_of`, a text literal: `Pure`, one effect, or several in parentheses (wiki/effects.md
  "API"). The two questions become one table of the compiler's questions in calls.wap (a word and its answer
  function), so the second one adds no special case.
- **The claim:** `… ! IO` after a function's body is checked against the fact: an effect beyond the claim is refused
  naming the call that brings it.
- **How the reader reads `body ! IO` today** (from source, core/parse/operators.wap `operator_after_operand` and
  types/operators.wap): `!` has a postfix row only, `required` in the superscript group, and a prefix alias `not`.
  After an operand the reader takes a spaced `!` as infix where it has an infix reading, and since it has none it
  falls through to the postfix, though the function's own comment says spaced on both sides is infix. So
  `print(t) ! IO` is `required(print(t))` followed by `IO` in a space list, the shape the theory's
  elaborate/effects.wap `effect_marked` reads (a space list whose first item is the `!` call). `double(x) := x * 2 !
  Pure` is worse: the superscript group binds tighter than `*`, so `!` lands on the `2`, `x * required(2)` then
  `Pure`, and neither analyze nor `effect_marked` sees a claim.
- **The claim's reading, recommended:** a table row, no reader branch: `!` gets an infix reading in a group of its
  own between `arrow` and `assignment` (types/operators.wap), so `f(x) := x * 2 ! Pure` is the claim applied to the
  whole body and `x!` stays `required(x)`. The reader then does what its comment says (spaced on both sides is
  infix). types +2, core 0; the claim's check +10 in analyze (in T5b1's +120). The theory's `effect_marked` reads the
  infix call instead of the space list (−5 extension).
- **What reads it:** terms.wap enters only a Pure function (or Fail with T5d's `T or Error`) as a definition; the
  census prints how many functions have each effect, and T5's gate becomes "every function defined, Div, or opaque by
  a named effect".

## The migration in landable sub-steps

Every step is a track T step (coc-plan.md 14: no core, census or speed limit; measured and reported). T5b2 onward
change what the kernel holds for every compile, so they take the careful path; T5b1 adds a fact and a question, the
normal path.

| step | what | core / kernel / types lines (estimate) | deletes from extensions/theory | outcome lines |
|---|---|---|---|---|
| T5b1 effects | prim rows carry their effect; analyze writes `effects` per instance; `effects of`, one table of questions with `type of`; the `!` claim checked; the census prints the effects | core +120 (analyze/effects.wap +100, calls.wap's question table +10, the claim +10), kernel +10 (primitives.wap), sugar +1 | elaborate/effects.wap's inference half, about −120: the door (A2) reads the `effects` fact of a program's functions; the computation types (`T ! e`, Eff) stay for T6 | test_effects_wanted's four `effects of` checks (a constant free variable Pure, a global State, `! IO`, `! Pure`); test_errors_wanted's "effects of a function that can fail name Fail, try removes it"; wiki/effects.md's `effects of f // State` and `// Pure`, moved to test_effects_page |
| T5b2 enums | an enum's declaration fills its word with an inductive block, cases its constructors; mutual enums one block; a case's value a constructor term; open or refused enums stay assumed, counted | core +80 (analyze/inductives.wap: block of a record +50, grouping +15, case terms in terms.wap +15), kernel 0 (A1's fill) | the door finds a program's enum filled and elaborates it no more (declare.wap's block path for programs, about −15); blocks.wap stays for indexed families and propositions | the census counts enums defined and assumed, a ratchet; every test as before (an enum's equality, a law's `Dime == Dime`, needs the decidable equality coc-plan.md 7 adds per block: T6) |
| T5b3 bool | `enum bool { no, yes }` in wap/types fills core's bool and its truths; `if` is bool's recursor | core −5 (literals_declared's choice, choice_term names the recursor), kernel −12 (DeclarationKind.Choice, `choice_step`, its `stated` arm), types +2 | logic.wap's `bool` and its `runs` lines go once the prelude is read on core's words (A1 already defines bool in its place) | every test as before; test_law_runs' "a law without binders that holds is Proved by computing it" still Proved |
| T5b4 match | a match on a filled enum with case arms is the recursor's case split, the catch-all filling the cases left; literal arms are choices on the row's equality | core +60 (terms.wap `match_term` +45, literal arms +15) | match.wap's program path: the door takes analyze's term; `arm_of`, `names_case`, `pattern_name`, `pattern_fields` and `minor_elaborated`'s non-dependent half, about −50; the dependent motive (`motive_made`) stays for T6, the course (`course_elaborated`) goes with T5c | wiki/law.md and enum.md: `enum Coin { Penny, Nickel, Dime }`, `cents(c: Coin) := match c { Penny: 1; Nickel: 5; Dime: 10 }`, `law dime: cents(Dime) == 10` prints `dime: Proved` (test_law_runs, a new line); `effects of cents` is Pure (coc-t5.md T5b row); "match on Coin misses Dime" unchanged |
| T5b5 the recursor | `E.recursor(minors…, value)` typed with its motive found; it runs by the definition analyze adds to the enum | core +50 (calls.wap: the recursor's type for a filled enum +30, the added definition +20) | match.wap `recursor_given`, about −8 | the form of wiki/enum.md on an enum of the program, `enum Tree { leaf, node(left: Tree, right: Tree) }`, `leaves(t: Tree): int := Tree.recursor(1, (l, r, below_l, below_r) => below_l + below_r, t)`, `leaves(node(leaf, leaf))` is 2 (test_enum_wanted); enum.md's own `double(3)` is 6 needs the numerals at nat, so it goes green with T6c |

Order: T5b1 can start at once (it needs neither the fill nor the door for its core half); its theory deletion waits
for the door (A2). T5b2 needs A1 on main. T5b3 and T5b4 follow T5b2 in either order; T5b3 first is recommended,
since it is a pure shrink that makes `if` and `match` one mechanism before `match_term` is written. T5b5 last.

## The estimate

T5b as a whole: core about +305 (+120, +80, −5, +60, +50), kernel about −2 (+10, −12), types +2, sugar +1; the
extension about −190 (−120, −15, −50, −8). Against coc-t5.md's T5b row (+220 analyze, −191 matching.wap): the
effects (+130) moved in from T6, as the audit R3 counted them; matching.wap stays, since it types patterns that are
no recursor's and its covering refusal is the wiki's; elaborate/match.wap goes in three parts (here, T5c, T6), since
its dependent motive serves the theory spelling that analyze reads only from T6.

## Gate

T5b is done when:
- the outcome lines above are green, and test_effects_wanted's and test_errors_wanted's effects lines have moved to
  page tests;
- the census counts every enum of wap's source defined or assumed with a reason (open field, refused), and prints the
  effects per function; the defined instances ratchet does not fall;
- the kernel holds no Choice: `if` computes by bool's recursor;
- elaborate/effects.wap holds no inference of a program's effects, and the door elaborates no program's enum or plain
  match;
- the whole suite has no new red, `--stage 2` is a fixed point; the self-compile and memory are measured and reported
  (soundness, never a limit).

## Decided (wap-supervisor 2026-11-27)

- T5b1's core half lands first; its deletion in elaborate/effects.wap lands with A2, the door reading analyze's nodes.
- elaborate/match.wap goes in three parts: the plain arms here, the course with T5c, the dependent motive with T6.
- nat is one type: an inductive for the kernel, int's layout when it runs, converting up to int for free; this reads
  wiki/number.md and wiki/enum.md alike, so no wiki text changes.
- analyze finds levels itself.

# T6 and T7: what the law statements ask of analyze

## The finding

The tests state 141 laws and theorems (supervisor's count, 2026-11-27). 104 of them are written in the theory's own
spelling and read only by extensions/theory: `Equal(nat, add(2, 2), 4)`, `Even.step(…)`, `And`/`Or`, `Prop`, levels
in brackets (`Equal[1](bool, …)`), almost all in test/wap/test_theory_*.wap and test_proof_wanted. About 19 are wap
statements that wap verify reads today through the law run (lib/laws.wap, extensions/law_runs.wap) but cannot prove
or even try: they need `nat` binders (`law doubled(n: nat): n + n == 2 * n`), hypotheses as binders
(`law positive_product(x: nat, y: nat, a: x > 0, b: y > 0): x * y > 0`), `implies`, `exists n: nat where …` and
`False`. A one-line count (`law|theorem name(` or `name:` on one line, test .wap and .sh files) finds 122, of which
about 71 name Equal, Even, And, Or, Prop, Sort, False or a level: the same split, the multi-line statements aside.
nat is the word most of them need: 72 of the 122 name it, Equal 54, Even 13, bool 9, int 9, False and `implies` 3
each.

T7 retires the extension, so by then every one of these statements is read by analyze. Two ways for the 104: rewrite
them in wap spelling (`law four: 2 + 2 == 4`), or let analyze read the explicit spelling. The second is free once
the words are wap/types words: `Equal(nat, add(2, 2), 4)` is a call of an indexed enum with a function in it, an
ordinary call. Only three things in it are no wap: `Sort(u)`, a level argument `[1]`, and `Prop` as a sort.
Decided (wap-supervisor 2026-11-27): analyze finds levels and never reads `[u]` (6.3: levels are found); the prelude files, which write
them, become wap/types files in wap spelling. A test that writes a level is an existing test: dropping its level
goes to wap-interviewer when that step comes up, never a free commit.

## What moves to wap/types, and what analyze needs for each

Each prelude file of extensions/theory/prelude moves at the step whose analyze work it needs; what it holds is
written once, in wap/types, and the prelude file goes (T7, "the run door and its prelude, whose words now live once
in wap/types").

| prelude file (lines) | words | goes to | analyze needs | step |
|---|---|---|---|---|
| logic.wap (63) | `bool`, `no`, `yes` | types/types.wap | nothing beyond T5b2 | T5b3 |
| logic.wap | `False`, `True`, `And`, `Or`, `Not`, `Exists`, `Decidable` | types/logic.wap (new) | `Prop` as a sort: an enum declared `: Prop`, a field universe check (7, check 3) and elimination into Prop only (check 5); `Not(a)` as `a -> False`; a law's statement typed at Prop | T6a |
| logic.wap | `Equal`, `refl`, and `Even`-like families of the tests | types/logic.wap | indexed families: an enum's header `T -> Prop`, a case's result type written per case (`step(e: Even(n)): Even(n + 2)`), its letters found as fields; a match on one makes the dependent motive (elaborate/match.wap `motive_made`, ported), solving the indices | T6a |
| logic.wap | `Pair`, `Sum`, `Unit` | none new: tuples, `A or B` (T5u) and the empty tuple are these; the products the course of a recursion rides (below.wap) are found from them | that the kernel's products are declared from wap/types' tuple, not the prelude's | T5c |
| logic.wap | `proposition_extensionality` (axiom), the first laws (and_swap, equal_symmetric, …) | types/logic.wap, laws with their proofs | `axiom` and `theorem` as declarations analyze types (the theory's declare.wap path), a proof a term analyze builds | T6a |
| operators.wap (29) | `implies`, `not` on propositions | types/operators.wap rows | the operator table's rows by the operands' sort: `and`, `or`, `not`, `implies`, `==`, `exists … where` of propositions write And, Or, Not, `->`, Equal, Exists; of bools the bool words. A bool statement where a proposition is wanted is `Equal(bool, b, yes)` (one conversion, coc-plan 8's "conversions", the prelude's `chosen_decided`) | T6b |
| numbers.wap (197) | `nat` (zero, successor), `add`, `multiply`, `subtract`, `at_most`, `predecessor`, their laws | types/numbers.wap | nat as an enum with a host layout: its cases' values and its case split by int's (9.7, the prelude's `runs(nat, int)`): one declared layout per enum, read by the emitter, the general form of `runs`; the numerals at nat (the kernel's `numbers` literal binding); nat up to int Same, int down to nat by `it >= 0` (T4's narrowing), so wiki/number.md's "`nat` is `int where it >= 0`" and wiki/enum.md's `enum nat { zero, successor(n: nat) }` are one type | T6c |
| numbers.wap | `int` as `of_nat`/`negative_successor`, `divide`, `remainder`, `equal_integers` | types/numbers.wap | the same layout form; int's operators as definitions over nat for the kernel and the host rows for the run (T1's rows, `prim` bodies) | T6c, or T8 (big numbers) |
| data.wap (82) | `list(T)` (empty, item), `count`, `item_at`, `drop`, `joined`, `mapped`, optional, `text` | types/lists.wap, types/texts.wap | the layout form again (a list runs as today's list); `#xs`, `xs#i`, `xs + ys`, `xs.map(f)` as those definitions for the kernel, the library's code for the run; `index(xs)` (T4e) | T6d |
| effects.wap (22) | `Effects`, `Eff`, `Fallible`, `Inhabited`, `never` | types/effects.wap | T5b1's facts made computation types: `T ! IO` as `Eff(IO, T)`, a function's type ending in its computation (9.2) | T6e |
| quotient.wap (20) | `quotient`, `of`, `lift`, `quotient_sound`, `function_extensionality` | types/quotient.wap | `quotient(T, r)` as a type form, `.of` and `.lift` typed (test_quotient_wanted's three laws) | T6f |
| checked.wap (43) | `fraction`, `rational`, `set`, `map` keys, `char`, i64's wrap | types/numbers.wap, types/maps.wap, types/characters.wap | quotients (T6f); char is T4c's; i64's wrap T8's | T6f, T4c, T8 |
| any.wap (9), conversions.wap (3) | `any`, `convert` | none: T5u's unions and core's conversions are these | nothing | T5e |

## What the ~19 wap statements need, in order

1. `nat` binders: nat in wap/types (T6c) and its trial values in lib/laws.wap (`trial_values(): list<nat>`, the
   whole numbers from 0), so the law run tries them before any proof exists.
2. Hypotheses as binders: a binder whose type is a proposition (`a: x > 0`) takes no trial value; the run tries the
   other binders' values and skips a trial where a hypothesis computes to no; the proof reads it as a hypothesis.
   It needs T6b's bool-to-proposition conversion.
3. `implies`: T6b's operator row; the law run computes it as `not a or b`.
4. `exists n: nat where p`: Exists (T6a); the law run tries values until one holds, else Tested-untried.
5. `False`: the empty proposition (T6a), the statement of a refutation.

## Order

T6a (Prop and indexed families, logic.wap moved), T6b (the operators of propositions), T6c (nat and int with their
layouts), then laws as theorems proved by computing and by the provers (coc-plan's T6 row), T6d to T6f as the tests
need them; T7 deletes the prelude files and what is left of elaborate/, the explicit-spelling tests then read by
analyze.
