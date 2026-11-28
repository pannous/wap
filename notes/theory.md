# The theory's kernel: its files and what each gives the others

The kernel of notes/coc-plan.md (sections 6 and 7) lies in `wap/kernel/` (terms.wap to integer_laws.wap below);
core typing writes a program's terms into it (`wap/core/analyze/terms.wap`), the verify door
(`wap/extensions/verify/`) judges a program's laws with it, and the export and the second checker lie in
`wap/extensions/theory/`. This note is the contract between its files: what each holds, the functions the others call, and the rules
all of them keep. The plan says what the rules are; this note says where they live.

## Files

| file | holds | plan |
|---|---|---|
| `terms.wap` | levels and terms, building them, substitution, sameness | 6.1 |
| `levels.wap` | levels compared: equal, at most, the level of a function type | 6.2 |
| `environment.wap` | declarations, the environment, the state of a check, refusals | 6.6 |
| `compute.wap` | a term computed to its head: beta, zeta, delta, iota (with K) | 6.4, 7 |
| `equal.wap` | definitional equality | 6.5 |
| `typing.wap` | a term's type; a declaration checked and added | 6.3, 6.6 |
| `show.wap` | a term shown in wap notation | below |
| `inductive.wap` | an inductive block checked | 7, checks 1 to 5 |
| `nested.wap` | a block nested in another inductive type made plain | 7, nested types |
| `recursors.wap` | recursors made, their computation rules | 7, checks 6 and 7 |
| `quotients.wap` | the statement `quotients(Equal)`: the quotient and its ways out | 6.4, 6.6 |
| `numbers.wap` | the statements `numbers(…)` and `shortcut(…)`: number literals and the seven shortcuts | 6.7 |
| `equality.wap` | `Equal` and `Equal.refl`, the equality laws state, and the laws the provers glue proofs with | T5 |
| `logic.wap` | the proposition with no proof and the one with one, and the first laws of the truths | T5 |
| `counting.wap` | the count int's cases carry, its functions and shortcuts; int, its meanings and the bridge between its two equalities | T5 |
| `integer_laws.wap` | int's laws the linear prover builds its proofs of, declared before the first goal | T5 |
| `core/analyze/courses.wap` | core's products, Pair and Unit, and each enum's below and course | 8, T5c |
| `core/analyze/holes.wap`, `unify.wap` | holes and unification, which are not trusted: notes/elaborate.md | 8 |
| `extensions/verify/` | the door: a program's laws judged by the kernel (below) | P1 |
| `extensions/prove/` | the provers, whose proofs the kernel checks | P2 |
| `extensions/theory/export.wap` | what the environment accepted written as an export, one record a line | K7 |
| `extensions/theory/second/` | the second checker: an export checked again by rules of its own | K7 |

The files use each other freely: computing, equality and typing call one another.

## What each file gives

**terms.wap**
- `Level`: `Zero`, `Successor(of)`, `Max(left, right)`, `Imax(left, right)`, `Parameter(name)`.
- `Term`, a class: `shape`, and what the walkers need at hand: `hash`, `loose` (how many binders around it its loose
  variables reach), `holds_free`, `holds_parameter`. A rule matches on `t.shape`: `Bound(index)`, `Free(id)`,
  `Sort(level)`, `Constant(name, levels)`, `Apply(function, argument)`, `Lambda(binder, domain, body)`,
  `Pi(binder, domain, body)`, `LetIn(binder, type, value, body)`, `Numeral(value)`, `Projection(structure, field, of)`.
- A term is built only by `bound`, `free`, `universe`, `constant`, `apply`, `apply_all`, `lambda`, `pi`, `let_in`,
  `numeral`, `projection`, which fill in the hash and the rest; never by `Term(…)`. `PROP`, `type_at(level)`.
- `head(t)`, `arguments(t)`: a chain of applications taken apart. `parts(t)`: the terms t is made of, in order.
- `instantiated(body, value)`: a binder's body with its variable replaced; `instantiated_all(body, values)`: the
  body under several binders, the outermost one's value first; `body_under(t, binders)`: what lies under a
  function type's first binders, for `instantiated_all`. A value put in holds no loose variable, and both refuse
  one that does. `abstracted(t, id)`: a term made the body of a binder. `with_levels(t, names, levels)`: level
  parameters replaced.
