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

- **The term:** `T where p` is read by the type door into `Subset(T, condition)`, a type term of the parent T and
  the condition's place in TypeTerms (`conditions: map<int, Node>`, the condition as written with `it` free). Two
  subtypes are one type when their parents are and their conditions are the same code; `narrowed_type` of a subset
  is its parent, so every reader of narrowing reads it unchanged.
- **Where it is written:** a type alias, `type positive = int where it > 0` (an alias is a rewrite rule, so the alias
  names the subset wherever it is used); a parameter's type, `initial(name: text where #it > 0)`; a field's or a
  variable's type, anywhere a type is.
- **Up is free:** a subset's value is its parent's (Same), so `shout(c)` with a char c costs nothing and every
  function of the parent takes it.
- **Down is an obligation:** where a subset is wanted and its parent given, conversion answers Narrowed, and the
  emitter tests the condition with `it` the value, raising `refused by condition: #"ab" == 1` (the condition with
  the value written in, as the wiki's run-time check names it). `x is positive` is the same test giving a bool, and
  `line as char` the conversion, through the existing `as` sugar (sugar/types.wap).
- **Facts in scope:** a parameter of a subset is of it in its body, so its own condition holds with nothing to
  check. An `if` whose condition is a subset's condition at a variable (the same code, `it` read as that variable)
  finds the variable of the subset in its then-arm, and after the if where the other arm never finishes: `if #line
  == 1 { e: char = line }` needs no check. The comparison is by code, so `1 == #line` is no finding: a prover finds
  more (step 3, after T5).
- **Computed obligations,** a literal that breaks the condition refused when compiled (`d: char = "ab"`), come with
  the conditions as kernel terms: T4d, after T5's first step.

## The migration in landable sub-steps

T4a and T4b add a type form, so they take the careful path; T4c changes the value layout of `char`, so it does too.

| step | what | core lines (estimate) | checks |
|---|---|---|---|
| T4a subsets | `T where p` read into a subset term; up Same, down Narrowed with the run-time test of the condition naming it; `x is S` | +60 (the door +15, the conditions table +10, the test emitted +25, `is` +10) | careful; test_subtype_wanted's `positive`, `adult`, `initial` lines; the run-time check line of test/wap/test_subtype_wanted |
| T4b facts | a parameter's condition holds in its body; an `if` condition equal to a subset's condition at a variable is a finding | +30 (conditions.wap `found`) | normal; the `if #line == 1` line |
| T4c char | `char` is `text where #it == 1`; core's char conversions go (char_text, the READS row, the place-typed `'a'`, `is_plain`'s char); `type Port < int where …` once c-type-names has `<` | −30 core, +20 types | careful (value layout); test_subtype_page and test_char_page unchanged, the Port line |
| T4d computed | an obligation whose value and condition compute is decided when compiling: no is refused by condition, yes needs no check | +40 (the condition read as a term with T5a's reader; `computed` at the value) | normal plus the census; the two compile-time refusal lines of test/wap/test_subtype_wanted |
| T4e value arguments | a type alias of value parameters, `vector(T, n: nat)`, `index(xs)`; its arguments found by unification and compared by computing | +60 | careful; the vector and index lines; test_type_wanted's `dot` and `append` lines |

Order: T4a, T4b, T4c (after c-type-names lands), then T5a (definitions and pure expressions as kernel terms), then
T4d and T4e. T4d and T4e are T4's in what they give and T5's in what they need, so they land after T5a, before the
rest of T5.

## The estimate

T4 as a whole: about +180 core (+60, +30, −30, +40, +60) and +20 types, against coc-plan's +409 (450 analyze and 100
types added, 141 deleted). The difference: the plan counted a mechanism of its own for conditions and obligations,
where narrowing and findings exist; and the extension's obligations.wap (64) and convert.wap (28) are not deleted in
T4, since the theory's doors read programs as written until T5 (as T3g's work moved to T5).

## Gate

T4 is done when all of these hold:
- the T4 row's test lines are green: `d: char = "a"` accepted and `d: char = "ab"` refused by `condition`; `char` is
  `text where #it == 1` and nothing else; the lines of test/test_subtype_wanted.wap and
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
- **char's storage:** the plan stores a char as its text (3.2), today it is an i32 code point. T4c as written
  changes the value layout: a char is its text, `ord(c)` decodes it, and lists of chars cost a reference per item
  instead of 4 bytes. The other reading keeps the code point as char's storage and makes the up-conversion a
  declared one (c-type-names' `<`), which costs a conversion where the plan's costs nothing. Recommendation: the
  plan's, its text; core −30 either way, the layout question is the emitter's (+10 for the declared conversion).
