# A dependent type theory for wap: the plan

A plan, no code. It says what is built, in which order, how each step is tested, what can be cut and what is open.

In short: the nine features asked for are the type theory of Lean 4. The plan is a checker for exactly that theory,
written in plain wap as a library (0 lines in wap/core and wap/kernel). It first checks the proofs Lean exports, then
theories written in wap's own notation, up to the proofs of a program's `law`s.

## 1 What is asked

A version of the Calculus of Constructions with
1. full dependent types;
2. inductive types, also mutual ones and ones that recurse nested under other inductive types;
3. an impredicative, definitionally proof-irrelevant, extensional universe of propositions;
4. a predicative, non-cumulative hierarchy of universes of data;
5. quotient types with a definitional computation rule;
6. propositional function extensionality, a theorem that follows from the quotients;
7. definitional eta-equality for functions and products;
8. universe-polymorphic definitions;
9. consistency: no axiom-free closed term of type `False`.

This list is how Lean's language reference describes Lean 4's own type theory (Sources). So the theory has a precise
definition that is published, implemented several times and used every day: the rules of Lean 4's kernel. Taking
those rules exactly, instead of a look-alike, gives four things no own variant has:
- a consistency argument that exists (section 7);
- a test corpus: every declaration of Lean's library is a proof this checker must accept;
- proof writing for free: Lean's elaborator and tactics find the proof terms, wap only checks them. A small
  independent checker beside a big prover is the classic way to trust a proof (the de Bruijn criterion);
- the user's Lean work, W0 first (wiki/W0.md), becomes something wap checks itself.

## 2 How it fits wap: the options and their core cost

One fact decides the layer. wap's types describe the values of running programs, and programs may loop, raise and
change state: `loop(): False := loop()` is a well-typed wap function. In a logic that line would be a proof of `False`.
A consistent theory needs terms that are total and pure, so its terms cannot be wap functions: they are data, a tree
of terms that a wap program checks. wap's own types (wiki/type.md, W0) and the theory's types are two layers.

The compiler today, in lines: core 9,265 (parse 1,600, rules 1,307, analyze 3,385, emit 1,982, the rest 991), kernel
89, types with sugar and extensions 3,999; lib/ holds 74 wap files, 9,487 lines.

| option | what it is | cost in the compiler | verdict |
|---|---|---|---|
| **A library** | the checker in plain wap: terms, levels and declarations are enums, the rules are functions | core 0, kernel 0, sugar 0, extensions 0; about 3,600 trusted lines of library | recommended, built first |
| **B surface on A** | theories written in wap notation, a `law` proved by a term | no mechanism of its own: it is one more user of `parse(text)`, the `data` parameter, the `law` form and `wap verify`, which the wiki already specifies; core 0 | recommended, built second |
| **C core** | wap's own type system becomes the theory | analyze (3,385 lines) rewritten, plus the checker, an elaborator with unification, a totality check and erasure in emit: core at least doubles (estimate: 8,000 to 12,000 new core lines) | refused |
| **D foreign** | an existing checker (Rust, C++) compiled to wasm and linked through `use "checker.wasm"` | 0 lines | kept only as a test oracle |

