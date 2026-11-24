# The elaborator: its files and what each gives the others

The elaborator of notes/coc-plan.md (section 8) turns a program as it is written into complete terms and hands
every declaration to the kernel (notes/theory.md). It lies in `wap/extensions/theory/elaborate/` until the switch
and is reached through a door of its own, `elaborate/door.wap`. It is not trusted: whatever it builds, the kernel's
`declared` and `inductive_declared` judge. This note is the contract for its first four milestones: E1 (arguments
found), E2 (enums, classes, match, recursion), E3 (operators, traits, conditions) and E4 (subtypes and
obligations).

## What it reads and writes

- **Reads** a program's statements as the reader gives them (`statements_of`, as check.wap does): an enum or a class
  as written, read by explicit.wap's enum reader, the one the kernel's door uses; any other statement lowered alone
  first (wap/kernel/forms.wap: Call, Fn, Define, If, Block, literals, Symbol). Before lowering, a statement is
  rewritten by the shape rules of the tree the door is given (`--tree <root>`, its `wap/` folder loaded into a
  language of its own, `Theory.spellings`), and lowered by that language: so `if c then a else b` arrives as
  If(c, a, b), `match s { … }` as Case(s, Arm…), a dotted name as Get(subject, "name"), and `list.item(x, r)` as
  `item(list, x, r)`, which a name read finds as `list.item` when `item` alone names nothing. A form or name read no
  other way is tried once more through those rules before it is refused. Lowering is the input of today's pipeline, which the elaborator replaces, so it
  lowers no enum form the kernel needs (parameters, result types). It does not read today's binding or typing
  facts: it resolves names itself. A type is read by the same function as a value: there is one reader of
  expressions. Two forms are the reader's own, since a type is a value now:
  - a type after a colon is not lowered (`Type(1)` is Key(Type, None, (1)) there and a call where a value
    stands): the reader takes both;
  - `->` is the function type wherever it stands and `=>` the one arrow of a function value (wiki/closure.md):
    `(A: Type) -> A` where a value stands is the call of `->` on its binders and its result, never an Fn.
- **Theorems, laws and axioms** arrive as their word called on the declaration (wap/sugar/definitions.wap):
  `theorem four: 2 + 2 == 4 := refl` as `theorem(Define(four: 2 + 2 == 4, (), refl))`, a proved one the definition of
  its proof; `axiom int: Type` as `axiom(int: Type)`. One without a value whose name takes parameters is one of a
  function type: `axiom f(x: A): B` arrives as `axiom(f: (x: A) -> B)`, the type lowered as a written one is.
  `declaration_elaborated` (elaborate/declare.wap) takes them all. A theorem without a proof is refused; a law
  without one is elaborated and kept in `Theory.unproved_laws`, never declared, so a proof naming it is refused; an
  axiom is an `Axiom`.
- **Writes** declarations into the theory's `Environment` through `declared` and `inductive_declared`, and
  nothing else. A term it hands over holds no hole.
- **The door** `elaborate/door.wap --tree <root> program.wap` loads the prelude (`wap/extensions/theory/prelude/`), elaborates the
  program statement by statement, and prints as the kernel's door does: nothing for an accepted declaration, the
  value's type for `type of e`, a refusal as `refused by <rule>: …`. The kernel's own door, `check.wap`, stays the
  door of the explicit programs.

## Holes

A hole stands for what the program left out: a letter's value, a level, a `_`. A hole for a term is a free variable
of the kernel (`hypothesis(c, name, type)`) that the elaborator may answer; so the kernel's `type_of` and `computed`
work on a term with holes as they are, a hole being a variable nothing is known of. A hole for a level is a level
parameter whose name starts with `?`.

**A hole is a function of the binders in scope.** Under the binders `x` and `y` a hole of type `T` is made as a
variable of type `(x: X) -> (y: Y) -> T`, and what the reader gets is that variable applied, `?h(x, y)`. So:
- a binder that closes binds its variable inside `?h(x, y)` like anywhere else, also when the hole has no answer
  yet; an answer found after the binder closed is still good;
