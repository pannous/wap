# The elaborator: its files and what each gives the others

The elaborator of notes/coc-plan.md (section 8) turns a program as it is written into complete terms and hands
every declaration to the kernel (notes/theory.md). It lies in `wap/extensions/theory/elaborate/` until the switch
and is reached through a door of its own, `elaborate/door.wap`. It is not trusted: whatever it builds, the kernel's
`declared` and `inductive_declared` judge. This note is the contract for its first four milestones: E1 (arguments
found), E2 (enums, classes, match, recursion), E3 (operators, traits, conditions) and E4 (subtypes and
obligations).

## What it reads and writes

- **Reads** the lowered forms of a program (wap/kernel/forms.wap: Call, Fn, Define, Record, Case, Arm, If, Block,
  literals, Symbol), made by the compiler's own stages up to `lower`. It does not read today's binding or typing
  facts: it resolves names itself. A type is read by the same function as a value: there is one reader of
  expressions.
- **Laws and axioms** arrive as their word called on the declaration (wap/sugar/definitions.wap): `law four: 2 + 2
  == 4 := refl` as `law(Define(four: 2 + 2 == 4, (), refl))`, a proved law the definition of its proof;
  `axiom int: Type` as `axiom(int: Type)`. A law or axiom without a value whose name takes parameters is one of a
  function type: `axiom f(x: A): B` arrives as `axiom(f: (x: A) -> B)`, the type lowered as a written one is.
  `declaration_elaborated` (elaborate/declare.wap) takes both.
- **Writes** declarations into the theory's `Environment` through `declared` and `inductive_declared`, and
  nothing else. A term it hands over holds no hole.
- **The door** `elaborate/door.wap program.wap` loads the prelude (`wap/extensions/theory/prelude/`), elaborates the
  program statement by statement, and prints as the kernel's door does: nothing for an accepted declaration, the
  value's type for `type of e`, a refusal as `refused by <rule>: …`. The kernel's own door, `check.wap`, stays the
  door of the explicit programs.

## Holes

A hole stands for what the program left out: a letter's value, a level, a `_`. A hole for a term is a free variable
of the kernel (`hypothesis(c, name, type)`) that the elaborator may answer; so the kernel's `type_of` and `computed`
work on a term with holes as they are, a hole being a variable nothing is known of. A hole for a level is a level
parameter whose name starts with `?`.

`Elaboration` is the state of one declaration: the environment, a `Checker`, the names in scope (each a free
variable), the holes with their answers, and the problems put off.
- `hole(el, name, type)`: a new hole; `level_hole(el)`: a new level hole.
- `filled(el, t)`: t with every answered hole replaced by its answer, levels too. A term is filled before it is
  computed, compared or handed on.
- `unified(el, a, b)`: whether a and b can be made equal, answering holes on the way. It follows equal.wap's rules
  on filled terms and adds: a hole against a term is answered by it when the term names no variable made after the
  hole and not the hole itself; a hole applied to distinct variables is answered by the function of them; two
  levels are unified by answering a level hole that stands alone on one side. A problem none of this solves is put
  off and tried again whenever a hole is answered.
- At the end of a declaration every hole is answered, or the refusal `cannot find` names it by the name the
  program would have written: "the T of identity cannot be found from its arguments".

## Names