Why A. A proof checker is the textbook case of a small program over a tree: an enum with fields and an exhaustive
`match` are exactly wap's idiom (wap/nodes.wap is written this way), wap values are garbage-collected wasm structs,
and lib/exact.wap has the unbounded numbers the literals need. "A feature is a library function before it is core
code" holds without strain. The checker is also wap's first large pure program with a ground truth for every answer
(Lean's own verdict), which makes it a strong test of the compiler.

Why not C. (1) The fact above: a logic over wap's function space is inconsistent, so C needs a total fragment, an
effect discipline and erasure, which is a new language (Lean, Idris), not a feature. (2) Optional typing (`any`),
unions, the number tower, multiple dispatch and conversions have no counterpart in the theory. (3) core is
semi-frozen and names no library word, but would have to name `Nat`, `Eq` and `Quot`. (4) Trust: a checker of 3,600
readable lines can be reviewed, one woven into a compiler cannot. Nothing in A blocks C: the compiler is written in
wap and could `use` the library one day. The reachable part of C is in B: a pure, total wap function is also a term
of the theory (section 4.6).

Why not D. It is no implementation, and its terms stay opaque to wap programs. As an oracle it is welcome: a second
checker reading the same files gives a verdict to compare with (section 7.1).

The second decision is inside A: Lean's rules exactly, or an own variant. Recommended: Lean's rules exactly, for the
four reasons of section 1. The checker may stay below Lean in one direction only: it may leave out a rule that makes
more terms equal (literal arithmetic, say) or give up early, so that everything it accepts Lean accepts too. It never
adds a rule.

## 3 What a program sees

`use proof` brings the module in. It lies in `lib/extra/proof.wap` with its files in `lib/extra/proof/`: lib/extra is
the folder of modules that load only by an explicit `use`, so common words like `normal` or `same` never come in by
themselves. "kernel" already names wap/kernel, so the trusted part is called the checker here.

| word | what it gives |
|---|---|
| `Theory` | an environment of checked declarations, empty or started from a prelude |
| `theory.add(declaration)` | the verdict; an accepted declaration is part of the theory from then on |
| `type_of(term)` | the term's type, or the rule the term breaks |
| `normal(term)` | the term reduced as far as the rules go |
| `same(a, b)` | whether two terms are definitionally equal |
| `axioms_of(name)` | every axiom a declaration rests on, through everything it uses |
| `read_export(file)` | the declarations of a Lean export file |
| `show(term)` | the term in wap notation; reading that text gives the same term again |

The words are settled when built: the recommended word is canonical, the others are aliases.

Three verdicts, never a fourth:
- **Accepted**: every rule holds. The declaration is in the theory.
- **Rejected**: it names the rule broken, the declaration, and the two types that differ, in wap notation.
- **Gave up**: the step budget ran out. Type checking this theory can run forever in corner cases (section 7.2), so
  the checker counts its reduction steps and stops. Giving up never counts as accepted. The budget counts steps, not
  seconds, so a verdict is the same on every machine; it is an argument of the call, never an environment variable.

The files fall in two groups, and only the first can make a false theorem pass:

| trusted: the checker | lines (estimate) | untrusted: everything around it | lines (estimate) |
|---|---|---|---|
| terms and levels: substitution, level order | 600 | the export reader | 400 |
| reduction | 500 | the builders | 200 |
| definitional equality | 500 | the printer `show` | 300 |
| typing | 400 | the reader of wap notation (the elaborator) | 600 to 2,000 |
| declarations and the theory | 300 | the law bridge | 300 |
| inductive types: checks, recursors, nested types | 1,000 | | |
| quotients | 80 | | |
| literals | 250 | | |

Whatever an untrusted file produces is checked by the trusted ones, so a bug there can only reject a good proof or
print a wrong text. The second kind matters too: a statement must be shown as it was checked, so `show` prints from
the checked term, never from the source text.

## 4 Terms, and how they read as wap

### 4.1 The term

One enum, matched exhaustively by every rule. Binders are locally nameless, as in Lean: a variable bound inside the
term is an index, and a binder the checker has entered is a free variable with its own identity.

| term | fields | meaning |
|---|---|---|
| bound variable | index | counts the binders between the variable and its own |
| free variable | identity | a binder the checker is inside of; its type lies in the local context |
| sort | level | `Prop`, `Type u`, `Sort u` |
| constant | name, levels | a declared name at its universe arguments |
| application | function, argument | |
| lambda | binder name, domain, body | |
| pi | binder name, domain, body | the dependent function type; `A -> B` when the body ignores the binder |
| let | name, type, value, body | |
| number | an unbounded natural number | |
| text | a text | |
| projection | structure name, field index, term | a field of a structure value |

A level is zero, a successor, `max`, `imax` or a parameter name. The checker's terms are complete: there is no hole,
no metavariable and no annotation in them. Each node keeps its hash and how far its bound variables reach, the two
numbers that keep substitution and the caches cheap.

### 4.2 Three notations for one term

- **Lean's export file**, written by machines: the declarations of a Lean library as lean4export writes them. This is
  the corpus and the way Lean's proofs reach wap.
- **Builders**, plain wap that runs with the compiler as it is: one function per term form, a binder is a wap lambda
  (`pi(Type, A => pi(A, a => A))` builds the type of the identity function). The tests use them, above all for the
  declarations that must be rejected: Lean exports nothing it rejects.
- **wap notation**, written by people: a theory is wap text read as data, with no reader of its own.

### 4.3 The wap notation

| in the theory | in wap notation |
|---|---|
| sorts | `Prop`, `Type`, `Type 1`, `Sort u` |
| levels | `u + 1`, `max(u, v)`, `imax(u, v)` |
| dependent function type | `(x: A) -> B`, and `A -> B` when `B` ignores `x` |
| function | `x => b`, `(x: A) => b` |
| application | `f(a, b)` |
| universe arguments | `f[u, v](a)`; left out where they follow from the arguments |
| definition | `double(n: Nat): Nat := add(n, n)` |
| axiom | `axiom choice(A: Sort u): Nonempty(A) -> A` |
| theorem | a named `law`, proved by a definition of the same name (4.4) |
| inductive type | `enum Nat { zero, succ(n: Nat) }` |
| family with indices | `enum Equal(A: Sort u, a: A): A -> Prop { refl: Equal(A, a, a) }` |
| mutual types | enums that name each other; the reader groups them, no keyword |
| nested type | a field under another type: `enum Tree { node(children: List(Tree)) }` |
| structure | `class Pair<A, B> { first: A; second: B }`, a field is `p.first` |
| recursion | `match` on a value; the reader turns it into the recursor (4.5) |
| local definition | a block: `{ x = value; body }` |
| literals | `3`, `"text"` |
| implicit arguments | wap's generic letters: in `identity(a: T): T := a` the `T` is found from `a` |
| universe parameters | a name after `Sort` or `Type` that nothing binds is a universe parameter |
| equality and connectives | `==`, `and`, `or`, `not`, `implies`, `iff` |

The last row is vocabulary, so it is library: the theory's prelude says which constant an operator means (`==` is
`Equal`, `and` is `And`), and the reader of the notation knows no logic by name. A dotted name (`Quot.mk`) is one
name.

