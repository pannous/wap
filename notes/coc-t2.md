# T2, the kernel inside: how it is built

notes/coc-plan.md 11, step T2: the kernel moves out of wap/extensions/theory into wap/kernel. Its typing becomes
rule functions that make `Checked(term, type)`. The environment keeps declarations by id and is persistent. Kernel
numbers are i64 with an overflow check. This page covers what moves where, the shapes the kernel gets, and the
order of the landings. The line counts are from `wc -l`, the node counts from scripts/wap-size.warp, both taken on
main 76d89f53.

## What moves

Twelve files, 2,241 lines, 21,312 nodes. The census types every function of them as they are today: 418 of 418,
none typed `any`. In this table "moved" means `git mv`, followed by the edits of the sub-steps below.

| file | lines | into wap/kernel | its job (coc-plan) |
|---|---|---|---|
| terms.wap | 282 | terms.wap | 6.1 terms, locally nameless; hash, `same` |
| levels.wap | 103 | levels.wap | 6.2 universe levels |
| typing.wap | 174 | typing.wap | 6.3 and 6.6: becomes the rule functions (below) |
| equal.wap | 153 | equal.wap | 6.5 definitional equality |
| compute.wap | 157 | compute.wap | 6.4 beta, zeta, delta, iota, projection, quotient |
| inductive.wap | 257 | inductive.wap | 7, checks 1 to 5 |
| recursors.wap | 218 | recursors.wap | 7, checks 6 and 7 |
| nested.wap | 144 | nested.wap | 7, nested types |
| quotients.wap | 59 | quotients.wap | 6.6 the quotient declaration |
| environment.wap | 338 | environment.wap | 6.6: becomes the persistent environment (below) |
| show.wap | 102 | show.wap | a term in wap notation, for messages and `type of` |
| numbers.wap | 254 | numbers.wap | 6.7 the numbers and shortcut declarations, texts |

wap/kernel today: forms.wap (82) and surface.wap (11), read by core as data and as rules. Nothing in core `use`s
the moved files until T3. So in T2 the compiler neither links nor reads them, and its self-build and its seed are
unaffected (see "The seed rule").

## What stays in wap/extensions/theory

- **The door `wap check`** on the explicit spellings: check.wap (18), explicit.wap (356), bindings.wap (40),
  options.wap (27), 441 lines, as 5.2 says. It `use`s wap/kernel.
- **below.wap (141).** `products(Pair, Unit)` and the course-of-values definitions. These are ordinary definitions
  that the kernel checks, so they are not trusted code. The Environment fields `products` and `courses` leave the
  kernel along with them and become state of below.wap (an untrusted record beside the environment). T5 moves
  below.wap into analyze, when structural recursion arrives.
- **export.wap (103) and second/ (1,211).** The second opinion. T7 moves them to wap/extensions/proof. second/
  keeps its own unbounded numbers, because its job is to be independent of the kernel.
- **elaborate/ (3,700), run/ (410) and prelude/ (668).** They are deleted step by step from T3 to T7 (5.2), and
  until then they use wap/kernel.
- **wap/extensions/prove (951).** The provers use wap/kernel, and move to wap/extensions/proof at T7.

## The persistent environment by id

