# T4, subtypes by condition: how it is built

notes/coc-plan.md 11, step T4, after T3. A type may carry a condition, `T where p`: its values are the T's that meet p
(3.2). Going up, from the subtype to T, is free; going down asks the condition, an obligation, which the compiler
computes, finds among the facts in scope, or checks when the program runs (3.9). Line counts are `grep -vc '^\s*#'`
on main ade14e3b.

## What is there to build on

- **Narrowing, in core:** a shape names the values of a type that have its shape (core/analyze/shapes.wap, 109
  lines): an enum's case, `Record` of Node, a declared pattern. Its word carries the type it narrows as a fact, so a
  value of the shape is a value of that type (fits.wap `conversion`, Same) and a value of the type where the shape is
  wanted is tested at run time (Narrowed). A subtype by condition is the same relation with a condition in place of
  a shape test, so it is built as one more narrowing, not a second mechanism.
- **Findings, in core:** a condition finds what holds in each arm of an `if` (core/analyze/conditions.wap, 105
  lines): `x != ø` makes x present, `x is int` makes it an int. A condition that is a subtype's condition at a
  variable is one more finding: in that arm the variable is of the subtype.
- **What core has not:** a way to compute at compile time. The kernel computes terms, but a condition is wap code
  calling library functions (`#it`, `it.age`, `>=`), which since T3f are opaque constants in the compile's
  environment: no body to unfold, so `#"ab" == 1` computes to nothing. Computing an obligation needs the bodies of
  the functions a condition calls as kernel definitions, which is T5's reading of definitions and expressions as
  terms. So does a type whose arguments are values, `vector(int, 2 + 1)` being `vector(int, 3)`.
- **What core has not either:** effects. `effects of` and the effect Fail of a function with a check left come with
  effects in T6 (3.8); T4 inserts the check, T6 names its effect.
- **`char`** is a code point today, an i32 (types/texts.wap `char(t: text)` refuses a longer text at run time),
  with its conversion to text written in core (calls.wap `char_text`, type_notation.wap READS, types.wap's `'a'`
  typed by its place). The plan's `char` is `text where #it == 1`, stored as its text (3.2).
- **`type X < T`** is c-type-names' (wap-native-no-layout-any, T4's first slice): a new type with a declared
  conversion to its parent, the edge in fits.wap `conversion`. No sub-step here touches it; T4c builds on it.

## Subtypes as narrowings

- **The term:** `T where p` is read as its parent and a predicate: the condition is lifted to a function of `it`,
  `it => p`, the names it reads besides `it` (`n` in `#it == n`, `xs` in `it <= #xs`) its further parameters. The
  predicate is a function like any other, so analyze types it and it enters the kernel as an opaque constant (T3f);
  the subset is the term `Subset(T, p(args))`, compared as every term is. Two `#it == n` of different `n` are two
  types, and T4d gives the constant its body, T4e its value arguments, with no second representation of a type.
- **One test for both kinds of narrowing:** `narrowed_type` of a subset is its parent, but the readers that take a
  narrowed type for a shape (conditions.wap `type_test_typed`, dispatch.wap's shape tests, matching.wap's three,
  shapes.wap `pattern_part`) are made to ask one function, `narrowing_test(value, type)`, which a shape answers by its
  pattern and a subset by a call of its predicate. Narrowing is from any type that converts to the parent as Same,
  so an `int` narrows to `index` through `nat`, not from the exact parent only (fits.wap `conversion`).
- **Where the filter sugar stops:** `$xs where $condition` (sugar/data.wap) is the list filter. In a type's place
  the type door reads `where` first, so the rule's left side takes a typed hole, `$xs: list`, and leaves a type
  alone: no reader branch.
- **Where it is written:** a type alias, `type positive = int where it > 0` (an alias is a rewrite rule, so the alias
  names the subset wherever it is used); a parameter's type, `initial(name: text where #it > 0)`; a field's or a
  variable's type, anywhere a type is.
- **Up is free:** a subset's value is its parent's (Same), so `shout(c)` with a char c costs nothing and every
  function of the parent takes it.