The compiler's reader takes every shape of this table as it is. Three spellings it does not take, with their
replacement: a type list glued to a call (`Vector<T>(zero)`, `identity<u>(a)`) is written with round or square
brackets (`Vector(T, zero)`, `identity[u](a)`), and a binder followed by a comma (`exists x: Nat, p`) is written as a
`for` line of a law, as `(x: A) -> p`, or with a function, `exists(x => p)`.

### 4.4 A theory

```wap
enum Nat { zero, succ(n: Nat) }

add(m: Nat, n: Nat): Nat := match n {
	zero => m
	succ(k) => succ(add(m, k))
}

law zero_add:
	for n: Nat
	add(zero, n) == n

zero_add(n: Nat) := match n {
	zero => refl
	succ(k) => congruence(succ, zero_add(k))
}
```

The law is the wiki's named law (wiki/laws.md) and states the theorem. The definition of the same name is its proof:
its type is the law's statement, and its recursive call is the induction hypothesis. The same law can instead carry
its proof on its own line, `law zero_add(n: Nat): add(zero, n) == n := …`, which the reader takes too (section 10,
question 3).

### 4.5 From notation to terms

The reader of the notation is untrusted and grows in three steps.
- **Explicit**: every argument written, recursion by calling the recursor (`Nat.rec(…)`), names resolved to indices.
- **Convenient**: implicit arguments and universe arguments found by first-order unification, a hole `_` filled the
  same way, `match` with recursive calls on a field turned into the recursor, operators through the prelude.
- **Laws**: a law and its proof become a theorem; a pure whole-number function of the program becomes a definition.

What it cannot fill it reports, naming the hole; it never guesses. Tactics and type classes are not part of the plan
(section 9).

### 4.6 One text, two readings

The theory of 4.4 without its law is also a wap program: with `two = succ(succ(zero))`, wap runs `add(two, two)` and
gives four. Mutual enums and an enum nested under a list run the same way. So for pure, total functions over enums
the same text has two readings that must agree, the compiler's run and the checker's `normal`, and that agreement is
an outcome test of both. It is also how a law's assurance rises "without touching the source", as wiki/laws.md puts
it: stated, tested on values, proved by Lean, and as the new last step proved by a term wap's own checker accepts.