Today an Environment is a set of mutable maps (declarations, places, axioms) plus an `accepted` list. To try
something and take it back, the code copies it (`copied`: every map, used in inductive.wap `holding`, in the
elaborator's `held`/`copied(p)`, and in templates' untyped tries) or rewinds it (`Reach`/`withdrawn`: used by the
provers' goal search).

The new shape:

```
# one statement the kernel accepted, by its id: the place in the log, from 1
class Entry { statement: Accepted; declarations: list<Declaration>; axioms: list<list<int>> }
# every statement accepted on the way to the newest environment; ids index it; names find ids
class Log { entries: list<Entry> = []; named: map<text, list<int>> = {} }
# an environment: the log as far as it reaches, and what the binding statements bound by then
class Environment { log: Log; reach: int = 0; numbers: Numbers? = ø; texts: int? = ø }
```

- **Checking returns a new environment or refuses.** `declared(e, d): Environment`, `block_declared`,
  `numbers_declared` and the rest return `Environment(e.log, e.reach + 1, …)`. A refused statement returns
  nothing, so the caller still holds `e`, and nothing needs to be rolled back.
- **The log is shared and append-only.** An environment sees only the ids up to its own `reach`. Appending to an
  environment whose log has grown past its reach first drops the entries after that reach. Those entries came from
  an attempt that was given up (a refused statement, a template's try, a failed proof search), and that attempt's
  environment is never used again. The persistence is therefore linear: an old environment can be returned to, but
  two newer ones cannot live side by side. Every current use is linear in this way (elaborate, prove, the door).
  Making it loud instead: stamp the log with a generation that dropping entries increments, so that using a dropped
  environment refuses instead of reading stale data (a decision for review).
- **Ids, not names.** `Constant(id: int, levels)` replaces `Constant(name: text, levels)`. Hashing and comparing
  a constant becomes one integer operation. `show` prints `log.entries[id]`'s name, so a name's text is used only
  for showing. `Numbers`, `RecursorFacts`, `InductiveFacts` and `QuotientPart` hold ids. The kernel no longer has a
  "name taken" check (`names_new` goes): two declarations may share a name, because they have different ids. Which
  id a written name means is the elaborator's question (a module's scope, then the ones it uses), never the
  kernel's.
- **`place`** (which of two definitions unfolds first, 6.5) is the id: the later declaration has the higher id.
- **`accepted`** is the log itself: an export walks `entries` up to the reach. An exported name that the log holds
  twice gets its id appended (`Side.17`), because lean4export's format needs unique names.

**Deleted by this:**
- in the kernel: `copied` (13 lines), `Reach`, `reach_of` and `withdrawn` (14), the `places` and `accepted` maps,
  `names_new` (6), and the copy in inductive.wap `holding` (it becomes an environment that reaches further);
- in prove/goals.wap: the reach/withdraw pair;
- in elaborate/read.wap `held`: the environment line (`p.environment = copied(from.environment)` becomes a plain
  assignment of the old value).

**Not deleted.** `held` copies about fifteen other parts of the elaborator's own state (found, binders, overloads,
traits, stated, labels, sets …), and `copied(p)` in templates.wap copies them too. That state is not the kernel's,
and it goes when the elaborator files go (T3 to T5). `refused_names` is not a rollback: it remembers why a refused
name is missing so that a later use can say so, so it stays in the elaborator. Analyze will need the same
mechanism at T3 (a name declared in a refused statement).

## Checked(term, type): the rule functions

One rule function per row of 6.3. Each takes the premises as judgements and returns one judgement. Every judgement
is appended to the checker's table, and its number is what a node's fact will hold.

```
class Checked { term: Term; type: Term }
# the judgements one check made, by number
Checker.judgements: list<Checked>
```

| today (typing.wap) | rule | premises → conclusion |
|---|---|---|
| `type_found` Sort + `levels_declared` | `sort_rule(c, level)` | → `Sort(u): Sort(u+1)` |
| `type_found` Constant + `constant_type` | `constant_rule(c, id, levels)` | → `k[levels]: type[levels]` |
| `type_found` Free + `hypothesis_of` | `free_rule(c, id)` | → `x: A` |
| `application_type` (a chain, one walk) | `apply_rule(c, f: Checked, a: Checked)` | `f: (x: A) -> B`, `a: A'`, `A ≡ A'` → `f(a): B[a]` |
| `type_found` Lambda | `lambda_rule(c, x, A: Checked, body: Checked)` | `A: Sort u`, `b: B` under x → `(x: A) => b : (x: A) -> B` |
| `type_found` Pi | `pi_rule(c, x, A: Checked, B: Checked)` | `A: Sort u`, `B: Sort v` → `Sort(imax(u, v))` |
| `type_found` LetIn | `let_rule(c, x, A, v: Checked, body: Checked)` | `v: A'`, `A ≡ A'` → `body[v]` |
| `type_found` Numeral | `numeral_rule(c, n)` | numbers bound → `n: nat` |
| `projection_type` | `projection_rule(c, structure, field, of: Checked)` | `of: S(params)` → the field's type |
| `declared` / `value_checked` | `declaration_rule(e, d, type: Checked, value: Checked?)` | → a new Environment |

