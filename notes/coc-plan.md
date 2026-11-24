# Dependent types in wap's core: the plan

A plan, no code. It says what wap is once its own type system is a dependent type theory: how programs read, what
the compiler is made of and what of it is trusted, in which order it is built, how each step is tested, what can be
cut and what is open.

## In short

- wap's types become a version of the Calculus of Constructions with the nine features asked for (section 1). A type
  is a term like any other: `vector(int, n + 1)` is a function applied to arguments, and two types are the same when
  they compute to the same.
- **Dependent types are part of the core, not a library.** The typing stage of the compiler is replaced by two
  parts: an *elaborator*, which turns everything a program writes into complete terms, and a small *kernel*, which
  accepts or refuses each term. Only the kernel is trusted. The library holds the vocabulary (`nat`, `list`, `Equal`)
  and the provers, in plain wap.
- A script stays a script. Precision is added a step at a time and never forced: plain types, subtypes by condition
  (`type char = text where #it == 1`), types that depend on values, laws, proofs. What the compiler cannot prove it
  checks when the program runs.
- The pure, total part of wap is the logic. wap's own effects mark everything else (`Div` may not end, `Fail` may
  raise, `IO` acts), so a loop proves nothing and no program can add an axiom.
- The rules are those of Lean 4's kernel, the best-tested rules for exactly this list of features. Nothing of Lean
  itself is used: syntax, elaborator, library and provers are wap's own, written in wap.
- Cost: core and kernel together grow from 9,350 to about 18,000 lines, 3,600 of them trusted.

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

Four conditions frame the plan:
- The theory is wap's own type system, not a second language beside it. The measure is the user's example: a
  character is a text of length 1, so `char` is a subtype of `text`, by a general rule.
- Lean's practices are adopted, Lean is not: no Lean install, no proof found by Lean, no library taken from it.
- Architecture and syntax may be overhauled; anything wap does today may be given up where the theory needs it.
- Everything needed can be built. The plan describes the target and names the parts workers can start now.

## 2 The design on one page

Three layers, each knowing only the one below:

| layer | what it is | trusted |
|---|---|---|
| **kernel** | the theory: ten kinds of term, the rules of typing and of equality by computing, inductive types, quotients, universes. It knows no library word, no effect, no subtype, no overload, no recursion | yes, and nothing else |
| **elaborator** | the compiler's typing stage: it turns what a program writes (names, overloads, arguments left out, conversions, `match`, loops, recursion) into complete terms and hands every one to the kernel | no: a bug here refuses a good program, or builds a term the kernel refuses |
| **library** | the vocabulary in plain wap (`nat`, `int`, `list`, `text`, `Equal`, `and`, the effects) and the provers that write proofs | no: whatever it defines or proves passes the kernel |

What a program writes, and what it is in the theory:

| a program writes | in the theory it is |
|---|---|
| `f(x: A): B := …`, pure and ending | a definition, a term of the type `(x: A) -> B`; it unfolds in types and proofs |
| `list<int>`, `map<K, V>`, `vector(T, n)` | a function applied to arguments: types are terms, and a type may take values |
| a one-letter name nothing binds, `T`, `n` | an argument the compiler finds by itself |
| `class Point { x: int; y: int }` | an inductive type with one constructor: a structure, with fields and eta |
| `enum Shape { Dot(size: int), … }` | an inductive type; with parameters and indices a family; mutual and nested ones too |
| `T where condition` | the subset type: a value of `T` with a proof of the condition, the proof gone at run time |
| `type Color < int` | a new type with a conversion to its parent, put in by the compiler |
| `T?`, `A or B`, `any` | inductive sums; a value of a part converts into the sum |
| `x == y`, `and`, `or`, `not`, `implies`, `for x: A` | propositions: types in `Prop`; a proof is a term of one |
| the condition of an `if` | a proposition that can be decided; its branch knows that it holds |
| `law` | a proposition; with its proof a theorem |
| a trait | a structure of operations and their laws, found by the compiler |
| `f(x) := …` with an effect | a function into a computation type, `B ! IO` |
| `quotient(T, same)` | the quotient type |
| `axiom` | an axiom: the only way to add one, and always reported |

## 3 How programs read

### 3.1 A script stays a script

```wap
names = ["Ada", "Alan"]
for name in names { print "Hello " + name }
names#1                    // "Ada"
```

Nothing in it changes. The compiler finds its terms: `names` is a `list<text>`, the loop is a fold over the list,
the program is a computation with the effect IO, and `names#1` is in range because the list is written right there.

### 3.2 Subtypes by condition

```wap
type char = text where #it == 1

c: char = "a"                      // fine: the compiler computes #"a" == 1
d: char = "ab"                     // refused: "ab" is no char, #"ab" == 1 does not hold
shout(t: text) := t.upper + "!"
shout(c)                           // fine: a char is a text, and the call costs nothing
line = read_line()
if #line == 1 { e: char = line }   // fine: inside the if, its condition is the proof
f = line as char                   // checked when the program runs
initial(name: text where #it > 0): char := name#1
```

In the theory `text where #it == 1` is the subset type: a pair of a text and a proof that its length is 1. The proof
is a proposition's, so it is gone when the program runs: a char is stored as its text. Going up, from char to text,
takes the pair's first part and is free. Going down needs the proof, which the compiler computes, finds or checks
(3.9). Two chars are equal exactly when their texts are: eta for structures and proof irrelevance say so. `x is char`
asks whether the condition holds.

This one rule replaces what the compiler handles case by case today: the conversion from char to text, the `'a'`
literal typed by the place it meets, a case as a narrower type than its enum, `type Color < int`, and named patterns
used as types (`pattern Adult = {age: >= 18}`). Each is a subset type or a declared conversion.

### 3.3 Types that depend on values

```wap
type vector(T, n: nat) = list<T> where #it == n
type index(xs: list<T>) = nat where 1 <= it and it <= #xs
type matrix(m: nat, n: nat) = vector(vector(number, n), m)

dot(a: vector(number, n), b: vector(number, n)): number := sum(a .* b)
dot([1, 2, 3], [4, 5, 6])          // 32
dot([1, 2, 3], [4, 5])             // refused: b is a vector(number, 2), dot takes two of one length
append(a: vector(T, m), b: vector(T, n)): vector(T, m + n) := a + b
multiply(a: matrix(m, n), b: matrix(n, p)): matrix(m, p) := …
at(xs: list<T>, i: index(xs)): T := …       // the type of i names the argument before it
```

`T`, `m`, `n` and `p` are one-letter names nothing binds, so they are arguments the compiler finds from the others.
`vector(int, 2 + 1)` and `vector(int, 3)` are one type: the kernel computes. The wiki's spellings of sized lists
(`char[3]`, `26 * char`) are spellings of `vector`. Units of measure work the same way: a quantity's dimension is an
argument of its type, so `3m + 2s` is refused when it is compiled.

### 3.4 Inductive types

