# The theory's kernel: its files and what each gives the others

The kernel of notes/coc-plan.md (sections 6 and 7) lies in `wap/kernel/` (terms.wap to numbers.wap below); the door,
the elaborator, the prelude and the rest of this table lie in `wap/extensions/theory/`, a module of its own beside the
compiler. This note is the contract between its files: what each holds, the functions the others call, and the rules
all of them keep. The plan says what the rules are; this note says where they live.

## Files

| file | holds | plan | card |
|---|---|---|---|
| `terms.wap` | levels and terms, building them, substitution, sameness | 6.1 | theory-terms |
| `levels.wap` | levels compared: equal, at most, the level of a function type | 6.2 | theory-terms |
| `environment.wap` | declarations, the environment, the state of a check, refusals | 6.6 | theory-terms |
| `compute.wap` | a term computed to its head: beta, zeta, delta, iota (with K) | 6.4, 7 | theory-computing |
| `equal.wap` | definitional equality | 6.5 | theory-equality |
| `typing.wap` | a term's type; a declaration checked and added | 6.3, 6.6 | theory-typing |
| `explicit.wap` | a program in the explicit spellings read into terms and declarations | below | theory-explicit |
| `show.wap` | a term shown in wap notation | below | theory-explicit |
| `check.wap` | the door: a program checked statement by statement | below | theory-explicit |
| `inductive.wap` | an inductive block checked | 7, checks 1 to 5 | theory-inductive-checks |
| `nested.wap` | a block nested in another inductive type made plain | 7, nested types | theory-inductive-checks |
| `recursors.wap` | recursors made, their computation rules | 7, checks 6 and 7 | theory-recursors |
| `quotients.wap` | the statement `quotients(Equal)`: the quotient and its ways out | 6.4, 6.6 | theory-quotients |
| `numbers.wap` | the statements `numbers(…)` and `shortcut(…)`: number literals and the seven shortcuts | 6.7 | theory-numbers |
| `below.wap` | the statement `products(Pair, Unit)`: each enum's below and course | 8, E2 | theory-below |
| `bindings.wap` | the statements that bind names, read and sent to their files | below | theory-below |
| `prelude/logic.wap` | the logic as an explicit program: False, True, And, Or, Not, Equal, Exists, bool, Decidable | L1 | theory-prelude-logic |
| `prelude/quotient.wap` | the quotients bound, their axiom, function extensionality proved | K5 | theory-quotients |
| `prelude/numbers.wap` | nat with its shortcuts and the theorems that license them, the comparisons, int with its sum and product | L2 | theory-prelude-numbers |
| `prelude/effects.wap` | the effect sets, the one opaque family of computation types `Eff`, `never`, `pure`, `bind`, Error and `Fallible` (`T or Error`) | L4 | theory-prelude-effects |
| `prelude/checked.wap` | the checked types as subsets and quotients of plain carriers: `Subset`, rationals, i64, sets and maps | L5 | prelude-collections-rationals |
| `elaborate/` | the elaborator, which is not trusted: notes/elaborate.md | 8 | theory-arguments-found and after |
| `export.wap` | what the environment accepted written as an export, one record a line | K7 | theory-second-opinion |
| `second/` | the second checker: an export checked again by rules of its own | K7 | theory-second-opinion |

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
- `names_new(e, names)`, `levels_distinct(levels)`, `closed(t, name)`: the checks every declaration passes before
  its type is read. `copied(e)`: another environment holding the same declarations.

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
  applied to `a`. That joined values are equal is the prelude's axiom `quotient_sound` (prelude/quotient.wap), from
  which `function_extensionality` is proved.

**explicit.wap, show.wap, check.wap**
- `statement_read(e, statement)`: one statement of an explicit program as a `Statement`: `Declares(declaration)`,
  `AsksType(of)` or `Quotients(equality)`. A block `{…}` is read as its bindings and the term they lead to, so a
  value written on the lines below its head reads as that one term.
- `shown(t)`: a term in wap notation; reading that text gives the same term again. A binder whose variable the rest
  does not use is shown without its name, `a -> b`; arrows nest to the right without brackets, and a function type
  as a domain has them, `(a -> b) -> c`.
