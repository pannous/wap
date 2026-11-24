# The elaborator: its files and what each gives the others

The elaborator of notes/coc-plan.md (section 8) turns a program as it is written into complete terms and hands
every declaration to the kernel (notes/theory.md). It lies in `wap/extensions/theory/elaborate/` until the switch
and is reached through a door of its own, `elaborate/door.wap`. It is not trusted: whatever it builds, the kernel's
`declared` and `inductive_declared` judge. This note is the contract for its first two milestones, E1 (arguments
found) and E2 (enums, classes, match, recursion).

## What it reads and writes

- **Reads** the lowered forms of a program (wap/kernel/forms.wap: Call, Fn, Define, Record, Case, Arm, If, Block,
  literals, Symbol), made by the compiler's own stages up to `lower`. It does not read today's binding or typing
  facts: it resolves names itself. A type is read by the same function as a value: there is one reader of
  expressions.
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

## Rules every file keeps

- The rules of notes/theory.md hold here too: closed terms only (a binder is entered by a free variable), names
  are hints, never `==` on a term, each file names what it uses.
- Refuse, never guess: where two readings fit, both are named. The elaborator's refusals have their own rule
  names: `cannot find`, `overload`, `covering`, `recursion`, `unknown name`.
- Nothing here is trusted and nothing here may weaken a check: a term the kernel refuses is reported as the
  elaborator's bug, with the declaration, never retried another way.
- Tests are lines of the pages' test files through the door: a program in, what the door says out.
