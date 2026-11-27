# Dependent types in wap's core: the plan

A plan, no code. It says what wap is once its own type system is a dependent type theory: how programs read, what
the compiler is made of and what of it is trusted, in which order it is built, how each step is tested, what can be
cut and what is open.

## In short

- wap's types become a version of the Calculus of Constructions with the nine features asked for (section 1). A type
  is a term like any other: `vector(int, n + 1)` is a function applied to arguments, and two types are the same when
  they compute to the same.
- **Dependent types are part of the core, not a library.** The typing stage of the compiler grows into an
  *elaborator*, which turns everything a program writes into complete terms, and builds them only through a small
  *kernel*, the only maker of checked facts. Only the kernel is trusted. The types module holds the vocabulary
  (`nat`, `list`, `Equal`) in plain wap; the provers are an extension that only `wap check` and proofs load.
- A script stays a script. Precision is added a step at a time and never forced: plain types, subtypes by condition
  (`type char = text where #it == 1`), types that depend on values, laws, proofs. What the compiler cannot prove it
  checks when the program runs.
- The pure, total part of wap is the logic. wap's own effects mark everything else (`Div` may not end, `Fail` may
  raise, `IO` acts), so a loop proves nothing and no program can add an axiom.
- The rules are those of Lean 4's kernel, the best-tested rules for exactly this list of features, with four
  stated departures (section 6). Nothing of Lean itself is used: syntax, elaborator, library and provers are wap's
  own, written in wap.
- Cost: the compiler is at 16,067 lines and ends about 17,100 once T5 deletes the analyze files it replaces, near
  the ballpark of 17,000, about 2,500 of them trusted.

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
| **elaborator** | the compiler's typing stage: it turns what a program writes (names, overloads, arguments left out, conversions, `match`, loops, recursion) into complete terms, building each one through the kernel's rule functions (LCF), so the kernel never re-checks a finished term | no: a bug here refuses a good program, or builds a term the kernel refuses |
| **types module and provers** | the vocabulary in plain wap (`nat`, `int`, `list`, `text`, `Equal`, `and`, the effects), and the provers, extensions that write proofs | no: whatever they define or prove passes the kernel |

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
| `and`, `or`, `not`, `implies`, `for x: A`, a comparison | propositions: types in `Prop`; a proof is a term of one |
| the condition of an `if` | a proposition that can be decided; its branch knows that it holds |
| `law` | a proposition; with its proof a theorem |
| a trait | a structure of operations and their laws, found by the compiler |
| `f(x) := …` with an effect | a function with its effects as facts (`effects of f`), a claim `! IO` checked against them |
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
enum Even: nat -> Prop { zero: Even(0), step(e: Even(n)): Even(n + 2) }     // a family of propositions
enum Equal(a: T): T -> Prop { refl: Equal(a, a) }                 // the prelude's equality
```

`enum` and `class` keep their spelling and gain what the theory needs. What is written after the name is the same
in every case: the parameters, `T` of `list<T>` and `a` of `Equal`. What differs from case to case stands in the
result type after the head (`: nat -> Prop`), and each such case writes its own result (`zero: Even(0)`). Each enum
gets its recursor from the kernel, `nat.recursor`; a program rarely calls it, it writes `match` and recursion.

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
| `Equal(a, b)` | the prelude's equality | `refl`, when both sides compute to the same |

A comparison is a proposition, and one that can be decided has a value: `if`, `while` and `bool` places compute it.
`==` is a type's test for equality, a function that answers yes or no. For the test the compiler derives (enums,
classes, lists, texts, whole numbers) it also proves that the test says yes exactly for equal values, so in a law
`a == b` reads as `Equal(a, b)` and laws rewrite with it. A type's own `equals` and the floats' `==` (which is not
yes for a NaN with itself) are tests only: a law about them states what the test answers.
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
half == fraction(2, 4)                          // yes, and in a law they are equal, not merely alike
sign(q: rational): int := q.lift(f => sign(f.top * f.bottom))
top(q: rational): int := q.lift(f => f.top)     // refused: top differs on 1/2 and 2/4
```

A function leaves a quotient only through `lift`, with a proof that it gives equal results on values the relation
joins. The compiler looks for that proof as for any obligation; it cannot be checked at run time, so without it the
function is refused. `lift` applied to a value made by `quotient.of` computes to the function applied to it: that is
the definitional computation rule. At run time a rational is a fraction and `lift` is a call.

The library uses it for `rational`, for `set<T>` (lists up to order and repeats) and for `i64` (integers up to
2^64). Function extensionality is a theorem of the prelude, proved from the quotient (milestone K5). A type is a
quotient only where `quotient(…)` is written: a class that defines its own `equals` stays a class with a test of its
own (3.5), so no script is asked for a proof.

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

A proof, which refuses a function that is not pure by inference, and `wap check --strict` for a whole program, stop after step 3: every obligation is then
proved or the program is refused. `wap check` lists the obligations left to run time, so a program's assurance rises
without touching its source, as wiki/laws.md says of laws. A function's effect depends on what the provers find, so
their work is counted in steps like the kernel's: the same program has the same effects on every machine.

### 3.10 Sums: unions, optional values, any

```wap
s: int or text = 3
show(n: int) := "number"; show(t: text) := "text"
show(s)                        // "number": the call distributes over the cases of s
x: any = [1, "a"]              // a data node; typed values convert into it
n: int = x#1                   // checked when the program runs: the way out of an any is always a check
```

A union is a sum of its parts, flat and without order (`text or int` is `int or text`, `int or int` is `int`), `T?`
the sum of `T` and ø, `any` the inductive type of data nodes (wiki/node.md), nested under list. A function inside
an `any` is a handle; calling it has the effects Div and Fail, since nothing says that it ends or what it takes. A
call whose argument is a sum and whose definitions take single cases distributes over the cases: the compiler
writes the `match`. That one rule gives run-time dispatch on unions, on `any` and on a class with its extensions.

### 3.11 What the reader needs

Checked with `wap format` on today's compiler: the reader takes every spelling of this section as it is. Two need a
shape rule: an enum's result type written before its brace (`enum Even: nat -> Prop { … }`), and the effect of a
function type (`(text) -> unit ! IO`), where a `!` after a type is glued to it today as the required mark, `unit!`.
New words: `Prop`, `Type`, `Sort`, `where` after a type, `quotient`, `axiom`, `assume`, `by`, `chain`, `axioms of`
and the command `wap check`.

A program may also write what the compiler otherwise finds: a level in square brackets glued to a name
(`identity[1](int, 3)`), a type argument in its place, and a recursor called with its motive
(`nat.recursor[1](n => nat, 0, (k, double_k) => double_k + 2, n)`). The kernel's own tests are written this way
(notes/theory.md "The explicit spellings").

The type words need no new form, because each one is the kernel's typing or an ordinary library word:
- `x : T` and `x as T` are one ascription. It checks when x already has type T. Otherwise it calls the library's
  conversion for that pair of types (`π as int`, `"1h 30m" as Duration`). After a signature, `:` and `as` declare the
  same result type.
- `to` is an alias of `as` (`convert text to int`). The `to` that starts a definition (`to add a to b: …`) is a
  different word, told apart by where it stands.
- `is` checks a value against a type and narrows it on the branch it guards.
- `->` and `→` write only function types (Pi). `=>` and `↦` write only functions (lambda).
- `read text as int` picks the overload whose result is the type wanted (T3e).
- `for x: T` before a body is one binder, and `∀` and `∃` are aliases of `for` and `exists`. The body's type
  decides what the binder means:
  - When the body is a proposition, the binder is Pi, and its proofs are functions of x.
  - When the body is an action, the binder is the loop, run for every x of its domain (`for i in 1...3: print i`).
    `for x in S` is `for x: T` with `x in S` as a premise.
  Both are the kernel's Pi and lambda, typed by the stage-3 kind rules. The theory's own reading of the `for` line
  (extensions/theory/elaborate/declare.wap) goes at T7.
The core cost is nothing.

## 4 What changes and what goes

The freedom to overhaul is used on the compiler's middle, not on the surface. No spelling has to go: nothing in the
theory needs the syntax changed. What goes is looseness in what a type means.

| today | in the target | why |
|---|---|---|
| a type is notation, compared as text | a type is a term, compared by computing | dependent types |
| generic letters: unification, one copy per tuple of types | a letter is an argument found by the compiler; the polymorphic term is checked once, copies per type are made after checking | one check instead of one per use |
| an untyped parameter: one version per argument type | stays: an untyped function is a template, elaborated at each use | scripting |
| a function nothing calls is never typed | only templates; every typed function is checked, called or not | a law may speak of it |
| `x = 1; x = "a"` makes x an any, with a warning | allowed without an any: an assignment is a new binding, so x holds the new type from there on; where two paths meet, a name they left with unlike types holds their union | nothing in the theory forbids it; a `let`, a `const` or a written type still fixes the type |
| unlike types join to `any` | they join to their union: `[1, "a"]` is a `list<int or text>`; `any` only where written | no silent loss of types |
| char to text, range to list, case to enum, int to float: conversions inside the typing code | conversions declared in the types module (3.2) | no special cases |
| overloads ranked by weights | the most specific takes the arguments as they are where another converts one, then has parameters that convert into the others', then is the program's own | one order, the conversions' |
| run-time dispatch written by the typing code for `any` | a call on a sum distributes over its cases (3.10) | one rule for any, unions, class families |
| `T?` also holds an Error | `T?` is T or ø; an error is `T or Error`, the effect Fail | each type says one thing |
| `==` compares values, loosely across types | `==` is the type's test after both sides are converted to the type they join in; the derived test is proved to be equality, a type's own `equals` and the floats' stay tests (3.5) | laws rewrite with equality, and no script is asked for a proof |
| `extends`: the `inherited` rule (sugar/records.wap) copies the parent's fields into the class | the rule still copies the fields; analyze builds the closed sum: a place typed by the parent holds the class or any of its extensions, and the method is picked by the case (T5) | no open-world dispatch |
| a protocol: a class with a required word, its record annotated `@protocol` | a trait (section 2), a structure of its words; a class that has the words is an instance (T6) | one notion of trait |
| a kind rule's output is bound at the top level and typed again, without its position, firing again up to 100 rounds | typed in place, at the node's position, as that node; it never fires on its own output (T3) | a fact belongs to one node |
| `while`, general recursion | pure when a measure proves they end, else the effect Div | totality |
| effects: specified, not built | types (section 9) | consistency rests on them |
| index, divide, unwrap raise at run time | obligations: proved where the compiler can, checked otherwise (3.9) | fewer checks, same safety |
| a unit mismatch is found at run time | at compile time where the units are written; `quantity("5 km")` still checks at run time | dimensions are type arguments |
| `f == g` on functions: by hash, by polynomial normal form, else "undecidable" | a proposition; the same methods are provers, extensionality is a theorem | the answer comes with a proof |
| `int`: 64 bits and wrapping on some wiki pages, unbounded on others | each number type is one mathematical object: `int` the whole numbers, stored by context; `i32` and `i64` the wrapping words | a law must mean one thing |
| `wap verify` proves with Lean | with wap's own provers and kernel | no second system |
| W0, the model of wap's types in Lean | the kernel is the model; `wap types` shows a program's terms | one definition of wap's types |
| `type(x)` asks at run time | known at compile time; for an `any` it reads the node's kind | types are gone at run time |
| the sixteen kernel forms, read by the emitter | the emitter reads the same statements, their facts made by the kernel; types and proofs emit nothing | what is checked is what runs |
| no evaluator in the compiler | the kernel computes: types, proofs by computing, folding | equality by computing |

