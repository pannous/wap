# The theory's kernel: its files and what each gives the others

The kernel of notes/coc-plan.md (sections 6 and 7) lies in `wap/extensions/theory/`, a module of its own beside the
compiler. This note is the contract between its files: what each holds, the functions the others call, and the rules
all of them keep. The plan says what the rules are; this note says where they live.

## Files

| file | holds | plan | card |
|---|---|---|---|
| `terms.wap` | levels and terms, building them, substitution, sameness | 6.1 | theory-terms |
| `levels.wap` | levels compared: equal, at most, the level of a function type | 6.2 | theory-terms |
| `environment.wap` | declarations, the environment, the state of a check, refusals | 6.6 | theory-terms |
| `compute.wap` | a term computed to its head: beta, zeta, delta | 6.4 | theory-computing |
| `equal.wap` | definitional equality | 6.5 | theory-equality |
| `typing.wap` | a term's type; a declaration checked and added | 6.3, 6.6 | theory-typing |
| `explicit.wap` | a program in the explicit spellings read into terms and declarations | below | theory-explicit |
| `show.wap` | a term shown in wap notation | below | theory-explicit |
| `check.wap` | the door: a program checked statement by statement | below | theory-explicit |
| `inductive.wap` | an inductive block checked | 7, checks 1 to 5 | theory-inductive-checks |
| `recursors.wap` | recursors made, their computation rules | 7, checks 6 and 7 | theory-recursors |

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
- `head(t)`, `arguments(t)`: a chain of applications taken apart.
- `instantiated(body, value)`: a binder's body with its variable replaced; `instantiated_all(body, values)`: the
  body under several binders, the outermost one's value first. `abstracted(t, id)`: a term made the body of a
  binder. `with_levels(t, names, levels)`: level parameters replaced.
- `same(a, b)`: the same tree, binder names aside. `level_same`, `levels_same`, `level_with`, `level_above`.

**levels.wap**
- `levels_equal(a, b)`, `level_at_most(a, b)`: for every value of the parameters.
- `is_zero(level)`, `never_zero(level)`, `simplified(level)`, `imax_level(domain, result)`.
- `level_parameters(level)`, `level_number(level)`.

**environment.wap**
- `Declaration`: `name`, `levels` (its level parameters), `type`, `kind`: `Axiom`, `Defined(value)`,
  `Theorem(value)`, `Opaque(value)`. `unfolding(d)`: the value a use unfolds to, ø for an axiom and an opaque one.
- `Environment`, `declaration(e, name)`, `place(e, name)` (later declared, larger), `added(e, d)`.
- `Checker`: the state of one check, made by `checker(e, levels)`. `hypothesis(c, binder, type)` gives the free
  variable of a binder gone into, `hypothesis_of(c, id)` its name and type. `stepped(c)` counts a step of computing.
  `Memory`, `remembered`, `remember`: results kept by term.
- `refused(rule, found)` and the rules' names.

**compute.wap**
- `computed(c, t)`: t computed until its head is no beta, zeta or delta step (6.4).
- `computed_folded(c, t)`: the same without delta, so the caller chooses what unfolds.
- `unfolded(c, t)`: t with its head constant replaced by its value at its levels, ø when the head unfolds to nothing.

**equal.wap**
- `equal(c, a, b)`: definitional equality (6.5).

**typing.wap**
- `type_of(c, t)`: the type of t, or a refusal (6.3).
- `level_of(c, type)`: the level of the sort a type lies in; a refusal when it is no type.
- `declared(e, d)`: d checked (6.6) and then part of e, or a refusal.

**explicit.wap, show.wap, check.wap**
- `statement_read(e, statement)`: one statement of an explicit program as a `Statement`: `Declares(declaration)` or
  `AsksType(of)`.
- `shown(t)`: a term in wap notation; reading that text gives the same term again.
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
- **Results kept by term.** A result is kept (`remember`) only for a term without free variables, or dropped with
  the checker: a `Checker` lives for one declaration.
- **No library word.** No file names a type or function of the prelude. A rule that needs one gets it by a
  declaration (plan 5.4).

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
| `type of e` | the question for e's type |

A level name in a declaration that nothing binds is a level parameter of it, in the order of first appearance. A
name is looked up among the binders around it, innermost first, then among the declarations; anything else is the
refusal "unknown name".

## The door

`check.wap` reads a program and takes its statements in order. A declaration is checked and added; nothing is said
when it is accepted. `type of e` prints the type. The first refusal is printed as its one line, `refused by <rule>:
<what was found>`, and ends the run with a failing exit code. The output is the test: test/wap/test_theory.wap gives
a program and compares what the door says. A line for a refusal compares the part before the colon only.

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
