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

What moves is what the provers call and what that calls in turn, measured over the two files' code lines (no
comments, no blank lines; data/t3-plan/closure.py): 268 of their 275. analyze calls the same functions, since its holes
are the provers' holes.

| file today | code lines | moves to wap/core/analyze | stays in the extension |
|---|---|---|---|
| theory/elaborate/unify.wap | 133 | all 133, as unify.wap | none |
| theory/elaborate/state.wap | 142 | 135, as holes.wap: `Elaboration` (the checker, the binders in scope, the holes and their answers), Hole, Problem, Found, `filled`, `holes_in`, `back_to`, `taken_back`, the level holes | 7: `holes_left`, `level_problems_hold`, `unscoped` and CANNOT_FIND, which only the elaborator calls; they go when T5 deletes it |

The provers read the elaboration through `el.c` (39 places) and the moved functions, so the record moves whole.
The plan's 180 for unification was an estimate of a unifier written fresh. The one the provers already run is 268
lines, and moving it saves writing a second one.

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
- **Compared by computing:** two types are one where their terms are: `==` of two terms is the kernel's `same`, and
  fits.wap's `same_type` and `same_types` are gone into it. Opaque types compare structurally, so typing should be
  little slower; the gate below measures it.

### Where a type lives

A fact is a Node, and a kernel Term cannot be one. So a compile keeps one table of the type terms it met, and a
TYPE fact holds `Number(place)` in that table.

- **The table** (core/type_terms.wap) is `class TypeTerms { terms: list<Term>; places: map<int, list<int>>;
  words: map<text, int> }`. A term is entered once, found again by its hash, so two equal types have one place, and
  a TYPE fact compared with `==` compares the types. A type word gets its constant's id from `words` the first time
  the door reads it, an opaque constant without levels. T3e and T3f move these ids to the program's kernel
  environment, once the prelude declares the words there.
- **The table is the compile's own, as a symbol table is:** one value for the whole run in core/type_notation.wap
  (`TYPES`), so `value_type(n)` and emit's `type_of(n)` read a fact through it without a parameter. Handing it down
  would add a parameter to about 300 functions of analyze, emit and rules, and give nothing: a run compiles one
  program, and a table that only grows reads the same from every stage.
- **Signatures hold terms:** `Signature.parameters: list<Term?>` and `result: Term?`. declare reads each written
  type through the door as it builds them.
- **The warm state is unchanged.** It packs the files read and the modules lowered, which is code with its types
  written as notation, never a signature or a typed node. The door reads that notation each compile, so constants
  are taken by name and nothing depends on the order of a log; packed.wap gets no new line.
- **Shown:** `type_shown(t)` writes the notation, `list<int>`, `(int) -> text`, `int?`, the door's inverse, used in
  messages and `format` only.

## One pass

- **Headers first:** a recursive function's header is typed before its body, so a call of the function in its own
  body reads the written result type. A call of itself without a written result takes none at first, and the body
  is typed again once its other arm gives the type (calls.wap function_typed); a body no other arm gives a type is
  refused with the fix-it naming the result to write.
- **An assignment of another type is a new binding:** `x = 1; x = "a"`, and from there on x holds a text. The
  retyping round goes: typed_among's restart, TypingState `retyped`, `retypings` and `fixed`, and `retyped(…)` in
  types.wap. A `let`, a `const` or a written type still fixes the type
  (coc-plan 4).
- **A kind rule's output is typed in place,** at the node's position and as that node, and never fires on its own
  output. ROUNDS_LIMIT, `refirings` and the refusal "still fire after 100 rewrites" go. A rule's error names the line
  of the phrase it rewrote, because the output keeps that position.
- The dispatcher's restart (`dispatches_completed`) stays until T6, the restart for a standard module until TM4.

### Parked and refused at T3d

A name's bindings live in core/analyze/flow.wap. These forms are refused with a fix-it, each until what brings it back:

| form | refusal | brought back by |
|---|---|---|
| a loop body giving a carried name another type, `y = 1; for … { y = "c" }` (parked; test_type_wanted's loop line) | give it that type before the loop | the body typed with the join at its head, once a typing can be discarded; or the union at E7 |
| a break or continue after a rebinding in the round | give it that type before the loop | the jump's bindings met with the loop's exit |
| a rebinding inside a try body | give it that type before the try | the handler met with every point the body may raise from |
| a function giving a global another type | write `x: any` where the program first gives it one | globals as bindings a function takes (T5 statements as terms) |
| a function reading a global the program gives other types | write `x: any` where the program first gives it one | as above |

## Numbers through the kernel

- **A numeral has the type its place wants, else `int`:** `x: float = 3` is a float, with no int-to-float
  conversion written. `i32` and `i64` are the wrapping words, and `#xs` is an `int`. The numbers prelude
  (theory/prelude/numbers.wap 197, checked.wap 43) moves into wap/types in the explicit spelling. Compiler source does
  not use its words, so no seed refresh is needed. `int` keeps today's storage until T8.
- **Overloads: the most specific by conversion order** (coc-plan 4). Of the definitions that fit, one is more
  specific than another by the first of three steps that decides:
  1. it takes the arguments as they are where the other converts one, compared as sets of places and read as the call
     binds the letters: `text(c: char)` before `text(t: text)` for a char, `contains(xs: list<T>, item: T)` before
     `contains(xs: list<T>, item: T?)` for an item that is no optional, and after it for one that is;
  2. each of its parameter types converts into the other's and not all of the other's back: `empty(xs: list)` before
     `empty(x: T)`, `==(a: T?, b: T?)` before `==(a: T, b: T)`, a written type before a letter or none;
  3. the program wrote it and a rule wrote the other (`DERIVED`, a class's `show`).
  Ties go to the innermost scope. This one order replaces `fewest_conversions`, `most_specific`'s `rank`,
  `typing_weight`, `type_weight` and `written_structure`, and the exact-fit prefilter in `chosen_definition`; `ranked`
  in dispatch.wap sorts by it, so a dynamic call tests the definitions as the static choice would pick them.
- **An argument is read at its parameter's type when every fitting definition wants the same type there,** else alone,
  where a numeral is an `int`. `abs(0 - 3)` subtracts ints, and `1.5 + 2` adds floats through the declared
  int-to-float conversion.
- **No weights are ported** (audit finding 5). read.wap's `nearest` (five weights), TRIAL_LIMIT and the numeral
  special cases (`numeral_in_cases`, `declares_case`, the `literals` and `result` counts of Trial) are not copied
  into analyze. T5 replaces them in read.wap with analyze's choice, so the two typers choose alike and the weights
  are gone from the tree.
- **The readings typing chose stay the compile's table:** `typed_readings` (calls.wap, read by format.wap) is keyed
  by the source place, as TYPES is one table for the run: `format` prints the code as parsed, which a fact on the
  typed call never reaches.

## Functions in the kernel until T5

A function analyze typed enters the program's kernel environment as an opaque constant of its signature's type.
The census counts it as assumed. Types and laws can name it from T3 on, and T5 gives it its body.

## The migration in landable sub-steps

T3 is the first step whose core uses wap/kernel's typing, so it takes the careful path. Every sub-step that touches
wap/core needs test_hello, the test areas it touches, test_self.sh (`--stage 2` a fixed point) and the census ratchet.
The whole suite runs at T3b, T3d and T3e, compared line by line with main's last full run.

| step | what | core lines (estimate) | checks |
|---|---|---|---|
| T3a unifier | unify.wap and state.wap `git mv` into wap/core/analyze (unify.wap, holes.wap); the elaborator and the provers import them from there; nothing else changes | +268 moved, extension −268 | normal path: theory areas, prove's tests, test_hello |
| T3b terms | the table; TYPE facts hold its places; signatures hold terms; type_notation.wap's readers read terms; one notation door; `type_shown` for messages and format; emit through the readers | about +300 (the table +30, the door +40, `type_shown` +30, the readers on terms, about 200 call sites edited and about 120 comparisons by `==` or `text()` rewritten; the user decides the size) | careful; the whole suite as before; `--stage 2` time and warm hello measured against the baseline |
| T3c holes | letters.wap goes: letters, `_` and α are holes of the unifier, `settles`/`deferred` are answers; fits.wap's remaining comparisons go to kernel equality (`bare_fit`, `joined_settling`'s settling) | −169 letters, −45 fits, +60 | careful; `identity(3)` and `identity(int)`; the census |
| T3c3 holes by id | a definition's letters are holes made once in a table by its key (letters.wap letter_holes), the signature's holes in all but where they are kept, so declare stays apart from the typing state; a call's answers, `s.unknowns` and `s.members` keyed by the hole's id (`variable_id`), a letter's name only in the types the definition writes; `hole_text` and its cache in TypeTerms go | about −10 type_notation, +20 letters (the call's letters and answers apart) | careful; two calls of one generic, a generic calling itself (test_letters) |
| T3d one pass | headers first, assignment as a new binding, the retyping round goes; kind rules typed in place, the refiring goes | −40 analyze, −20 rules, +40 | careful; a recursive function's result is written, or found once its other arm gives the type, else refused with the fix-it naming it; a kind rule's error names the line of its phrase |
| T3e numbers | numerals at the wanted type, else `int`, and an empty `{}` or `[]` at the type its place wants, the right of `??` wanting the left's (`m.get(k) ?? {}`; core/pipeline.wap line_told's `has` test goes); i32 and i64; `#xs` int; the numbers prelude in wap/types; overloads by conversion order| −40 analyze (the ranking's 5 words), +170 analyze, +200 types | careful; `0 - 3` is -3; `m.get(k) ?? {}` of a map<text, map<text, text>> is a map<text, text>; `#xs - 1` is -1 on an empty list; `type of 3` is `int` |
| T3f functions | each typed function an opaque constant of its signature in the kernel environment; the census counts them as assumed | +20 | normal plus the census |

T3a changes no core behaviour. T3b is the largest diff: about 200 places edited, mechanically, plus
type_notation.wap.

## The estimate

| | plan (coc-plan 11) | this page |
|---|---|---|
| unification | +180 | +268 moved from the extension (measured), then letters.wap −169 |
| numerals at the expected type | +170 | +170 |
| types as terms, the notation's readers | +100 | +100 |
| one pass | +40, −40 | +40, −40 |
| kind rules in place | +20, −20 | −20 |
| the numbers prelude (types) | +200 | +240 (numbers 197, checked 43), moved from the extension |
| functions as opaque constants | | +20 |
| the holes wired into analyze | | +60 |
| deleted | letters 235, fits 189, typed_readings and numerals 40 | letters 169, fits 45, ranking 40 |
| **net** | **+186** | **about +584 in the compiler, −548 in the extension** |

Two budget differences:
- **The unifier moves in, it is not written again:** the extension shrinks by what core gains, and with the prelude moved too the tree as a whole
  grows by about +36.
- **fits.wap goes only in part:** its conversions (`conversion`, `converted`, `repacked`, the Conversion enum, about
  80 lines) are T4's job, where conversions are declared in the types module (coc-plan 3.2), and they leave with
  T4. The plan's T3 row counted all of fits.wap.

## Gate

T3 is done when all of these hold:
- the T3 row's test lines are green: `0 - 3` is -3; `#xs - 1` is -1 on an empty list; `type of 3` is `int`;
  `identity(3)` and `identity(int)`; a recursive function's result is written, or found once its other arm gives the type, else refused with the fix-it naming it; a kind rule's
  error names the line of the phrase it rewrote;
- the whole suite has no new red;
- the census types every function, with 0 places typed any beyond the language's 5 dynamic words (`show` four times in types/prelude.wap, `text` once in nodes.wap);
- `--stage 2` is a fixed point;
- typing stays fast: T3 as a whole adds at most 25% to `--stage 2` (84 s on the integrator's last run) and to a
  warm `print "Hello"`, each measured against its time before T3a on the same machine. That is a ceiling for the
  whole step, shared out below, not slack for the first sub-step;
- typed_among's retyping round is gone (typed_readings stays the compile's table), and so are the five ranking words
  in calls.wap; letters.wap, ROUNDS_LIMIT and `nearest`'s weights in read.wap go in T5.

What the gate still lacks, and the step that brings each (T3 closes when machine-words lands, wap-supervisor
2026-11-27):
- `type of 3` is `int` and `identity(int)`: types as values in an expression's place, with T5's kernel forms.
  `type of x` gives the type as text until then.
- a kind rule's error naming the line of its phrase: its test line comes with T5.
- the loop red (test_type_wanted, a loop that gives a carried name another type): a typing that can be discarded,
  listed after T3 in coc-plan, measured before building.
- letters.wap (its letter holes) and ROUNDS_LIMIT (shape rules refiring on their own output, core/rules/stages.wap)
  go in T5.
- speed: the self-compile takes 12.5 s CPU and a warm hello 0.11 to 0.13 s, against 18.3 s and 130 ms before T3a.

## The speed budget

Each sub-step measures `--stage 2` and a warm hello, three runs each, the median, against the baseline taken before
T3a. It lands only if the total so far stays within the sum of the shares so far. A share a sub-step does not use
carries over to the next one, and one that needs more goes to the supervisor before it lands.

| step | share of the 25% | why |
|---|---|---|
| T3a | 0 | moved code only, the elaborator's own |
| T3b | 10 | each type comparison becomes kernel equality on terms |
| T3c | 5 | holes and answers in place of letter bindings |
| T3d | 0 | one pass in place of the retyping rounds and the refiring: expected to be faster, and a gain is credited |
| T3e | 7 | numerals typed through the kernel, the prelude's declarations read |
| T3f | 3 | one opaque constant per typed function |

## Open for the user (through the supervisor)

- **The speed ceiling:** 25% over T3 as a whole, shared by sub-step as above, is the recommendation. A kernel check per type comparison could cost more; if T3b
  measures above it, the next step is caching the opaque type terms, not a second representation.