Unchanged: the reader, the operator table, the rewrite rules and sugar, phrases and prepositions, multiple
dispatch as a way to write functions, sharing (wiki/Footguns.md "Aliasing"), flow facts from conditions,
truthiness (a conversion to a proposition), the wasm value layouts, the command line.

## 5 The compiler

### 5.1 Stages

| stage | reads | writes | trusted |
|---|---|---|---|
| read, operators, shape rules, declare, declared rules, lower, bind | text | bound statements: the program in the plain forms (call, block, define, function, get, set, if, case, try, while, return, break, continue) | no |
| elaborate (core/analyze) | bound statements | the same statements with their facts: every definition a complete term with its type, every instance chosen, every conversion and proof written out, each fact built by the kernel | no |
| the kernel | the rule applications elaborate makes, one per row of 6.3 | checked facts `Checked(term, type)`, which only its rule functions make, and the environment: each declaration accepted, or the compile refused; the kernel checks each declaration whole as analyze finishes it; a node's facts are read only once the kernel has accepted their declaration, and a refused declaration's facts are never read | yes |
| emit, encode | the statements and their checked facts; types, levels and proofs emit nothing; each constant runs by its body (9.7) | the wasm module | for what runs only |

Elaborate is today's type, kind rules and elaborate (wap/core/analyze), grown in place. The kind rules (stage 3)
fire in it, on a node once its type is known. The kernel is no stage of its own: elaborate builds every fact through
the kernel's constructors (LCF), so nothing checks the statements a second time. The stage contract of
notes/backbone.md holds as before: each stage reads one language and writes one.

Three lines through the stages:

| the program writes | the term the kernel checks | what runs |
|---|---|---|
| `shout(c)`, with `c: char` | `shout(c.value)`: the conversion from the subset type is written out | `shout(c)`: a char is stored as its text |
| `d: char = "a"` | the pair of `"a"` and a proof of `#"a" == 1`, found by computing | `"a"` |
| `law double(3) == 6` | a theorem: `refl`, of the type `Equal(double(3), 6)` | none: a proof does not run |

### 5.2 The tree

- `wap/kernel/`: the theory. `forms.wap` (today's kernel forms), `primitives.wap` (one row per host operation), the
  terms, levels, reduction, equality, typing, declarations, inductive types, quotients, numbers. No other folder is
  trusted.
- `wap/core/`: the machinery. `parse/` and `rules/` as today, `analyze/` grown into the elaborator, `emit/`.
- `wap/types/`: the language every program gets, in plain wap: the logic (`Equal`, `and`, `or`, `exists`,
  `Decidable`), numbers, lists, texts, maps, optional values, the effects and the computation type, the conversions.
- `wap/extensions/proof/`: what only `wap check` and proofs load: the provers, the second opinion and its export,
  the arithmetic proofs and the big numbers they reason with.

Until step T2 the kernel lives in `wap/extensions/theory/`, a module of its own with its own elaborator; T2 moves
the kernel into wap/kernel, each later step deletes the `elaborate/` files whose job analyze took over, and T7 retires
the rest of that folder. The door `wap check` on the explicit spellings (explicit.wap, bindings.wap, check.wap,
options.wap: 441 lines) stays in the extension and uses wap/kernel.

### 5.3 Size

The whole compiler (wap/core, wap/kernel, wap/types, sugar, compiler.wap and nodes.wap) is guided by a ballpark of
17,000 lines (user 2026-11-25), not a gate: a step that needs more lines gets them without a question. Today, counted with `wc -l` over the .wap files, and the target the steps of 11 add
up to:

| part | today | target | trusted |
|---|---|---|---|
| reader, operators, rules (core/parse, core/rules) | 3,036 | 3,036 | no |
| typing: core/analyze, grown into the elaborator | 3,491 | 4,898 (2,470 added, 1,023 of five files and 40 of restarts deleted) | no |
| kernel | 93 | 2,553 | yes |
| emit | 2,081 | 2,131 | for what runs |
| rest of core | 1,058 | 1,058 | no |
| types module and sugar | 2,239 | 2,889 | no |
| compiler.wap, nodes.wap | 326 | 326 | no |
| **the compiler** | **12,324** | **16,891** | |

That is about 20 lines above the ballpark, with the emitter's step T1b (measured: core −43, kernel +18) counted; cutting T8 (storage
by context) gives 16,841. The total holds near the ballpark only if
the steps delete the five analyze files they replace (letters.wap, fits.wap, conditions.wap, matching.wap,
dispatch.wap: 983 lines) and analyze's own numerals; kept, the compiler ends near 18,050. The estimates for T3 to T6
rest on the theory extension's elaborator, which does the same work in about 2,175 lines plus below.wap (141) and
run/erase.wap (315); an overrun in any of them is taken as needed; each step reports its measured lines.

Outside the compiler, in wap/extensions/proof, which only `wap check` and proofs load: the provers (951 lines today,
2,000 to 3,000 with P3 and P4), the second opinion and its export (1,309), the arithmetic proofs, and the door
`wap check` on the explicit spellings (441). wap/extensions/theory (5,957 lines today) is gone after T7: its kernel
moved in, its elaborator deleted file by file as analyze takes each job over. The kernel has no unbounded
arithmetic: its numbers are i64 with an overflow check (6.7). The size limit of wap's source
(test/wap/ratchet_census.sh) is raised by hand with each step that lands, by what the step measured.

### 5.4 Core knows no library word

The kernel and the elaborator name no library word. Where a mechanism needs one, the types module binds it by a
declaration:
- **numbers**: which type number literals belong to, and which functions the arithmetic shortcuts stand for (6.7);
- **quotient**: which type is the equality (6.6);
- **texts**: a text literal is the kernel's second literal, typed by the library's function from a list of code
  points; where a rule asks for a constructor it opens into that function applied to the list of its code points,
  each a number, as Lean's string literal does (`texts(text_of, list.empty, list.item)`, notes/coc-t2.md). The
  kernel has two literals, the natural number and the text;
- **conversions, instances, the computation type, decidable conditions**: declarations of the types module that the
  elaborator's general mechanisms read (section 8); spellings such as `T where c`, `T?` and `if` reach library
  functions through rules in sugar/.

### 5.5 The question: in the core, not a library?

Yes. The kernel and the elaborator are the compiler's core, and wap's own types are the theory's types. A library
could only check terms handed to it as data, beside a language whose own types stay loose: `char` would not be a
subtype of `text`, and a law would speak about a copy of the program instead of the program. What stays library is
vocabulary and proof search: the types module and the provers, which the kernel checks like any program.

The trust a library would have offered is kept: the kernel is a folder of about 2,350 lines, the only maker of checked
facts, and shares no code with the elaborator. A bug anywhere else can refuse a good program; it cannot make a false law pass,
short of a compiler that builds the kernel itself wrongly (10.2).

## 6 The kernel

The rules are Lean 4's kernel's, stated here as wap builds them, with four departures. Three only narrow what is
accepted: the natural number and the text are the literals (a text opens into a library function of its code points); no library name
is written in the kernel, each is bound by a declaration (5.4); a projection is allowed only out of a structure that
does not hold itself. One adds equalities, and has its own argument: arithmetic on literals is switched on by
theorems instead of being built in (6.7). Every rule has a test on both sides: something it accepts and something
it refuses (section 11).

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
| number | a natural number below 2^63, an i64 | a literal |
| text | its code points | a literal, opened into the bound function of the list of its code points |
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
- **delta**: a definition or theorem by its value; an axiom and an opaque constant never unfold;
- **iota**: a recursor on a constructor takes that constructor's rule. For a structure the value is first expanded
  into its constructor (eta), never for a proposition. For a type with the K property (a proposition with one
  constructor without fields, like `Equal`) the value need not be a constructor: the constructor is built from the
  value's type and used once its type equals the value's type;
- **projection**: a field of a constructor application is that argument;
- **quotient**: `quotient.lift(f, respects, quotient.of(a))` computes to `f(a)`, and
  `quotient.induct(h, quotient.of(a))` to `h(a)`;
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
| inductive block | section 7 |
| quotient | once, naming the equality type, whose shape is checked; it adds `quotient`, `quotient.of`, `quotient.lift` and `quotient.induct` with fixed types |
| numbers | once, naming the number type and the truth values, whose shapes are checked, and for each shortcut its function and the theorems that license it (6.7) |

For all of them: the name is new, the level parameters are distinct, no undeclared level parameter and no free or
loose variable occurs. Constructors and recursors are made by the kernel, never handed to it.

How a constant runs is no declaration and no business of the kernel: the bodies programs run by are the statements
the emitter reads (9.7); the kernel is asked only the ordinary question whether a term has a type.

The standard axioms are declared in the prelude with the word `axiom`, like any other: `proposition_extensionality`
(two propositions that imply each other are equal: the "extensional" of feature 3) and `quotient_sound` (values the
relation joins are equal in the quotient). `function_extensionality` is a theorem resting on `quotient_sound` alone.

### 6.7 Numbers

A number literal is a short way to write `successor(successor(… zero))`, and arithmetic on two literals is a
shortcut through definitions. The kernel holds seven shortcuts: add, subtract, multiply, divide, remainder, equal
and at most. Power, gcd, the bit operations and log2 are library functions over them. Each shortcut has the
equations that fix its function on every literal: for addition `m + 0 == m` and `m + successor(n) ==
successor(m + n)`; divide and remainder together, `m / n * n + m % n == m`, `m / 0 == 0` and
`m % successor(n) <= n`. The numbers declaration switches a shortcut on for a library function by naming theorems
of these statements.