- `check.wap` is the program `wap wap/extensions/theory/check.wap program.wap`, run from the tree's root.

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
  made twice. The elaborator fills a hypothesis's type in place (elaborate/read.wap `bound_over`): `type_of` looks a
  free variable alone up each time, and a kept type of a larger term still holds the unfilled hole, which every
  reader of the elaborator fills in; `equal` keeps only pairs found equal, which a filled hole leaves equal.
- **No library word.** No file names a type or function of the prelude. A rule that needs one gets it by a
  declaration (plan 5.4).
- **Never `==` on a term.** Terms and levels are compared by `same`, `level_same` and `levels_equal`, and a map is
  keyed by a term's `hash` through `Memory`, never by the term: `==` on a program's own recursive enum and a map's
  hash of one are what "Costs" below measures. An optional value is tested with `is ø`.
- **Each file names what it uses.** `use` is not transitive: a file that names a `Shape` case uses terms.wap
  itself, even when it also uses a file that does.
- **A list is a value.** A list handed to a function is the function's own: `found += [x]` there never reaches
  the caller. What a walk gathers it gives back as its result, or puts into a map or a field of a class, which the
  caller shares.

## The explicit spellings

A program for the door writes every argument and every type. Nothing is found for it: these spellings are a corner
of the language, and each is read as its term directly.

| written | term |
|---|---|
| `Prop`, `Type`, `Type(u)`, `Sort(u)` | `Sort`: at level 0, 1, u + 1, u |
| a level: `0`, `2`, `u`, `u + 1`, `max(u, v)`, `imax(u, v)` | `Level` |
| `(x: A) -> B`, `A -> B` | `Pi` |
| `(x: A) => b` | `Lambda` |
| `f(a, b)` | `Apply(Apply(f, a), b)` |
| `f[u, v]` | `Constant` at those levels; a constant without level parameters is written bare |
| `{ x: A = v; b }` | `LetIn` |
| `axiom name: type`, `axiom name(x: A): B` | an axiom; parameters make a function type |
| `name(x: A): B := value`, `name: B := value` | a definition; parameters make a function type and a function |
| `law name(x: A): statement := proof` | a theorem |
| `opaque name(x: A): B := value` | an opaque constant |
| `enum Name(p: A): I -> Sort(u) { case(x: B): Name(p, i) }` | a type of an inductive block: what stands after the name are the parameters, the same in every case; the result type holds the indices; each case writes its fields and its result in full. Inside its own block a type stands without levels. Enum statements that stand next to each other and name one another are one block |
| `Name.recursor[v, u](parameters, motive, one minor premise per case, indices, major premise)` | the recursor: the motive's level first, where the type may compute into any universe; a minor premise takes the case's fields and then the induction hypothesis of each field of the type itself |
| `projection(Pair, 1, p)` | `Projection`: the first field of p, a value of the structure Pair (K4) |
| `type of e` | the question for e's type |

A level name in a declaration that nothing binds is a level parameter of it, in the order of first appearance. A
name is looked up among the binders around it, innermost first, then among the declarations; anything else is the
refusal "unknown name".