- an answer names no binder at all, only its own parameters and other holes. It is a closed function, put in
  anywhere as it is. No order of making and no scope is asked when an answer is given: "names a binder" is the
  whole test, and it is what keeps a variable from escaping its binder.

`Elaboration` is the state of one declaration: a `Checker`, the binders in scope (their variables, the outermost
first; a binder's name is its hypothesis's), the holes with their answers, and the problems put off.
- `scoped(el, binder, type)`: a binder gone into, in scope from here; `unscoped(el, variables)`: binders left
  again; `named(el, name)`: the innermost binder in scope of a name. The reader enters every binder so, a
  definition's parameters and its letters too.
- `hole(el, name, type)`: a new hole over the whole scope. `hole_over(el, name, type, variables)`: one over these
  binders only, for a letter's type, which may depend on the letters before it and on nothing written.
  `level_hole(el)`: a new level hole.
- `filled(el, t)`: t with every answered hole replaced by its answer, levels too; an answered hole applied to its
  arguments is the answer's body with them put in. It goes under a binder by a free variable, as the kernel does,
  so what is put in is closed. A term is filled before it is computed, compared or handed on.
- `unified(el, a, b)`: whether a and b can be made equal, answering holes on the way. Two terms without a hole are
  the kernel's `equal`. With holes it follows equal.wap's rules on filled terms (the unfolding order, eta for
  functions) and adds:
  - **the pattern rule**: a hole applied to variables of binders, no two the same, against a term t is answered by
    the function of those variables that gives t, when that function names neither the hole itself nor a binder;
    the answer's type is unified with the hole's type, which is what finds a letter's level from its value. With
    a hole on both sides the left one is tried first, then the right one;
  - **waiting**: a hole applied to anything else (a value, a variable twice, another hole), and a pattern whose
    other side still holds a hole and gave no answer, is a problem put off: the unification says yes, and the
    problem is tried again whenever a hole is answered; an answer a waiting problem refuses is no answer;
  - a pattern that finds no answer against a term without holes is a mismatch;
  - two levels are unified by answering a level hole that stands alone on one side; other level problems wait for
    the end of the declaration (`level_problems_hold`).
  `found_so_far(el)` and `back_to(el, kept)` take a reading back: the answers, the problems and the scope.
- At the end of a declaration every hole in what is handed to the kernel is answered, or the refusal `cannot find`
  names it by the name the program would have written: "the T of identity cannot be found from its arguments". A
  problem still waiting then is the kernel's to judge: it checks the filled term whole.

Not in the unifier: no guess is made for a hole applied to values. `?F(?A)` against `list(int)` waits; taking it
apart as `?F` against `list` and `?A` against `int` (first-order approximation) is what a letter standing for a
type constructor needs, and it comes with the traits of E3, as a rule that says which of several answers is
taken.

## Names

- A name is looked up among the binders around it (`named`), then among the program's and the prelude's
  declarations. A program's declaration of a name the prelude declares hides the prelude's from there on, as a local
  name hides an outer one: the kernel holds it under the name marked (`nat'`, a mark no written name holds), the
  marked name is shown as written, and a dotted name follows its owner (`nat.zero` the program's nat's case). A
  binding statement's names are read so too.