- `type_of(c, t)` stays the interface for the door and the elaborator. It becomes the walk that calls these rules
  bottom-up and returns the conclusion's type. Its memory (`c.types`) keeps the judgement number instead of the
  type. `level_of`, `is_proposition` and `sort_level` read a judgement's type.
- An `apply_rule` per argument replaces the one walk over a chain of arguments. The chain walk is kept as a loop of
  `apply_rule` calls, so a call with n arguments makes n judgements, which is what a node per argument needs at T3.
- **LCF.** Only the rule functions make a `Checked`. wap has no private constructor, so for now this holds by
  convention plus a landing check: `scripts/compiler-growth.sh` refuses a `Checked(` outside wap/kernel/typing.wap.
  Making a class constructor private to its module would be a language form: that is a question for the user, and
  not part of T2.
- **"A node's fact is a judgement's number"** (in the T2 row) has no node in T2, because analyze writes kernel facts
  from T3 on. T2 provides the table and the rules; T3 writes the numbers into nodes. Proposed: move that clause to
  T3's row.

## Numbers: i64 with the overflow check

The kernel stops using lib/magnitude (`use magnitude` in terms, typing, show and numbers; 12 call sites).

- `Numeral(value: int)`. Literals from source already arrive as `value as int` (explicit.wap, elaborate/read.wap).
  A literal the reader cannot hold is the reader's refusal.
- The seven shortcuts compute on int, and only when the result fits. Every numeral is non-negative, so the check is
  `a <= MAX - b` for add, `b == 0 or a <= MAX ÷ b` for multiply, and nothing for subtract, divide, remainder and the
  two comparisons. A shortcut that would overflow returns ø, so the term is left to the definitions and the step
  budget (6.7). About 10 lines. `MAX` is i64's largest value (2^63 − 1), a constant at the top of numbers.wap.
