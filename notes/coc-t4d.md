# T4d: computed obligations, in landable steps

coc-t4.md's T4d row: when a value and its subtype's condition both compute, the obligation is decided while
compiling. A no is refused by the condition, and a yes needs no check. This is the first of the five ways in wiki/type.md
"Proved or checked" (type.md:177-180, item 1), and subtype.md:16-21 ("A value fills a subtype place when its
condition holds. The compiler sees that it holds by computing it"). wiki/Footguns.md has no passage on it.

## Where obligations are made and checked

- A value given where a subtype is wanted is converted Narrowed (core/analyze/fits.wap:121-124). `converted`
  (fits.wap:150) calls `narrowed_call` (dispatch.wap:263). That writes one function per subtype,
  `narrowing(T)`, whose body is `If(narrowing_test(x), x, raise …)`. shapes.wap:156-160 builds the test as a call
  of the condition's function, and `other_shape` gives the raise's text, `refused by condition: …, wanted at …`.
- A call whose argument narrows a parameter's subtype goes through the dispatcher (dispatch.wap:30-37
  `dispatching`, `tests_of`/`test_of` at :250-251), which tests each such argument when the program runs.
- Both paths record the obligation in one place, `obliged(at, type)` (dispatch.wap:290-294). It adds a line to the
  global `obligations` list (dispatch.wap:26), which `wap check` prints (extensions/native/driver.wap:141).
- conditions.wap writes facts, not obligations. `found`/`subset_found` (conditions.wap:45-107) make an `if`'s
  condition or a parameter's condition a Finding, so the conversion inside is Same and nothing is obliged (T4b).
- **On unify-typers** each subtype's condition is already a kernel definition. `conditions_typed` and
  `conditions_entered` (analyze/terms.wap:160-190 there) declare `<subtype> holds : parent -> bool`, defined by the
  condition's body with `it` its binder. They do this after `instances_entered` (types.wap:207, :218 there). A whole
  number is `int_numeral`, and a row on ints is defined by `int_meaning`, so the kernel computes `0 - 2 > 0`
  exactly. A condition that calls something the kernel only assumes is left out (no declaration).
- **Texts do not compute.** No texts are declared in the compile's environment (kernel/numbers.wap:96-101, the gap
  in coc-plan's "Not in T6"). `#(t: text)` (types/texts.wap:257) is impure, because its count is cached in two
  globals, so `#it == 1` and `#it > 0` are left out as conditions.

T4d builds on unify-typers, so its branch starts from unify-typers (or from main once that lands).

## The steps

| step | what works after it | files | lines (estimate) | wiki | tests it turns green |
|---|---|---|---|---|---|
| T4d1 decided | `obliged` records `Narrowing(at, value, type)` in the TypingState in place of the global `obligations` lines (the dispatcher's path passes the argument node it tests). After `conditions_entered`, each narrowing whose value has a closed term (`term_of` with no binders) and whose subtype has a `holds` declaration is computed: `holds(value)` to bool's yes or no case. A no is a refusal at the place, worded as the run's raise without "wanted at" (`refused by condition: it > 0`). A yes is no obligation. The rest are `wap check`'s lines as today | analyze/dispatch.wap (`obliged`, the list goes), analyze/terms.wap (`decided`), analyze/types.wap (one call after `conditions_entered`), extensions/native/driver.wap (reads the list from the state) | core +30 (record +5 −3, decided +18, refusal +4, the lines from the undecided +6), kernel 0 | type.md:177-178 item 1 ("a condition that is no is refused at once"), subtype.md:16 | none red today (both red lines are texts). Gaps to add first, test/wap/test_subtype_wanted.wap: `f(x: int where it > 0): int := x\nprint "a"\nprint f(0 - 2)` is refused by condition `it > 0` and prints no `a` (refused while compiling, not at the run, unlike test_subtype.wap:5's green line); test/wap/test_check.wap: `checked` of `f(x: int where it > 0): int := x\nprint f(3)` lists nothing |
| T4d2 a yes needs no check | A narrowing decided yes is placed as its value: the narrowed call is replaced by its argument, and a dispatcher call whose tested arguments are all decided yes calls the one definition left directly. Once T5b1 lands, the effect Fail is not reported for such a value | analyze/types.wap or the placing pass (`instances_placed`), analyze/dispatch.wap | core +12 | type.md:177 ("yes needs no check": coc-t4.md's row), effects.md's Fail | with T5b1: `effects of g` for `g() := f(3)` over `f(x: int where it > 0)` is Pure (a gap line for test_effects_wanted once t5b-effects lands) |
| T4d3 texts compute | The kernel computes a text literal's count, equality and joining, so `#"ab" == 1` decides. Two readings, which go to the user through wap-interviewer: **A (recommended)** text rows. `#`, `==` and `+` of texts are rows of T1's table that the kernel folds on `Quoted` values, as it folds whole-number rows. The types module's `#(t: text)` names its row through one table in kernel/primitives.wap, beside RUNTIME_WORDS (the library words the kernel computes by a row), so the cache's globals stay in the run code. The trust base grows by those rows. **B** texts as the list of their code points (kernel/numbers.wap `text_opened`) waits on lists as an enum (parked, coc-plan "Not in T6") and a pure `#(t: text)` | A: kernel/compute.wap (`row_step` on Quoted), kernel/primitives.wap (the table), analyze/terms.wap (`row_term` for the tabled words) | A: kernel +20, core +10; B: lists as an enum's core +60, types +40, plus a pure count | subtype.md:18-19, type.md:177 ("the text has one character") | test/wap/test_subtype_wanted.wap:6 "a literal argument that breaks a parameter's condition is refused" (`initial("")`; if its `: char` result is still red it is T4c's) |

Net: core about +52 (+30, +12, +10), kernel +20 with reading A.

## What T4c (char) needs

T4c makes `char` `text where #it == 1`. A char literal must be a char by computing, or every one is checked at the run
(coc-t4.md's order). So T4c needs **T4d1, T4d2 and T4d3**: T4d1 to refuse `"ab"`, T4d2 so that `c: char = "a"` costs no
run check, and T4d3 so that `#"a" == 1` computes at all. With them, T4c turns green test/wap/test_subtype_wanted.wap:5
(`d: char = "ab"` refused by condition) and :7 (a failed run check names `#"ab" == 1`, T4c's own).

## Order and gate

T4d1 after unify-typers (it reads `conditions_entered`), normal path plus the census. T4d2 right after it, and its
Fail line waits on T5b1. T4d3 after the user's answer, careful path (the kernel's rows). T4d is done when its gap
lines and test_subtype_wanted:6 are green and `wap check` lists no obligation that computes.