- A declaration's binders are of three kinds, kept beside the kernel's declaration (the kernel has no kinds):
  written, found (a letter), instance (a trait's, from E3 on). A call gives a hole for each found binder and reads
  an argument for each written one.
- **Letters.** In a definition's header a one-letter name that nothing binds is a found binder of the definition,
  in the order of first appearance, before the written ones, and in scope for the whole header and the body. Its
  type is a hole: a letter used as a type gets `Sort(?u)`, any other what its use says (`n` in `vector(T, n)` is a
  `nat`). That hole is made over the letters before it only, so a letter's type names no written binder: a found
  binder whose type must name a parameter is written as a parameter. A one-letter level name nothing binds is a
  level parameter. Level holes left when the header is done become level parameters too.
- **Overloads.** Several declarations of one name are one overload set. A call tries each against its arguments
  and the type wanted, going back to what was found before each try; exactly one must fit, none or several is the
  refusal `overload` naming them. In the environment the first declaration of a name keeps the bare name, and a
  later one of that name is declared by the name with its parameter types, `size(text)`.

## Reading an expression

`read(el, node, wanted)` gives a term whose type is the type wanted (ø: any), in both directions: a function
without written types takes its binder types from the type wanted; a call's result is unified with the type
wanted before its later arguments are read, so they are read with more known.

| form | term |
|---|---|
| a name | its variable, or its constant with a level hole for each level parameter |
| a number | the kernel's number (its type the prelude's `nat`; other number types come with the conversions, E4) |
| `Call(f, arguments)` | f applied: holes for found binders, the arguments read against the domains |
| `Fn(parameters, body)` | a function; a binder type not written is a hole |
| a function type, `Prop`, `Type`, `Sort(u)` | as in the explicit corner |
| `_` | a hole |
| `Case(subject, arms)` | a recursor applied (below) |

## Declarations

- `Define` with a type and a body: the header is read first (letters, levels), giving the declared type; the body
  is read against it; holes are filled; then `declared`. A `theorem` or a proved `law` is a `Theorem`, `axiom` an `Axiom`.
- An enum or a class: the names after the type's name are its parameters, the result type's binders its
  indices, the cases its cases; a class is a block of one type with one case named as the type. Enums that name
  each other are one block. The block goes to `inductive_declared`, then the recursors are made.
- A recursive `Define` is made a term over the recursor (below); a function that fails this is refused in E2 with
  `recursion`, until measures (E6) and the effect Div give it its other readings.

## Match and recursion (E2)

- **Match.** A `match` whose arms are the cases of one enum, each arm's pattern a case applied to names, is the
  enum's recursor applied: the motive is the type wanted with the subject (and its indices) made a binder; each arm
  is the minor premise of its case, its names the fields; an arm the program left out is the refusal `covering`,
  unless an `other` arm fills it. Patterns inside patterns, literals and several subjects are first split into
  such plain matches, outermost first.
- **Recursion.** A function that matches on one of its parameters and calls itself only on fields of the matched
  case, with the other arguments as they are or changed, is the recursor with those calls replaced by the
  induction hypotheses; the parameters that change ride in the motive as function arguments.
- **The values below.** Once `products(Pair, Unit)` is bound (the prelude binds it), a match on a parameter of the
  function goes through its type's course instead (theory/below.wap, made from the recursor the first time it is
  asked for): the match is `T.course(params, motive, step, indices, n)`, and step reads the arms with the values below
  n, a chain of pairs, riding every match inside as a parameter does. A call is the hypothesis found in that chain
  whose value is the argument, with every variable an arm matched replaced by its case: `fib(k)` with
  `n = successor(k)`, `k = successor(j)` finds `fib(successor(j))`. Without the products, or for an enum of several
  types, one that eliminates only into Prop, or with a field that is a function into it, the recursor path stands,
  and a call reaches only a field.
- The body a function runs by is its recursion as written; it is kept for erase (plan 9.7) once S2 exists.

## Operators, traits and conditions (E3)

No new mechanism carries an operator: `a + b` is the call of the word `+`, an overload set like any other. What E3
adds is how a candidate fits and where its instances come from.

- **Fitting.** An argument fits a parameter when its type unifies with the parameter's, or converts to it (E4's
  conversions; E3 needs the number tower's). Of the candidates that fit, one without a conversion beats one with,
  fewer conversions beat more; two left is the refusal `overload`. So `x + y` of a `nat` and an `int` is the `int`
  one, and `3 + 4` the `nat` one, with no rule about operators.