## 5 The checker

The rules are Lean 4's. Each is stated here as understood from Lean's documentation and the sources of its kernels;
the exact conditions are taken from those sources when the rule is built, and every rule has a test on both sides.

### 5.1 Universe levels

A level stands for a natural number once its parameters are given. `imax(u, v)` is 0 when `v` is 0 and `max(u, v)`
otherwise. `Prop` is `Sort 0` and `Type u` is `Sort (u + 1)`.
- Two levels are equal when they agree for every value of their parameters; `u <= v` is asked the same way. Both are
  decided on a normal form, splitting a parameter under an `imax` into the cases zero and successor.
- **Non-cumulative**: no rule moves a type from `Sort u` into `Sort (u + 1)`. Two sorts are equal only at equal levels,
  and `<=` is asked in one place only, the size of a constructor's field (section 6).
- **Universe polymorphism**: a declaration lists its level parameters; a use of the constant gives exactly as many
  levels, which replace the parameters in its type and value. The checker has no level variables to solve.

### 5.2 Typing

| term | its type | checked |
|---|---|---|
| `Sort u` | `Sort (u + 1)` | every level parameter is declared |
| constant | its declared type at the given levels | the number of levels is exact |
| free variable | the type of its binder | |
| `f(a)` | the result type of `f` with `a` put in | the type of `f` reduces to a function type; the type of `a` equals its domain |
| `(x: A) => b` | `(x: A) -> B`, where `B` is the type of `b` | `A` is a type |
| `(x: A) -> B` | `Sort (imax(u, v))` for `A: Sort u` and `B: Sort v` | both are types |
| let | the type of the body with the value put in | the value's type equals the declared type |
| number, text | `Nat`, `String` | the theory holds them in the expected shape (5.3) |
| projection | the field's type, earlier fields put in as projections | the term's type is a structure: one constructor, no indices |

The `imax` in the function type is both universe rules at once: a function type into a proposition is a proposition
whatever it ranges over (impredicative), and every other function type lies at the larger of its two levels
(predicative).

Projections out of a proof are narrowed: from a structure that is a proposition only a proof may be projected, and no
field whose type mentions an earlier data field. Without this the witness of an `Exists` could be read out.

### 5.3 Reduction

Weak head reduction, one rule per step:
- **beta**: a function applied to its argument;
- **zeta**: a let, by putting the value in;
- **delta**: a definition or theorem by its value; an axiom or an opaque constant never unfolds;
- **iota**: a recursor on a constructor takes that constructor's rule. For a structure the value is first expanded
  into its constructor (eta), never for a proposition. For a type with the K property (a proposition with one
  constructor without fields, like `Equal`) the value need not be a constructor: the constructor is built from the
  value's type and used once its type equals the value's type;
- **projection**: a field of a constructor application is that argument;
- **quotient**: `Quot.lift(f, h, Quot.mk(r, a))` reduces to `f(a)`, and `Quot.ind(h, Quot.mk(r, a))` to `h(a)`;
- **literals**: a number is `zero` or the successor of the number before it, one step at a time, where a rule asks
  for a constructor; arithmetic on two numbers is computed directly for Lean's list of words (add, sub, mul, div,
  mod, gcd, beq, ble, land, lor, xor, shiftLeft, shiftRight, pow, log2); a text literal is its constructor form.

Numbers and texts are a short way to write constructor terms, and the direct arithmetic is a shortcut through
definitions. Both are switched on only after the theory's own `Nat`, `String` and those words are checked to be the
expected declarations: a file that defines `Nat.add` differently gets no shortcut.

### 5.4 Definitional equality

Two terms are equal when the first rule that applies says so:
1. they are the same tree; two sorts at equal levels; two equal literals;
2. two binders of the same kind: equal domains, then equal bodies under one fresh variable;
3. **proof irrelevance**: the type of the terms is a proposition and their types are equal;
4. definitions are unfolded step by step, the one declared later first, with a stop as soon as the heads agree;
5. two constants of one name at equal levels; one free variable; two projections of one field of equal terms; two
   applications of equal heads to equal arguments;