A proved equation becomes a computed one here, so the checks are the rule:
- the number type has exactly the shape of the natural numbers: one type, no parameters, a case without fields and
  a case with one field of the type itself; the truth values are a type of two cases without fields, and the
  declaration says which is yes;
- each function has exactly its type, without level parameters;
- each statement is built by the kernel from the bound names and compared exactly with the theorem's;
- no axiom lies in what the theorem and the function rest on, opaque values read too;
- an equation names only bound names and shortcuts switched on before it;
- a shortcut fires only on its bound constant applied to two literals.

The arithmetic the shortcuts run on is the host's i64 with an overflow check, trusted code of the kernel: a shortcut
whose result would pass 2^63 does not fire, and the term is left to the definitions and the step budget. Reasoning
about larger numbers is the proof extension's, with a library of big numbers that only proofs load. A function
without its theorems gets no shortcut, and no library name is written in the kernel.

### 6.8 What the kernel does not have

No recursion and no termination check (recursion exists only as recursors); no effects; no subtypes, conversions,
overloads, implicit arguments or holes; no library word; no "trust me" declaration; no evaluation by compiled code;
nothing about how a program runs.

## 7 Inductive types

A block declares one or more types with their constructors. `enum` and `class` are its spellings: a parameter list
after the name, the indices in the result type, a class being a block of one type with one constructor. The checks,
in order:
1. **Header**: all types of the block share the parameters and the universe of the result; each is
   `(parameters) -> (indices) -> Sort(l)`.
2. **Constructors**: each starts with the same parameters and returns its type applied to exactly those parameters
   and then the indices. Every other occurrence of a type of the block, in a field, carries exactly those
   parameters too.
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
7. **Flags**: K (a block of one type that is a proposition with one constructor without fields); structure (one
   constructor, no indices, not recursive), which opens projections and eta.

**Mutual types** are one block: the motives and the positivity check range over all its types together. A program
writes no keyword: enums that name each other are grouped by the elaborator.

**Nested types** occur under another inductive type, as in `branch(children: list<Tree>)`. They are allowed only in
the parameters of an earlier inductive type and only without loose variables. Each distinct container at its
arguments (`list<Tree>`) becomes one more type of the block with the container's constructors copied in; the plain
block is checked (a container that uses its parameter negatively fails positivity right there), the recursors are
made, and the extra types are turned back into the container in every result.

For each block the elaborator adds ordinary definitions the kernel checks like any other: case analysis, the helper
structural recursion is built on, that constructors are distinct and injective, the size of a value, decidable
equality, `show`.

**Where two rules of this plan meet.** By the checks above a type cannot hold itself under a subset type whose
condition speaks of it, under a quotient or under an opaque type: `class Quad { parts: vector(Quad, 4) }`, a
`list<Tree> where #it > 0`, a `set<Tree>` are all refused by strict positivity, and the refusal names the fix:
declare the plain type and state the condition as a `where` on its uses.

## 8 The elaborator

The elaborator is where wap stays wap: everything a program may leave unsaid is found here and written into the
term. It is the larger half of the work and none of it is trusted.

| a program leaves unsaid | the elaborator | practice adopted |
|---|---|---|
| arguments: letters, levels, `_` | finds them by unification, first-order and for patterns; what it cannot find it reports by name | implicit arguments with holes solved in a second pass |
| which overload | by the argument types, then by the type wanted; equal fits are refused naming both | overloads chosen with the expected type |
| conversions | puts in the declared conversion where the type wanted differs: subset to parent, case to enum, part to sum, the number tower; the path between two types must be the only one. A conversion lifts through a list, an optional value and a map's values (a `list<char>` where a `list<text>` is wanted): in the term a map over the container, at run time nothing where the conversion itself costs nothing | coercions as declared functions |
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
a function's own recursion. `by` and steps 2 and 3 of "prove or check" call them. The provers live in the
proof extension, which only `wap check` and proofs load. Whatever a prover returns is checked by the kernel, so a
wrong prover proves nothing.

**What runs.** The emitter skips what does not run: types, levels, proofs, arguments that are types or proofs. A structure with
one field left is that field, so a subset type is its value and a quotient its representative. A recursor never
reaches the emitter: a recursive function runs by its body as written (9.7). A polymorphic function is copied per
type where the set of copies is finite, as today; where it is not, and for a value whose type is computed only
when the program runs, the value has the one boxed layout an `any` has. A statement that reaches an axiom of data
is refused: an axiom has no value to run.

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

A type or a proof may use functions of the first two rows only, one with Fail as the function into `T or Error`
that it is: `vector(int, read_number())` is refused. Allocation, which wiki/effects.md reports, is no effect of the
type: building a value is pure.

### 9.2 Computation types

`T ! IO` is `Eff(IO, T)`, an opaque type of the prelude. The theory knows three things of the computation types
and nothing else: `pure` makes a computation of a value, `bind` runs one and hands its value to the next, and every
computation type has a member, the computation that never returns. These, the host types (a float, a file) and
every host operation are opaque constants: each has a value the kernel checked, built from that one member, and
none is ever unfolded. There is no world to build, to compare or to use twice, and nothing to hide from a program.
Three things follow, and they are the whole of what consistency needs from effects:
- every computation type has a member, so an opaque constant of such a type needs no axiom: host operations and
  functions that may not end add none;
- the value of a computation can be used only inside another computation, so a pure term cannot run one, and a
  proof returned by a computation is not a proof;
- nothing false about the world can be proved, because nothing about it can be proved at all: what a computation
  does is no term of the theory. Laws speak of pure code (section 12).

The effect set is part of the type and has one written form, a yes or no for each effect and then the program's
own events in order, so two spellings of one set are one type, and the kernel's own type check holds a function to
every bound written (`! IO`), and a proof to the inferred effects being none.

The opaque types need no rule and no axiom: the prelude declares one opaque constant, a family of pairs of a type
and a member of it. `Eff(e, T)` is the first part of the pair at `e` and `T`, the computation that never returns
the second.

A function that takes a function is elaborated once for pure arguments and once for effectful ones, from one
source, as an untyped function is elaborated per argument type.

### 9.3 Ending

The kernel has no recursion, only recursors, which always end. The elaborator turns a recursive function into a term
over recursors, trying in order:
1. **structural**: every recursive call is on a part of an argument of an inductive type; also across a mutual
   group and under a nested type;
2. **by a measure**: a natural number computed from the arguments that every recursive call makes smaller, or a
   tuple of such numbers, ordered by its first part first. The default is the sum of the arguments' sizes,
   `decreasing m` names another. That it gets smaller is an obligation for the provers. The term recurses
   structurally on a bound for the measure, one bound per part of a tuple, so it computes in the kernel as fast as
   the function recurses; where a bound is used up the term needs no value, since the proof that the measure lies
   below the bound rules that case out;
3. **accessibility**: recursion over any relation proved well-founded, through the library;
4. otherwise the function has the effect **Div**: it is an opaque constant of a computation type, it runs as
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
a list, a map and an instance are shared, as in Python (wiki/Footguns.md "Aliasing"): `xs#i = v`, `p.x = v` and a
method that changes its receiver change the one value every name of it sees. A write to a value the function made
itself and gave no second name is a new binding of that name, so `k.inc()` on a local `k` binds `k` again; a write
through a parameter, a capture, a global or a second name (`ys = xs; ys.add(2)`) is State, inferred as the
function's effect, and a name ending in `!` (`sort!(xs)`) claims it, checked. So `total` in 3.8 is a pure, total
function, and laws about it can be proved; `grown() := { xs = [1]; ys = xs; ys.add(2); xs }` gives `[1, 2]`, has
State, and its laws are Tested, never Proved. Since an assignment is a new binding, a name may be given a value of another type and
holds that type from there on; where two paths meet, it holds the union of what they left it with.

An `emit` used as a value is no action either: it is an argument the compiler passes down from the handler that
answers it, and the effect that names the event says the function takes it. What does act: a variable a nested
function writes (`nonlocal`, `global`) is a cell, which is State, as a `shared` value is; the host is IO.

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

Each constant runs by its statements as written, the ones the emitter reads with their checked facts; the
kernel checks their translation (9.5), never runs it. A loop runs as a loop, an assignment and a write as a store,
not as the fold and the new bindings the kernel checked: that the statements do what the translation says is
believed for what runs, and tested by every law run on values (10.2). For most constants the statements are their
value. Three kinds differ:
- a recursive function runs by its recursion as written, not by its term over recursors. The emitter takes that body
  only with a theorem the kernel checked: that the constant equals the body, where the body's calls of itself are
  the constant. A function that may not end has no such theorem and needs none: nothing is proved of it;
