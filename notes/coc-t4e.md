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

- `type vector(T, n: nat) = list<T> where #it == n` reads two ways. sugar/definitions.wap:30 makes it the
  definition `vector(T, n: nat) := list<T> where #it == n`, a function whose value is a type. rules/stages.wap
  declaration_taken makes it a rewrite rule, the way `type Long = int` is read. Part (1) below uses the rule.
- A subtype's condition is found by its word: `subset_condition(type)` (type_notation.wap:209) asks
  `TYPES.conditions` for a word's id. An applied alias, `vector(int, 3)`, is no word, so it has no condition.
- `conditions_entered` (analyze/terms.wap:177-190) declares `<subtype> holds : parent -> bool` with `it` as its one
  binder. A condition naming other values (`n`, `xs`) gets no declaration.
- `term_of` has no list literal, and a list's `#` is the run's host word, so `#[1, 2, 3]` does not compute.
- `vector` and `index` are in no types file. test_type_wanted uses them undeclared.

## What analyze must compute

1. **An applied alias is its body with the arguments written in.**
   - `type vector(T, n: nat) = list<T> where #it == n` is the rule `vector($T, $n) => list<$T> where #it == $n`.
     Each parameter of the head is a hole of the pattern and of the template, and its written type is dropped
     (rules/stages.wap alias_added).
   - `vector(int, 3)` then reads as `list<int> where #it == 3`. That is a subtype by condition, which type_term
     already reads, keyed by its code.
   - A type is shown as its body: `list<int> where #it == 3`. The test lines compare types as values (7), never as
     text.
   - core +7.
   - **Open:**
     - A rule is global syntax. Every call `vector(a, b)` or `index(a)` in any program reads as the type, even
       when the program defines its own function of that name.
     - A parameter's written type (`n: nat`) is never checked.
     - The function reading avoids both. It calls `vector(T, n: nat) := …` in a type place and reads it as its
       body with the arguments written in (sugar/definitions.wap:30). The name stays shown and scoped. The cost
       is about core +8 more than the rule.
2. **A condition's other names are its function's first parameters.** After (1), a condition whose arguments
   are closed has only one name, `it`. Two kinds of name stay free in a condition:
   - a letter, the `n` of `dot(a: vector(number, n), …)`;
   - an earlier parameter, the `xs` of `at(xs: list<T>, i: index(xs))`.

   How each stage handles them:
   - conditions_typed reads each free name that no definition binds as a parameter before `it`:
     `(n, it) => #it == n`.
   - It is typed as the untyped function value it is, one instance per use. Two functions whose `xs` have
     different types read one generic condition.
   - condition_entered declares `holds` over those names and then `it`.
   - At a call, obligation_entered applies `holds` to the names' terms first (an argument, or a letter's
     filling, 4), then to the argument.
   - The subset's key keeps the free names, so `#it == n` in two functions is one condition.
   - core +10 (terms.wap).
3. **Lists compute: list's block fills core's list word.**
   - core_environment declares list's block in Data, as truths_declared declares bool's:
     `list(T) { empty; item(first: T, rest: list(T)) }`. It fills core's list word, so every `list<T>` the
     compiler reads is that block. A program's own `enum list` stays its own, as every enum of a program does.
   - Beside it, the kernel defines a list's count. It recurses over the block into count, and int's natural case
     makes the result an int (kernel/counting.wap, after int_declared).
   - term_of reads a list literal as its items folded into item and empty, as text_opened folds a text's code
     points. It reads `#` of a list as that count.
   - The run's list layout and host code stay as they are. The kernel only computes.
   - No row: the count is the block's own recursion, so the trust base stays as it is. Texts keep their three
     rows.
   - This is the smallest part of coc-plan.md's parked "Lists as an enum": the block, the literal and `#`. The
     kernel's `xs#i`, `+` and map stay parked.
   - core +8 (type_notation.wap +4, terms.wap +4), kernel +3.