```wap
enum nat { zero, successor(n: nat) }                              // the prelude's; 0, 1, 2 … are its literals
enum list<T> { empty, item(first: T, rest: list<T>) }             // the prelude's; [a, b] is its literal
enum Tree { leaf(value: int), branch(children: list<Tree>) }      // nested: Tree under list
enum Expression { number(n: int), block(body: list<Statement>) }  // mutual: the two name each other,
enum Statement { show(e: Expression), assign(name: text, e: Expression) }   // no keyword needed
enum Even(n: nat): Prop { zero: Even(0), step(e: Even(n)): Even(n + 2) }    // a family of propositions
enum Equal(a: T): T -> Prop { refl: Equal(a, a) }                 // the prelude's equality; == writes it
```

`enum` and `class` keep their spelling and gain what the theory needs: parameters, a result type after the head
(`: Prop`, `: T -> Prop`), and a result type per case where the cases differ in it. Each enum gets its recursor from
the kernel; a program never calls it, it writes `match` and recursion.

### 3.5 Propositions, laws and proofs

```wap
double(n: nat): nat := match n { zero => 0; successor(k) => double(k) + 2 }

law double(n) == n + n                          // stated: tested, and proved when the provers can
law double_even(n: nat): Even(double(n)) :=     // proved by a program whose type is the statement
	match n { zero => Even.zero; successor(k) => Even.step(double_even(k)) }
```

| a proposition | is the type | a proof of it is |
|---|---|---|
| `A and B` | a structure of two proofs | a proof of each |
| `A or B` | a sum of two cases | a proof of one |
| `A implies B` | `A -> B` | a function from proofs of A to proofs of B |
| `not A` | `A -> False` | a function from proofs of A to the empty proposition |
| `for x: T` then `P(x)` | `(x: T) -> P(x)` | a function giving a proof for each x |
| `a == b` | `Equal(a, b)` | `refl`, when both sides compute to the same |

A comparison is a proposition, and one that can be decided has a value: `if`, `while` and `bool` places compute it.
Proofs are programs: `match` is a proof by cases, a call of the law itself on a smaller value is the induction
hypothesis, a call of another law uses that law. Beside that there are three prover words: `by` hands the rest to
the provers, with the laws to use (`by add_commutes`); `chain` writes a chain of equal steps; `assume` leaves a gap,
which becomes an axiom the reports name. `wap verify` prints a verdict per law: Proved, Tested, FAILED with a
counterexample, or Assumed. `axioms of double_even` lists every axiom a law or function rests on.

### 3.6 Quotients

```wap
class fraction { top: int; bottom: int where it != 0 }
same_value(a: fraction, b: fraction) := a.top * b.bottom == b.top * a.bottom
type rational = quotient(fraction, same_value)

half: rational = fraction(1, 2)
half == fraction(2, 4)                          // yes: they are equal, not merely alike
sign(q: rational): int := q.lift(f => sign(f.top * f.bottom))
top(q: rational): int := q.lift(f => f.top)     // refused: top differs on 1/2 and 2/4
```

A function leaves a quotient only through `lift`, with a proof that it gives equal results on values the relation
joins. The compiler looks for that proof as for any obligation; it cannot be checked at run time, so without it the
function is refused. `lift` applied to a value made by `quotient.of` computes to the function applied to it: that is
the definitional computation rule. At run time a rational is a fraction and `lift` is a call.

The library uses it for `rational`, for `set<T>` (lists up to order and repeats) and for `i64` (integers up to
2^64). Function extensionality is a theorem of the prelude, proved from the quotient (milestone K5). And one rule for
programs follows: a type that defines its own `equals` is a quotient by it, so `==` always means equal (open
decision 4). For `==` to be computed by that `equals`, it must be proved to hold of every value with itself, both
ways round, and across a chain: an obligation like any other.

### 3.7 Universes

```wap
identity(a: T): T := a
identity(3); identity(int); identity(Type)      // one definition, used at three levels
```

`Prop` is the universe of propositions, `Type` that of data, `Type(1)` that of types such as `Type` itself, and so
on. `Sort(u)` names any of them: `Prop` is `Sort(0)`, `Type(u)` is `Sort(u + 1)`. A program rarely writes a level:
`T` above stands for a type of any level, found at each use, and a level letter nothing binds is a parameter like
`T` is. Levels do not include each other: `int` is a `Type` and never a `Type(1)`. What should serve at several
levels is polymorphic, as `identity` and `list` are.

### 3.8 Effects

```wap
greet(name: text) := print "Hello " + name      // found: unit ! IO
effects of greet                                // IO
total(xs: list<int>): int := { s = 0; for x in xs { s += x }; s }   // pure: a variable and a loop are no effect
loop(): False := loop()                         // found: False ! Div. It runs; it proves nothing
law oops: False := loop()                       // refused: loop may not end (Div), a proof must be pure
```

The effects are the ones wiki/effects.md names, found by the compiler as today's wiki says, and now part of the
type: `(text) -> unit ! IO`. Section 9 says what each is in the theory.

### 3.9 Prove or check

Every condition a type puts on a value is an obligation: the index is in range, the divisor is not zero, the text
has length 1, the lengths agree. For each one the compiler does the first of these that works:
1. it computes it: `"a"` is a char because `#"a" == 1` computes to yes; a condition that computes to no is refused
   at once;
2. it finds it among the facts in scope: a parameter's own condition, the condition of the `if` or `match` arm
   around it, a proved law;
3. it asks the provers;
4. it checks it when the program runs, where the condition can be decided: the check raises naming the condition,
   and the function gets the effect Fail;
5. it refuses, naming the condition and the fixes: state it as a parameter's condition, or test it with `if`.

`! Pure` on a function, and `wap check --strict` for a whole program, stop after step 3: every obligation is then
proved or the program is refused. `wap check` lists the obligations left to run time, so a program's assurance rises
without touching its source, as wiki/laws.md says of laws.

### 3.10 Sums: unions, optional values, any

```wap
s: int or text = 3
show(n: int) := "number"; show(t: text) := "text"
show(s)                        // "number": the call distributes over the cases of s
x: any = [1, "a"]              // a data node; typed values convert into it
n: int = x#1                   // checked when the program runs: the way out of an any is always a check
```

A union is a sum of its parts, `T?` the sum of `T` and ø, `any` the inductive type of data nodes (wiki/node.md),
nested under list. A call whose argument is a sum and whose definitions take single cases distributes over the
cases: the compiler writes the `match`. That one rule gives run-time dispatch on unions, on `any` and on a class
with its extensions.

### 3.11 What the reader needs

Checked with `wap format` on today's compiler: the reader takes every spelling of this section as it is. Two need a
shape rule: an enum's result type written before its brace (`enum Even(n: nat): Prop { … }`), and the effect of a
function type (`(text) -> unit ! IO`), where a `!` after a type is glued to it today as the required mark, `unit!`.
New words: `Prop`, `Type`, `Sort`, `where` after a type, `quotient`, `axiom`, `assume`, `by`, `chain`, `axioms of`
and the command `wap check`.

## 4 What changes and what goes

The freedom to overhaul is used on the compiler's middle, not on the surface. No spelling has to go: nothing in the
theory needs the syntax changed. What goes is looseness in what a type means.

