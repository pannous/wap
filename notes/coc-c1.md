# C1: traits

coc-plan.md's C1 row: traits are structures, `x is shape` computes, and the built-in traits are declared in wap/types.
Read on unify-typers 2b0e87be. C1 lands after it.

## The wiki passages

- trait.md "Built-in traits": the table, and "`sort`, `min`, `max` and `<` need Comparable values, `==` Equatable
  ones"; `3 is Comparable // yes`.
- "Conforming":
  - a class conforms by defining the operation, structurally;
  - `compare(a: person, b: person)` makes `sort` and `>` work;
  - `equals(a: word, b: word)` makes `==` work;
  - a non-conforming use is refused: `dot is not Comparable: sort needs compare(a:dot, b:dot)`;
  - a claim `class dot: Comparable {x:int}` is checked.
- "Declaring a trait": `trait shape{area(); perimeter()}`, then `square(1) is shape // yes`.
- "Iterable": a type defining `iterate` is walked by `for x in b`.
- "Dispatch" and "Constraints" are C2's and C4's.

## What unify-typers holds

- `trait X {…}` is a class (sugar/types.wap:15). A class with a required word is a protocol, its record annotated
  `@protocol` (sugar/records.wap:33). Each required word is a field of the function type that takes the protocol
  first.
- Conformance is structural and by specialisation. `conforms` and `does_word` (core/analyze/calls.wap:402-468): a
  function of a protocol parameter is typed anew for each type given. Default bodies work (test_protocols:38).
- A claim is checked (`claim_checked`, calls.wap:455-460). Its refusal reads
  `dot is no Comparable: define compare(x: dot, …)`, not the wiki's wording.
- **`x is shape` is refused**: "Comparable names no type and no test" (test/results.txt:2863). `is` knows types and
  test functions, never protocols.
- **No built-in trait is declared.** Comparable, Equatable and Iterable are names nothing defines. `sort` orders
  values with `<` (test_trait_page:4 is green for texts), and a class's `compare` or `equals` reaches neither `<` nor
  `==`.

## The plan, in two parts

### C1a: traits a program can use (this step)

1. **`x is T` with T a trait computes when compiling.** The answer is `conforms(type of x, T)`, a bool literal, as
   `type of` is answered. core +6 (the `is` arm beside the type test).
2. **The built-in traits are wap.** types/traits.wap (a new types file), only the traits wap has words for:
   - `trait Equatable { equals(b): bool }`
   - `trait Orderable { less(b): bool }`
   - `trait Comparable { compare(b): int }`
   - `trait Sized { size(): int }`
   - `trait Iterable { iterate(): list }`
   - `trait Addable { add(b) }`
   - `trait Printable { text(): text }`

   The table's other rows (Formattable, Serializable, Hashable, Cloneable, Indexable, Callable, Parsable,
   Approximable) come when a word of theirs exists. types +8.
3. **The operations read the traits.** Plain wap overloads in types/traits.wap:
   - `compare` for int, float and text (`a - b` for numbers; texts by their order);
   - `<`, `>`, `<=`, `>=` of two Comparables, through `compare(a, b)` against 0;
   - `==` of two values of a class that defines `equals`, through it.

   A number's own `<` stays the more specific choice (calls.wap `ranked`: a protocol takes every type, so it ranks
   last), and the run's code for ints is unchanged. A class with `compare` then gets `>` and, through `<`, `sort`
   (test_trait_wanted:8-9). types +10.
   - The builder measures that typing a `sort` of ints stays as fast as before. A protocol overload of `<` is a
     candidate at every `<`.
4. **Iterable walks.** `for x in b` with b's type doing `iterate` walks `iterate(b)`. The for rule's list is a list
   wanted, and a value whose type does Iterable converts to one through `iterate`: a declared conversion of the
   trait, `list(g: Iterable): list := iterate(g)`. Fits.wap's `conversion` takes a function named as the wanted type
   from a trait, as it takes a claim's. types +1, core +4.
5. **The refusal says the wiki's words.** `words_lacking` names the caller that needs the word:
   `dot is not Comparable: sort needs compare(a: dot, b: dot)`, with the fix line
   `fix: define compare(a: dot, b: dot) := …`. core +3 (the text and the caller's name passed in).

### C1b: traits as structures, moved to C2

The row's kernel half:
- the trait as a structure over the conforming type, one field per word with that type in the trait's place;
- a type's instance as the record of its overloads that `does_word` finds.

Its only users are C2 (an instance passed with a boxed value), V3 (laws over a trait) and Q1. No C1 outcome reads it.

Recommended: build it with C2, its first user. It is the same code: T5b2's record block with the protocol's name read
as the block's type parameter, plus the instance term (the constructor applied to the overloads' constants), core
about +22. A structure without a reader would be dead code until C2.

## The red lines it turns green

| line | form | part |
|---|---|---|
| test_trait_wanted:4 | `3 is Comparable` | 1, 2, 3 (int's compare) |
| test_trait_wanted:8 | `sort people` uses aged's compare | 3 |
| test_trait_wanted:9 | `aged("Ann", 40) > aged("Bob", 30)` | 3 |
| test_trait_wanted:12 | `word("Hi") == word("hi")` through equals | 3 |
| test_trait_wanted:17 | `square(1) is shape` | 1 |
| test_trait_wanted:21-22 | `for item in bag(3, 4)` walks iterate | 4 |

Gap lines for a builder, in a new test/wap/test_trait_wanted.wap (trait.md "Conforming"):
- `class dot{x:int}\nsort [dot(2) dot(1)]` is refused with `dot is not Comparable: sort needs compare(a: dot, b: dot)`;
- `class dot: Comparable {x:int}` is refused until `compare(a: dot, b: dot)` is defined.

## Estimate

| part | lines |
|---|---|
| 1 `is` against a trait | core +6 |
| 2 the built-in traits | types +8 |
| 3 the operations through them | types +10 |
| 4 Iterable walks | core +4, types +1 |
| 5 the refusal's words | core +3 |
| **C1a** | **core +13, types +19** (the row: core +30, types +25, including C1b's structure) |
| C1b, with C2 | core about +22 |

Kernel 0. Normal path, plus the speed measure of (3): test_trait_wanted, test_trait_page, test_protocols,
test_operators. One builder; the row names wap-annotation-attachment-fix once t5b-enums is handed off.

The traits' words are vocabulary, so they live in wap/types. core gains no trait name: `is` asks `conforms`, and the
conversion of (4) is any trait's function named as a type.