4. **A letter is filled at typing with the code its condition names, and decided at obligations.** For
   `dot([1, 2, 3], [4, 5])`:
   - The first parameter's condition is an equation with the unfilled letter on one side, `#it == n`. Typing
     fills n with the other side at the argument, as code: n := `#[1, 2, 3]`. Nothing is computed. No condition
     is entered yet, and this needs none.
   - Every later narrowing reads n as filled. The second argument's obligation is `#[4, 5] == #[1, 2, 3]`, which
     is (2)'s `holds` applied to the filling.
   - obligations_entered decides it with every other narrowing. It computes to no, so the second argument is
     refused. With a variable as argument it stays for the run, whose check is that same code.
   - An argument whose own type has the same equation (`v: vector(int, 3)`) fills n from its own condition's
     other side, 3, not from `#v`.
   - A letter that no equation of `it` fills is refused at the definition: "the type of a names n in no
     equation of it, so no argument gives it".
   - The letters are typing's own, filled as type letters are (core/analyze/letters.wap). The kernel's holes are
     not needed.
   - core +8.
   - **Open:** wap/test_type_wanted:6 says "refused by argument type", but this refusal is the narrowing's, by
     condition. The wording goes to the interviewer.
5. **A result type is its template with the letters' fillings.**
   - `append([1], [2, 3])`'s `vector(T, m + n)` reads `list<int> where #it == #[1] + #[2, 3]`.
   - `type of` shows that type. `type of append([1], [2, 3]) == vector(int, 3)` is (7)'s comparison, which
     computes both conditions.
   - The obligation on the body (`#(a + b) == m + n`) stays the run's check until a law proves it (V3).
   - core +2.
6. **A parameter's type names an earlier parameter.** The earlier parameter is (2)'s free name, given the call's
   argument.
   - `at([5, 6], 2)` applies `index holds` to `[5, 6]` and 2.
   - `1 <= 2 and 2 <= #[5, 6]` computes to yes (3), and T4d2's yes needs no check.
   - core +2.
7. **Two types compare once the conditions are entered.**
   - At the run, a type value is its shown text (analyze/types.wap type_value). So `vector(int, 2 + 1) ==
     vector(int, 3)` would compare `#it == 2 + 1` with `#it == 3` as text.
   - The kernel's conversion cannot decide it either. Its subtype is Defined as its parent, so any two subtypes
     of one parent convert.
   - Instead, an `==` of two type values (each with a DENOTES fact) is no run comparison. Typing records it beside
     the obligations, and obligations_entered decides it once the conditions are entered.
   - Two types are one when their heads and parts are one, by the kernel's conversion. At a subtype by condition
     they are one when their parents are one and their two `holds` compute to the same: `#it == 2 + 1` and
     `#it == 3` both reduce to `#it == 3`. The walk goes through parts, so `list<vector(int, 3)>` compares the
     same way.
   - The verdict is a fact on the `==`, which emit writes as a bool literal.
   - An undecided comparison is refused: "these two types compare by their conditions, which compute to no
     answer".
   - core +10 (terms.wap +6, emit +2, typing +2).
8. **A type argument is pure.** `vector(int, read_number())` is refused by effect: a type argument's `effects`
   fact (T5b1) must be Pure.
   - core +4, after T5b1.

**The spellings, in plain wap (types +6).** types/lists.wap has these, over int while nat is not in the preload:
- `type vector(T, n: int) = list<T> where #it == n`;
- `type index(xs: list) = int where 1 <= it and it <= #xs`;
- `*(n: int, T: Type): Type := vector(T, n)`, an overload, so `3 * char` is `vector(char, 3)`.

`3·char` is the same `*` if `·` is its alias in the operator table; the builder checks that. `char[3]` is also the
type `vector(char, 3)` (decided: type.md:99; a value reading would cost about core +10 for one phrase). It reads
through the same `vector`, at 0 core beyond T4e. test_type_wanted:20-21 reads `letters = char[3]` as a value with
`#letters` 3. It is rewritten to `check("…", char[3], vector(char, 3))` in its own commit, which gives that reason.

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
| (1) an applied alias is its body, as a rule | core +7 |
| (2) a condition's free names as its first parameters | core +10 |
| (3) list's block, its literal and its count | core +8, kernel +3 |
| (4) letters filled at typing with code | core +8 |
| (5) result types from the fillings | core +2 |
| (6) a parameter's type over an earlier parameter | core +2 |
| (7) types compared once the conditions are entered | core +10 |
| (8) pure type arguments | core +4 |
| vector, index, `*` | types +6 |
| **total** | **core about +51, kernel +3, types +6** |

Careful path: (1) and (3) change what every subtype and every list literal reads as, so the census and test_self
run. One builder. (1)-(3) first (with test_subtype_wanted:23), then (4)-(7) (the dot, append and at lines), then
(8) once T5b1 lands.