| today | in the target | why |
|---|---|---|
| a type is notation, compared as text | a type is a term, compared by computing | dependent types |
| generic letters: unification, one copy per tuple of types | a letter is an argument found by the compiler; the polymorphic term is checked once, copies per type are made after checking | one check instead of one per use |
| an untyped parameter: one version per argument type | stays: an untyped function is a template, elaborated at each use | scripting |
| a function nothing calls is never typed | only templates; every typed function is checked, called or not | a law may speak of it |
| `x = 1; x = "a"` makes x an any, with a warning | refused; `x: int or text` says it | a name has one type |
| unlike types join to `any` | they join to their union: `[1, "a"]` is a `list<int or text>`; `any` only where written | no silent loss of types |
| char to text, range to list, case to enum, int to float: conversions inside the typing code | conversions declared in the types module (3.2) | no special cases |
| overloads ranked by weights | the most specific is the one whose parameters convert into the others' | one order, the conversions' |
| run-time dispatch written by the typing code for `any` | a call on a sum distributes over its cases (3.10) | one rule for any, unions, class families |
| `T?` also holds an Error | `T?` is T or ø; an error is `T or Error`, the effect Fail | each type says one thing |
| a type's own `equals` | the type is a quotient by it (3.6) | `==` is equality |
| `extends` (specified, not built) | the fields of the parent with a conversion to it; a place typed by the parent holds the sum of the class and its extensions | no open-world dispatch |
| `while`, general recursion | pure when a measure proves they end, else the effect Div | totality |
| effects: specified, not built | types (section 9) | consistency rests on them |
| index, divide, unwrap raise at run time | obligations: proved where the compiler can, checked otherwise (3.9) | fewer checks, same safety |
| a unit mismatch is found at run time | at compile time where the units are written; `quantity("5 km")` still checks at run time | dimensions are type arguments |
| `f == g` on functions: by hash, by polynomial normal form, else "undecidable" | a proposition; the same methods are provers, extensionality is a theorem | the answer comes with a proof |
| `int`: 64 bits and wrapping on some wiki pages, unbounded on others | each number type is one mathematical object (open decision 1) | a law must mean one thing |
| `wap verify` proves with Lean | with wap's own provers and kernel | no second system |
| W0, the model of wap's types in Lean | the kernel is the model; `wap types` shows a program's terms | one definition of wap's types |
| `type(x)` asks at run time | known at compile time; for an `any` it reads the node's kind | types are gone at run time |
| the sixteen kernel forms, read by the emitter | the statement language between lower and elaborate; the emitter reads erased terms | what is checked is what runs |
| no evaluator in the compiler | the kernel computes: types, proofs by computing, folding | equality by computing |

Unchanged: the reader, the operator table, the rewrite rules and sugar, phrases and prepositions, multiple
dispatch as a way to write functions, value semantics (wiki/Footguns.md "Aliasing"), flow facts from conditions,
truthiness (a conversion to a proposition), the wasm value layouts, the command line.

## 5 The compiler

### 5.1 Stages

| stage | reads | writes | trusted |
|---|---|---|---|
| read, operators, shape rules, declare, declared rules, lower, bind | text | bound statements: the program in the plain forms (call, block, define, function, get, set, if, case, try, while, return, break, continue) | no |
| elaborate | bound statements | declarations: every definition a complete term with its type, every instance chosen, every conversion and proof written out | no |
| check: the kernel | declarations | the environment: each declaration accepted, or the compile refused | yes |
| erase | accepted terms | run terms: no types, no proofs, no levels | for what runs only |
| emit, encode | run terms | the wasm module | for what runs only |

Elaborate replaces today's type, kind rules and elaborate (wap/core/analyze). The kind rules (stage 3) fire in it, on
a node once its type is known. The stage contract of notes/backbone.md holds as before: each stage reads one
language and writes one.

Three lines through the stages:

| the program writes | the term the kernel checks | the run term |
|---|---|---|
| `shout(c)`, with `c: char` | `shout(c.value)`: the conversion from the subset type is written out | `shout(c)`: a char is stored as its text |
| `d: char = "a"` | the pair of `"a"` and a proof of `#"a" == 1`, found by computing | `"a"` |
| `law double(3) == 6` | a theorem: `refl`, of the type `Equal(double(3), 6)` | none: a proof does not run |

### 5.2 The tree

- `wap/kernel/`: the theory. `forms.wap` holds the ten terms; beside it levels, reduction, equality, typing,
  declarations, inductive types, quotients, numbers. No other folder is trusted.