Read by the elaborator's door, a prelude file's declaration of a name taken is an overload of it, by the key the
elaborator gives its own (the name and its own binders' types after the found ones). The binders an elaborated program's call finds of an
explicit declaration are its leading sorts that a later binder's type names (the letters of an elaborated header);
a call giving every binder its header has, as an explicit program does, finds none, and a result that is itself a
function type takes no part in that count.

## The declarations that bind names

The kernel names no type of the prelude (plan 5.4). Four statements of the explicit corner bind the ones a
mechanism needs (bindings.wap), and `texts` a fifth. Each is checked; `quotients` and `numbers` stand once, and a later `products`
stands instead of an earlier one, as a below already made keeps the pair it was made of.

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
an axiom of the prelude, written like any other: `axiom quotient_sound(T: Sort(u), r: T -> T -> Prop, a: T, b: T):
r(a, b) -> Equal[u](quotient[u](T, r), quotient.of[u](T, r, a), quotient.of[u](T, r, b))`.

**`products(Pair, Unit)`** (E2). `Pair` must have the shape of `enum Pair(A: Sort(u), B: Sort(v)): Sort(max(1, max(u,
v))) { intro(first: A, second: B) }`, `Unit` of `enum Unit: Sort(u) { unit }`. From then on an enum of one type that
eliminates into any sort, with no field a function into it, gets two definitions the first time a recursion asks:
`T.below[u, …](params, motive, indices, t): Sort(max(1, u))`, by the recursor into types, each case the pairs of its
recursive fields' motive and their own below, ending in Unit; and `T.course[u, …](params, motive, step, indices, t):
motive(indices, t)`, the first of the recursor's pair of the motive's value and the values below, where step takes
the indices, the value and its below. The kernel checks both like any definition.

**`numbers(nat, bool.yes, Equal)`** (K3, plan 6.7). `nat` must be a block of one type without parameters, indices
or level parameters, in `Type`, with a case without fields and then a case with one field of `nat`; `bool.yes` a
case of a block of one type with two cases without fields, in `Type`; `Equal` as above. From then on a number has
the type `nat`, and where a rule asks for a case, 0 is the first case and n + 1 the second applied to the number n.

**`texts(text_of, list.empty, list.item)`** (L3, plan 5.4, notes/coc-t2.md, from T2b). A text literal is the
kernel's second literal. `list` must have the shape of prelude/data.wap's: one type with one level parameter `u` and
one parameter `T: Sort(u)`, in `Sort(max(1, u))`, a case without fields, then a case of a `T` and a list of `T`;
`text_of` must be `list[1](nat) -> X` without level parameters, after the numbers statement. From then on a text
literal has the type `X`, and where a rule asks for a case it is `text_of` applied to the list of its code points,
each a number. Until T2b the statement is `texts(text_of)`, and a literal is `text_of` of the number that spells it:
a 1 and then its code points, base 0x110000.

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

A theorem licenses its shortcut when it is a declared theorem whose type is the built statement (`same`, so binder
names aside) and neither it nor the function rests on an axiom (`axioms_of` is empty for both). A shortcut fires
only on its bound constant, without levels, applied to two numbers, and gives what the arithmetic of numbers
without a bound gives: a number, or a truth value. A statement the order forbids is refused: multiply needs add
bound, divide needs add, multiply and at most. The rules these statements refuse by are `numbers` (a shape that
is not the wanted one, a second numbers statement) and `shortcut` (a function's type, a theorem's statement, an
axiom rested on, a function bound already or needed and not bound).

## The door

`check.wap` reads a program and takes its statements in order. A declaration is checked and added; nothing is said
when it is accepted. `type of e` prints the type. The first refusal is printed as its one line, `refused by <rule>:
<what was found>`, and ends the run with a failing exit code. The output is the test: test/wap/test_theory.wap gives
a program and compares what the door says. A line for a refusal compares the part before the colon only.

## The run trust base

What runs is believed where the kernel cannot see it (notes/coc-plan.md 9.7, 10.2): the kernel's own computation
(from T2b its shortcuts on i64 with the overflow check, and a text literal opened into its code points), and
the layouts of the prelude, each a `runs(…)` statement after the declaration it is about, which erase reads in place
of the declaration's value (`elaborate/file.wap` layout_noted). Only the prelude writes them: every door refuses a
program's own. Nothing checks them before a program's terms run: `run/erase.wap` layouts_checked has no caller. A spelling that
is a host operation, `prim i64.add(m, n)`, is checked against its row in the table of the host's operations
(wap/kernel/primitives.wap): its operands, the parameters it names at the wasm types their values run as (`nat`'s as an
int, an i64), numbers and the operations inside it, are exactly the wasm types the row takes, and the row gives the
wasm type of the declaration's value. Any other spelling (a list's, until lists have their rows) is host code, which
wap's own typer types as the value of a definition of the parameters it names, a case's test as a bool and its fields
as their wap types, a type's spelling as a wap type. What is checked is only that a spelling fits; that it means what
the theory's word means is believed, and tested by the laws run on values. The set is kept small:

| what | runs as | believed |
|---|---|---|
| `nat`, `int` | a machine int: `nat.zero`, `nat.successor`, `int.of_nat`, `int.negative_successor` by their tests and fields | the tests split the ints as the cases split the numbers, and `i64.sub(it, 1)`, `i64.sub(-1, it)` undo the cases |
| `bool` | wap's bool: `bool.no`, `bool.yes` | |
| `add`, `multiply`, `equals` | the machine's `i64.add`, `i64.mul`, `i64.eq` on two nats | they compute what the recursions do, below the wrap |
| `minus`, `sum`, `times`, `negative`, `equal_integers` | the machine's `i64.sub` from 0, `i64.add`, `i64.mul`, `i64.lt_s` with 0, `i64.eq` on ints | as above |
| `negated` | `i32.eqz` | |
| `list`, `count`, `item_at`, `drop`, `joined`, `mapped` | wap's list: `list.empty`, `list.item` by `#it == 0`, `#it > 0`, `it#1`, `drop(it, 1)`; `#xs`, `xs#i`, `drop(xs, n)`, `xs + ys`, `xs.map(f)` | wap's list functions count, index, drop, join and map as the recursions do |
| `Subset` | its value: `Subset.intro` as the value, its proof gone | |
| `Eff`, `pure`, `bind` | a computation as its value, `pure(x)` as x, `bind(c, next)` as `next(c)` | a computation's effects happen as it runs |

A number runs as a machine int, so one past 2^63 wraps where the theory's does not.

The types module adds two more, made by the declarations themselves (elaborate/declare.wap), never by a `runs(…)`:
- **Its words the prelude has too.** A declaration with the signature of a prelude declaration is that declaration:
  proofs read the prelude's definition, and the program runs the types module's function for it, by its name, where
  the prelude lays out none. The signature is the name, the parameters' types and the result's. The pairs, every
  declaration of the types module whose signature a prelude declaration has: int's `+`, `-` (both arities), `*`,
  `==`, `<`, `<=`, `>`, `>=`, and text's `+` (types/texts.wap's `+(a: text, b: text)`). Every other function of the types module runs its own body, as
  the theory read it. A name is laid out once: a second layout of it is refused, never a silent replacement.