- A name is looked up among the binders around it, then among the program's and the prelude's declarations.
- A declaration's binders are of three kinds, kept beside the kernel's declaration (the kernel has no kinds):
  written, found (a letter), instance (a trait's, from E3 on). A call gives a hole for each found binder and reads
  an argument for each written one.
- **Letters.** In a definition's header a one-letter name that nothing binds is a found binder of the definition,
  in the order of first appearance, before the written ones. Its type is a hole: a letter used as a type gets
  `Sort(?u)`, any other what its use says (`n` in `vector(T, n)` is a `nat`). A one-letter level name nothing binds
  is a level parameter. Level holes left when the header is done become level parameters too.
- **Overloads.** Several declarations of one name are one overload set. A call tries each against its arguments
  and the type wanted; exactly one must fit, none or several is the refusal `overload` naming them. In the
  environment an overloaded name is written with its parameter types, `+(nat, nat)`; a name with one declaration
  is bare.

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
  is read against it; holes are filled; then `declared`. A `law` is a `Theorem`, `axiom` an `Axiom`.
- `Record` (an enum or a class): the names after the type's name are its parameters, the result type's binders its
  indices, the cases its cases; a class is a block of one type with one case named as the type. Enums that name
  each other are one block. The block goes to `inductive_declared`, then the recursors are made.
- A recursive `Define` is made a term over the recursor (below); a function that fails this is refused in E2 with
  `recursion`, until measures (E6) and the effect Div give it its other readings.

## Match and recursion (E2)

- **Match.** A `Case` whose arms are the cases of one enum, each arm's pattern a case applied to names, is the
  enum's recursor applied: the motive is the type wanted with the subject (and its indices) made a binder; each arm
  is the minor premise of its case, its names the fields; an arm the program left out is the refusal `covering`,
  unless an `other` arm fills it. Patterns inside patterns, literals and several subjects are first split into
  such plain matches, outermost first.
- **Recursion.** A function that matches on one of its parameters and calls itself only on fields of the matched
  case, with the other arguments as they are or changed, is the recursor with those calls replaced by the
  induction hypotheses; the parameters that change ride in the motive as function arguments. A call on a field of
  a field is reached through the helper the elaborator declares for each enum beside its recursor (the values
  below a value).
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
- **Conditions.** The condition of `if`, `while` and of a `bool` place is a proposition with a decision: a value of
  `Decidable(c)`, found by the same search (comparisons of numbers and texts, `and`, `or`, `not` of decided ones,
  a `bool` being yes). None found is the refusal `undecidable condition`. A value of another type used as a
  condition converts to a proposition by its trait of truth (a list: it is not empty). Inside the branch taken the
  condition is a fact in scope, a variable whose type is the proposition, and its negation in the other branch:
  E4's obligations read them.

## Subtypes and obligations (E4)

- **Subset types.** `T where c` is `subset(T, it => c)`, a structure of the prelude with the fields `value` and
  `proof`. `where` is one word with two definitions, told apart by their first argument as overloads are: a list's
  filter, and this one, whose first argument is a type. `type vector(T, n: nat) = list<T> where #it == n` is a
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
- `x as S` is going down with step 4 always allowed. `x is S` is the decision of the condition at x, a `bool`.
- A provers' search is counted in steps like the kernel's work, so what is proved does not depend on the machine.

## Files

| file | holds | milestone |
|---|---|---|
| `elaborate/state.wap` | `Elaboration`, holes, `filled`, binder kinds, scope | E1 |
| `elaborate/unify.wap` | `unified`, level unification, problems put off | E1 |
| `elaborate/read.wap` | `read`: names, calls, functions, types, overloads | E1 |
| `elaborate/declare.wap` | headers with letters and levels, `Define`, `law`, `axiom` | E1 |
| `elaborate/door.wap` | the door | E1 |
| `elaborate/blocks.wap` | `Record` to inductive blocks, the definitions made for each enum | E2 |
| `elaborate/match.wap` | `Case` to recursors, covering, patterns split | E2 |
| `elaborate/recursion.wap` | recursion to recursors | E2 |
| `elaborate/instances.wap` | the search that fills an instance binder: traits, decisions | E3 |
| `elaborate/conditions.wap` | conditions, their decisions, the facts a branch knows | E3 |
| `elaborate/convert.wap` | the conversions, the path between two types, lifting through containers | E4 |
| `elaborate/obligations.wap` | going down: prove or check | E4 |

## Rules every file keeps

- The rules of notes/theory.md hold here too: closed terms only (a binder is entered by a free variable), names
  are hints, never `==` on a term, each file names what it uses.
- Refuse, never guess: where two readings fit, both are named. The elaborator's refusals have their own rule
  names: `cannot find`, `overload`, `covering`, `recursion`, `unknown name`; from E3 on `trait` and
  `undecidable condition`; from E4 on `conversion`, `condition` and `unproved condition`.
- Nothing here is trusted and nothing here may weaken a check: a term the kernel refuses is reported as the
  elaborator's bug, with the declaration, never retried another way.
- Tests are lines of the pages' test files through the door: a program in, what the door says out.