6. **eta for functions**: `f` equals `x => f(x)`: a function is compared with a non-function by applying both;
7. **eta for structures**: a constructor application equals any term of its structure type whose projections equal
   its arguments (`p` equals `Pair(p.first, p.second)`); only for a structure: one constructor, no indices, not
   recursive;
8. **unit eta**: two terms of a structure without fields are equal when their types are.

Function types are the dependent products and structures are the products with fields, so rules 6 and 7 are the
eta-equality "for functions and products" of the list. The caches of this check are keyed by the whole term, and the
answer for an open term is kept only while its variables live.

### 5.5 Declarations

| declaration | checked |
|---|---|
| axiom | its type is a type |
| definition | the same, and the value's type equals the declared type |
| theorem | as a definition, and its type is a proposition |
| opaque | as a definition; it never unfolds |
| quotient | once, after `Equal` is checked to have the expected shape; it adds `Quot`, `Quot.mk`, `Quot.lift`, `Quot.ind` with fixed types |
| inductive block | section 6 |

For all of them: the name is new, the level parameters are distinct, no undeclared level parameter and no free or
loose variable occurs. Constructors and recursors are made by the checker; where a file states them they are
compared, and a difference is a rejection.

The four quotient constants are the checker's own. `Quot.sound`, `propext` and `Classical.choice` are axioms of the
prelude, declared as Lean declares them: the "extensional" universe of propositions is the axiom `propext`.
`axioms_of` lists them wherever they are used, and Lean's own `funext` reports `[Quot.sound]`.

### 5.6 What the checker does not have

No termination checker (recursion exists only as recursors), no unsafe or partial definitions, no code attached to a
constant, no native evaluation (`Lean.ofReduceBool` is an axiom and shows in the axiom report), no metavariables.

## 6 Inductive types

A block declares one or more types with their constructors. The checks, in order:
1. **Header**: all types of the block share the parameters and the universe of the result; each is
   `(parameters) -> (indices) -> Sort l`.
2. **Constructors**: each starts with the same parameters and returns its type applied to exactly those parameters
   and then the indices.
3. **Universes**: a field's universe is at most the type's, unless the type is a proposition, which may hold
   anything. A type in `Sort u` may or may not be a proposition, so it obeys both sides.
4. **Strict positivity**, after reducing each field's type: a type of the block may occur only as the result of a
   field's function type, never in an argument position of it and never inside the indices.
5. **Elimination**: a type that can be a proposition has a recursor into `Prop` only. The exception, which may
   eliminate into any sort: a single type with no constructor (`False`), or with one constructor whose every field is
   a proof or appears in the result's indices (`And`, `Equal`, `Acc`). So `Or` and `Exists` cannot be taken apart
   into data.
6. **Recursors**, one per type: parameters, one motive per type of the block, one minor premise per constructor with
   an induction hypothesis for every recursive field, the indices, the major premise; and one reduction rule per
   constructor.
7. **Flags**: K (a proposition, one constructor, no fields), structure (one constructor, no indices, not recursive),
   which opens projections and eta.

**Mutual types** are one block: the motives and the positivity check range over all its types together.

**Nested types** occur under another inductive type, as in `node(children: List(Tree))`. They are allowed only in
the parameters of an earlier inductive type and only without loose variables. Each distinct container at its
arguments (`List(Tree)`) becomes one more type of the block with the container's constructors copied in; the plain
block is checked (a container that uses its parameter negatively fails positivity right there), the recursors are
made, and the extra types are turned back into the container in every result.

## 7 Consistency

### 7.1 The argument

Feature 9 is no rule of the checker; it is a property of all the rules together, and it cannot be tested. The plan
rests it on three layers and says for each what the evidence is.

**The rules are consistent.** They are Lean 4's. Mario Carneiro's "The Type Theory of Lean" gives a set-theoretic
model of the theory of Lean 3 (propositions two-valued, types sets, universes from inaccessible cardinals), in which
`propext`, `Quot.sound` and choice hold too. Lean 4 adds eta for structures, projections, built-in mutual and nested
types and literals; Lean4Lean (the same author) reimplements the Lean 4 kernel in Lean and formalises its rules, with
the full proof still in work. So the standing is: a paper proof for a close relative, a formalisation under way, and
several independent kernels agreeing on a very large library, but no finished machine-checked proof for the rules as
implemented. The plan inherits exactly that standing and adds no rule of its own, which is the reason to take Lean's
rules exactly: every own rule would need its own proof.