- `wap/core/`: the machinery. `parse/` and `rules/` as today, `statements.wap` (today's kernel forms), `elaborate/`
  (in place of `analyze/`), `erase/`, `emit/`.
- `wap/types/`: the language every program gets, in plain wap: the logic (`Equal`, `and`, `or`, `exists`,
  `Decidable`), numbers, lists, texts, maps, optional values, the effects and the computation type, the conversions.
- `wap/extensions/prove/`: the provers.

Until the switch (milestone S3) the kernel is built in `wap/extensions/theory/`, as a module of its own, so
wap/core and wap/kernel stay as they are and the compiler keeps its size and speed while it grows.

### 5.3 Size

| part | today | target | trusted |
|---|---|---|---|
| reader, operators, rules (core/parse, core/rules) | 2,907 | about the same | no |
| typing: analyze, then elaborate | 3,385 | 7,000 to 9,000 | no |
| kernel | 89 | 3,600 | yes |
| erase | 0 | 400 | for what runs |
| emit | 1,984 | about 2,000, rewritten for run terms | for what runs |
| rest of core | 991 | about 1,000 | no |
| types module | 1,855 | about 4,000 | no |
| provers | 0 | 4,000 to 6,000 | no |

Core and kernel together go from 9,354 lines to about 18,000. The size ceiling of wap's source
(test/wap/ratchet_census.sh) is raised by hand with each milestone that lands, as its rule asks.

### 5.4 Core knows no library word

The kernel and the elaborator name no library word. Where a mechanism needs one, the types module binds it by a
declaration:
- **numbers**: which type number literals belong to, and which functions the arithmetic shortcuts stand for (6.7);
- **quotient**: which type is the equality (6.6);
- **texts**: a text literal is the library's function from the number that spells its bytes, applied to that
  number. The kernel has one literal, the natural number;
- **conversions, instances, the computation type, decidable conditions**: declarations of the types module that the
  elaborator's general mechanisms read (section 8); spellings such as `T where c`, `T?` and `if` reach library
  functions through rules in sugar/.

### 5.5 The question: in the core, not a library?

Yes. The kernel and the elaborator are the compiler's core, and wap's own types are the theory's types. A library
could only check terms handed to it as data, beside a language whose own types stay loose: `char` would not be a
subtype of `text`, and a law would speak about a copy of the program instead of the program. What stays library is
vocabulary and proof search: the types module and the provers, which the kernel checks like any program.

The trust a library would have offered is kept: the kernel is a folder of 3,600 lines that reads complete terms and
shares no code with the elaborator. A bug anywhere else can refuse a good program; it cannot make a false law pass.

## 6 The kernel

The rules are Lean 4's kernel's, stated here as wap builds them. Every rule has a test on both sides: something it
accepts and something it refuses (section 11).

### 6.1 Terms

| term | fields | meaning |
|---|---|---|
| bound variable | index | counts the binders between the variable and its own |
| free variable | identity | a binder the kernel is inside of; its type lies in the local context |
| sort | level | `Prop`, `Type(u)`, `Sort(u)` |
| constant | name, levels | a declared name at its level arguments |
| application | function, argument | |
| function | binder name, domain, body | `x => b` |
| function type | binder name, domain, body | `(x: A) -> B`; `A -> B` when the body ignores the binder |
| let | name, type, value, body | |
| number | an unbounded natural number | the one literal |
| projection | structure name, field index, term | a field of a structure value |

A level is zero, a successor, `max`, `imax` or a parameter name. Terms are complete: no hole, no overload, no
argument left out, no conversion left unsaid. Each node keeps its hash and how far its bound variables reach, which
keep substitution and the caches cheap.

### 6.2 Universe levels

A level stands for a natural number once its parameters are given. `imax(u, v)` is 0 when `v` is 0 and `max(u, v)`
otherwise.
- Two levels are equal when they agree for every value of their parameters; `u <= v` is asked the same way. Both are
  decided on a normal form, splitting a parameter under an `imax` into the cases zero and successor.
- **Non-cumulative**: no rule moves a type from `Sort(u)` into `Sort(u + 1)`. Two sorts are equal only at equal
  levels, and `<=` is asked in one place only, the size of a constructor's field (section 7).
- **Universe polymorphism**: a declaration lists its level parameters; a use of the constant gives exactly as many
  levels, which replace the parameters in its type and value. The kernel has no level to solve: the elaborator finds
  them.

### 6.3 Typing

| term | its type | checked |
|---|---|---|
| `Sort(u)` | `Sort(u + 1)` | every level parameter is declared |
| constant | its declared type at the given levels | the number of levels is exact |
| free variable | the type of its binder | |
| `f(a)` | the result type of `f` with `a` put in | the type of `f` computes to a function type; the type of `a` equals its domain |
| `(x: A) => b` | `(x: A) -> B`, where `B` is the type of `b` | `A` is a type |
| `(x: A) -> B` | `Sort(imax(u, v))` for `A: Sort(u)` and `B: Sort(v)` | both are types |
| let | the type of the body with the value put in | the value's type equals the declared type |
| number | the bound number type | a numbers declaration exists (6.7) |
| projection | the field's type, earlier fields put in as projections | the term's type is a structure: one constructor, no indices |

The `imax` in the function type is both universe rules at once. A function type that ends in a proposition is a
proposition whatever it ranges over: impredicative. Every other function type lies at the larger of its two levels:
predicative.

Projections out of a proof are narrowed: from a structure that is a proposition only a proof may be projected, and
no field whose type mentions an earlier data field. Without this the witness of an `exists` could be read out.

### 6.4 Computing

One step at a time, to the head of the term:
- **beta**: a function applied to its argument;
- **zeta**: a let, by putting the value in;
- **delta**: a definition or theorem by its value; an axiom, an opaque constant and a program body never unfold;
- **iota**: a recursor on a constructor takes that constructor's rule. For a structure the value is first expanded
  into its constructor (eta), never for a proposition. For a type with the K property (a proposition with one
  constructor without fields, like `Equal`) the value need not be a constructor: the constructor is built from the
  value's type and used once its type equals the value's type;
- **projection**: a field of a constructor application is that argument;
- **quotient**: `lift(f, respects, quotient.of(a))` computes to `f(a)`, and `induct(h, quotient.of(a))` to `h(a)`;
- **numbers**: where a rule asks for a constructor, a number is zero or the successor of the number before it, one
  step at a time; the shortcuts of 6.7 compute arithmetic on two numbers at once.

### 6.5 Definitional equality

Two terms are equal when the first rule that applies says so:
1. they are the same tree; two sorts at equal levels; two equal numbers;
2. two binders of the same kind: equal domains, then equal bodies under one fresh variable;
3. **proof irrelevance**: the type of the terms is a proposition and their types are equal;
4. definitions are unfolded step by step, the one declared later first, with a stop as soon as the heads agree;
5. two constants of one name at equal levels; one free variable; two projections of one field of equal terms; two
   applications of equal heads to equal arguments;
6. **eta for functions**: `f` equals `x => f(x)`: a function is compared with another term by applying both;
7. **eta for structures**: a constructor application equals any term of its structure type whose projections equal
   its arguments (`p` equals `Pair(p.first, p.second)`); only for a structure: one constructor, no indices, not
   recursive;
8. **unit eta**: two terms of a structure without fields are equal when their types are.

Function types are the dependent products and structures the products with fields, so rules 6 and 7 are the
eta-equality "for functions and products" of the list. The caches of this check are keyed by the whole term, and
the answer for an open term is kept only while its variables live. The kernel counts its steps: a declaration
that runs out of the budget is refused as "gave up", never accepted, and the count is the same on every machine.

### 6.6 Declarations

| declaration | checked |
|---|---|
| axiom | its type is a type |
| definition | the same, and the value's type equals the declared type |
| theorem | as a definition, and its type is a proposition |
| opaque | as a definition; its value is never unfolded |
| program | for a constant already declared, the body it runs by: the body has the constant's type, and inside it the constant stands for itself. The kernel never unfolds or compares it; only erasure reads it |
| inductive block | section 7 |
| quotient | once, naming the equality type, whose shape is checked; it adds `quotient`, `quotient.of`, `lift` and `induct` with fixed types |
| numbers | once, naming the type with a zero and a successor that number literals belong to, and for each shortcut its function and the theorems that license it (6.7) |

For all of them: the name is new, the level parameters are distinct, no undeclared level parameter and no free or
loose variable occurs. Constructors and recursors are made by the kernel, never handed to it.

A program body is the only place recursion is written, and it is no part of the logic: it says how a constant
runs. A host operation is an opaque constant whose program is a `prim`.

The standard axioms are declared in the prelude with the word `axiom`, like any other: `proposition_extensionality`
(two propositions that imply each other are equal: the "extensional" of feature 3) and `quotient_sound` (values the
relation joins are equal in the quotient). `function_extensionality` is a theorem resting on `quotient_sound` alone.

### 6.7 Numbers

A number literal is a short way to write `successor(successor(… zero))`, and arithmetic on two literals is a
shortcut through definitions. The kernel holds the list of shortcuts (add, subtract, multiply, divide, remainder,
power, equal, at most, gcd, the bit operations, log2), each with the equations that pin its function down on every
literal, for addition `m + 0 == m` and `m + successor(n) == successor(m + n)`. The numbers declaration switches a
shortcut on for a library function by naming axiom-free theorems of exactly these statements. A function without
the theorems gets no shortcut, and no library name is written in the kernel.

### 6.8 What the kernel does not have

No recursion and no termination check (recursion exists only as recursors, and in program bodies it never reads);
no effects; no subtypes, conversions, overloads, implicit arguments or holes; no library word; no "trust me"
declaration; no evaluation by compiled code.

## 7 Inductive types

A block declares one or more types with their constructors. `enum` and `class` are its spellings: a parameter list
after the name, the indices in the result type, a class being a block of one type with one constructor. The checks,
in order:
1. **Header**: all types of the block share the parameters and the universe of the result; each is
   `(parameters) -> (indices) -> Sort(l)`.
2. **Constructors**: each starts with the same parameters and returns its type applied to exactly those parameters
   and then the indices.
3. **Universes**: a field's universe is at most the type's, unless the type is a proposition, which may hold
   anything. A type in `Sort(u)` may or may not be a proposition, so it obeys both sides.
4. **Strict positivity**, after computing each field's type: a type of the block may occur only as the result of a
   field's function type, never in an argument position of it and never inside the indices.
5. **Elimination**: a type that can be a proposition has a recursor into `Prop` only. The exception, which may
   eliminate into any sort: a single type with no constructor (`False`), or with one constructor whose every field
   is a proof or appears in the result's indices (`and`, `Equal`, accessibility). So `or` and `exists` cannot be
   taken apart into data.
6. **Recursors**, one per type: the parameters, one motive per type of the block, one minor premise per constructor
   with an induction hypothesis for every recursive field, the indices, the major premise; and one computation rule
   per constructor.
7. **Flags**: K (a proposition, one constructor, no fields); structure (one constructor, no indices, not recursive),
   which opens projections and eta.

**Mutual types** are one block: the motives and the positivity check range over all its types together. A program
writes no keyword: enums that name each other are grouped by the elaborator.

**Nested types** occur under another inductive type, as in `branch(children: list<Tree>)`. They are allowed only in
the parameters of an earlier inductive type and only without loose variables. Each distinct container at its
arguments (`list<Tree>`) becomes one more type of the block with the container's constructors copied in; the plain
block is checked (a container that uses its parameter negatively fails positivity right there), the recursors are
made, and the extra types are turned back into the container in every result.

For each block the elaborator adds ordinary definitions the kernel checks like any other: case analysis, the helper
structural recursion is built on, that constructors are distinct and injective, decidable equality, `show`.

## 8 The elaborator

The elaborator is where wap stays wap: everything a program may leave unsaid is found here and written into the
term. It is the larger half of the work and none of it is trusted.

| a program leaves unsaid | the elaborator | practice adopted |
|---|---|---|
| arguments: letters, levels, `_` | finds them by unification, first-order and for patterns; what it cannot find it reports by name | implicit arguments with holes solved in a second pass |
| which overload | by the argument types, then by the type wanted; equal fits are refused naming both | overloads chosen with the expected type |
| conversions | puts in the declared conversion where the type wanted differs: subset to parent, case to enum, part to sum, the number tower; the path between two types must be the only one | coercions as declared functions |
| operators on unlike types | converts both sides to the type they join in, then applies the operator there | one rule for binary operators |
| trait instances | builds the structure from the overloads in scope; a trait with laws needs their proofs | type classes, found by search |
| `match` | compiles it to case analysis on recursors; checks that the cases cover; solves the indices | dependent pattern matching by case trees |
| recursion | structural, else by a measure, else the effect Div (9.3); proves the equation a recursive function was written with as a theorem | recursion compiled to recursors |
| statements | blocks, variables, loops and exits become terms (9.5) | `do` blocks compiled to terms |
| untyped parameters | elaborates the template at each use | |
| obligations | prove or check (3.9) | proof obligations sent to automation |
| nothing: an elaborated term the kernel refuses | reports a compiler bug, with the declaration | the kernel as the only judge |

Its messages use the canonical words and name a fix, as every wap message does.

**The provers** are functions from a goal to a proof term: by computing; by a fact in scope; by rewriting with
proved laws; by the normal form of ring expressions; by linear arithmetic over the whole numbers; by induction along
a function's own recursion. `by` and steps 2 and 3 of "prove or check" call them. Whatever a prover returns is
checked by the kernel, so a wrong prover proves nothing.

**Erasure** removes what does not run: types, levels, proofs, arguments that are types or proofs. A structure with
one field left is that field, so a subset type is its value and a quotient its representative. A recursor never
reaches the emitter: the run term of a recursive function is its program body. A polymorphic function is copied per
type where the set of copies is finite, as today.

## 9 Totality and effects

A term of the theory must end and must not act, and wap programs loop, raise, read files and change variables. The
effects wiki/effects.md already names draw the line, and the compiler finds them.

### 9.1 What a function is in the theory

| a function that | has | in the theory it is |
|---|---|---|
| computes a value, covers every case and ends | no effect | a definition: it unfolds in types and proofs |
| may raise | Fail | a definition whose result is `T or Error`: failure is a value, `try` is its `match` |
| may not end | Div | an opaque constant of a computation type: it runs, it never unfolds |
| acts on the world: IO, State, FFI, Async, Eval, Unsafe | those | a function into a computation type; the host operations in it are opaque |

A type may mention only functions of the first row: `vector(int, read_number())` is refused.

### 9.2 Computation types

`T ! IO` is `Eff(IO, T)`, a structure of the prelude around a function from the world to an outcome: the value with
the next world, a raised error, or stopped. `World` is a structure of the prelude whose constructor no program can
call: the program's main is handed the only one. A host type (a float, a file) is likewise a structure around the
number that is its bits or its handle, with opaque operations. Three things follow, and they are the whole of what
consistency needs from effects:
- every computation type has a member, the computation that stops, so an opaque constant of such a type needs no
  axiom: host operations and functions that may not end add none;
- the value of a computation can be used only inside another computation, so a pure term cannot run one, and a
  proof returned by a computation is not a proof;
- the effect set is part of the type, so the kernel's own type check holds a function to its `! Pure` and to every
  other bound, given the types of the host operations.

A function that takes a function is elaborated once for pure arguments and once for effectful ones, from one
source, as an untyped function is elaborated per argument type.

### 9.3 Ending

The kernel has no recursion, only recursors, which always end. The elaborator turns a recursive function into a term
over recursors, trying in order:
1. **structural**: every recursive call is on a part of an argument of an inductive type; also across a mutual
   group and under a nested type;
2. **by a measure**: a natural number computed from the arguments that every recursive call makes smaller. The
   default is the sum of the arguments' sizes, `decreasing m` names another, a tuple orders by its first part first.
   That it gets smaller is an obligation for the provers. The term recurses structurally on a bound for the measure,
   so it computes in the kernel as fast as the function recurses;
3. **accessibility**: recursion over any relation proved well-founded, through the library;
4. otherwise the function has the effect **Div**: it is an opaque constant with its program body, it runs as
   written, and laws about it stay at Tested.

`for` over a list or a range always ends. `while` needs a measure or is Div. Step 4 is never an error: a script
needs no proof.

### 9.4 Covering

Every `match` covers its cases or ends in `other`. An operation that cannot answer for every value says so in a
condition of its parameter: `xs#i` takes an `index(xs)`, `a / b` a divisor that is not zero, `x!` a value that is
not ø. The condition is an obligation of the caller: proved, or checked with the effect Fail (3.9). A run-time
check is the library function that turns a decidable proposition into its proof or a raised error; no primitive is
needed for it.

### 9.5 Statements are no effect

A local variable, a loop and an early exit are ways to write a function, not actions on the world. The elaborator
turns them into terms: an assignment is a new binding of the name; the variables a branch assigns are its result; a
`for` is a fold with those variables as its state; `return`, `break` and `continue` are a mark in that state;
`xs#i = v` and `p.x = v` give the variable the updated value (value semantics). So `total` in 3.8 is a pure, total
function, and laws about it can be proved. A `global`, a `shared` value and the host are State and IO.

### 9.6 What a proof may use

| | in a type or a proof |
|---|---|
| a pure, total function | by its definition |
| a function with Fail | by its definition, its result an error or a value |
| a function with Div or a world effect, a host operation | by its type only, and only inside a computation |
| a law that is Proved | as a theorem |
| a law that is Tested or FAILED | not at all |
| an `axiom`, an `assume` | yes, and every report names it |

### 9.7 What runs

A recursive function reaches the kernel twice: as a term over recursors, which is what types and proofs see, and
as its program body, the recursion as written, which is what runs. The equation between them is a theorem the
elaborator proves. A function of the prelude may run by a host operation instead (`int` addition by the machine's):
its program body is then a `prim`, believed for what runs and tested by the laws, never read by a proof.

## 10 Consistency

### 10.1 The argument

Feature 9 is no rule and cannot be tested, and no system of this strength proves it about itself. It is an argument
in three steps; for each the plan says what carries it.

**The rules have a model.** Read every term as a set. `Prop` is the two truth values, and a proposition is empty or
has one member, so all its proofs are equal. `Type(u)` is the sets below the u-th of a ladder of ever larger
universes of sets. A function type is the set of functions, and one that ends in a proposition is true exactly when
every instance is: that is why impredicativity is harmless there and nowhere else. An inductive type is the
smallest set closed under its constructors, which exists because of strict positivity and fits its universe because
of the field rule. A quotient is the set of classes. In this reading every rule of sections 6 and 7 is true: terms
the kernel calls equal are the same set, a term of a type is a member of it. `False` is the empty set, so no term
has it. The reading makes the two standard axioms true as well, and choice.

The standing of that argument: the model is published for these rules without eta for structures, projections,
mutual and nested blocks and number literals. Those four have short arguments of their own: eta holds for tuples of
sets; a projection is a recursor applied; a mutual block is one family over a tag, and a nested one is rewritten
into a mutual one before it is checked; a shortcut is licensed by a theorem. The model needs set theory with a
ladder of large sets, the usual price of a universe hierarchy. No system of this family has a finished
machine-checked proof for all its rules together, and the plan claims none.

**Nothing outside the kernel can add a rule.**
- The elaborator, the sugar rules and the provers only build terms, and every term is checked whole.
- Effects add no axiom (9.2), and a program body is never unfolded.
- Erasure and the emitter come after the check and feed nothing back: the kernel computes by its own rules, never
  by running compiled code.
- An axiom enters only by the word `axiom` or `assume` in a source file, and `axioms of` and `wap verify` name it.

**The kernel follows the rules.**
- It is small and has no escape hatch (6.8).
- Every pitfall of 10.4 is a test that must end in a refusal naming the rule.
- A second opinion: wap writes every accepted declaration to a file in the export format of Lean's kernel, and an
  independent checker of that format must accept it. The rules being the same is what makes this possible. It is a
  test, not a dependency.
- The stage builds: the compiler that passes its own kernel builds the kernel again (`--stage`), and the tests run
  on that one.

### 10.2 What is trusted for what

| | that no false law is accepted | that a proved law holds for the running program |
|---|---|---|
| the model of the rules | yes | yes |
| the kernel, the compiler that built it, the wasm engine it runs on | yes | yes |
| reader, sugar rules, elaborator, provers, library | no | no: a statement is shown as it was checked, printed from the term |
| erasure, emitter, which host operation runs a prelude function | no | yes |

Every proved law is still run on test values against the compiled program. A prelude function that disagrees with
the host operation it runs by shows as FAILED beside its Proved.

### 10.3 Known defects of the rules, accepted

Three flaws are known for these rules and none touches consistency: equality as checked is not transitive, a term's
type can change under computing in corner cases, and checking can run forever in corner cases (proof irrelevance
together with recursion over accessibility). The kernel therefore never relies on transitivity, and the step budget
turns a loop into "gave up".

### 10.4 Pitfalls, each with its rule and its test

| pitfall | the rule that stops it | must be refused |
|---|---|---|
| a universe inside itself | `Sort(u)` is a `Sort(u + 1)`; exact level counts; declared level parameters | a definition of type `Type` with value `Type`; a constant at too few levels |
| impredicativity leaking into data | `imax` collapses at level 0 only | `(A: Type(1)) -> nat` taken as anything but a `Type(2)` |
| data read out of a proof | elimination into `Prop` only (7.5) | a function from a proof of `A or B` to a bool; a data motive for `exists` |
| a witness projected out of a proof | the narrowed projection (6.3) | the first field of an `exists` |
| a field larger than its type | a field's universe is at most the type's (7.3) | `enum Box: Type { box(A: Type) }` |
| a type in `Sort(u)` taken as data only, or as a proposition only | both sides hold (7.3, 7.5) | a two-case type in `Sort(u)` with a data motive |
| a type defined through its own negation | strict positivity (7.4) | `enum Bad { bad(f: Bad -> False) }`, and the merely positive `bad(f: (Bad -> Prop) -> Prop)` |
| nesting where it is not allowed | nested types only in parameters, checked after copying (7) | nesting in an index; nesting under a container that uses its parameter negatively |
| K without a check | the constructor built from the type must have the value's type (6.4) | a recursor on a proof of another equation computing as if it were `refl` |
| proof irrelevance on data | the type's sort is checked first (6.5) | `yes == no` by `refl` |
| eta where there is no structure | structures only (6.5, 7.7) | eta on a recursive or an indexed type |
| a quotient over a wrong equality | the equality's shape is checked (6.6) | a quotient declared over a type of another shape |
| arithmetic against the definitions | a shortcut only by its theorems (6.7) | `2 + 2 == 5` by `refl`; a shortcut for a function whose theorems are missing or rest on an axiom |
| two terms taken for one | caches keyed by the whole term (6.5) | two terms that differ only deep inside |
| variables that escape | declarations are closed (6.6) | a value with a loose or a free variable |
| stolen names | names are new; constructors and recursors are made (6.6) | a second `nat.recursor` |
| one level parameter listed twice | distinct level parameters (6.6) | a definition over `u, u` |
| a term too large or too deep | the step budget, a depth limit | `2 ^ (2 ^ 64)` compared by `refl` ends as "gave up"; a wasm trap is never an acceptance |
| a loop as a proof | no recursion in terms; Div is a computation type (9.3) | `law oops: False := loop()` |
| a raise or a missing case as a proof | every match covers; Fail is a value (9.1, 9.4) | `law oops: False := raise "no"`; a proof by a `match` that skips a case |
| a run-time check taken for a proof | a check gives its proof inside a failing computation only (9.4) | `law five: 2 + 2 == 5 := check(2 + 2 == 5)` |
| a type that depends on the world | types mention pure, total terms only (9.1) | `vector(int, read_number())` |
| a tested law used as a proved one | only Proved laws are theorems (9.6) | a proof citing a law that is Tested |
| an axiom nobody sees | `axiom` and `assume` are the only doors (10.1) | a prover's result that rests on an axiom the source does not state |
| a host operation that lies | a host operation is opaque (6.6) | a proof that unfolds `print` or a program body |
| `any` as a back door | the way out of an any is a check; an unsafe cast is a computation (3.10) | a pure function turning an `any` into a proof |
| compiled code as evidence | the kernel computes by its rules only (10.1) | a law accepted because the compiled program printed yes |
| a mistake of the elaborator | every term is checked whole (10.1) | a hand-built declaration with a wrong level, type or conversion |

Every soundness bug published for a kernel of this family joins the table as one more line.

### 10.5 Risks that are wap's own

- **Speed.** The kernel is the first large pure program in wap, and every compile runs it. Measured before the
  first rule is written (milestone K0): `match` over an enum of a dozen cases, 10 million small allocations, a
  recursion 100,000 deep, and whether a value has a cheap identity and hash (if not, terms are interned and carry a
  number). Deep recursion is avoided by design: long chains of applications and binders are walked in loops.
- **Ambiguity.** Overloads, conversions and arguments left out meet in the elaborator. The rule stays wap's: where
  two readings fit, refuse and name both.
- **Loops from terms.** The emitter gets functions where it got `while`: a call of itself in last place must become
  a loop, a loop's state its locals. Measured by the existing benchmarks at milestone S2.
- **The reach of the provers** decides how many laws read Proved. It grows a prover at a time and never blocks a
  program: an unproved law is Tested, an unproved obligation a check.
- **The switch.** The compiler is written in wap and built from a seed, so its own source must pass both the old
  typing and the new one until the seed is refreshed (track S).

## 11 Milestones

The pages come first: each milestone starts with its wiki page (through the interviewer, as every page) with a
green test file and a red one whose red lines are the work list. Every test gives a wap program to the compiler and
checks what comes out: a printed value in `test/test_<area>.wap`; a refusal's message or a command's output in
`test/wap/test_<area>.wap`, which compiles the program with the compiler under test. No test looks inside the
kernel.

Four tracks. K is reached through programs in which every argument and type is written and recursion is a call of
the recursor: that explicit corner of the language needs almost no elaborator, so the kernel is tested from its
first day.

**K, the kernel**

| milestone | what works after it | outcome tests |
|---|---|---|
| K0 measure | the numbers of 10.5 | none kept; results in data/ |
| K1 functions and universes | terms, levels, `wap check`, `type of`; sorts, function types, functions, let, constants; axioms, definitions and opaque constants with level parameters; beta, zeta, delta, eta for functions | `type of Prop` is `Type`; `(A: Prop) -> A` is a `Prop`; `(A: Type) -> A` is a `Type(1)`; `bad: Type := Type` is refused; a definition given `P(x => f(x))` where `P(f)` is wanted is accepted; a constant at the wrong number of levels is refused; one identity function used at two levels |
| K2 inductive types | plain, indexed and mutual blocks: checks, recursors, iota, K | `nat`, `list`, `Equal`, `vector`, `Even` with `Odd`, `False`, `and`, `or`, `exists` accepted; `add(two, two) == four` by `refl`; each bad type of 10.4 refused naming its rule |
| K3 numbers | literals, the numbers declaration, shortcuts | `2 + 2 == 4` by `refl`, at once also for numbers of 100 digits; `2 + 2 == 5` refused; a function without its theorems gets no shortcut |
| K4 structures and proofs | projections, eta for structures, unit eta, proof irrelevance | `p == Pair(p.first, p.second)` by `refl`; two proofs of one proposition equal by `refl`; `yes == no` refused; the witness of an `exists` is not projected |
| K5 quotients | the quotient declaration and its computing | `lift(f, h, quotient.of(a)) == f(a)` by `refl`; `function_extensionality` proved in the prelude, and `axioms of` it is `[quotient_sound]` |
| K6 nested types | nesting under other inductive types | `Tree` under `list` accepted, a function over it by its recursor computes; the bad nestings of 10.4 refused |
| K7 second opinion | the export, and an independent checker run over it | every declaration of the test programs accepted by both |

**E, the elaborator: the language**

| milestone | what works after it | outcome tests |
|---|---|---|
| E1 arguments found | letters, level letters, `_`; unification | `identity(3)`, `identity(int)`, `identity(Type)`; `type of identity` shows `(a: T) -> T`; an argument that cannot be found is reported by name |
| E2 enums, classes, match, recursion | today's spelling makes inductive blocks; `match` to recursors; structural recursion; program bodies | the programs of 3.4 and 3.5 as written; `double(3)` is 6 when run and by `refl`; a `match` that misses a case is refused naming it |
| E3 subtypes | `where`, `type X < T`, conversions, obligations by computing and by facts in scope, else a check | the lines of 3.2 and 3.3, each with the outcome its comment states; `effects of` a function with a check left is Fail |
| E4 traits and conditions | traits as structures with laws; instances from overloads; operators; decidable conditions; the number tower as conversions | `sort` on a class with `compare`; a class without it refused naming the trait; `3 == 3.0` is yes; `if` on a proposition nothing can decide is refused |
| E5 statements and effects | blocks, variables, `for`, exits as terms; computation types; `effects of`; `! Pure` | `total` of 3.8 is Pure, and `total([1, 2, 3]) == 6` holds by `refl`; the lines of wiki/effects.md; `! Pure` refuses naming the chain |
| E6 measures | recursion by measure, `while` with a measure, Div; the decrease proved for a parameter moved by a literal toward a guarded bound (wiki/Footguns.md), other measures by a written proof until P3 | `fact(4)` is 24 and `fact` is Pure; a `while` without a measure is Div and still runs; `loop` of 3.8 |
| E7 sums | unions, optional values, `any`, class families; calls distribute | the lines of 3.10; `speak` over a list of an animal and a dog picks each one's method |

**P, proving**

| milestone | what works after it | outcome tests |
|---|---|---|
| P1 laws are theorems | a law with a proof term; `wap verify` without Lean: Proved, Tested, FAILED, Assumed; `axioms of` | `double_even` Proved; a wrong proof refused showing the two types that differ; an `assume` shows as Assumed and in `axioms of` |
| P2 the simple provers | computing, facts in scope, rewriting with proved laws, `by`, `chain` | `law 2 + 2 == 4` Proved; a law proved from two earlier laws |
| P3 arithmetic | ring identities, linear arithmetic over the whole numbers | the laws of wiki/laws.md: `square(-x) == square(x)` and `twice(x) == 2 * x` Proved; an index proved in range from the loop's bounds leaves no check |
| P4 induction | along a function's own recursion | `fact(n) > 0` Proved with its helper law, Tested without |

**S, the switch**

| milestone | what works after it | outcome tests |
|---|---|---|
| S1 census | elaborate and check run beside today's typing; the census (test/wap/ratchet_census.sh) gains a ratchet "accepted n of N" over the compiler's source, lib/ and the test programs | the count, which only grows |
| S2 running from terms | erase, and emit from run terms, behind an option | every test program prints the same both ways; the benchmarks within their guardrails |
| S3 the switch | the new stages are the compiler; wap/core/analyze goes; the kernel moves to wap/kernel; the seed is refreshed | test_hello, test_self, the census, `--stage 2`: the compiler built through its own kernel builds itself again |
| S4 the prelude in the theory | `nat`, `int`, `list`, `text`, `map`, optional values defined as inductive, subset and quotient types, each with the host operations it runs by | the prelude's laws Proved and run on values; `char` is `text where #it == 1` and nothing else |

Order: K1, then K2 to K6 in a row, with K3 right after K2 since every program is full of numbers. E1 follows K1, E2
follows K2, E3 follows K4; E4 to E7 follow E3 in any order. P1 follows E2 and K4; P2 to P4 follow it. S1 starts with
E2, S2 follows E5, S3 follows all of E, S4 follows S3. K7 any time after K2.

Feature by feature:

| feature | rule | milestone | the test that shows it |
|---|---|---|---|
| 1 dependent types | 6.3 | K1, E3 | a function type whose result names its argument; `dot` refusing two lengths |
| 2 inductive, mutual, nested | 7 | K2, K6, E2 | `Even` with `Odd`; `Tree` under `list`; the bad ones refused |
| 3 propositions: impredicative, proof-irrelevant, extensional | 6.3, 6.5, 6.6 | K1, K4 | `(A: Prop) -> A` is a `Prop`; two proofs equal by `refl`; `proposition_extensionality` in the axiom report of what uses it |
| 4 data: predicative, non-cumulative | 6.2, 6.3 | K1 | `(A: Type) -> A` is a `Type(1)`; a `Type` value where a `Type(1)` is declared is refused |
| 5 quotients | 6.4, 6.6 | K5 | `lift` on `quotient.of` computes; `half == fraction(2, 4)` |
| 6 function extensionality | none: it is a theorem | K5 | proved in the prelude, resting on `quotient_sound` only |
| 7 eta for functions and products | 6.5 | K1, K4 | `P(x => f(x))` where `P(f)` is wanted; `p == Pair(p.first, p.second)` by `refl` |
| 8 universe polymorphism | 6.2, 6.6 | K1, E1 | `identity` at three levels; a wrong level count refused |
| 9 consistency | 9, 10 | all | every line of 10.4 refused; the second opinion |

## 12 What can be cut

In the order to cut, first what costs most for least:
1. proofs about the world (what a program with IO does), tactics written by programs, coinduction: never part of
   the plan;
2. the second opinion (K7): evidence, not function;
3. the arithmetic provers (P3) and induction (P4): laws stay Tested and bounds stay checks, nothing is refused;
4. accessibility (9.3 step 3): a measure covers what programs write;
5. structural recursion across mutual groups and under nested types: such functions get a measure or Div;
6. one elaboration per effect for functions that take functions: they are written twice;
7. unions as sums of any width: `T?`, enums and `any` cover the dispatch;
8. the prelude in the theory (S4) for `map` and `text`: they stay opaque types with host operations, and laws about
   them stay Tested;
9. nested types (K6): a nested type can be written as a mutual one by hand, but `any` then needs it done.

Not to cut: K1 to K5, E1 to E3, E5, E6, P1, S1 to S3 and the refusal tests of 10.4. Together they are the nine
features in wap's own types.

## 13 Open decisions

Each with the recommendation first and its cost in core. They go to the user through the interviewer.

1. **What `int` is.** The wiki has it both unbounded and 64 bits wrapping. Recommended: `int` is the whole numbers,
   as wiki/laws.md promises ("proved for wap's mathematical integers"), and `i64` is the wrapping type, the whole
   numbers up to 2^64. 0 core lines either way; the emitter keeps a fast path with an overflow test.
2. **Classical logic.** Recommended: the prelude declares two axioms, `proposition_extensionality` and
   `quotient_sound`; excluded middle and choice come only with `use classical`, and every report names them. A
   condition of an `if` must be decidable either way. 0 core lines.
3. **An obligation nobody proved.** Recommended: checked when the program runs, listed by `wap check`, the effect
   Fail; `! Pure` and `--strict` refuse instead (3.9). The other way: always refuse until the program writes `as` or
   an `if`. 0 core lines of difference.
4. **A type's own `equals`.** Recommended: such a type is a quotient by it, so `==` is always equality and every
   function of the type respects it (3.6). The other way: `==` stays a free function for such types, and laws cannot
   rewrite with it. 0 core lines.
5. **`extends`.** Recommended: the parent's fields with a conversion to the parent, and a place typed by the parent
   holds the sum of the class and its extensions, so dispatch at run time is the sum rule (3.10); a hierarchy is
   closed where it is compiled. The other way, an open hierarchy decided by a tag at run time, needs a mechanism of
   its own in core.
6. **What a type holds.** Recommended: unlike types join to their union, not to `any`; `T?` is T or ø and no longer
   also an Error, which is `T or Error` (section 4). 0 core lines.
7. **W0 and `wap verify`.** Recommended: the Lean model and the Lean prover retire at milestones S3 and P3; until
   then they stay beside the new ones. 0 core lines.
8. **Words**, each an alias question: `Prop`, `Type`, `Sort`; `where` for a subset type; `quotient`, `lift`;
   `refl`; `axiom`, `assume`; `by`, `chain`; `decreasing`; the axioms' names. Settled on the wiki pages.

Decided by the plan, for the user to overrule: the rules are exactly those of Lean 4's kernel, known flaws included
(10.3), because that is the rule set with a model and with independent checkers to test against. An own variant,
say without large elimination for accessibility, would be decidable and would have neither.

## 14 What can start now

None of these waits for a decision above, and none touches wap/core or wap/kernel:
1. **K0**, the measurements of 10.5, as a throwaway program in data/.
2. **K1 and K2 in `wap/extensions/theory/`**: terms, levels, computing, equality, typing, inductive blocks, with the
   explicit programs as tests. This is needed whatever the answers are, and writing it shows what wap itself lacks
   for a program of this kind.
3. **The pages**: drafts of the wiki pages `type` (rewritten), `subtype`, `proposition`, `proof`, `quotient`,
   `universe`, with their red test files, for the interviewer.
4. **The two shape rules** of 3.11, once the pages are approved.

The kernel and the elaborator each get an owner (notes/agents/wap-owner.md "Owners"); a change to the kernel passes
a second reader, since it is the one trusted part.

## Sources

- The feature list: the Lean language reference, "The Type System".
- The model: Mario Carneiro, "The Type Theory of Lean" (2019).
- The practices adopted: Lean 4's kernel for the rules; its elaborator for arguments left out, conversions, `match`
  and recursion compiled to recursors, and `do` blocks compiled to terms; its opaque constants and its IO type for
  effects.
- In wap: wiki/type.md, alias.md, char.md, enum.md, variant.md, trait.md, effects.md, laws.md, W0.md, Footguns.md;
  notes/backbone.md; wap/kernel/forms.wap; wap/core/analyze/.