- a function of the prelude may run by a host operation (`int` addition by the machine's): its body is a `prim`;
- a type of the prelude runs by a host layout: its constructors and its case analysis have `prim` bodies, so a
  `nat` runs as a number and a text as its bytes, with the wasm layouts of today. This is the same table and the
  same mechanism, and core names no library word for it.

Every body is checked by the kernel's ordinary typing to have its constant's type. What stays believed for what
runs: that a `prim` does what the definition it stands for says, and that a recursion proved to end does end when
run. Both are tested by every law run on values (10.2).

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
mutual and nested blocks and number literals. Three of those have short arguments of their own: eta holds for
tuples of sets; a projection is a recursor applied; a shortcut is licensed by theorems, whose equations are true in
the model, where the numbers are exactly the literals. That a mutual block is one family over a tag, and that a
nested block may be rewritten into a mutual one before it is checked, is believed as it is for Lean: it is used
daily and has no published proof. The model needs set theory with a ladder of large sets, the usual price of a
universe hierarchy. No system of this family has a finished machine-checked proof for all its rules together, and
the plan claims none.

**Nothing outside the kernel can add a rule.**
- The elaborator, the sugar rules and the provers only build terms, and every term is checked whole.
- Effects add no axiom (9.2), and the body a constant runs by is no declaration: the kernel never reads one.
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
| the kernel with its i64 arithmetic under an overflow check, the compiler that built it, the wasm engine it runs on | yes | yes |
| reader, sugar rules, elaborator, provers, types module | no | no: a statement is shown as it was checked, printed from the term, and a body other than a constant's value runs only with its checked theorem (9.7) |
| emit; 9.5's translation of loops, assignments and writes; which host operation or layout a `prim` stands for; that a recursion proved to end does end when run | no | yes |

Every proved law is still run on test values against the compiled program. A prelude function that disagrees with
the host operation it runs by shows as FAILED beside its Proved.

Until T8, `int` runs as an i64 that wraps: a law proved of the theory's `int`, `x + 1 > x`, is false for the running
program at the i64 maximum. The second column holds for `int` only within the i64 range until then.

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
| a host operation that lies | a host operation is opaque (6.6) | a proof that unfolds `print` |
| `any` as a back door | the way out of an any is a check; a function taken out of one may not end; an unsafe cast is a computation (3.10) | a pure function turning an `any` into a proof; a pure function calling a function it took out of an `any` |
| compiled code as evidence | the kernel computes by its rules only (10.1) | a law accepted because the compiled program printed yes |
| a mistake of the elaborator | every term is checked whole (10.1) | a hand-built declaration with a wrong level, type or conversion |

Every soundness bug published for a kernel of this family joins the table as one more line.

A test of this table pins that the program is refused and by which rule, `refused by strict positivity`, never the
message after it (user 2026-11-24: the theory's rules are exempt from "no refusal tests" in this form). Five rows
no program can write: two terms taken for one, variables that escape, an axiom nobody sees, compiled code as
evidence, a mistake of the elaborator. They are properties of how the kernel is made (6.8), kept by its review and
by the second opinion, not by a test.

### 10.5 Risks that are wap's own

- **Speed.** The kernel is the first large pure program in wap, and every compile runs it. Measured (milestone K0,
  data/k0): a small allocation takes 12 ns, a `match` over a dozen cases 16 to 19 ns, a recursion 100,000 deep is
  fine and one a million deep is not. A value has no identity, `==` on a program's own recursive enum doubles its
  work with every level, and a map hashes an enum by its case name alone. So a term carries its own hash, terms are
  compared by `same`, never by `==`, caches are keyed by the hash, and long chains of applications and binders are
  walked in loops. Terms become interned, each with a number, when the first census asks for it.
- **Ambiguity.** Overloads, conversions and arguments left out meet in the elaborator. The rule stays wap's: where
  two readings fit, refuse and name both.
- **Compile time.** Every fact is now built through the kernel. Each T step measures the wall time of the
  self-build (`--stage 2`) before it lands: at most a fifth more than the step before, else it goes to the user.
  The baseline before T3, a warm compile of `print "Hello"` on the Mac at 07e358d8, 350 ms in all
  (scripts/compile-steps.wap measures it again):
  | step | ms |
  |---|---|
  | the warm state brought in | 12 |
  | the rules compiled (types/rules.wap, sugar/, the C function rules) | 56 |
  | the types module declared, read from types.wasm | 187 |
  | the program declared | 1 |
  | typed, the library functions it calls included | 92 |
  | emitted and encoded | 1 |
- **The reach of the provers** decides how many laws read Proved. It grows a prover at a time and never blocks a
  program: an unproved law is Tested, an unproved obligation a check.
- **Growing in place.** The compiler is written in wap and built from a seed, so each T step keeps its own source
  passing the typer it builds; a step that changes the kernel the seed reads takes the careful path (track T).

## 11 Milestones

The pages come first: each milestone starts with its wiki page (through the interviewer, as every page) with a
green test file and a red one whose red lines are the work list. Every test gives a wap program to the compiler and
checks what comes out: a printed value in `test/test_<area>.wap`; a refusal's rule or a command's output in
`test/wap/test_<area>.wap`, which compiles the program with the compiler under test. No test looks inside the
kernel.

Five tracks. K is reached through programs in which every argument and type is written and recursion is a call of
the recursor: that explicit corner of the language needs almost no elaborator, so the kernel is tested through its
door, `wap check` on the explicit spellings (notes/theory.md). L writes the prelude in that corner. E is what the
one typer, core/analyze, learns as it grows into the elaborator; P lives in the proof extension. T, the track that
grows the compiler, says in which step each of them reaches it.

**K, the kernel**

| milestone | what works after it | outcome tests |
|---|---|---|
| K0 measure | the numbers of 10.5 (done) | none kept; results in data/ |
| K1 functions and universes | terms, levels, `wap check`, `type of`; sorts, function types, functions, let, constants; axioms, definitions and opaque constants with level parameters; beta, zeta, delta, eta for functions | `type of Prop` is `Type`; `(A: Prop) -> A` is a `Prop`; `(A: Type) -> A` is a `Type(1)`; `bad: Type := Type` is refused; a definition given `P(x => f(x))` where `P(f)` is wanted is accepted; a constant at the wrong number of levels is refused; one identity function used at two levels |
| K2 inductive types | plain, indexed and mutual blocks: checks, recursors, iota, K | `nat`, `list`, `Equal`, `vector`, `Even` with `Odd`, `False`, `and`, `or`, `exists` accepted; `add(two, two) == four` by `refl`; each bad type of 10.4 refused naming its rule |
| K3 numbers | literals, the numbers declaration, the seven shortcuts on i64 with an overflow check | `2 + 2 == 4` by `refl` at once; a shortcut whose result passes 2^63 does not fire; `2 + 2 == 5` refused; a function without its theorems, or with theorems resting on an axiom, gets no shortcut |
| K4 structures and proofs | projections, eta for structures, unit eta, proof irrelevance | `p == Pair(p.first, p.second)` by `refl`; two proofs of one proposition equal by `refl`; `yes == no` refused; the witness of an `exists` is not projected |
| K5 quotients | the quotient declaration and its computing | `lift(f, h, quotient.of(a)) == f(a)` by `refl`; `function_extensionality` proved in the prelude, and `axioms of` it is `[quotient_sound]` |
| K6 nested types | nesting under other inductive types | `Tree` under `list` accepted, a function over it by its recursor computes; the bad nestings of 10.4 refused |
| K7 second opinion | the export, and an independent checker run over it | every declaration of the test programs accepted by both |

**L, the prelude in the theory**

| milestone | what works after it | outcome tests |
|---|---|---|
| L1 logic | `False`, `True`, `And`, `Or`, `Not`, `Exists`, `Equal`, `bool`, `Decidable`, as explicit programs (after K2) | each accepted through the door; `And` swapped and `Equal` turned round by their recursors, shown by `refl` laws |
| L2 numbers | `nat` with the numbers declaration and the theorems of its shortcuts; `int`; the comparisons (after K3) | `2 + 2 == 4` by `refl` in the prelude's own `nat`; `axioms of` each of the theorems is empty |
| L3 data | lists, optional values, pairs; texts as their code points, a text literal as the library's function of a number; `char` (after K4) | `#"abc" == 3` by `refl`; `"a"` is accepted as a char, `"ab"` is refused by `condition` |
| L4 effects | the opaque family of computation types, `pure`, `bind`, the effect sets in their one form, `T or Error` (after K4) | a host operation is declared and `axioms of` it is empty; a proof that uses a computation's value is refused by `effect` |
| L5 collections | `map` and `set` with their plain carriers, `rational`, `i64` (after K5) | `half == fraction(2, 4)`; a set equal to itself in another order |

**E, the elaborator: the language**

| milestone | what works after it | outcome tests |
|---|---|---|
| E1 arguments found | letters, level letters, `_`; unification | `identity(3)`, `identity(int)`, `identity(Type)`; `type of identity` shows `(a: T) -> T`; an argument that cannot be found is reported by name |
| E2 enums, classes, match, recursion | today's spelling makes inductive blocks; `match` to recursors; structural recursion; the bodies functions run by | the programs of 3.4 and 3.5 as written, the nested one once K6 is in; `double(3)` is 6 when run and by `refl`; a `match` that misses a case is refused by `covering` |
| E3 traits, operators and conditions | traits as structures with laws; instances from overloads; operators through traits; decidable conditions; the number tower as conversions | `sort` on a class with `compare`; a class without it refused naming the trait; `3 == 3.0` is yes; `if` on a proposition nothing can decide is refused by `undecidable condition` |
| E4 subtypes | `where`, `type X < T`, conversions, obligations by computing and by facts in scope, else a check | the lines of 3.2 and 3.3, each with the outcome its comment states; `effects of` a function with a check left is Fail |
| E5 statements and effects | blocks, variables, `for`, exits as terms; computation types; `effects of`; a proof refuses an impure function by inference | `total` of 3.8 is Pure, and `total([1, 2, 3]) == 6` holds by `refl`; the lines of wiki/effects.md; a proof refuses an impure function naming the chain |
| E6 measures | recursion by measure, `while` with a measure, Div; the decrease proved for a parameter moved by a literal toward a guarded bound (wiki/Footguns.md), other measures by a written proof until P3 | `fact(4)` is 24 and `fact` is Pure; a `while` without a measure is Div and still runs; `loop` of 3.8 |
| E7 sums | unions, optional values, `any`, class families; calls distribute | the lines of 3.10; `speak` over a list of an animal and a dog picks each one's method |

**P, proving**

| milestone | what works after it | outcome tests |
|---|---|---|
| P1 laws are theorems | a law with a proof term; `wap verify` without Lean: Proved, Tested, FAILED, Assumed; `axioms of` | `double_even` Proved; a wrong proof refused showing the two types that differ; an `assume` shows as Assumed and in `axioms of` |
| P2 the simple provers | computing, facts in scope, rewriting with proved laws, `by`, `chain` | `law 2 + 2 == 4` Proved; a law proved from two earlier laws |
| P3 arithmetic | ring identities, linear arithmetic over the whole numbers | the laws of wiki/laws.md: `square(-x) == square(x)` and `twice(x) == 2 * x` Proved; an index proved in range from the loop's bounds leaves no check |
| P4 induction | along a function's own recursion | `fact(n) > 0` Proved with its helper law |

**T, one typer grown in place**

There is one typer: core/analyze grows into the elaborator, one idea at a time, numbers first, then subtypes, then
definitions, then laws. The kernel is the only maker of checked facts (LCF): a checked fact is `Checked(term, type)`,
made only by the kernel's rule functions, one per row of 6.3, so what analyze writes is checked as it is written and
no pass checks it again. The kernel checks each declaration whole as analyze finishes it; a node's facts are read
only once the kernel has accepted their declaration, and a refused declaration's facts are never read; the emitter reads those same nodes, so what is checked is what runs. Each step lands alone with
the compiler building itself (`--stage 2` a fixed point), the census and the seed guarding it, and reports its
measured core and kernel lines and its self-build time: the wall time of `--stage 2` may grow by at most a fifth per
step, measured against the step before; more goes to the user.

| step | what works after it | outcome tests |
|---|---|---|
| T1 one table of primitives | wap/kernel/primitives.wap holds one row per host operation: its name, the wasm types it takes and gives, its builder; the emitter finds an operation by one lookup, and the Prim(shown) mark goes into the row; a `runs(…)` body is a `prim` of that table, checked against its row (9.7), and no wap spelling of a host operation is typed or checked | `runs(add, prim i64.add(m, n))` accepted, a body of the wrong width refused naming the row; the trust base listed by a command from the `runs(…)` declarations |
| T1b the emitter decides nothing it can be told | the text routines are written in wap, once for both builds, and the emitter calls the library's words it needs by the kernel's list of runtime words; the type words' value layouts are rows of T1's table; a build that keeps its values in the memory reads its own text and list files by its layout's row. The branches on such a build are build strategies, not row values (GC structs or C structs in the memory, call_ref or a table, struct.get or a load): they go to T5's erasure stage. The list words stay emitter helpers (card lists-once-in-wap) | every test as before; a value layout changed in its row alone, no emitter line touched |
| T2 the kernel inside | the kernel (terms, levels, typing, equality, computing, inductive types, recursors, quotients, the environment, show) moves from wap/extensions/theory into wap/kernel; its typing becomes rule functions that each make one `Checked(term, type)`, and the kernel checks each declaration whole as analyze finishes it; a node's facts are read only once the kernel has accepted their declaration, and a refused declaration's facts are never read; the environment keeps declarations by id and is persistent: checking a declaration gives a new environment or a refusal, so a refused statement needs no rollback and a name's text is only how it is shown; kernel numbers are i64 with an overflow check (6.7); the door `wap check` stays in the extension and uses wap/kernel; the theory census (its statement floor and time ratio in test/wap/ratchet_census.sh) retires, the typing census guards from here on, over wap/kernel too, its size ceiling raised by the kernel's measured nodes; how it is built: notes/coc-t2.md | the K and L test files green through the compiler's kernel; `2 + 2 == 4` by `refl`; a shortcut whose result passes 2^63 does not fire; two modules that declare the same name both accepted, each one's uses meaning its own (format.wap's `Side`); `--stage 2` a fixed point |
| TM one environment per module | each module is read with its own environment, built from the modules it `use`s: the language record splits into the language, the tables kept per file, one compile's caches and the build; an operator, alias, rule or phrase word declared in a file applies from its declaration on, in that file and in the files that use it, never in a file read later that does not; a file's text is scanned once, not three times for its uses; the restart after a standard module is brought in goes (notes/audit/2026-11-25-2.md R1) | a rule declared in one file does not fire in a file that does not use it; an operator used above its declaration in the same file is refused; `--stage 2` a fixed point |
| T3 numbers and arguments found | the typer's types are kernel terms, one representation, compared by computing and shown as notation only in messages and `format`; analyze's readers of the notation read terms. analyze types each function once: a recursive function's header is typed first, an assignment of another type is a new binding, and the retypings and the fresh start on a retype go, since a discarded round would leave checked judgements behind (the dispatcher's restart goes with T6, the restart for a standard module brought in with TM4). A kind rule's output is typed in place, at the node's position, as that node, and never fires on its own output. analyze types numbers through the kernel: a numeral has the type its place wants, else `int`; `i32` and `i64` the wrapping words; `#xs` an `int`; letters and `_` found by unification (E1); the readings typing chose stay the compile's table, keyed by the source place `format` prints. Until T5 a function analyze typed enters the kernel as an opaque constant by its signature, counted by the census as assumed; the numbers prelude is read in the explicit spelling | `0 - 3` is -3; `#xs - 1` is -1 on an empty list; `type of 3` is `int`; `identity(3)` and `identity(int)`; a recursive function's result is written, or found once its other arm gives the type, else refused with the fix-it naming it; a kind rule's error names the line of the phrase it rewrote |
| T4 subtypes | `where`, `type X < T`, the declared conversions; `nat` is `int where it >= 0`; an obligation proved by computing or by facts in scope, else a check with the effect Fail (E4, 3.2, 3.3, 3.9) | `d: char = "a"` accepted and `d: char = "ab"` refused by `condition`; `char` is `text where #it == 1` and nothing else; `effects of` a function with a check left is Fail |
| T5u unions (before T5a) | `A or B` (also `A \| B`, written `or`) is a sum type, flat, without order or repeats, `T or ø` being `T?`; its value is boxed as an `any`'s, so a part converts into the union as into any (Boxed) and the union narrows to a part by its `is` test (Narrowed, T4's check); unlike types join to their union; a call on a union picks each case's definition when the program runs, a case with none refused; `T or Error` is a failable value: `failed` is `is Error`, and narrowing an Error out raises it. Steps T5u1 types, T5u2 calls, T5u3 failable; T5a (definitions and pure expressions as kernel terms) follows, and T4d waits for T5a | the lines of wiki/type.md "Optional values and unions"; `type of [1, "a"]` is `list<int or text>`; `describe(s)` picks by the case; `r failed` of a `T or Error` |
| T5 definitions, statements and inductive types (steps: notes/coc-t5.md) | enums, classes, functions, `match`, blocks, variables, loops and exits become kernel declarations and terms as analyze types them: inductive blocks, recursors, structural recursion, a measure, else Div; unions, optional values and `any`; classes with type arguments, `class Pair<A, B> { first: A; second: B }` (wiki/type.md), as inductive types with parameters: each use an instance of the record, as T3f instances functions (about 40–80 lines in types, fits and declarations, the letters handed on by a records.wap rule); `extends` as the closed sum, built by analyze from the class declarations while the `inherited` rule keeps copying the fields; a compiled library carries, beside its signatures, the bodies that may unfold (definitions a type or a proof computes with), as a Lean module does, which replaces the signatures-only format of notes/compile_inputs.md; a compiled library's declarations are; the theory's doors read analyze's typed nodes, so read.wap takes analyze's choice in place of `nearest`, TRIAL_LIMIT and the numeral special cases (extension −40); letters.wap, fits.wap, conditions.wap and ROUNDS_LIMIT go
carried once, as the kernel accepted them when it was built (13); the emitter reads the statements and their checked facts, types, levels and proofs left out (E2, E5's statements, E6, E7), and the erasure stage chooses the build's strategies, the emitter's branches on a build that keeps its values in the memory (GC structs or C structs, call_ref or a table, struct.get or a load) | a `match` that misses a case is refused by `covering`; `effects of fact` is Pure; `effects of` a `while` without a measure is Div and it still runs; `speak` over a list of an animal and a dog picks each one's method |
| T6 laws, effects and instances | a law is a theorem; a plain compile proves by computing, else the law is Tested; a function's effects are facts and a proof refuses an impure function; traits are structures and instances come from overloads, a protocol (a class with a required word) is such a trait (E3, E5's effects, P1, P2); `wap check` loads the proof extension | `law double(3) == 6` Proved; `wap check` proves a law from two earlier laws; a proof using an impure function refused naming the chain; `sort` on a class without `compare` refused naming the trait |
| T7 the theory extension retires | what is left of wap/extensions/theory goes: its run door and its prelude, whose words now live once in wap/types; the provers (P3, P4), the second opinion (K7), the export, the arithmetic proofs and the door `wap check` live in wap/extensions/proof, which only `wap check` and proofs load | every test as before; `wap check` and the second opinion from wap/extensions/proof; the trust base listed by a command |
| T8 storage by context (cuttable) | an `int` is stored as i32 or i64 where computing or a fact in scope shows it fits (the plain compile loads no provers), else as a big number; the big numbers come from a library only the programs that need them load; `int` no longer wraps. Three layers stop at 2^63 and all three change here: the reader (a literal past i64 reads as an int, not a float), the runtime (the storage above), and the kernel (a count at or past 2^63 is `Large(Magnitude)`, `Numeral(int)` below it; ROW_OVERFLOW goes with the wrap; notes/unify-provers.md "Exact int literals past 2^63") | `2 ^ 62 * 4` prints 18446744073709551616; a loop counter stays an i64 and the benchmarks keep their guardrails; the compiler's build holds no big numbers (13); test_theory_prelude_numbers' `big: Proved` (4294967296² exact) green |

Order: K1, then K2 to K6 in a row, with K3 right after K2 since every program is full of numbers. L follows K as
its table says. P1 and P2 follow K4; P3 and P4 follow P2, in the proof extension. T1 to T8 follow one another, T1b right after T1, T5u before T5a (held work waits on unions: possessive-dynamic, record-fields-loop, refusal-partway's finally, emit-literals' K), TM between T2 and T3, each
landing before the next begins. T1 changes the kernel the seed reads beside it, so it takes the careful
path: the new kernel added, the seed refreshed, then the old code deleted. T2 changes nothing the seed reads (the
compiler reads only kernel/forms.wap and links no moved file until T3), so its sub-steps land on the normal path
plus the census (notes/coc-t2.md); T3, the first step whose core uses wap/kernel's typing, takes the careful path. Each of T3 to T6 deletes the files of
wap/extensions/theory/elaborate whose job analyze took over, so the two typers never both do one job. The E
milestones are reached in the T steps that name them.

What T1 to T8 cost, roughly, in the compiler (wap/core, wap/kernel, wap/types, sugar). The estimates for T3 to T6
follow the theory extension's elaborator, which does the same work today:

| step | added | deleted | analyze file replaced | net |
|---|---|---|---|---|
| T1 | 60 kernel (the table) | 80 emit (seven tables, the spelling check) | | -20 |
| T1b | 53 core, 18 kernel (the runtime words, the value layouts as rows), 58 types (texts in wap) | 96 core (five text routines, the layout tables), 46 types (the twins of the two builds) | | -13 |
| T2 | 2,300 kernel (moved, show.wap included, the unbounded numbers left behind), 60 kernel (judgements), 40 kernel (the environment by id, persistent) | 0 | | +2,400 |
| TM | measured | measured (the audit counts about −70: the pre-scans, the restart, language.wap's mixed fields) | | ≈ −70 |
| T3 | 350 analyze (unification 180, numerals at their expected type 170), 100 analyze (types as terms, the notation's readers), 40 analyze (one pass: headers first, assignments as bindings), 20 rules (kind rules in place), 200 types (the numbers prelude) | 100 (80 analyze: the 40 below and 40 of restarts and retypings; 20 rules: the refiring) | typed_readings and analyze's own numerals (40); letters.wap and fits.wap stay, T5 deletes them | +610 |
| T4 | 450 analyze (conditions, obligations, conversions, below), 100 types | 0 | conditions.wap stays and grows, T5 deletes it | +550 |
| T5 | 1,000 analyze (declarations, match, recursion, blocks, statements, sums), 200 types (data), 200 emit (erasure) | 967 (817 analyze, 150 emit) | matching.wap (192), letters.wap (286), fits.wap (196), conditions.wap (143); emit's shape guessing that erasure replaces (150) | +433 |
| T6 | 500 analyze (effects, instances, laws, tested), 30 analyze (protocols as traits), 150 types (logic, effects) | 90 analyze | dispatch.wap's rounds (about 90): generic dispatch goes through instances; calls on an `any` keep their `is` chains, the dispatch of a union | +590 |
| T7 | 0 | 0 in the compiler; the rest of the extension | | 0 |
| T8 | 200 emit and types | 20 | | +180 |
| **all** | **6,000** | **1,357** | **947 of analyze** | **+4,643** |

Measured, the compiler is at 16,067 lines with T4 underway; with the rest of T4, T5, T6 and T8 as estimated it ends
near 17,850 if T5 keeps the analyze files, about 17,250 with the four deleted as its row says, near the ballpark of
17,000 (5.3). A step's deletions belong in its gate, measured by a script (the file is gone), as its tests are. A step that
needs more lines takes them and reports its measured lines; only a jump far above the ballpark goes to the
interviewer.

### T6 after T6a3a: laws everywhere, traits and instances

T6a3, T6a4, T6a5 and T6a6 are planned in notes/coc-t6a.md; T6a7 is the first row below. The rest of T6 is two
tracks, V (verdicts of laws) and C (traits), which share no file, and a row of wap/types after C1, Q1 (quotients).
Each step is one builder, on the careful path when it changes a value layout (C2) and on the normal path
otherwise. Line estimates are for the compiler (core, kernel, types, sugar); the proof extension's lines
are counted apart, since a plain compile does not load them.

| step | what works after it | core / kernel / types (estimate) | extension | wiki pages it serves | outcome tests |
|---|---|---|---|---|---|
| T6a7 universes in analyze | A binder's type may be a universe, `Sort(u)`, `Type(u)` or `Prop`, and a one-letter level name nothing defines is found as `T` is (universe.md "One definition at every level"); `type of Type` is `Type(1)`; a level written as an argument, `identity[1](int, 3)`, is read where the name before it is a function with level parameters, and refused with both readings named where it might also be an index (`fs[1](3)` of a list, wiki/lambda.md) | core +45 (level binders found +20, a written level argument +15, levels shown +10), kernel 0 | 0 | universe.md | test_theory.wap's 13 universe lines: `type of (A: Type) -> A` is `Type(1)`, `bad: Type := Type` refused, `box(int)` refused where box takes a `Type(1)` |
| V1 one verdict per law | A plain compile computes each law. Without binders, it is Proved by computing or reported as FAILED, and it never stops the program. With binders, the run tries it and it is Tested. `wap verify` adds the provers and prints proof.md's six verdicts: Proved (with "rests on" its axioms, from the kernel's `axioms_of`), Tested, FAILED with the counterexample, Untested, Assumed (an `assume` it uses) and Axiom | core +25 (analyze/laws.wap: the statement computed to yes or no, its notice), kernel 0 | verify +30 (Tested, Assumed and Axiom beside today's three) | proof.md "Checking proofs", law.md "Checking a law" | `law double(3) == 6` Proved on a plain compile; `hard: Assumed`; `uses_choice: Proved, rests on choice`; an `axiom` line `Axiom`; a program's own `runs(…)` refused by `wap verify` too (test_theory_layouts: only the types module says how the host runs a declaration) |
| V2 `wap check` | `wap check` lists the obligations left to the run, `--strict` refuses each one not proved, and the laws' verdicts are printed as `wap verify` prints them. Both commands load the proof extension through one door; a plain compile never loads it. dispatch.wap's global `obligations` list becomes a fact the door reads | core −5 (the global list goes), kernel 0 | check +40 (a door beside verify.wap, sharing door_arguments and the verdicts) | type.md "Proved or checked", effects.md (`wap check --strict` refuses an impure function), cli.md | `wap check` on `xs#i` with nothing proving `i` in range lists "is checked when the program runs"; `--strict` exits 1 naming it; a program with every obligation proved lists none |
| V3 proved laws are facts | A law proved earlier is a fact for the laws after it (law.md's `fact(n) > 0` with its helper law first) and for obligations (3.9 step 2: an obligation matched against the conclusions of proved laws by unification, with no search, so a plain compile needs no provers). An obligation the provers prove under `wap check` loses its run check and its Fail | core +30 (an obligation instantiated from a proved law's conclusion), kernel 0 | prove +15 (an obligation as a Goal) | law.md (the helper-law example), type.md "Proved or checked" | law.md's pair both Proved; `#xs > 0` discharged by a proved law, so `effects of` the function has no Fail |
| C1 traits are structures | `trait shape { area(); perimeter() }` (today a class annotated `@protocol`, sugar/types.wap) is a structure over the type that conforms: one field per word, the word's type with that type in the trait's place. A type's instance is the record of its overloads found by `does_word`. `square(1) is shape` and `3 is Comparable` compute at compile time. The built-in traits that wap has words for (Equatable, Orderable, Comparable, Printable, Iterable, Sized, Addable) are declared in wap/types as traits, so the vocabulary stays library | core +30 (the structure from the record, `is` against a trait), kernel 0, types +25 (the traits), sugar 0 | 0 | trait.md "Built-in traits", "Conforming", "Declaring a trait" | `square(1) is shape` yes; `3 is Comparable` yes; `sort [dot(2) dot(1)]` refused with "dot is not Comparable: sort needs compare(a:dot, b:dot)"; `class dot: Comparable {x:int}` refused until `compare` is defined |
| Q1 quotients | `quotient(T, same)` is a type, `.of` puts a value in and `.lift` takes a function that respects `same` out (the kernel has quotients since K5); `fraction`, `rational` and `set` are quotients in wap/types | core +50 (the type form +20, `.of` and `.lift` typed +20, values compared by `same` +10), kernel 0, types +40 (fraction, rational, set) | 0 | quotient.md | test_theory_quotients_wanted's three laws: `lift` on `quotient.of` computes, `half == fraction(2, 4)`; test_theory_prelude_checked's lines in wap spelling |
| C2 instances passed | A value whose type is not known at the call (a list of mixed shapes, a value through `any`, a function value) carries its instance. The instance is the record of its type's function references, built where the value is boxed into the trait (`x as shape`, a `list<shape>` literal); a word called on it reads its field (call_ref). Where the type is known statically, the call is specialised as today, with no change to the emitted code. This pays off calls.wap's protocol DEBT (mixed lists, `x is shape` at run time). A trait's word with a body is the instance's default where the type has none (green today for known types, test_protocols) | core +110 (the instance built at boxing +40, a word called through it +30, the trait value's layout as a row of T1's table +20, defaults in the instance +20), emit +20 (a record of function references), kernel 0 | 0 | trait.md "Dispatch", "Constraints", "Declaring a trait" (each type its own `area`) | `[square(2), circle(1)].map(area)` gives each its own; `smallest([person("Ann", 3), person("Bo", 1)])` through `Comparable list`; careful path (value layout) |
| C4 generic dispatch through instances | A generic definition (`f(x: T)` with a trait word in its body) called on a boxed value takes the value's instance, instead of a dispatcher retyped round by round for each boxed type. dispatch.wap's rounds go (generic_choices, generic_results, taken, dispatches_completed, deeper_type, fits_generic, boxed_known, dispatcher_retyped: about 90 lines); its `is` chains over the definitions of a word called on an `any` stay, because an `any` is the trait of no words and carries no instance | core −90 (measured at the gate) | 0 | trait.md "Dispatch" | every dispatch test as before; a generic `describe(x: T)` called on mixed boxed values picks each type's `area`; the rounds' "nests without end" refusal is never reached |

#### Each step's wiki lines and the tests that pin them

A builder starts from these lines red. "red" is the last recorded full run (test/reds.txt); `_wanted` files are
red by design until their step lands. A **gap** is a wiki line no test pins, with the line to add first, in the
page's own test file (test/test_<page>_wanted.wap, or test/wap/test_<page>_wanted.wap where it needs a command).

- **T6a3 indexed families.** proposition.md:74-80 (`Even`, `Even(4)` proved, `Even(3)` has no proof), :82-86 (Even
  with Odd), enum.md:94-95. Pinned: test_proposition_wanted "an enum of proofs proves its cases", `four_is_even`;
  wap/test_proposition_wanted "Even(3) has no proof", "two propositions defined together" (all red). No gap.
- **T6a4 cases and induction.** proof.md:17-18, :42-45 (`double_even`, the theorem's own call), enum.md:100-114 (the
  recursor). Pinned: test_proof_wanted "a law's proof is a function giving a proof for each value", "a recursor
  computes like the match it makes", "a function by its recursor"; wap/test_proof_wanted "a match that misses a case
  proves nothing", "wap verify: a law with its proof is Proved" (all red). No gap.
- **T6a5 False, Exists, effects.** proof.md:111-117 (a loop or a raise is no proof), proposition.md:24-28 (`False`,
  `exists`), :66 (an undecidable `if`), effects.md:81 (a proof refuses an impure function, naming the chain).
  Pinned: wap/test_proof_wanted "a loop is no proof", "a raise is no proof"; wap/test_proposition_wanted "an if on a
  proposition nobody can decide is refused" (red). The chain a refusal names is V2's line. No gap.
- **T6a6 propositions as values, the logic in wap/types.** proposition.md:6-7, :16-24 (the table), :99-105 (`use
  classical`). Pinned: test_proposition_wanted "an equation is a proposition", "a false equation is a proposition
  too", "True has its proof"; wap/test_proposition_wanted "a proof decides no data", "excluded middle comes with use
  classical" (red), its verdict in proof.md:77's words, `rests on`.
- **T6a7 universes.** universe.md, all of it. Pinned: test_universe_wanted, 16 lines (red); wap/test_universe_wanted
  "levels do not include each other", "a universe never holds itself" (red); test_universe_page "one definition
  serves a value" (green). Gap: universe.md:20-21 → `[Type(1), Type(2)] == [Sort(2), Sort(3)]` is yes.
- **V1 one verdict per law.** proof.md:74-84 (the six verdicts, :84 the exit status), law.md:6-7 (a law never stops the
  program), law.md "Checking a law". Pinned: wap/test_law_runs, 5 lines (green: closed laws Proved or FAILED, Tested,
  the counterexample); test_theory_verify "a proof that uses an axiom is Proved and names what it rests on", with
  `Axiom` (green); wap/test_proof_wanted "a law nobody proved is Tested", "a broken law shows its counterexample", "an
  assume shows as Assumed", "an axiom is reported" (red); test_laws_page "a law with written binders leaves the
  program's value alone" (green); test_theory_layouts, a program's own `runs(…)` (red). Gaps:
  - proof.md:84: the exit status of `wap verify` on `law two: 2 + 2 == 5` → 1, and on `law both: 1 < 2` → 0.
- **V2 `wap check`.** type.md:188-189, effects.md:81, cli.md "Proofs". Pinned: wap/test_check, 4 lines (green: an
  obligation listed, an `if`'s condition, an assignment ending it, a parameter's own). Gaps:
  - type.md:189: `wap check --strict` of `n = 3\nx: int where it > 0 = n\nprint x` → refused, naming `it > 0` (its
    exit status 1 by cli.md:87, a failed run);
  - effects.md:81: `wap check --strict` of `log(): int := { print "a"; 1 }\nlaw one: log() == 1 := refl` → refused,
    naming `one → log` and IO.
- **V3 proved laws are facts.** law.md:36-44 (a proved law a lemma of the later ones), type.md:181-182 (an
  obligation found from a proved law). Pinned: test_laws_wanted checks only the program's value (red), no verdict. Gaps:
  - law.md:36-44: `wap verify` of the three lines → both laws Proved (red until the provers have a product law);
  - type.md:181-182: `law up(n: int where it >= 0): n + 1 > 0` and `h(n: int where it >= 0) := g(n + 1)` beside
    `g(x: int where it > 0) := x` → `wap check` lists nothing.
- **C1 traits are structures.** trait.md "Built-in traits", "Conforming", "Declaring a trait". Pinned:
  test_trait_page "sort orders Comparable values", a type's own text (green); test_trait_wanted "a number is
  Comparable", "sort uses a class's compare", "> uses a class's compare", "== uses a class's equals", "a class
  defining a trait's words is of the trait", "for walks what iterate gives" (red); test_protocols, the structural
  fit and a class's claim (green). Gaps:
  - trait.md:74-76: `class dot{x:int}\nsort [dot(2) dot(1)]` → refused with `dot is not Comparable: sort needs
    compare(a:dot, b:dot)`;
  - trait.md:83: `class dot: Comparable {x:int}` with no `compare` → refused naming `compare(a:dot, b:dot)`.
- **C2 instances passed.** trait.md "Dispatch", "Constraints", "Declaring a trait" ("a call picks the one of its
  argument's type"). Pinned: test_protocols "a class fits a protocol by having its words" (green, known types only).
  Gap:
  - trait.md:109-111: `smallest(xs: Comparable list) := (sort xs)#1` on `[person("Ann", 3) person("Bo", 1)]` →
    `person("Bo", 1)`, and on `[dot(3) dot(1)]` refused naming `compare(a:dot, b:dot)`.
  trait.md:114's default body is pinned for known types by test_protocols: "a protocol's default body is the word of
  a class without its own", "a class's own word replaces the protocol's default" (green). No page shows a default
  reached through an instance, so C2 adds no line for it.
- **C4 generic dispatch through instances.** trait.md "Dispatch". Pinned: test_dynamic, the dispatch of a known and
  an unknown value (green), which must stay green. No wiki line beyond C2's; C4 is a shrink measured by its gate.
- **Q1 quotients.** quotient.md, all of it. Pinned: test_quotient_wanted, 9 lines (red: the relation, `quotient.of`,
  `lift`, `lift_of` by `refl`, a set, function extensionality, i64's wrap, which is T8's);
  wap/test_quotient_wanted "a function that tells joined values apart is refused" (red); test_quotient_page (green).
  No gap.

Net: core about +195 (T6a7 +45, V +50, C +50, Q1 +50), types +65, emit +20, kernel 0; the proof extension
+85. Against the cost table's T6 row: the 500 analyze for "effects, instances, laws, tested" are T6a's +355 plus
V's and C's +100; the 30 for protocols is C1; the 90 deleted are C4's. T6a7 and Q1 (+95 core, +40 types) are beyond
the row, which counted quotients under the prelude the deletion took.

**Order.** T6a7 after T6a6. V1, then V2, then V3. C1, then C2, then C4. Q1 after C1, T6a3 and
T6a4 (a quotient's `same` is a proposition about two values, and laws over it are proved by cases). V and C run
side by side, one builder each. V3 needs T6a2 (hypotheses), and the law.md example needs the provers to prove `x > 0 and y > 0 implies
x * y > 0`, which they do once a product law joins int's kernel laws (T6a2's positive_product); until then that
example stays red. C2 needs T5's classes with type arguments (the trait's structure takes the conforming type as one).

**Beside the dedup and the exact-big-literals landing.**
- The dedup (unify-dedup: the equation toolkit and the regrouper shared by kernel/counting.wap,
  kernel/integer_laws.wap and extensions/prove/linear.wap) touches none of T6a7, V1, V2, C1, C2, C4 or Q1's
  files, so these run in parallel with it. V3 touches extensions/prove (goals.wap, facts.wap), so it starts after the dedup lands. Of
  T6a, T6a4 starts after it (a nat subject goes through int's case split in counting.wap); T6a3, T6a5 and T6a6 run
  beside it.
- exact-big-literals touches the reader, kernel/numbers.wap, kernel/show.wap and lib/magnitude.wap; no T6 step does.
  The one meeting point is V1's FAILED line, which prints the counterexample through show, so V1 lands after it or
  merges show.wap. C2 is a careful landing, and no other careful landing (a seed refresh, T6a3's
  families) may share their run.

**Wiki before building.** law.md "Checking a law" and cli.md:108 still say `wap verify` proves "with Lean" and list
Lean's tactics. V1 rewrites that text to wap's own provers. As a rewrite of what a page says, it goes to the user
through wap-interviewer first, with the old and the new text. Default bodies and C1's built-in traits are on
trait.md already; a trait carrying laws ("a structure of operations and their laws", section 2) has no wiki line, so
it is not built in T6.

**Not in T6.**
- Effects as computation types (`B ! IO` as `Eff(IO, B)`): cut. Every wiki line about effects (effects.md: a claim
  checked, `effects of`, a proof refusing an impure function) is met by the effect facts (T5b1) and T6a5's check.
  The computation types of 9.2 stay the theory extension's and leave with it at T7.
- `map default ListMap` (trait.md "Protocol and default class"): a declaration rule, not an instance.
- Lists as an enum with a host layout (`enum list<T> { empty; item(first: T, rest: list<T>) }` for the built-in
  list, the kernel computing `#xs`, `xs#i`, `xs + ys`, `map` by its recursor; about core +60, types +40, careful
  path): parked until a wiki page states a law over the built-in list. enum.md:93's `enum list<T>` is a program's own
  enum and needs none of it; test_theory_prelude_data's lines came from this plan's L3, not from a page, and go as
  unpinned.
- A trait with laws (above).

K7 any time after K2, in the proof extension.

After T3:
- a typing that can be discarded (closes the loop red, and would let headers find a recursive result), measured before building.

Feature by feature:

| feature | rule | milestone | the test that shows it |
|---|---|---|---|
| 1 dependent types | 6.3 | K1, E4 | a function type whose result names its argument; `dot` refusing two lengths |
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
2. the arithmetic provers (P3) and induction (P4), in the proof extension: laws stay Tested and bounds stay checks,
   nothing is refused;
3. accessibility (9.3 step 3): a measure covers what programs write;
4. structural recursion across mutual groups and under nested types: such functions get a measure or Div;
5. one elaboration per effect for functions that take functions: they are written twice;
6. unions as sums of any width: `T?`, enums and `any` cover the dispatch;
7. conditions lifted out of recursive types (E8): the refusal that names the fix stays;
8. `map` and `set` in the theory (L5): they stay opaque types with host operations, and laws about them stay
   Tested;
9. storage by context (T8): a compiled `int` keeps wrapping, as it does until T8 lands;
10. the second opinion (K7): it is the only check wap does not build itself, so it is cut last of these.

Not to cut: K1 to K6, L1 to L4, E1 to E6, optional values and `any` of E7, P1, T1 to T7 and the refusal tests of
10.4. Together they are the nine features in wap's own types, with `char` a subtype of `text`.

## 13 Decisions

Decided by the user (2026-11-26):
- **A small language first**: the theory may cut wap's language drastically where that serves it; parked forms
  keep their wiki text and red tests, and come back later, on demand, as rewrites to the small core.

Decided by the user (2026-11-24):
- A name can be given a value of another type; from there on it holds that type, and where two paths meet, their
  union. A name declared with `let`, `const` or a written type keeps its type (section 4, 9.5).
- The theory's refusal tests are exempt from "no refusal tests": they pin `refused by <rule>`, never the message.
- **Classical logic** is not in the prelude: it declares two axioms, `proposition_extensionality` and
  `quotient_sound`; excluded middle and choice come only with `use classical`, and every report names them. A
  condition of an `if` must be decidable either way.
- **An obligation nobody proved** is checked when the program runs, is listed by `wap check`, and gives the function
  the effect Fail; a proof and `--strict` refuse instead (3.9).
- **`==`** is the type's own test. The derived test (enums, classes, lists, texts, whole numbers) is proved to be
  equality, so laws rewrite with it; a class's own `equals` and the floats' `==` stay tests; a type is a quotient
  only where `quotient(…)` is written (3.5, 3.6).
- **`extends`** makes a closed sum: a place typed by the parent holds the class or any of its extensions, a value of
  an extension converts into that sum (never down to the parent's fields alone, which would be a second path), and
  the method is picked by the case when the program runs (3.10). A hierarchy is closed where it is compiled; a
  function over the parent is elaborated again for each program's hierarchy.
- **What a type holds**: unlike types join to their union, not to `any`; `T?` is T or ø and no longer also an Error,
  which is `T or Error` (section 4).
- **`f == g` between two functions** says they give equal results for every argument. It is a statement, decided
  when the program is compiled: in a law it is equality of functions, proved by the provers (computing, the normal
  form of polynomials, every value of a small domain, induction); as a condition it is answered with a proof or a
  counterexample, and refused where the compiler finds neither. Function values known only when the program runs
  are refused. It is the rule of every condition that cannot be decided (E3).
- **`===`** is the strict test the compiler writes for a type, field by field: no conversion before it
  (`3 === 3.0` is no) and no `equals` of the program in it. It is refused on a quotient and on functions, and is
  never the identity of two objects.

Decided by the user (2026-11-25):
- **`int`** is the whole numbers, unbounded and exact; the proofs see only that. Its storage is picked by context:
  i32 or i64 where the value provably fits, a big number where it might not (T8). `nat` is `int where it >= 0`.
  `i32` and `i64` are the wrapping machine words, written only where wrapping is wanted. Until the storage is picked
  by context, a compiled `int` wraps silently (no overflow test, no big numbers in the compiler's build).
- **A numeral** where no type is wanted is an `int`; `nat` only where a `nat` is wanted. `0 - 3` is -3 everywhere.
- **A count minus a count**: `#xs - 1` is -1 on an empty list.
- **A leading annotation** (`@runs …`) belongs to the whole phrase it leads, operated code and enums included.

Decided by the user (2026-11-25), the basis of track T:
- **One typer.** core/analyze grows into the elaborator in place, one idea at a time: numbers, then subtypes, then
  laws. There is no second typer beside it, no gate of agreement between two typers and no merge of two libraries.
  The census and the seed guard each step.
- **The kernel is the only maker of checked facts** (LCF). The elaborator builds its results only through it, so no
  pass checks them again; the facts the stages write on nodes are those checked facts.
- **No unbounded arithmetic in core or kernel.** Kernel numbers are i64 with an overflow check; reasoning about
  larger numbers in proofs comes from a module only proofs load.
- **The provers (P3, P4), the second opinion (K7) and the arithmetic proofs** live in an extension that only
  `wap check` and proofs load.
- **Size.** About 17,000 lines for the whole compiler is a ballpark, not a gate (5.3): "If someone needs more, give
  him more." Each step reports its measured core and kernel lines; only a jump far above the ballpark goes to the
  interviewer.
- The audit's Prim(shown) mark goes with the table of primitives (T1); the typed_readings global stays the compile's
  table, keyed by the source place that `format` prints, as TYPES is (T3).
- **`i64` is the integers modulo 2^64** (prelude/checked.wap: `quotient(int, wrapped_alike)`), as Lean's `Int64`.
  Laws that hold modulo 2^64 (commutativity, associativity) prove on `i64`; laws that assume no overflow
  (`a + 1 > a`) are refused there. The compiler's own source writes `i64` where it means a machine word, so its
  build holds no big numbers; 0 core lines, a source edit after a seed refresh.
- **T8** stays in the plan and is decided at its turn, once the sizes of T1 to T7 are measured.

Decided by the user (2026-11-25), after the extensions audit (data/extensions-audit/report.md) and R1:
- **One environment per module** is step TM, between T2 and T3, measured like T1b. A declaration in a file applies
  from its declaration on, not to the whole file.
- **Conditions lifted out of recursive types (E8)** are cut (cut 7): the refusal names the fix (user 2026-11-26).
- **The run door** is gone (user 2026-11-26): erase.wap stays without a door as T5's reference, theory/run/terms.wap
  its vocabulary.
- **The arithmetic provers stay** (P3, P4: linear, induction, apart). They import the elaborator's state, unify and
  match, which T3 to T6 delete: the step that deletes a file a prover imports ports that prover onto analyze and
  wap/kernel in the same step, and counts its lines.

Decided by the user (2026-11-25), after the audits:
- **A checked library carried once, trusted as built.** A compiled library carries its declarations as the kernel
  accepted them when the library was built, with their erased bodies; templates, rules and class hierarchies still
  travel as source. The library's reader joins the trust base. About 60 lines in extensions/wasm, outside the
  compiler's count, deleting about 150 there (the warm state, one of two section readers); it lands by T5.
- **The emitter decides nothing it can be told**, as step T1b right after T1: core −43, kernel +18, types +12 (5.3); the branches on a build keeping its values in the memory are T5's.
- **Native builds**, in the user's words: "use the full packet on demand and the small version whenever possible,
  consider adding the universal conversion mechanisms where needed". `wap build` makes the small executable (wasm2c,
  values in the memory) when the program fits that layout, and an executable running the program's .cwasm by
  wasmtime when it needs the full language. Fitting is the memory layout's own refusal: the build tries the small
  layout and takes the full one where that refuses. The memory layout keeps the forms it has; T5 and T8 emit their
  new forms for the GC layout only. A conversion between the layouts is written once, generally, where a value
  crosses from one to the other, and only when a program needs it. 0 core lines; about 60 in extensions/native (the
  launcher and the choice), outside the compiler's count.
- **Both value layouts stay**; no spike, and the driver keeps the memory layout.
- **One test command against a baseline**: the tests' known reds are listed once, and a run reports only what
  changed against them (card test-regression-known).

Open, with the recommendation first and its cost in core; with the user through the interviewer:

1. **W0 and `wap verify`.** Recommended: the Lean model and the Lean prover retire at steps T7 and P3; until
   then they stay beside the new ones. 0 core lines.
2. **Words**, each an alias question: `Prop`, `Type`, `Sort`; `where` for a subset type; `quotient`, `lift`;
   `refl`; `axiom`, `assume`; `by`, `chain`; `decreasing`; the axioms' names. Settled on the wiki pages.

Decided by the plan, for the user to overrule: the rules are those of Lean 4's kernel with the four departures of
section 6, known flaws included (10.3), because that is the rule set with a model and with independent checkers to
test against. An own variant, say without large elimination for accessibility, would be decidable and would have
neither.

## 14 How it is built

- The board's topic `dependent-types` has one card per milestone; the parts of K1 and K2 are a card per file.
- The kernel grows in `wap/extensions/theory/`, a module of its own with the door `check.wap`, until T2 moves it
  into wap/kernel; the contract between its files is notes/theory.md.
- The pages are on the wiki: `universe`, `proposition`, `subtype`, `type`, `proof`, `quotient`, and the recursor
  section of `enum`, each with a green and a red test file.
- The kernel and the elaborator each have an owner (notes/agents/wap-owner.md "Owners"); a change to the kernel
  passes a second reader, since it is the one trusted part. The elaborator's owner also owns the closed sum of
  `extends` (T5) and protocols as traits (T6), with the class rules of sugar/records.wap.
- A track T step lands with no OK for its core lines, census rise or speed: its card and merge message report the
  measured numbers, and the integrator raises the ceilings at landing. The self-build's memory and speed are
  reported as soundness checks, never as limits. Core counts and the standing OKs bound only sugar and syntax forms
  (user 2026-11-27).

## 15 Modules without source

The goal (card modules-without-source): a compiled module ships without its source, its types entirely in the wasm,
and the seed runs with no .wap file beside it.

What a module reads back from source today:
- its wap section is wap text: the module's files with the definitions it compiled cut out (extensions/wasm/modules.wap
  header_source, kept_lines), parsed again by every use (wasm_source, through core/pipeline.wap source_of and
  notation_of);
- each export's name is a header line, `add(a: int, b: int = 1) → int`, parsed into a foreign definition
  (foreign_definition);
- the files it uses travel as text in sections of their own, `types.wasm/host.wap` (carried_files, part_source);
- the seed folder holds the types module's sources, the kernel, the extensions' rule files and lib/ as .wap
  (scripts/lib/wap-beside.sh WAP_BESIDE), read where no warm state covers them, and lib/'s modules on every `use`.

What it carries in their place: the code as read, never text. The warm state (extensions/warm.wap) already holds
every file the compiler reads before a program operated once, packed (extensions/packed.wap), and a compile takes a
file from it with no parse: core/pipeline.wap operated_once finds the file in `language.operated` and reads nothing.
A module's wap section becomes that same thing for its own files: one packed list of file entries, each the file's
operated code (its rules, records, enums, the bodies that travel along: generic and inlinable functions), its words
and its declared code, its exports' declarations as declared code built from their signatures, and one entry for
each file it carries. The header line stays as the export's name for other languages and the dispatcher; wap itself
reads the entry.

| step | what works after it | core | extension | outcome lines |
|---|---|---|---|---|
| M1 packed section | a `use "m.wasm"` brings m's entries in operated, as the warm state brings the compiler's own files: no reader, no shape rules, no header parse on it; header_source, kept_lines, carried_files, part_source and foreign_definition's parse go | +3 (pipeline.wap: a file's reader may bring it operated) | about −70, +30 (warm.wap's file_entry, shared) | a program using a module whose .wap files are deleted after its build runs and prints as before; a carried file's rule works in the program |
| M2 seed without source | the seed folder holds wap.wasm, types.wasm, lib/'s modules compiled once each, and the tools; no .wap; the standard words name the modules (warm.wap standard_entry) | 0 | wap-beside.sh copies modules, not sources; refresh-seed.sh builds lib/ | test_hello and a `use math` program run from a seed folder holding no .wap file |
| M3 kernel terms (with T5g) | the entries hold the declarations as the kernel accepted them: signatures and records as kernel terms, the bodies of pure definitions erased (T5a); the compiler's warm state is the types module's own section, so warm.wap goes | 0 | −100 (warm.wap), +60 (T5g's reader) | T5g's line |

Messages: a refusal inside a module's code quotes it as the compiler holds it (core/errors.wap quoted, which already
does so for code no file holds), with the module's file and line, which the places in the entry keep.

Cost: +3 core in all, the extension about −80 net; the seed folder smaller by the sources. Order: M1 and M2 need no
T step and can land beside T5a; M3 lands with T5g.

The wiki: wiki/wasm-representation.md:39, old: "Format: The wap section is a header file in wap format, plain wap
text: the module's rules, enums and the bodies that travel as source. Its exports' declarations need no lines there,
since each export's name is its header line, `add(a: int, b: int = 1) → int`. The reader then runs the normal reader
and declare stages on it. That needs no new binary format and no second schema, and reading a .wasm reuses about 90%
of reading a .wap". New: "Format: the wap section holds the module's code as the compiler read it: its rules, enums,
records, declarations and the bodies that travel along, already read and declared, in wap's packed notation. A use
reads no source and parses nothing, so a module needs no source beside it. Each export's name stays its header line,
`add(a: int, b: int = 1) → int`, for other languages and the dispatcher." Line 32, "Generic or inlinable functions as
source", reads "Generic or inlinable functions, their bodies read: … its body goes along and the importer compiles a
copy for its own types".

Open for the user: the decision of 2026-11-25 lets templates, rules and class hierarchies "still travel as source";
this plan carries them read, as packed code. Recommended: packed, since the warm state shows it works and it is what
lets a module ship without source.

## Sources

- The feature list: the Lean language reference, "The Type System".
- The model: Mario Carneiro, "The Type Theory of Lean" (2019).
- The practices adopted: Lean 4's kernel for the rules; its elaborator for arguments left out, conversions, `match`
  and recursion compiled to recursors, and `do` blocks compiled to terms; its opaque constants and its IO type for
  effects.
- The architecture audits notes/audit/2026-11-25-2.md and 2026-11-25-3.md ("What the plan misses").
- In wap: wiki/type.md, alias.md, char.md, enum.md, variant.md, trait.md, effects.md, laws.md, W0.md, Footguns.md;
  notes/backbone.md; wap/kernel/forms.wap; wap/core/analyze/.
