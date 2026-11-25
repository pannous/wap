# T3, numbers and arguments found: how it is built

notes/coc-plan.md 11, step T3, after TM (notes/coc-tm.md, TM1 to TM4). analyze's types become kernel terms, compared
by computing and shown as notation only in messages and `format`. Letters, `_` and an empty list's item type are
found by one unifier over terms. analyze types each function once, and a kind rule's output is typed in place.
Numbers are typed through the kernel: a numeral has the type its place wants, else `int`. Line counts are
`grep -vc '^\s*#'` on main 59a4edd3.

## One unifier, in core

The elaborator's unifier is analyze's job from T3 on: letters, `_`, holes and an empty list's α are one thing, a hole
of the unifier. It is untrusted (the kernel checks what it fills in), so it lives in core, beside the typer, not in
wap/kernel.

| file today | lines | goes to |
|---|---|---|
| theory/elaborate/unify.wap | 152 | wap/core/analyze/unify.wap, as it is |
| theory/elaborate/state.wap: `Elaboration` (the checker, the binders in scope, the holes and their answers), Hole, Problem, Found, `filled`, `holes_in`, `back_to`, `taken_back`, the level holes | 156 | wap/core/analyze/holes.wap, as it is |

The provers read the elaboration only through `el.c` (39 places) and the moved functions, so the whole record moves
and no part of it is split off.

This settles the audit's finding 6 for two of the three files the provers import (data/extensions-audit/report.md):
goals, linear, induction, apart, computing, introduction and rewriting import core/analyze/unify.wap and holes.wap
in place of the extension's: a path edit ports them. Their third import, elaborate/match.wap (`Matched`,
`eliminating`, the recursor's motive), stays until T5. T5 deletes match.wap when analyze elaborates `match`, and in
that step the four provers that use it call analyze's eliminating, its lines counted there.

## Types as terms

A TYPE fact holds a kernel Term. type_notation.wap keeps its readers' names (`type_parts`, `item_type`,
`function_parts`, `base_of_optional`, `key_type`, `type_text` …, 27 words read at 111 places in analyze, 29 in emit,
5 in rules), and their bodies read terms. Most callers change nothing. The `X_TYPE` and `X_SYMBOL` constants (92 uses
in analyze, 26 in emit) become the kernel constants of the type words.

- **Declared in wap/types for the kernel:** the type words `int`, `float`, `bool`, `char`, `text`, `any`, `number`,
  and `list`, `map`, `optional` as type formers. They are opaque constants until T5 gives them their data. A
  function type is a Pi, `T?` is `optional T`. A class or an enum is an opaque constant analyze declares from its
  record, until T5 makes it an inductive block. Unlike types still join to `any` until T5's unions.
- **Read once:** a written type, `list<int>` or `(float) -> float`, becomes a term at one door, where declarations
  and parameters are read (analyze `shaped`). Nothing else parses notation.
- **Shown:** the kernel's show writes the notation for messages and `format`, `list<int>` as written.
- **emit** reads the type through the same readers, a type word's value layout by its constant's row (T1b's
  table). Its lines are measured at T3b; the estimate is none.
- **Compared by computing:** `same_type` is kernel equality. Opaque types compare structurally, so typing should be
  little slower; the gate below measures it.

## One pass

- **Headers first:** a recursive function's header is typed before its body, so a call of the function in its own
  body reads the written or found result type. The body is typed once.
- **An assignment of another type is a new binding:** `x = 1; x = "a"`, and from there on x holds a text. The
  retyping round goes: typed_among's restart, TypingState `retyped`, `retypings` and `fixed`, and `retyped(…)` in
  types.wap. A `let`, a `const` or a written type still fixes the type. wiki/type.md "Representation" is checked
  for the old wording before this lands; a changed sentence goes to the user first.
- **A kind rule's output is typed in place,** at the node's position and as that node, and never fires on its own
  output. ROUNDS_LIMIT, `refirings` and the refusal "still fire after 100 rewrites" go. A rule's error names the line
  of the phrase it rewrote, because the output keeps that position.
- The dispatcher's restart (`dispatches_completed`) stays until T6, the restart for a standard module until TM4.

## Numbers through the kernel

- **A numeral has the type its place wants, else `int`:** `x: float = 3` is a float, with no int-to-float
  conversion written. `i32` and `i64` are the wrapping words, and `#xs` is an `int`. The numbers prelude
  (theory/prelude/numbers.wap 197, checked.wap 43) moves into wap/types in the explicit spelling. Compiler source does
  not use its words, so no seed refresh is needed. `int` keeps today's storage until T8.