**The checker follows the rules.**
- It is small and has no escape hatch (5.6).
- It only ever accepts less than Lean (section 2), so each accepted declaration is one Lean's rules accept.
- Differential tests in both directions: it reads Lean's exports and must accept them; an export writer hands every
  theory wap accepts to an independent Lean checker, which must accept it too.
- Every pitfall of 7.3 is a test that must end in Rejected, built with the builders or a hand-edited export.

**What lies below is right**: wap's compiler, the wasm engine, the machine. A miscompiled `match` could accept
anything, so the rejection tests run the compiled checker itself, and the corpus run is repeated with the compiler
built by itself (`--stage`).

### 7.2 Known defects of the theory, accepted

Lean's theory has three known flaws, none of which touches consistency: definitional equality as checked is not
transitive, a term's type can change under reduction in corner cases, and type checking is undecidable in corner
cases (proof irrelevance together with recursion over `Acc`). The checker therefore never relies on transitivity
(each accepted equality is justified by rules directly), and the step budget turns a loop into Gave up.

### 7.3 Pitfalls, each with its rule and its test

| pitfall | the rule that stops it | must be rejected |
|---|---|---|
| a universe inside itself (Girard, Hurkens) | `Sort u : Sort (u + 1)`; exact level counts; declared level parameters | a definition of type `Type` with value `Type`; a constant at too few levels |
| impredicativity leaking into data | `imax` collapses at level 0 only | `(A: Type 1) -> Nat` typed as anything but `Type 2` |
| data read out of a proof | elimination into `Prop` only (6.5) | a function from a proof of `Or(A, B)` to `Bool`; a `Type` motive for `Exists` |
| a witness projected out of a proof | the narrowed projection (5.2) | the first field of an `Exists` |
| a field larger than its type | field universe at most the type's (6.3) | `enum Box: Type { box(A: Type) }` |
| a type in `Sort u` taken as data only, or as a proposition only | both sides hold (6.3, 6.5) | a two-constructor type in `Sort u` with a `Type` motive |
| a type defined through its own negation | strict positivity (6.4) | `enum Bad { bad(f: Bad -> False) }` and the merely positive `bad(f: (Bad -> Prop) -> Prop)` |
| nesting where it is not allowed | nested types only in parameters, checked after copying (6) | nesting in an index; nesting under a container that uses its parameter negatively |
| K without a check | the constructor built from the type must have the value's type (5.3) | a recursor on a proof of another equation reducing as if it were `refl` |
| proof irrelevance on data | the type's sort is checked first (5.4) | `same(true, false)` |
| eta where there is no structure | structure only (5.4, 6.7) | eta on a recursive or an indexed type |
| quotients over a wrong equality | `Equal` checked before the quotient (5.5) | a quotient in a theory whose `Equal` has another shape |
| literal arithmetic against the definitions | shortcut only for the expected definitions (5.3) | `2 + 2 == 5` by `refl`, also in a theory that redefines `Nat.add` |
| two terms taken for one | caches keyed by the whole term (5.4) | two terms that differ only deep inside |
| variables that escape | declarations are closed (5.5) | a value with a loose or a free variable |
| stolen names | names are new; made names are compared (5.5) | a second `Nat.rec`; a file whose recursor rule differs from the made one |
| one level parameter listed twice | distinct level parameters (5.5) | a definition over `u, u` |
| escape hatches | none exist (5.6) | a proof by native evaluation counted as axiom-free |
| a term too large or too deep | step budget and depth limit | `2 ^ (2 ^ 64)` compared by `refl` ends as Gave up; a wasm trap is never Accepted |

Every soundness bug published for a Lean kernel or checker joins this table as one more line.

### 7.4 Risks that are wap's own