- `variable_id(variable)`: the id of a free variable. `free_variables(t)`: the ids of those a term holds.
- `same(a, b)`: the same tree, binder names aside. `level_same`, `levels_same`, `level_with`, `level_above`.

**levels.wap**
- `levels_equal(a, b)`, `level_at_most(a, b)`: for every value of the parameters.
- `is_zero(level)`, `never_zero(level)`, `simplified(level)`, `imax_level(domain, result)`.
- `level_parameters(level)`, `level_number(level)`.

**environment.wap**
- `Declaration`: `name`, `levels` (its level parameters), `type`, `kind`: `Axiom`, `Defined(value)`,
  `Theorem(value)`, `Opaque(value)`, `Inductive(facts)` (a type of a block), `Constructor(of, place, fields)` (one
  of its cases), `Recursor(facts)` and `Quotient(part)`. `unfolding(d)`: the value a use unfolds to, ø for every
  kind but a definition and a theorem.
- `Environment`, `declaration(e, name)` (ø for a name nothing declares), `declared_named(e, name)` (the refusal
  `unknown name` instead), `place(e, name)` (later declared, larger), `added(e, d)`.
- `structure_facts(e, name)`: the facts of the structure a name declares (one type, one case, no index, holding no
  value of itself), ø for any other name: what projections, eta for structures and unit eta ask.
- `InductiveBlock` (its levels, its count of parameters, its `BlockType`s, each with its `WrittenCase`s) as written,
  and `InductiveFacts`, what checks 1 to 5 found of it: the block made plain (its types first, then one `Name#k`
  for each container), each container as a function of the block's parameters (`nested`), its level, each type's
  indices, each case's fields and recursive fields, whether it is taken apart into any universe, whether it is a
  structure, whether K holds.
- `Checker`: the state of one check, made by `checker(e, levels)`. `hypothesis(c, binder, type)` gives the free
  variable of a binder gone into, `hypothesis_of(c, id)` its name and type; an id is given once in a checker's
  life. `closed_over(c, t, variables, function)`: a term closed again over variables gone into, as a function type
  or as a function. `stepped(c)` counts a step of computing. `Memory`, `remembered`, `remember`: results kept by
  term.
- `refused(rule, found)` and the rules' names.
- `axioms_of(e, name)`: every axiom a declaration rests on. `rests_on(e, name, terms, own)` records it when a
  declaration is added: an axiom rests on itself, any other declaration on what the names in its terms rest on.
- `levels_distinct(levels)`, `closed(t, name)`: the checks every declaration passes before its type is read; that
  its name is new, `added` checks. `copied(e)`: another environment holding the same declarations.

**compute.wap**
- `computed(c, t)`: t computed until its head is no beta, zeta or delta step (6.4).
- `computed_folded(c, t)`: the same without delta, so the caller chooses what unfolds. Iota is part of it: a
  recursor whose major premise computes to a case of its type takes that case's rule; with K, a proof of its
  proposition that is no case stands for the case when their types are equal.
- `unfolded(c, t)`: t with its head constant replaced by its value at its levels, ø when the head unfolds to nothing;
  a head constant nothing declares is the refusal `unknown name`.
- A head constant computes by its declaration's kind: a recursor takes iota, a quotient's lift or induct its step
  on `quotient.of`; a function a shortcut statement bound takes its shortcut on two numbers where it would unfold.
  Where a rule asks for a case, a number is zero or the successor of the number before it (6.4): iota opens its
  major premise so, and equality opens a number that stands against a case.
- Structures (K4): `projection(S, k, t)` whose value t computes, delta too, to S's case applied to all its
  parameters and fields is field k, applied to what the projection was applied to; any other projection is stuck
  and stays as written. A recursor of a structure whose major premise p computes to no case takes p as the case
  applied to the parameters of p's type and to `projection(S, k, p)` for each field; never when p is a proof
  (`is_proposition` of its type), whose data fields no projection may read.