- `opened` (a number as a case) and `number_computed` (a case as a number, `sum(…, ONE)`) work on int.
- **Text literals do not fit.** `text_number` spells a text as a 1 followed by its code points in base 0x110000
  (5.4, notes/theory.md). That is a number of about 21 bits per code point, so i64 holds only three code points,
  and every longer text literal would fail. Options for review:
  1. **Recommended:** a text literal term of its own, `Text(value: text)`, typed by the texts statement's function,
     which opens (as `opened` does for numerals) into that function applied to the list of the text's code-point
     numerals. The texts statement then binds the list's two cases as well: `texts(text_of, list.add, list.empty)`.
     This is Lean's kernel's string literal. It costs about 30 kernel lines; 5.4's text paragraph and
     prelude/data.wap's `text_of` are rewritten.
  2. Keep the unbounded numbers for text literals only. This contradicts 6.7 ("the kernel has no unbounded
     arithmetic"), and lib/magnitude would stay in the compiler.
  3. Split long texts into three-code-point chunks joined by a bound `join`. This is ad hoc and shows badly.
- show.wap prints int digits directly (its `use magnitude` goes).

## The seed rule

- The seed's compiler reads wap/kernel only through types/rules.wap, which names kernel/forms.wap alone, and core
  `use`s only forms.wap and surface.wap. The moved files are therefore beside the seed (WAP_BESIDE copies all of
  wap/ except core) without being read or linked. **T2 changes nothing the seed reads.** The careful path's seed
  refresh for T2 (coc-plan 11, "T1 and T2 change the kernel the seed reads") is not needed, so each sub-step lands
  on the normal path plus the census.
- The moved files enter the census's and the size ratchet's scope automatically, because test/wap/compile.sh's
  `compiler_sources` excludes only extensions/theory and extensions/prove. This is theory-switch's census note:
  the size ceiling (SIZE_NODES, 143,077 today) rises by the kernel's measured nodes (21,312 as moved) in the same
  commit as the move, and the typing census covers the kernel from then on.
- The first seed refresh that matters is T3's, when core `use`s wap/kernel/typing.wap. By then T2b has removed
  `use magnitude`, so the compiler links no library module. Until then, the kernel's source may use only types
  words the seed's types module holds; it does so today, since the seed's compilers build the theory extension.

## The migration in landable sub-steps

Each sub-step lands alone. Each keeps test_hello, `--stage 2` (untouched: core does not use the kernel), the
theory test areas (`bash test/wap/run.sh --wait theory`) and the census green.

| step | what | lines (kernel) | checks |
|---|---|---|---|
| T2a move | `git mv` the 12 files into wap/kernel, then a pure path edit of every `use` (elaborate 19 files, run 3, second 1, prove, door, scripts/theory-census.wap); SIZE_NODES += 21,312 | +2,241 moved, 0 new | census (418/418 typed), theory areas, test_hello |
| T2b i64 | `Numeral(int)`, the overflow checks, magnitude out of the kernel, text literals as decided | −15, +10, +30 for option 1 | theory areas, the new line: a shortcut past 2^63 does not fire |
| T2c persistent | `Log`, `Environment(log, reach, …)`, every `declared…` returns an environment; the deletions above; callers assign instead of mutating | −50, +35 | theory areas, prove's tests |
| T2d ids | `Constant(id, levels)`, `show` by id, `names_new` goes, the facts hold ids; the elaborator resolves a written name to an id through its module's scope (the extension's lines, not the kernel's) | −8, +20 (elaborate +40) | theory areas, the new line: two modules with the same name |
| T2e rules | the rule functions and the judgement table; `type_of` as their walk | +60 | theory areas; the theory census time ratio stays under 3 (checked once, then the census retires) |
| T2f census | the theory census retires: `--theory`, THEORY_ACCEPTED and THEORY_TIME_RATIO leave ratchet_census.sh; scripts/theory-census.wap stays for whoever wants its numbers | 0 | the typing census |

T2a goes first so that every later diff is read in its final place. T2b comes before T2c and T2d because it is the
only step with a spec decision (texts), so its answer can be waited for while T2c is built. T2e comes last among the
kernel steps because its rules read ids and return environments.

## The estimate

| | plan (coc-plan 11) | this page |
|---|---|---|
| moved | 2,300 | 2,241 |
| judgements | 60 | 60 |
| environment by id, persistent | 40 | 35 − 50 + 20 − 8 = −3 |
| numbers | (in moved) | −15 + 10 + 30 = +25 |
| **kernel** | **+2,400** | **about +2,323** |

The elaborator's side (outside the compiler, deleted from T3 on): about +40 for resolving names per module, and a
few lines fewer where `held` and templates copied the environment.

## Acceptance (the T2 row, with this page's additions)

- The K and L test files green through wap/kernel: `bash test/wap/run.sh --wait theory`.
- `2 + 2 == 4` by `refl`.
- A shortcut whose result passes 2^63 does not fire: `law: 4611686018427387904 * 2 - 1 == 9223372036854775807 := refl`
  is refused by "gave up", not by a wrong value.
- **Two modules that each declare the same name are both accepted, and each one's uses mean its own.** For example,
  `enum Side { Left, Right }` in a program and in a module it uses, as wap/core/format.wap's `Side`.
- A text literal longer than three code points still checks (`#"hello" == 5` by `refl`), whichever option is chosen.
- `--stage 2` a fixed point.
- The census covers wap/kernel, every function typed, and the size ceiling raised by the kernel's measured nodes.