- **The host's operations.** A function of the types module whose body is `prim …` is a constant of its written
  type, never unfolded; it runs as the host's operation. One giving a proposition, or a type that may be one (a
  letter's), is refused as a hosted proposition (an opaque proof of an empty type would prove anything), and one with
  neither a written type nor a limit after its body (`! IO`) too, since nothing says what it does. A program's own
  `prim …` is refused: what it runs would be believed unproved, as a program's `runs(…)` would.

The compiler adds one outside the theory: its warm state (extensions/warm.wap). The rules it brings in were checked
to terminate when the state was written, and `rules_checked` marks them checked without checking them again, so the
rules of a warm state are believed as built.

## A second opinion

A program either door accepts can be written out: `export("file")` writes what the environment accepted, in order
and as it was given (a declaration as stated, a block as written, a binding statement with its names). The format is
Lean 4's export format with wap's own names, one JSON record a line, described at the top of `export.wap`. A block's
cases, recursors and the quotients' constants are never written: the reader makes them again.

`second/` checks an export again, `wap second/check.wap <export> [<name>…]`, silent when it accepts and printing the
first refusal otherwise; each name given prints the axioms it rests on, as `axioms of` does. It shares no function
with the kernel and reads only the export, so a mistake in one is caught by the other unless both make it. It is kept
as small as it can be: no elaboration, no caches, a term compared by its tree. Its files: `expressions.wap` (levels
and terms), `read.wap` (the export read, a record out of order or of no known kind refused), `judge.wap` (typing,
computing, equality, a declaration admitted), `blocks.wap` (a block checked, its recursors and their computation,
structures), `bindings.wap` (numbers, shortcuts and quotients). test/wap/test_theory_second.wap gives it the preludes
and mutual, indexed and level-polymorphic blocks with a projection (nested blocks are left out), compares its axioms
with the door's, and hands it forged exports that it must refuse.

## Costs

What the kernel's shapes cost in wap as it compiles today, measured by the probes in data/k0/ (native wap, one run
each, 10 million steps unless said):

| measured | time |
|---|---|
| a term built, `App(Var, Lit)` | 119 ms |
| a match over twelve cases | 190 ms; each case built and matched, 161 ms |
| recursion 100,000 deep | 1 ms |
| a loop written as a call of itself in last place, 100 × 100,000 | 93 ms, against 6 ms for `while` |

Three limits follow, and the kernel is written around them:
- **The stack** holds between 200,000 and 400,000 frames, and a call of itself in last place is not made a loop:
  chains are walked in loops, and recursion stays below 100,000 deep.
- **`==` on a recursive enum** costs twice as much per level of depth, so a term is never compared with `==`:
  `same(a, b)` compares the hash first, then the tree.
- **A map keyed by an enum value** hashes the case name only, so terms that share a head share a slot: caches are
  keyed by a term's int `hash`.
No two terms are made one (interning) yet: `same` stays the one place that would change when shared terms cost too much.
