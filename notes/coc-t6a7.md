# T6a7: universes in analyze

coc-plan.md's T6a7 row: a binder's type may be a universe. Level letters are found, and `type of Type` is `Type(1)`.
A level may be written in brackets. Read on unify-typers 2b0e87be. T6a7 waits on T6a6 (propositions as values),
which `type of (1 == 1)` being `Prop` needs.

## The wiki passages

All of universe.md:
- the opening (`type of int // Type`, `type of Type // Type(1)`, `type of (1 == 1) // Prop`,
  `type of Prop // Type`);
- "Levels" (`Sort(u)`, `Prop` is `Sort(0)`, function types in the larger universe);
- "Levels do not include each other" (`box(int)` refused);
- "One definition at every level" (`identity(int)`, `pair_type` with found `u`, `v`, written levels
  `identity[1](int, 3)`).

proposition.md:1-10 gives a comparison's type as Prop. lambda.md:18 has `fs[1](3)`, an index then a call.

## What unify-typers holds

- The kernel has universes and level unification: `Sort(level)` in holes.wap:101, :156 and unify.wap:90-91
  `levels_unified`.
- core/analyze/courses.wap already declares level-polymorphic blocks (`Pair(A: Sort(u), B: Sort(v))`).
- Analyze's type of every type word is `DATA_TERM = universe(TYPE_LEVEL)` (type_notation.wap:83).
- `type of` a type answers the word `TYPE_OF_TYPE = "Type"` (calls.wap:34), whatever the type is.
- The words `Prop`, `Sort`, and `Type` with a level are not type words.
- The 18 lines of test/test_universe_wanted.wap are red (test/reds.txt:594-611).

## The plan

1. **The universe words.** `Prop`, `Type`, `Type(n)` and `Sort(n)` read as the kernel's universes. `Prop` is
   `Sort(0)`, `Type` is `Sort(1)`, and `Type(n)` is `Sort(n + 1)`. type_notation.wap +6.
2. **`type of` a type is computed.** `type of T` with T a type is the kernel's type of T's term, in place of
   `TYPE_OF_TYPE`. It is shown in the canonical words: Sort(0) as Prop, Sort(1) as Type, Sort(n + 1) as Type(n).
   core +8 (−2 for the constant).
3. **A function type over types.** `(A: Type) -> A` as a value is the kernel's Π over a universe. Its universe is the
   kernel's rule (impredicative Prop, else the larger level). core +10 (the type door reads a binder's type that is a
   universe).
4. **Level letters found.** A one-letter name in a level place (`Type(u)`, `Sort(u)`, `max(u, v)`) that nothing
   defines is a level parameter of the definition, in the order it first appears (universe.md:76). At a call it is
   found by unifying levels, through analyze's holes as T's are. core +18. That covers:
   - `identity(a: T)`, whose T stands for a type of any level (its type is `Sort(u)` with u found);
   - `pair_type(int, Type)`, a `Type(1)`.
5. **A written level.** `name[n](…)`, where name is a definition with level parameters, gives its levels in order.
   Where name could also be a list (`fs[1](3)` with fs a list of functions), the call is refused, naming both
   readings. core +15 (the reader's glued bracket read in analyze, and the refusal).
6. **Levels shown.** `type of identity[1]` shows `(T: Type) -> T -> T`, the level written in. core +6.
7. **What falls out:**
   - `box(int)` is refused, since int is a `Type` and never a `Type(1)`: kernel levels are not cumulative.
   - `bad: Type := Type` is refused by value type.

## The red lines it turns green

| line | form | part |
|---|---|---|
| test_universe_wanted:6 | `type of Type` is `Type(1)` | 1, 2 |
| test_universe_wanted:8, :9 | `type of Prop` is Type; `[Sort(0), Sort(1), Sort(2)]` is `[Prop, Type, Type(1)]` | 1, 2 |
| test_universe_wanted:7 | `type of (1 == 1)` is Prop | with T6a6 (a comparison is a proposition) |
| test_universe_wanted:10-12 | the three function types | 3 |
| test_universe_wanted:13-15 | `identity(int)`, `identity(Type)` | 4 |
| test_universe_wanted:16-18 | `pair_type(int, text)`, `type of pair_type(int, Type)` | 4 |
| test_universe_wanted:19 | `identity[1](int, 3)`, `identity[2](Type, int)` | 5 |
| test/wap/test_theory.wap:9-18 | the same forms through verify's door | 1-6 |

The table lists the lines whose forms the plan reads. The builder counts the file's 18 red lines against
test/reds.txt.

**One line disagrees with the wiki.** test/wap/test_theory.wap:19 wants `type of identity(int, three)` refused "by level
count" for an `identity(T: Sort(u), a: T)`. universe.md:54-58 and :76 find a level that nothing writes, so the call is
`int`'s identity and its type is int. Decided: the line follows the wiki and becomes `type of identity(int, three)` is `int`, in its own commit naming
universe.md:54-58 and :76.

## Estimate

Core about +61 (+6, +6, +10, +18, +15, +6). The row said +45 and counted no universe words or computed `type of`.
Kernel 0. Careful path: `type of` and the type door change for every program, so the census runs.
