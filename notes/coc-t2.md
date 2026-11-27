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

The shape:

```
class Environment {
	# every declaration accepted so far, by id, its place in the log: ids are never given twice
	log: list<Declaration> = []
	# the id of each live declaration, by its name
	ids: map<text, int> = {}
	axioms: …; accepted: …; courses: …; numbers: Numbers? = ø; texts: Texts? = ø; products: Products? = ø
}
```

- **One environment, changed in place, taken back as a whole.** The theory, its checkers and the provers' goals all
  hold one Environment, so `declared(e, d)` appends to it rather than returning a new one. Every take-back goes
  through one scoped form in environment.wap: `kept_if_given(e, attempt)` keeps what the attempt declared where it
  gives a value and takes it back where it gives ø or refuses (a refused statement, a template's try, a prover that
  found nothing). It rests on `mark` and `back_to`, which nothing outside environment.wap calls, so no caller can
  forget a rollback. The bindings (`numbers`, `texts`, `products`) and the courses below.wap made are taken back with
  the declarations. Checking a block and making its recursors declare nothing to take back: the block's types are
  variables of the checker then (below).
- **The log keeps its ids.** A declaration taken back loses its name, its id stays given: anything still pointing
  into the given-up attempt (a term naming one of its constants, a stale `c.types` cache entry) finds no live
  declaration and is refused ("unknown name"), never read as some later declaration.
- **The kernel reads no name it is given.** It finds every declaration by id: constants, the facts of blocks and
  recursors, projections, the bindings (numbers, texts, products, quotients) and the axioms a declaration rests on.
  The binding statements take constants; the extension resolves their written names (bindings.wap `named_here`).
- **The scope being read** is two maps on the environment, set by whoever reads a module: `ids`, the module's own
  names, where `added` names a declaration and refuses a name declared twice, and `outer`, the names it sees from
  outside, which its own hide. A declaration stays live by id whatever the scope (`taken_back` marks the ids taken
  back), so two modules may declare the same name, each one's uses meaning its own.
- **Ids, not names.** `Constant(id: int, levels)` replaces `Constant(name: text, levels)`. Hashing and comparing
  a constant becomes one integer operation. `show` prints `log.entries[id]`'s name, so a name's text is used only
  for showing. `Numbers`, `RecursorFacts`, `InductiveFacts` and `QuotientPart` hold ids. The kernel no longer has a
  "name taken" check (`names_new` goes): two declarations may share a name, because they have different ids. Which
  id a written name means is the elaborator's question (a module's scope, then the ones it uses), never the
  kernel's.
- **`place`** (which of two definitions unfolds first, 6.5) is the id: the later declaration has the higher id.
- **`accepted`** is the log itself: an export walks the live entries up to the reach. An exported name that the
  log holds twice gets its id appended (`Side.17`), because lean4export's format needs unique names. The
  statements an export writes as blocks and bindings are marked on their first entry.
- **A block names itself through free variables.** Today a block's cases name its types as constants before they
  are declared: elaborate/blocks.wap:93 builds `constant(type_names#at, levels)`, and inductive.wap `holding`
  adds the types as axioms to a copied environment so the checks can type them. With ids, those axioms would take
  ids that the block's real declarations then need. Instead the block arrives with its types as free variables
  (hypotheses of the checker, `(T: Type) -> …` as `free(k)`), checks 1 to 5 type them as hypotheses, and on
  acceptance the kernel takes the fresh ids and substitutes each type's constant for its variable in every case
  and recursor. `holding` goes, and the elaborator (blocks.wap) and explicit.wap write free variables instead of
  constants. This lands with T2d, planned here before it.
**Deleted by this:**
- in the kernel: `copied` (13 lines), `reach_of` and `withdrawn`, the `places` and `declarations` maps, and the copy
  in inductive.wap `holding` and recursors.wap's axioms (the block's types are variables); with T2d `names_new` (6) and `ids`;
- in prove/goals.wap: the reach/withdraw pair (`kept_if_given`);
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
| `type_found` Quoted | `quoted_rule(c, t)` | texts bound → `"…": text` |
| `projection_type` | `projection_rule(c, structure, field, of: Checked)` | `of: S(params)` → the field's type |
| `declared` / `value_checked` | `declaration_rule(c, d, type: Checked, value: Checked?)` | `type: Sort u`, `value: A'`, `A ≡ A'` → the declaration added |

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

- `Numeral(value: i64)`, written with the wrapping word: `int` is the unbounded whole numbers (wiki/number.md,
  test/test_number_wanted.wap), and the kernel's bound is 6.7's, not storage's.
  A literal the reader cannot hold is the reader's refusal.
- The seven shortcuts compute on int, and only when the result fits. Every numeral is non-negative, so the check is
  `a <= MAX - b` for add, `b == 0 or a <= MAX ÷ b` for multiply, and nothing for subtract, divide, remainder and the
  two comparisons. A shortcut that would overflow returns ø, so the term is left to the definitions and the step
  budget (6.7). About 10 lines. `MAX` is i64's largest value (2^63 − 1), a constant at the top of numbers.wap.