The checker is the first large pure program in wap, so its risks are measured before the first rule is written
(milestone 0): the speed of `match` over an enum of a dozen cases, 10 million small allocations, a recursion
100,000 deep, a file of 100 MB read line by line, and whether a value has a cheap identity and hash (if not, terms are
interned and carry a number). The results decide how the caches are built and whether the corpus milestones are
minutes or hours. Deep recursion is avoided by design: long application chains and binder chains are walked in loops.

## 8 Milestones

The page comes first: a wiki page `proof` (through the interviewer, as every page) with a green test file
`test/test_proof_page.wap` and a red one, `test/test_proof_wanted.wap`, whose red lines are the work list. Every test
gives terms or a theory to the public words of section 3 and checks the verdict, the shown type or the shown normal
form; no test looks inside the checker. Milestones 1 to 9 need nothing but the compiler as it is.

| milestone | what works after it | outcome tests | cut |
|---|---|---|---|
| 0 measure | the numbers of 7.4 | none kept; results in data/ | |
| 1 terms | terms, levels, builders, `show`, `read_export` | a built term shown in wap notation; an export file read and shown back | |
| 2 core calculus | sorts, functions, let, constants; axioms, definitions and theorems with level parameters; beta, zeta, delta, eta for functions | `type_of(Prop)` is `Type`; `(A: Prop) -> A` is a `Prop`; `(A: Type) -> A` lies in `Type 1`; a value in `Type` is rejected where `Type 1` is declared; `same(f, x => f(x))`; a constant at the wrong number of levels is rejected; the identity function used at two universes | |
| 3 census | a ratchet over the export of Lean's prelude: "accepted n of N", which only grows | the count | |
| 4 inductive types | plain, indexed and mutual types: checks, recursors, iota, K | `Nat`, `List`, `Equal`, `Vector`, `Even` with `Odd`, `False`, `And`, `Or`, `Exists` accepted; `normal(add(two, two))` is four; each bad type of 7.3 rejected naming its rule | |
| 5 structures and proofs | projections, eta for structures, unit eta, proof irrelevance | `same(p, Pair(p.first, p.second))`; two proofs of one proposition are the same; two values of `Bool` are not; the witness of an `Exists` is not projected | |
| 6 quotients | the quotient constants and their reduction | `normal(Quot.lift(f, h, Quot.mk(r, a)))` is `f(a)`; Lean's own proof of `funext` is accepted and `axioms_of("funext")` is `[Quot.sound]` | |
| 7 nested types | nesting under other inductive types | `Tree` with `List(Tree)` accepted, its recursor shown; the bad nestings of 7.3 rejected | last of the core |
| 8 literals | numbers with direct arithmetic, texts | `same(2 + 2, 4)` at once also for 100-digit numbers; the two literal lines of 7.3 | speed only |
| 9 corpus | all of Lean's `Init` | "0 good rejected, 0 bad accepted", the export writer's theories accepted by a second checker | beyond the prelude |
| 10 explicit theories | the notation of 4.3 with every argument written; needs `parse(text)`, and the `data` parameter for a theory inside a program | the theory of 4.4 with the recursor called directly; `show` and reading back agree; program run and `normal` agree (4.6) | |
| 11 convenient theories | implicit and universe arguments, holes, `match` into recursors, operators through the prelude | 4.4 exactly as written is accepted; a hole that cannot be filled is reported by name | |
| 12 laws | a `law` with a proof is a theorem; `wap verify` reports it; a proof found by Lean is checked by wap; needs the `law` form | `Proved` for `zero_add` without Lean installed; a wrong proof is `FAILED` naming the two types | |
| 13 W0 | wap checks the proof that its own type model never gets stuck (the W0 model needs nothing beyond `Init`) | the export of W0's progress theorem is accepted with its axioms listed | showcase |

Feature by feature:

| feature | rule | milestone | the test that shows it |
|---|---|---|---|
| 1 dependent types | 5.2 | 2 | a function type whose result names its argument: the identity function over any type |
| 2 inductive, mutual, nested | 6 | 4, 7 | `Even` with `Odd`; `Tree` under `List`; the bad ones rejected |
| 3 propositions: impredicative, proof-irrelevant, extensional | 5.2, 5.4, 5.5 | 2, 5, 6 | `(A: Prop) -> A` is a `Prop`; two proofs are the same; `propext` in the axiom report |
| 4 data: predicative, non-cumulative | 5.1, 5.2 | 2 | `(A: Type) -> A` lies in `Type 1`; a `Type` value where `Type 1` is declared is rejected |
| 5 quotients | 5.3, 5.5 | 6 | `Quot.lift` on `Quot.mk` reduces |
| 6 function extensionality | none: it is a theorem | 6 | Lean's proof of `funext` accepted, resting on `Quot.sound` only |
| 7 eta for functions and products | 5.4 | 2, 5 | `same(f, x => f(x))`; `same(p, Pair(p.first, p.second))` |
| 8 universe polymorphism | 5.1, 5.5 | 2 | one definition used at two universes; a wrong level count rejected |
| 9 consistency | 7 | all | every line of 7.3 rejected; both directions of the differential run |

## 9 What can be cut

In the order to cut, first what costs most for least:
1. tactics, type classes, well-founded recursion and coinduction: never part of the plan. Proof terms come from Lean
   or are written out;
2. the W0 showcase and the export writer;
3. the convenient reader (milestone 11): explicit theories and Lean's exports stay;
4. text literals, then direct arithmetic: only speed is lost, numbers still work as constructor terms;
5. the corpus beyond the prelude; libraries of Mathlib's size are out of reach in any case until measured;
6. nested types: a nested type can be written as a mutual one by hand;
7. a command of its own on the command line: `wap verify` is the door.

Not to cut: milestones 0 to 6 and the rejection tests of 7.3. Together they are the nine features.

## 10 Open decisions

Each with the recommendation first and its cost in the compiler. They go to the user through the interviewer.

1. **What the theory is for.** (a) a proof-checker library, (b) also the engine behind `law` and `wap verify`,
   (c) wap's own types become dependent. Recommended: (a), then (b); both cost 0 core lines. (c) rewrites the analyze
   stage and at least doubles core (section 2).
2. **Which rules.** Lean 4's exactly (recommended), or an own variant. Both 0 core lines; an own variant needs its own
   consistency proof and has no corpus.
3. **Where theories are written.** Lean files only; theory files in wap notation (needs `parse`); a theory inside a
   program (needs the `data` parameter). Recommended: Lean's exports first, wap notation as those two wiki mechanisms
   arrive; 0 lines beyond them. And the spelling of a proof: a definition of the same name as the law (recommended),
   or the proof on the law's own line.
4. **How much the reader fills in.** Explicit terms only; plus implicit arguments and `match` (recommended as the
   second step); tactics (not recommended: a prover is a project of its own). All 0 core lines.
5. **Words.** The module `proof`; `law` for a theorem, with `theorem` as an alias; the verdicts Accepted, Rejected,
   Gave up. Aliases, so cheap to change.
6. **Axioms in the prelude.** `propext`, `Quot.sound` and `Classical.choice` ship as Lean has them, and every theorem
   reports the axioms it rests on (recommended). Without them Lean's library cannot be read.
7. **Source of the rules.** Written from the published rules, with the other kernels as oracles only (recommended),
   or ported from one of the Apache-2.0 kernels with its notice.

For the tree's owner, not the user: the module's place (`lib/extra/proof/`, or a package of the registry once it is
stable), and the wiki page before the first milestone.

## Sources

- Lean language reference, "The Type System": https://lean-lang.org/doc/reference/latest/The-Type-System/
- Mario Carneiro, "The Type Theory of Lean" (2019): https://github.com/digama0/lean-type-theory
- Mario Carneiro, "Lean4Lean: Towards a Verified Typechecker for Lean, in Lean": https://arxiv.org/abs/2403.14064,
  https://github.com/digama0/lean4lean
- Chris Bailey, "Type Checking in Lean 4": https://ammkrn.github.io/type_checking_in_lean4/, and the checker
  nanoda_lib: https://github.com/ammkrn/nanoda_lib
- The export format: https://github.com/leanprover/lean4export
- Lean's kernel: https://github.com/leanprover/lean4/tree/master/src/kernel
- In wap: wiki/laws.md, wiki/W0.md, wiki/dsl.md, wiki/node.md, wiki/use.md, wap/nodes.wap, notes/backbone.md,
  notes/lib-rules.md, lib/exact.wap, lib/json.wap