- **Overloads: the most specific by conversion order** (coc-plan 4). Of the definitions that fit, one is more
  specific than another when each of its parameter types converts into the other's. Ties go to the innermost scope.
  This one rule replaces `fewest_conversions`, `most_specific` with its `rank`, `typing_weight`, `type_weight` and
  `written_structure`, and the exact-fit prefilter in `chosen_definition`. `ranked` in dispatch.wap uses the same
  order. A derived definition (`DERIVED`, a class's `show` that a rule wrote) is declared in the scope around the
  class, so the program's own `show` wins as the innermost. If the census shows a case that needs `derived` still, it
  goes to the interviewer.
- **An argument is read at its parameter's type when every fitting definition wants the same type there,** else alone,
  where a numeral is an `int`. `abs(0 - 3)` subtracts ints, and `1.5 + 2` adds floats through the declared
  int-to-float conversion.
- **No weights are ported** (audit finding 5). read.wap's `nearest` (five weights), TRIAL_LIMIT and the numeral
  special cases (`numeral_in_cases`, `declares_case`, the `literals` and `result` counts of Trial) are not copied
  into analyze. T3g replaces them in read.wap with analyze's choice, so the two typers choose alike and the weights
  are gone from the tree.
- **The readings typing chose travel as facts:** `typed_readings` (calls.wap:76, read by format.wap:21) becomes a
  READING fact on the call node.

## Functions in the kernel until T5

A function analyze typed enters the program's kernel environment as an opaque constant of its signature's type.
The census counts it as assumed. Types and laws can name it from T3 on, and T5 gives it its body.

## The migration in landable sub-steps

T3 is the first step whose core uses wap/kernel's typing, so it takes the careful path. Every sub-step that touches
wap/core needs test_hello, the test areas it touches, test_self.sh (`--stage 2` a fixed point) and the census ratchet.
The whole suite runs at T3b, T3d and T3e, compared line by line with main's last full run.

| step | what | core lines (estimate) | checks |
|---|---|---|---|
| T3a unifier | unify.wap and state.wap `git mv` into wap/core/analyze (unify.wap, holes.wap); the elaborator and the provers import them from there; nothing else changes | +308 moved, extension −308 | normal path: theory areas, prove's tests, test_hello |
| T3b terms | TYPE facts hold terms; type_notation.wap's readers read terms; the type words declared in wap/types; one notation door; show for messages and format; emit through the readers | +100 (type_notation rewritten in place, the door +40, the declarations in wap/types +40) | careful; the whole suite as before; `--stage 2` time and warm hello measured against the baseline |
| T3c holes | letters.wap goes: letters, `_` and α are holes of the unifier, `settles`/`deferred` are answers; fits.wap's comparisons go to kernel equality (`same_type`, `same_types`, `bare_fit`, `joined_settling`'s settling) | −169 letters, −45 fits, +60 | careful; `identity(3)` and `identity(int)`; the census |
| T3d one pass | headers first, assignment as a new binding, the retyping round goes; kind rules typed in place, the refiring goes | −40 analyze, −20 rules, +40 | careful; a recursive function's result found from its body; a kind rule's error names the line of its phrase |
| T3e numbers | numerals at the wanted type, else `int`; i32 and i64; `#xs` int; the numbers prelude in wap/types; overloads by conversion order; READING fact | −40 analyze (typed_readings, the ranking's 5 words), +170 analyze, +200 types | careful; `0 - 3` is -3; `#xs - 1` is -1 on an empty list; `type of 3` is `int` |
| T3f functions | each typed function an opaque constant of its signature in the kernel environment; the census counts them as assumed | +20 | normal plus the census |
| T3g theory follows | read.wap's `nearest`, TRIAL_LIMIT and the numeral special cases replaced by analyze's choice | 0 core; extension −40 | theory areas; the theory census script compared per program with main (no floor) |

T3a and T3g change no core behaviour. T3b is the largest diff: about 200 places edited, mechanically, plus
type_notation.wap.

## The estimate

| | plan (coc-plan 11) | this page |
|---|---|---|
| unification | +180 | +308 moved from the extension, then letters.wap −169 |
| numerals at the expected type | +170 | +170 |
| types as terms, the notation's readers | +100 | +100 |
| one pass | +40, −40 | +40, −40 |
| kind rules in place | +20, −20 | −20 |
| the numbers prelude (types) | +200 | +240 (numbers 197, checked 43), moved from the extension |
| functions as opaque constants | | +20 |
| the holes wired into analyze | | +60 |
| deleted | letters 235, fits 189, typed_readings and numerals 40 | letters 169, fits 45, ranking and typed_readings 40 |
| **net** | **+186** | **about +624 in the compiler, −588 in the extension** |

Two budget differences:
- **The unifier moves in, it is not written again:** the extension shrinks by what core gains, and with the prelude moved too the tree as a whole
  grows by about +36.
- **fits.wap goes only in part:** its conversions (`conversion`, `converted`, `repacked`, the Conversion enum, about
  80 lines) are T4's job, where conversions are declared in the types module (coc-plan 3.2), and they leave with
  T4. The plan's T3 row counted all of fits.wap.

## Gate

T3 is done when all of these hold:
- the T3 row's test lines are green: `0 - 3` is -3; `#xs - 1` is -1 on an empty list; `type of 3` is `int`;
  `identity(3)` and `identity(int)`; a recursive function whose result type is found from its body; a kind rule's
  error names the line of the phrase it rewrote;
- the whole suite has no new red;
- the census types every function, with 0 places typed any beyond today's 4;
- `--stage 2` is a fixed point;
- typing stays fast: `--stage 2` takes at most 1.25 times its time before T3a (84 s on the integrator's last run),
  and a warm `print "Hello"` at most 1.25 times its time before T3a, measured on the same machine;
- letters.wap, typed_readings, ROUNDS_LIMIT and the retyping round are gone, and so are the five ranking words in
  calls.wap and `nearest`'s weights in read.wap.

## Open for the user (through the supervisor)

- **The speed limit:** 1.25 times is the recommendation. A kernel check per type comparison could cost more; if T3b
  measures above it, the next step is caching the opaque type terms, not a second representation.
- **`x = 1; x = "a"` as a new binding** changes what such a script says today: an any with a warning becomes a text
  from the second line on. coc-plan 4 decides it; the wiki sentence, if one says otherwise, goes to the user with
  T3d.