- `opened` (a number as a case) and `number_computed` (a case as a number, `sum(…, ONE)`) work on int.
- **Text literals get a term of their own.** Today `text_number` spells a text as a 1 followed by its code points
  in base 0x110000, about 21 bits a code point, so an i64 would hold three. The kernel gets a second literal,
  `Text(value: text)`, as Lean's kernel has its string literal:
  - its type is the texts statement's function's result; where a rule asks for a constructor, it opens (as
    `opened` does for a numeral) into that function applied to the list of its code points, each a numeral:
    `text_of(list.item[1](nat, 104, list.item[1](nat, 105, list.empty[1](nat))))` for `"hi"`;
  - the statement becomes `texts(text_of, list.empty, list.item)` and is shape-checked as numbers is: the list a
    block of one type with one level parameter `u` and one parameter `T: Sort(u)`, in `Sort(max(1, u))`, a case
    without fields and a case of a `T` and a list of `T`, in that order (prelude/data.wap's `list`); `text_of`
    exactly `list[1](nat) -> X` without level parameters;
  - about 30 kernel lines (the term, its typing, its opening, the statement's checks, show); prelude/data.wap's
    `text_of` takes the list instead of the number, and `spelled` goes;
  - outside the kernel: export.wap writes it as lean4export's `"strVal"` (+2 lines), and second/ reads, types and
    opens it (+20 lines in read.wap, judge.wap and expressions.wap).
  - **Not chosen: the elaborator expanding the literal itself** (0 kernel lines). The compiler's source alone holds
    2,204 text literals of 32,745 code points (14.9 on average, the longest 189; counted over `compiler_sources`).
    Expanded, a code point is 6 term nodes (three applications, `list.item`, `nat`, the numeral) and a literal 4 more:
    about 205,000 term nodes and three judgements a code point (about 98,000), against 2,204 nodes and judgements
    as literals: ninety times the terms, for every text in every program.
  - Also not chosen: unbounded numbers for texts only (lib/magnitude would stay in the compiler, against 6.7), or
    three-code-point chunks joined by a bound function (ad hoc, and shows badly).
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
  commit as the move, and the typing census covers the kernel from then on. Every later sub-step measures again
  (scripts/wap-size.warp over `compiler_sources`) and sets SIZE_NODES to what it measured, in its own commit.
- The first seed refresh that matters is T3's, when core `use`s wap/kernel/typing.wap. By then T2b has removed
  `use magnitude`, so the compiler links no library module. Until then, the kernel's source may use only types
  words the seed's types module holds; it does so today, since the seed's compilers build the theory extension.

## The migration in landable sub-steps

Each sub-step lands alone. Each keeps test_hello, `--stage 2` (untouched: core does not use the kernel), the
theory test areas (`bash test/wap/run.sh --wait theory`) and the census green.

| step | what | lines (kernel) | checks |
|---|---|---|---|
| T2a move | `git mv` the 12 files into wap/kernel, then a pure path edit of every `use` (elaborate 19 files, run 3, second 1, prove, door, scripts/theory-census.wap); SIZE_NODES += 21,312 | +2,241 moved, 0 new | census (418/418 typed), theory areas, test_hello |
| T2b i64 | `Numeral(i64)`, the overflow checks, magnitude out of the kernel, the `Text` literal and the new texts statement; export and second/ read it | −15, +10, +30 (outside: +22) | theory areas, test_theory_second, the new lines: a shortcut past 2^63 does not fire; a long text literal checks |
| T2c log | the log with its ids, `kept_if_given` the only take-back; the deletions above | −50, +35 | theory areas, prove's tests |
| T2d ids | `Constant(id, levels)`, `show` by id, `names_new` goes, the facts hold ids; a block's types as free variables, given their ids on acceptance, `holding` goes; the door and the elaborator resolve a written name to an id through their own scope (the extension's lines, not the kernel's) | −8 − 6, +20 + 15 (elaborate +40) | theory areas, the new line: two modules with the same name |
| T2e rules | the rule functions and the judgement table; `type_of` as their walk | +60 | theory areas; the theory census time ratio stays under 3 (checked once, then the census retires) |
| T2f census | the theory census retires: `--theory`, THEORY_ACCEPTED and THEORY_TIME_RATIO leave ratchet_census.sh; scripts/theory-census.wap stays for whoever wants its numbers | 0 | the typing census |

T2a goes first so that every later diff is read in its final place. T2b's text literal is decided (no form a
program writes changes). T2e comes last among the
kernel steps because its rules read ids.

## The estimate

| | plan (coc-plan 11) | this page |
|---|---|---|
| moved | 2,300 | 2,241 |
| judgements | 60 | 60 |
| environment by id, persistent | 40 | 35 − 50 + 20 − 8 + 15 − 6 = +6 |
| numbers | (in moved) | −15 + 10 + 30 = +25 |
| **kernel** | **+2,400** | **about +2,332** |

Outside the compiler: the elaborator about +40 for resolving names per module (deleted from T3 on), a few lines
fewer where `held` and templates copied the environment; export and second/ +22 for the text literal.

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
