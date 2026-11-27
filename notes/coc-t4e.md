# T4e: types that take values

coc-t4.md's T4e row: a type alias of value parameters, `vector(T, n: nat)`, `index(xs)`. Its arguments are found by
unification and compared by computing. This plan also covers a subtype condition that calls a program's function,
such as T5c3's `leaves`. Read on unify-typers 2b0e87be, with T4d1 (notes/coc-t4d.md) as the step it extends.

## The wiki passages

- type.md:1-3: a type is a value, and two types are one when they compute to the same (`vector(int, 2 + 1)` and
  `vector(int, 3)`).
- type.md:81-103 "Dependent Types":
  - the declarations `vector`, `index`, `matrix`;
  - one-letter names found from the arguments (`dot`, `append`, `at`);
  - `char[3]`, `3·char` and `3 * char` as spellings of `vector(char, 3)`;
  - a unit as a type argument;
  - `vector(int, read_number())` refused.
- subtype.md:76-96 "Types that take values":
  - `[1, 2, 3]` is a `vector(int, 3)`;
  - `xs#i` with i an `index(xs)` needs no run check;
  - a type holding a sized list of itself (`class Quad { parts: vector(Quad, 4) }`,
    `enum Tree { leaf, node(children: vector(Tree, 2)) }`), where `node([leaf])` is refused.
- No wiki page shows a condition over a program's function, such as `Tree where leaves(it) == 4`. It falls out of
  T4d1 and T5c3 (below), so it gets no test line of its own.

## What unify-typers holds

- `type vector(T, n: nat) = list<T> where #it == n` is the definition `vector(T, n: nat) := list<T> where #it == n`
  (sugar/definitions.wap:30). It is a function whose value is a type.
- A subtype's condition is found by its word: `subset_condition(type)` (type_notation.wap:209) asks
  `TYPES.conditions` for a word's id. An applied alias, `vector(int, 3)`, is no word, so it has no condition.
- `conditions_entered` (analyze/terms.wap:177-190) declares `<subtype> holds : parent -> bool` with `it` as its one
  binder. A condition naming other values (`n`, `xs`) gets no declaration.
- `term_of` has no list literal, and a list's `#` is the run's host word, so `#[1, 2, 3]` does not compute.
- `vector` and `index` are in no types file. test_type_wanted uses them undeclared.

## What analyze must compute

1. **An applied alias is a subtype.** `vector(int, 3)` in a type place reads as the alias's body with its parameters
   given: parent `list<int>`, condition `it => #it == 3`.
   - `subset_condition` and `narrowed_type` take an application of a type-valued definition as well as a word.
     The condition is the body's with the arguments written in.
   - Up stays Same, and down narrows, as for every subtype (coc-t4.md).
   - core +15 (type_notation.wap, conditions.wap).
2. **The condition takes the alias's parameters.** `vector holds : Type -> int -> list -> bool`, the body's
   parameters before `it`. `conditions_entered` lifts the names the condition reads besides `it`, as coc-t4.md
   "Subsets as narrowings" says.
   - A narrowing to `vector(int, 3)` computes `vector holds(int, 3, value)`.
   - core +8 (terms.wap).
3. **Lists compute.** A list literal is the kernel's list block: `item(T, x, rest)`, then `empty(T)`, the block that
   numbers.wap already uses for texts. A list's `#` is the kernel's count over that block. The types module's `#` of a
   list names it through T4d3's table of library words the kernel computes, the same table as texts' rows. The run's
   host code stays as it is.
   - core +8 (term_of's list arm, the tabled `#`), kernel +6 (the count of a list, beside texts').
4. **Letters are found by computing.** `dot(a: vector(number, n), b: vector(number, n))` called on `[1, 2, 3]` and
   `[4, 5]`:
   - Each argument's narrowing is T4d1's Narrowing, but with the letter n a hole.
   - A condition that is an equation with a hole on one side (`#it == n`) fills the hole with the other side,
     computed at the value: n := 3.
   - The next narrowing then has n filled. `#[4, 5] == 3` computes to no.
   - Two fillings of one letter that differ are a unification failure, refused by argument type (the
     wap/test_type_wanted:6 wording). A condition without a letter that computes to no stays T4d1's "refused by
     condition".
   - The holes are analyze's own (core/analyze/holes.wap, unify.wap). core +20 (T4d1's `decided` with holes).
5. **A result type computed from the arguments.** `append(a: vector(T, m), b: vector(T, n)): vector(T, m + n)`:
   - With m and n found by (4), the result type `vector(T, m + n)` computes its arguments, so
     `type of append([1], [2, 3])` shows `vector(int, 3)`.
   - The obligation on the body's value (`#(a + b) == m + n`) is checked at the run until a law proves it (V3).
   - core +5.