- **Down is an obligation:** where a subset is wanted and its parent given, conversion answers Narrowed, and the
  value is checked by a call of its predicate, raising `refused by condition: #"ab" == 1` (the condition with the
  value written in, as the wiki's run-time check names it). `x is positive` is the same call giving a bool, and
  `line as char` the conversion, through the existing `as` sugar (sugar/types.wap).
- **Facts in scope:** a parameter of a subset is of it in its body, so its own condition holds with nothing to
  check. An `if` whose condition is a subset's condition at a variable (the same code, `it` read as that variable)
  finds the variable of the subset in its then-arm, and after the if where the other arm never finishes: `if #line
  == 1 { e: char = line }` needs no check. The two are compared as bound nodes after the rules ran, so `1 == #line`
  is no finding: a prover finds more (step 3, after T5). A predicate is pure, and a finding ends where the variable
  or a field of it is assigned, so a fact about a mutable `person` never outlives the value it was about.
- **Computed obligations,** a literal that breaks the condition refused when compiled (`d: char = "ab"`), come with
  the conditions as kernel terms: T4d, after T5's first step.

## The migration in landable sub-steps

T4a and T4b add a type form, so they take the careful path; T4c changes how a char converts, so it does too.

| step | what | core lines (estimate) | checks |
|---|---|---|---|
| T4a subsets | `T where p` read as its parent and a lifted predicate; up Same, down Narrowed with the predicate's call; `x is S`; the readers of narrowing ask one `narrowing_test`; narrowing through Same; the filter rule's typed hole | +90 (the door and the lifting +35, `narrowing_test` and its five readers +40, `conversion` +5, `is` +10) | careful; test_subtype_wanted's `positive`, `adult`, `initial` lines |
| T4b facts | a parameter's condition holds in its body; an `if` condition equal to a subset's condition at a variable is a finding, ended by an assignment to it | +30 (conditions.wap `found`) | normal; the `if #line == 1` line |
| T5a | definitions and pure expressions as kernel terms (notes/coc-t5.md) | T5's | T5's |
| T4d computed (steps: notes/coc-t4d.md) | an obligation whose value and predicate compute is decided when compiling: no is refused by condition, yes needs no check | +30 (the predicate's constant given its body by T5a; `computed` at the value) | normal plus the census; the two compile-time refusal lines of test/wap/test_subtype_wanted |
| T4c char | `char` is `text where #it == 1`, kept as its code point (user 2026-11-27: the i32 stays, a declared conversion takes a char up to text, wiki/char.md:7 unchanged); core's char conversions go (char_text, the READS row, the place-typed `'a'`, `is_plain`'s char, about 49 uses) for that one conversion; `type Port < int where …` once c-type-names has `<` | about −10 core, +30 types | careful, the speed gate measured at this step; test_subtype_page and test_char_page unchanged; `[1, "a"]` is a `list<int or text>` (with T5u's unions it is `list<char or int>` while "a" is a char); the run-time check line of test/wap/test_subtype_wanted; the Port line |
| T4e value arguments (plan: notes/coc-t4e.md, core about +74, kernel +6, types +4) | a type alias of value parameters, `vector(T, n: nat)`, `index(xs)`; its arguments found by unification and compared by computing | +60 | careful; the vector and index lines; test_type_wanted's `dot` and `append` lines |

Order: T4a, T4b, then T5u (unions, coc-plan's T5u row), then T5a (definitions and pure expressions as kernel terms), then T4d, T4c (after c-type-names
lands) and T4e. A char literal is a char by computing (`#"a" == 1`), so T4c follows T4d: before it, every char
literal would be checked at run time, or the place-typed `'a'` kept under another name. T4 closes after T5a.

## The estimate

T4 as a whole: about +180 core (+90, +30, +30, −30, +60) and +30 types, against coc-plan's +409 (450 analyze and 100
types added, 141 deleted). The difference: the plan counted a mechanism of its own for conditions and obligations,
where narrowing and findings exist. The 141 deleted lines are the extension's conditions file (with
obligations, 64, and convert, 28), gone with the extension's elaborator; core's analyze/conditions.wap stays and
grows by T4b's 30.

## Gate

T4 is done when all of these hold:
- the T4 row's test lines are green: `d: char = "a"` accepted and `d: char = "ab"` refused by `condition`; `char` is
  `text where #it == 1` and nothing else (both T4d's and T4c's, so T4 closes after T5a); the lines of test/test_subtype_wanted.wap and
  test/wap/test_subtype_wanted.wap move to a page test, except `type Color < int`'s, which are c-type-names';
- the whole suite has no new red;
- the census types every function, with 0 places typed any beyond the language's 5;
- `--stage 2` is a fixed point;
- typing stays fast: T4 adds at most 10% to the self-compile and to a warm `print "Hello"`, measured against its
  time before T4a on the same machine;
- core's char conversions are gone: char_text, the char row of READS, the place-typed `'a'`.

The T4 row's `effects of` line (a function with a check left is Fail) moves to T6, which brings effects.

## Open for the user (through the supervisor)

- **The order:** T4d and T4e after T5a, as above, is the recommendation: computing a condition needs the bodies of
  the functions it calls, which T5a reads into kernel definitions. Without them, T4 proves nothing by computing and
  every obligation not found in scope is checked at run time. Core cost either way: the same lines, landing later.
- **char's storage:** the plan and wiki/subtype.md store a char as its text (3.2); today it is an i32 code point.
  T4c changes the value layout: a char is its text, and today's i32 becomes `codepoint`, the type wiki/char.md gives
  `.chars`. The other reading keeps the code point as char's storage and makes the up-conversion a declared one
  (c-type-names' `<`); it keeps core's READS row and costs a conversion where the plan's costs nothing.
  Recommendation: the plan's, its text, core −30; the other reading about −10.

## T4c re-read on unify-typers 2b0e87be

- **Where core's char conversions are now:**
  - `char_text` (analyze/calls.wap:218);
  - the char row of `READS` (type_notation.wap:322-326);
  - `is_plain`'s char (calls.wap, fits.wap, types.wap).

  The row's "about 49 uses" is counted again by the builder.
- **`type X < T` is not there.** sugar/definitions.wap:30 reads only `type $head = $body`. records.wap's `class $name <
  $base` is a class's extends. The Port line (test_subtype_wanted:20-21) waits on c-type-names' `<`.
- **The three T4d steps it needs are planned** (coc-t4d.md). T4d3's text rows give `#"a" == 1` by computing, which is
  what a char literal needs.
- **Estimate: about −10 core, +30 types**, as the row says. The speed gate is measured at this step. It lands after
  T4d1 to T4d3, and after c-type-names for the Port line only. The rest does not wait on `<`.