- **Numbers.** A number read against a wanted type other than the prelude's `nat` is the conversion of the number
  to that type; with no type wanted it is a `nat`.
- **Traits.** A trait is a structure with a field per operation: `Comparable(T)` holds `compare: T -> T -> int`. A
  definition that uses a trait's operation on a value of a letter's type gets a binder of the kind instance for
  that trait at that letter, written (`T is Comparable`) or not. A call fills an instance binder by search: the
  structure built from the program's and the prelude's functions of those names at the type the letter got. No such
  function is the refusal `trait`, naming the trait and the definition to write. A law written inside a trait is a
  field, and an instance must bring its proof; the prelude states the laws of its own traits beside them, so a
  script is never asked for one.
- **`==`.** `==` is the operation of the trait of equality tests, answering yes or no. For every enum and class
  blocks.wap makes the test and the proof that it says yes exactly for equal values. In a place that wants a
  proposition (a law, a condition's fact, an obligation) `a == b` at such a type reads as `Equal(a, b)`; at a type
  with its own `equals`, and at the floats, it reads as "the test answers yes".
- **Conditions.** `if c then a else b` is a match: on a `bool` c, `yes` gives a and `no` gives b. Any other
  condition is a proposition with a decision, a value of `Decidable(c)` matched by its cases `is_true` and
  `is_false`, found by a search over the declarations giving a `Decidable`, whose binders that are decisions are
  searched in turn (up to 8 deep) (comparisons of numbers and texts, `and`, `or`, `not` of decided ones,
  a `bool` being yes). None found is the refusal `undecidable condition`. A value of another type used as a
  condition converts to a proposition by its trait of truth (a list: it is not empty). Inside the branch taken the
  condition is a fact in scope, a variable whose type is the proposition, and its negation in the other branch:
  E4's obligations read them.

## Subtypes and obligations (E4)

- **Subset types.** `T where c` is `filter(T, it => c)`, whose value is `Subset(T, it => c)`, a structure of the
  prelude with the fields `value` and `proof`. `where` is one word with two definitions, told apart by their first
  argument as overloads are: a list's filter, and this one, whose first argument is a type. `type vector(T, n: nat) = list<T> where #it == n` is a
  definition whose value is a type.
- **Conversions.** These are automatic, each a function the elaborator puts in where the type wanted differs from
  the type given: a subset to its parent (`value`); a `type X < T` to `T`; a case, as a type the subset "it is
  this case", to its enum; a part to its union, `T` to `T?`; any value to `any`; and what the prelude declares
  between its own types, the number tower. Between two types the path of conversions must be the only one, else the
  refusal `conversion` names both. A conversion lifts through a list, an optional value and a map's values as a map
  over them.
- **Going down** needs a proof. Where a `T where c` is wanted and a `T` is given, the term is the pair of the value
  and a proof of `c` at it, and the proof is an obligation, discharged by the first of these that works (plan 3.9):
  1. computing: the decision of the condition computes to yes; computing to no is the refusal `condition`;
  2. a fact in scope whose type unifies with the obligation: a parameter's own condition, a condition of an `if` or
     `match` arm around the place, a proved law;
  3. the provers (P2 on);
  4. a check when the program runs, where the condition has a decision: the value becomes `T or Error`, which E5's
     effects carry as Fail. Until E5 this step is the refusal `unproved condition`;
  5. the refusal `unproved condition`, naming the condition. `! Pure` and `--strict` stop after step 3.
  Where the obligation still has holes, two facts that fill them differently are the refusal `two facts`. Among
  overloads, a candidate whose condition computes to no does not fit, as an ill-typed one does.
- `x as S` is going down with step 4 always allowed. `x is S` is the decision of the condition at x, a `bool`; an
  S without a condition is the refusal `not a subtype`.
- A provers' search is counted in steps like the kernel's work, so what is proved does not depend on the machine.

## Statements and effects (E5)

- **A block is its statements in order**, each binding what the rest reads (`elaborate/statements.wap`). `x = v` is
  a let of x whose body is the rest of the block, so a name given a value of another type holds that type from
  there on; `x: T = v` reads v as a T. The last statement is the block's value; a value before it is the refusal
  `statement` (it would be lost), and so is a block that ends by giving a name a value.
- **A choice joins again**: in `if c { a } else { b }; rest` the rest is read once, as a function (the join) of the
  names the parts give that the rest can see (named before the choice, or given by both parts), and each part ends by
  calling it. n choices in a row stay n joins, never 2^n copies; a return in a part skips the join.
- **Only a name is given a value**: `xs#1 = 2` or `p.x = 2` is the refusal `statement` until updates of a part
  come in (a binding named by the source text would drop the write).
- **A return** is the block's value at once; the statements after it are never read.
- Without rules the door sees blocks and lets only: `if` and `return` arrive as calls, which read.wap reads as calls.
  Choices and returns reach statements.wap once the door reads with the tree's rules (E3); their lines wait in
  test_theory_statements_wanted.wap.
- Statements are read as kernel forms (Block, Set, If, Return, While, Break, Continue), which the tree's rules
  write; the elaborator names no statement word.

## Sums (E7)

- **`A or B` of two types is their union**, the prelude's `Sum(A, B)` (logic.wap), cases `left(a)` and `right(b)`
  (`elaborate/sums.wap`). The spelling arrives as a condition, If(A, yes, B); a condition that is a type, neither a
  bool nor a proposition, has the union as its one reading (`union_written`), until `or` is a word of the prelude.
- **One normal form**: sums inside a union flattened, each part computed, kept once and ordered by its term's key,
  then summed from the right; a union of one part is that part. So `id(nat) or bool`, `bool or nat` and
  `nat or bool or nat` are one type.

## Files

| file | holds | milestone |
|---|---|---|
| `elaborate/state.wap` | `Elaboration`, holes, `filled`, binder kinds, scope | E1 |
| `elaborate/unify.wap` | `unified`, level unification, problems put off | E1 |
| `elaborate/read.wap` | `read`: names, calls, functions, types, overloads | E1 |
| `elaborate/declare.wap` | headers with letters and levels, `Define`, `law`, `axiom` | E1 |
| `elaborate/door.wap` | the door | E1 |
| `elaborate/blocks.wap` | enums and classes to inductive blocks, the definitions made for each enum | E2 |
| `elaborate/match.wap` | `match` to recursors, covering, patterns split | E2 |
| `elaborate/recursion.wap` | recursion to recursors, the helper of the values below a value | E2 |
| `elaborate/instances.wap` | the search that fills an instance binder: traits, decisions | E3 |
| `elaborate/conditions.wap` | conditions, their decisions, the facts a branch knows | E3 |
| `elaborate/convert.wap` | the conversions, the path between two types, lifting through containers | E4 |
| `elaborate/obligations.wap` | going down: prove or check | E4 |
| `elaborate/statements.wap` | blocks, lets, a choice's rest, returns | E5 |
| `elaborate/sums.wap` | unions of types as sums, their normal form | E7 |

## Rules every file keeps

- The rules of notes/theory.md hold here too: closed terms only (a binder is entered by a free variable), names
  are hints, never `==` on a term, each file names what it uses.
- Refuse, never guess: where two readings fit, both are named. The elaborator's refusals have their own rule
  names: `cannot find`, `overload`, `covering`, `recursion`, `unknown name`, `unproved theorem`, `unproved law`; from E3 on `trait` and
  `undecidable condition`; from E4 on `conversion`, `condition`, `unproved condition`, `two facts` and `not a subtype`.
- Nothing here is trusted and nothing here may weaken a check: a term the kernel refuses is reported as the
  elaborator's bug, with the declaration, never retried another way.
- Tests are lines of the pages' test files through the door: a program in, what the door says out.