6. **A parameter's type names an earlier parameter.** `at(xs: list<T>, i: index(xs))`:
   - the call `at([5, 6], 2)` reads `index(xs)` with xs bound to the call's first argument;
   - the narrowing `index holds([5, 6], 2)` computes `1 <= 2 and 2 <= #[5, 6]` to yes, and so needs no check (T4d2).
   - core +8 (the call's parameter types written over its arguments).
7. **Types compare by computing.** `vector(int, 2 + 1) == vector(int, 3)`: an `==` of two type values compares
   their computed terms when compiling, and the result is a bool literal.
   - The run never compares type values.
   - core +6.
8. **A type argument is pure.** `vector(int, read_number())` is refused by effect: a type argument's `effects` fact
   (T5b1) must be Pure.
   - core +4, after T5b1.

**The spellings, in plain wap (types +4).** In types/lists.wap:
- `type vector(T, n: nat) = list<T> where #it == n`;
- `type index(xs: list<T>) = nat where 1 <= it and it <= #xs`;
- `*(n: nat, T: Type): Type := vector(T, n)`, an overload, so `3 * char` is `vector(char, 3)`.

`3·char` is the same `*`, if `·` is its alias in the operator table; the builder checks that. `char[3]` is the type
`vector(char, 3)` as well (decided: type.md:99; a value reading would cost about +10 core for one phrase). It reads
through the same `vector`, at 0 core beyond T4e. test_type_wanted:20-21, which reads `letters = char[3]` as a value
with `#letters` 3, is rewritten to `check("…", char[3], vector(char, 3))` in its own commit, giving that reason.

**A condition over a program's function** (T5c3's `t: Tree where leaves(it) == 4 = node(…)`) needs nothing here.
`conditions_entered` runs after `instances_entered`, so `leaves` is a kernel definition by then (T5c3). T4d1 then
computes `Tree holds(node(…))`. The only T4e part involved is (1), when such a condition sits in an alias with
parameters.

## Where it meets T4d1

- T4d1 records `Narrowing(at, value, type)` and decides those whose value is closed and whose subtype has a `holds`
  declaration.
- T4e widens all three parts of that record:
  - the type may be an applied alias, with its condition's arguments written in (1, 2);
  - the value may be a list (3);
  - the narrowings of one call are decided in order, filling the call's letters (4).
- What T4d1 leaves for the run stays as `wap check`'s lines.
- T4d2's "yes needs no check" covers (6).
- T4d3's table covers (3)'s `#`.

So T4e lands after T4d1, T4d2 and T4d3, and after unify-typers. It needs T5b1 only for (8).

## The red lines it turns green

| line | form | parts |
|---|---|---|
| test_type_wanted:33 | `vector(int, 2 + 1) == vector(int, 3)` | 1, 2, 7, the types-module vector |
| test_type_wanted:44-45 | `dot([1, 2, 3], [4, 5, 6])` is 32 | 1-4 (`sum` and `.*` already run) |
| test_type_wanted:46-47 | `type of append([1], [2, 3])` is `vector(int, 3)` | 4, 5 |
| test_type_wanted:48-49 | `at([5, 6], 2)` is 6 | 6 |
| test_type_wanted:50 | `3 * char` is `vector(char, 3)` | the `*` overload, 7 |
| test_subtype_wanted:22-23 | `[1, 2, 3] is vector(int, 3)` | 1-3 |
| test_subtype_wanted:24-26 | `xs#(2 as index(xs))` is 20 | 1, 2, 6 (a run check, xs being a variable) |
| wap/test_type_wanted:6 | `dot([1, 2, 3], [4, 5])` refused by argument type | 4 |
| wap/test_type_wanted:8 | `vector(int, read_number())` refused by effect | 8, after T5b1 |

**Not T4e's:**
- wap/test_type_wanted:7, `3m + 2s` refused: the units library's quantity type with its unit as an argument. It rides
  on (1)-(4) but is the library's own work.

**Gap lines** for a builder, all subtype.md:90-96:
- test_subtype_wanted: `enum Tree2 { leaf, node(children: vector(Tree2, 2)) }`, then
  `check("a type holds a sized list of itself", node([leaf, leaf]) is Tree2, yes)`.
- wap/test_subtype_wanted: `node([leaf])` refused by condition.

The enum stays assumed in the kernel (a field of the enum inside a list), so these are run and compile checks of the
narrowing, not kernel terms.

## Estimate

| part | lines |
|---|---|
| (1) an applied alias is a subtype | core +15 |
| (2) the condition over the alias's parameters | core +8 |
| (3) list literals and their count | core +8, kernel +6 |
| (4) letters found by computing | core +20 |
| (5) computed result types | core +5 |
| (6) a parameter's type over an earlier parameter | core +8 |
| (7) types compared when compiling | core +6 |
| (8) pure type arguments | core +4 |
| vector, index, `*` | types +4 |
| **total** | **core about +74, kernel +6, types +4** (the row said +60) |

Careful path: (1) and (3) change what every subtype and every list literal reads as, so the census and test_self
run. One builder. (1)-(3) first (with test_subtype_wanted:23), then (4)-(7) (the dot, append and at lines), then
(8) once T5b1 lands.