**equal.wap**
- `equal(c, a, b)`: definitional equality (6.5), its rules in this order: the same tree; both sides computed
  without delta and compared again; proofs (rule 3: when a's type is a proposition the answer is whether the two
  types are equal, and it is final); the unfolding loop, the later-declared head first, heads of one name compared
  before they unfold; two terms of one shape, part by part, two projections of one structure and field by their
  values; then, each tried both ways, a number opened against a case, eta for functions, eta for structures (a
  structure's case applied to all its parameters and fields against a term t of an equal type: each field equal to
  `projection(S, k, t)`), and last unit (a term whose type computes to a structure without fields equals any term
  of an equal type).
- A pair found equal is kept for the rest of the check, open terms too: a free variable is made once. A pair found
  unequal is not kept.

**typing.wap**
- `type_of(c, t)`: the type of t, or a refusal (6.3). Its rules: `unknown name`, `level count`, `level parameter`,
  `not a function`, `argument type`, `value type` (a let's value), `not closed`, `no numbers` (a number before a
  numbers statement), and for a projection `not a structure` (the value's type is no structure, or has no such
  field) and `data out of a proof` (the value is a proof and the field is data, or a later field's type names it).
- `is_proposition(c, type)`: whether a type lies in Prop.
- `level_of(c, type)`: the level of the sort a type lies in; the refusal `not a type` when it lies in none.
- `declared(e, d)`: an axiom, a definition, a theorem or an opaque constant checked (6.6) and then part of e, with
  what it rests on recorded. Its rules beside those of typing: `name taken`, `level parameter`, `not closed`,
  `value type`, `not a proposition`.

**inductive.wap**
- `inductive_declared(e, block)`: the block checked (7, checks 1 to 5), its types and cases added, its facts given
  for the recursors; each type and case rests on the axioms its type names. Binders are entered as written: a header
  or case type written as no function type where one is wanted is refused. Its rules: `enum header`, `case type`,
  `parameters`, `case result`, `field universe`, `strict positivity`.

**nested.wap**
- `unnested(c, block, parameters)`: each container a type of the block is nested in, `list(Tree)`, becomes one more
  type of the block, with the container's cases copied in at its levels and parameters, and every occurrence of it is
  replaced by that type; the plain block goes through checks 1 to 5 unchanged. A container holding a type of the
  block in an index, or a variable of the case in a parameter, is refused by `strict positivity`; so is one that uses
  its parameter negatively, when the plain block is checked.

**recursors.wap**
- `recursors_made(e, facts)`: one recursor per type of a declared block, `<type>.recursor`, each one's type checked
  by typing; inductive_declared adds them. Its level parameters: a level for the motives first where the block may
  be taken apart into any universe (named so no program can write it), then the block's. Its binders: the
  parameters, one motive per type, one minor premise per case of the block (a case's fields, then an induction
  hypothesis per field of a type of the block), the type's indices, the major premise. Its `Recursor` facts hold one
  closed rule per case for iota. The types nested.wap added for containers are turned back into the containers, in
  every type, rule and case name.

**quotients.wap**
- `quotients_declared(e, equality)`: the statement `quotients(Equal)`. Equality must have the shape of `Equal`; the
  four constants `quotient`, `quotient.of`, `quotient.lift` and `quotient.induct` are checked by typing and added,
  resting on nothing. Computing (compute.wap) takes lift or induct applied to `quotient.of(T, r, a)` to the function
  applied to `a`. That joined values are equal is no rule of the kernel: it is an axiom, `quotient_sound`, which the program that
  needs it declares.

**show.wap**
- `shown(t)`: a term in wap notation; reading that text gives the same term again. A binder whose variable the rest
  does not use is shown without its name, `a -> b`; arrows nest to the right without brackets, and a function type
  as a domain has them, `(a -> b) -> c`.

**equality.wap, logic.wap, counting.wap, integer_laws.wap**
- Blocks and theorems core declares into every compile's environment (core/type_notation.wap `core_environment`),
  each checked as it is declared: `equality_declared`, `logic_declared`, `count_declared`, `int_declared`. Their own
  names carry the mark `·`, so no program writes or meets them; `Equal` is the one a law states.
- `equated(e, level, type, a, b)`: `Equal(type, a, b)`; `truth_stated(e, value)`: the proposition that a bool is yes.
- `integer_laws_ready(e)`: int's laws declared once, before the first goal a prover is given (prove/goals.wap).

## Rules every file keeps

- **Closed terms only.** `computed`, `equal` and `type_of` never get a term with a loose variable. A function that
  goes under a binder first replaces its variable: `instantiated(body, hypothesis(c, binder, domain))`. So
  `instantiated` never shifts anything, and a free variable's type is always at hand.
- **Names are hints.** A binder's name is for `shown` only. No rule reads one.
- **Steps are counted.** Every beta, zeta and delta step calls `stepped(c)`. The budget turns a check that would not
  end into the refusal "gave up", the same on every machine.
- **Refusals name their rule.** A rule that does not hold calls `refused(rule, found)`: the rule's name in plain
  words from environment.wap, then one sentence saying what was found, its terms shown with `shown`. Nothing is
  printed and nothing else is raised. A new rule gets its name in environment.wap.
- **Nothing is guessed.** The kernel finds no level, no argument and no conversion. What is missing is a refusal.
- **Results kept by term.** A result is kept (`remember`) for the life of the checker, one declaration: `computed`
  keeps it for a term without free variables, `type_of` and `equal` for any term, since a free variable is never
  made twice. A hypothesis's type is filled as it is read (`Checker.filled_in`, set by core/analyze/holes.wap):
  `type_of` looks a free variable alone up each time, and a kept type of a larger term still holds the unfilled hole,
  which every reader of the elaboration fills in; `equal` keeps only pairs found equal, which a filled hole leaves equal.
- **No library word.** No file names a type or function of the prelude. A rule that needs one gets it by a
  declaration (plan 5.4).
- **Never `==` on a term.** Terms and levels are compared by `same`, `level_same` and `levels_equal`, and a map is
  keyed by a term's `hash` through `Memory`, never by the term: `==` on a program's own recursive enum and a map's
  hash of one are two of the limits of "Costs" below. An optional value is tested with `is ø`.
- **Each file names what it uses.** `use` is not transitive: a file that names a `Shape` case uses terms.wap
  itself, even when it also uses a file that does.
- **A list is a value.** A list handed to a function is the function's own: `found += [x]` there never reaches
  the caller. What a walk gathers it gives back as its result, or puts into a map or a field of a class, which the
  caller shares.

## The declarations that bind names

The kernel names no type of the prelude (plan 5.4). Statements bind the ones a mechanism needs, each checked and
each standing once; core declares the products itself.

**`quotients(Equal)`** (K5, plan 6.6). `Equal` must have the shape of equality: a block of one type with one level
parameter `u`, the parameters `T: Sort(u)` and `a: T`, one index of type `T`, in `Prop`, and one case without
fields whose result is `Equal(T, a, a)`. The statement adds four constants:

| constant | type |
|---|---|
| `quotient[u]` | `(T: Sort(u)) -> (r: T -> T -> Prop) -> Sort(u)` |
| `quotient.of[u]` | `(T: Sort(u)) -> (r: T -> T -> Prop) -> T -> quotient[u](T, r)` |
| `quotient.lift[u, v]` | `(T: Sort(u)) -> (r: T -> T -> Prop) -> (B: Sort(v)) -> (f: T -> B) -> ((a: T) -> (b: T) -> r(a, b) -> Equal[v](B, f(a), f(b))) -> quotient[u](T, r) -> B` |
| `quotient.induct[u]` | `(T: Sort(u)) -> (r: T -> T -> Prop) -> (motive: quotient[u](T, r) -> Prop) -> ((a: T) -> motive(quotient.of[u](T, r, a))) -> (q: quotient[u](T, r)) -> motive(q)` |

Computing (6.4), the last argument computed first: `quotient.lift[u, v](T, r, B, f, h, quotient.of[u](T, r, a))` is
`f(a)`, and `quotient.induct[u](T, r, motive, h, quotient.of[u](T, r, a))` is `h(a)`. That joined values are equal is
an axiom the program that needs it declares, written like any other: `axiom quotient_sound(T: Sort(u), r: T -> T -> Prop, a: T, b: T):
r(a, b) -> Equal[u](quotient[u](T, r), quotient.of[u](T, r, a), quotient.of[u](T, r, b))`.

**The products** (core/analyze/courses.wap `products_declared(e)`). Core declares two blocks into every compile's
environment, `enum Pair(A: Sort(u), B: Sort(v)): Sort(max(1, max(u, v))) { intro(first: A, second: B) }` and
`enum Unit: Sort(u) { unit }`. From then on an enum of one type that
eliminates into any sort, with no field a function into it, gets two definitions the first time a recursion asks:
`T.below[u, …](params, motive, indices, t): Sort(max(1, u))`, by the recursor into types, each case the pairs of its
recursive fields' motive and their own below, ending in Unit; and `T.course[u, …](params, motive, step, indices, t):
motive(indices, t)`, the first of the recursor's pair of the motive's value and the values below, where step takes
the indices, the value and its below. The kernel checks both like any definition.

**`numbers(nat, bool.yes, Equal)`** (K3, plan 6.7). `nat` must be a block of one type without parameters, indices
or level parameters, in `Type`, with a case without fields and then a case with one field of `nat`; `bool.yes` a
case of a block of one type with two cases without fields, in `Type`; `Equal` as above. From then on a number has
the type `nat`, and where a rule asks for a case, 0 is the first case and n + 1 the second applied to the number n.

**`texts(text_of, list.empty, list.item)`** (plan 5.4), numbers.wap `texts_declared(e, function, empty_case,
item_case)`. A text literal is the kernel's second literal. The block of `empty_case` must have the shape of
`enum list(T: Sort(u)): Sort(max(1, u)) { empty: list(T), item(first: T, rest: list(T)): list(T) }`, with
`empty_case` its first case and `item_case` its second; `text_of` must be `list[1](nat) -> X` without level
parameters, and the statement comes after the numbers statement and stands once. From then on a text literal has
the type `X`, and where a rule asks for a case it is `text_of` applied to the list of its code points, each a number.

**`shortcut(kind, function, theorems…)`**, one per shortcut, in the order of this table. `N` is the number type, `Z`
and `S` its cases, `yes` and `no` the truth values. The kernel builds each statement as written here, the `==`
being `Equal[1]` at `N` or at the truth values' type. A statement binds only the variables it names, `m` before `n`,
each of `N`: `f(m, Z) == m` is `(m: N) -> …`, and `f(Z, Z) == yes` has no binder:

| statement | function | the theorems, in order |
|---|---|---|
| `shortcut(add, f, …)` | `f: N -> N -> N` | `f(m, Z) == m`; `f(m, S(n)) == S(f(m, n))` |
| `shortcut(subtract, f, …)` | `f: N -> N -> N` | `f(m, Z) == m`; `f(Z, n) == Z`; `f(S(m), S(n)) == f(m, n)` |
| `shortcut(multiply, f, …)` | `f: N -> N -> N`, after add `g` | `f(m, Z) == Z`; `f(m, S(n)) == g(f(m, n), m)` |
| `shortcut(equal, f, …)` | `f: N -> N -> bool` | `f(Z, Z) == yes`; `f(S(m), Z) == no`; `f(Z, S(n)) == no`; `f(S(m), S(n)) == f(m, n)` |
| `shortcut(at_most, f, …)` | `f: N -> N -> bool` | `f(Z, n) == yes`; `f(S(m), Z) == no`; `f(S(m), S(n)) == f(m, n)` |
| `shortcut(divide, d, r, …)` | `d`, `r: N -> N -> N`, after add `g`, multiply `p`, at most `l` | `g(p(d(m, n), n), r(m, n)) == m`; `d(m, Z) == Z`; `l(r(m, S(n)), n) == yes` |
| the kernel's own int difference `d` (no statement binds it) | `d: N -> N -> int` | `d(Z, Z) == zero`; `d(S(m), Z) == positive(m)`; `d(Z, S(n)) == negative(n)`; `d(S(m), S(n)) == d(m, n)` |

A theorem licenses its shortcut when it is a declared theorem whose type is the built statement (`same`, so binder
names aside) and neither it nor the function rests on an axiom (`axioms_of` is empty for both). A shortcut fires
only on its bound constant, without levels, applied to two numbers, and gives what the arithmetic of numbers
without a bound gives: a number, or a truth value. A statement the order forbids is refused: multiply needs add
bound, divide needs add, multiply and at most. The rules these statements refuse by are `numbers` (a shape that
is not the wanted one, a second numbers statement) and `shortcut` (a function's type, a theorem's statement, an
axiom rested on, a function bound already or needed and not bound).

## The door

`wap verify program.wap` (wap/extensions/verify/verify.wap, run as `verify.wasm --seed <seed folder> program.wap` by
the native wap, or with `--tree <root>`, options.wap) reads a program in plain wap. The program goes through the
compile's front and core typing (laws.wap `laws_typed`): each law becomes the bool function of its binders
(extensions/law_statements.wap), and core enters each pure function into the compile's environment as a kernel
definition (core/analyze/terms.wap); any other stays an opaque constant, an assumption. Each law then gets one
verdict, in the order the program states them:
- a law without binders is computed: `Proved` where it computes to yes, `FAILED` where it computes to no;
- a law with binders is `Proved` where the provers prove `Equal(f(x…), yes)` for every value of its binders, under
  its hypotheses and the conditions of its binders' subtypes, and the kernel checks the proof as a theorem of the law's name, so a
  later proof uses it;
- any other is `Untested`, and the run's verdict stands in its place (native/driver.wap).

A law whose function the kernel only assumes is refused, naming the first function its body calls that the kernel
only assumes. A refusal is printed in its law's place; the first refusal of the program ends the run. The run fails
when a law does. test/wap/test_theory_verify.wap gives programs and compares what the door says.

## The run trust base

What runs is believed where the kernel cannot see it (notes/coc-plan.md 9.7, 10.2). The kernel judges a program's
laws; the program itself runs as the compiler emits it, so what the kernel's terms mean and what the machine does are
joined only by these beliefs, kept small:

| what | in the kernel | runs as | believed |
|---|---|---|---|
| a whole number literal | int's case over a count numeral (core/analyze/terms.wap `int_numeral`) | a machine int | |
| the count's numerals | computed natively by the shortcuts `numbers_declared` binds (kernel/numbers.wap), each fixed by theorems the kernel checks (counting.wap) | | the native computation is the recursion's |
| int's host rows, `i64.add` … `i64.ge_s` on two ints | defined as their meanings, `·sum`, `·not_above` … (counting.wap `INT_MEANINGS`) | the machine's operation | it computes what the meaning does, below the wrap: one past 2^63 wraps where the kernel's int does not |
| any other host row | an opaque constant `prim <operation> <types>` that computes by the host's operation (kernel/compute.wap `row_step`) | the machine's operation | what the operation does |
| a text literal | its code points | wap's text | |

A function the kernel only assumes (it writes, raises or acts) is an axiom, and a law naming it is refused
(extensions/verify/laws.wap), so no belief about its effects enters a proof.

The compiler adds one outside the theory: its warm state (extensions/warm.wap). The rules it brings in were checked
to terminate when the state was written, and `rules_checked` marks them checked without checking them again, so the
rules of a warm state are believed as built.

## A second opinion

`export.wap` writes an environment out in Lean 4's export format with wap's own names, one JSON record a line,
described at its top: a declaration as stated, a block as written, a binding statement with its names. A block's
cases, recursors and the quotients' constants are never written: the reader makes them again. No door calls it.

`second/` checks an export again, `wap second/check.wap <export> [<name>…]`, silent when it accepts and printing the
first refusal otherwise; each name given prints the axioms it rests on. It shares no function with the kernel and
reads only the export, so a mistake in one is caught by the other unless both make it. It is kept as small as it can
be: no elaboration, no caches, a term compared by its tree. Its files: `check.wap` (the command: the export read and
checked, the names' axioms printed), `expressions.wap` (levels and terms),
`read.wap` (the export read, a record out of order or of no known kind refused), `judge.wap` (typing, computing,
equality, a declaration admitted), `blocks.wap` (a block checked, its recursors and their computation, structures),
`nested.wap` (a nested block made plain, apart from the kernel's), `bindings.wap` (numbers, shortcuts and
quotients).

## Costs

Three limits of wap's shapes, and the kernel is written around them:
- **The stack** holds between 200,000 and 400,000 frames, and a call of itself in last place is not made a loop:
  chains are walked in loops, and recursion stays below 100,000 deep.
- **`==` on a recursive enum** costs twice as much per level of depth, so a term is never compared with `==`:
  `same(a, b)` compares the hash first, then the tree.
- **A map keyed by an enum value** hashes the case name only, so terms that share a head share a slot: caches are
  keyed by a term's int `hash`.
No two terms are made one (interning): `same` stays the one place that would change when shared terms cost too much.
