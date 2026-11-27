# The new backbone: first principles and plan

The design of wap, from the user's decisions (2026-11-17). Read first: notes/first_principles.md. Inputs: wap/kernel/forms.wap (the kernel forms), notes/layers.md, wiki/Philosophy.md, wiki/guiding-principles.md, notes/taste.md.

**Names (user 2026-11-17):** **warp** is the old compiler (core/, frozen), **wap** the new one built here.

## Preamble: rules for every agent on this work

- **The old compiler is frozen.** Nothing new goes into it: no features, no cleanups. It only keeps building, so it
  can compile the new one. Everything moves to the new backbone.
- **The backbone is rewritten, not migrated.** Write each part the way first principles say it should be. Never copy
  an old pass and trim it: read it for the cases it handles, then close it.
- **Tests are a gauge, not the goal.** The pass rate tells us roughly how well the engine works. A red test means a
  missing rule or library function, or a form we discuss again. It never means a special case in the kernel or the
  emitter. Nobody compares the old and new compilers' output: only the tests count, not how they pass.
- **No watering down.** A compromise is never silent. It goes into "Debts" at the end of this file, with its reason
  and the principle it bends. The user reviews the debts at each milestone.
- **Separation of concerns.** Each stage has one job, a declared input language and a declared output language
  (nanopass style). It reads only its input language. A stage that peeks at surface forms its predecessor should have
  removed is a bug.
- **Untangle before adding.** When two concerns meet in one function (kinds inferred while emitting, binding redone
  inside a sugar pass), split them first.
- **Small, named, total.** Each function does one thing under an English name and handles every case of its input
  language. A case it can't handle is refused loudly, never skipped silently.
- **Ask before growing the kernel.** A kernel form or primitive is added only with a written case (below) and the
  user's OK.

## First principles

notes/first_principles.md: the core identities (functions = operators, `f(x)` = `x.f`, overloads, `@meta`,
aliases), the language and compiler principles, and how agents work by them. Every design choice here cites one.

## Layers

kernel, core, types, library, as wap/ is laid out: notes/first_principles.md "Layers" (user 2026-11-17). Kernel
forms are named patterns of Node with `$` holes: notes/first_principles.md, wiki/pattern.md.

## Stage languages: the contract between the workers

Each stage reads one language and writes one (nanopass, principle 11), and a worker owns each stage. A stage meeting a
form outside its input language refuses it, naming the stage that should have removed it. The wap lead owns this
section, wap/kernel/forms.wap and wap/core/stage.wap; a change to a language or a new kernel form goes through the
lead first, as a change of this table.

| stage | file | owner | reads | writes |
|---|---|---|---|---|
| read | core/parse/reader.wap | wap-reader | text | notation |
| operators | core/parse/operators.wap, table in the types module | wap-reader | notation | operated |
| shape rules (stage 1) | core/rules/, sugar/ | wap-reader | operated | surface |
| declare | core/analyze/declarations.wap | wap-binding | surface | declared, and Module.signatures: one Signature per function, value and record (the record: core/bindings.wap) |
| lower | core/rules/lowering.wap | wap-reader | declared | kernel |
| bind | core/analyze/scope.wap | wap-binding | kernel | bound kernel |
| type | core/analyze/types.wap | wap-binding | bound kernel | typed kernel |
| kind rules (stage 3): in the type walk, on each node as typing writes it, before elaborate | core/rules/typed.wap, engine core/rules/ | wap-reader | a node as typed | its rewrite, typed in place |
| elaborate | core/analyze/types.wap, calls.wap | wap-binding | typed kernel | typed kernel, one instance per tuple |
| emit | core/emit/ | wap-emitter | typed kernel (milestone 1: kernel) | Module (core/emit/wasm.wap) |

The languages, each a set of Node shapes:
- **notation:** what the reader makes and nothing else (wap/core/parse/reader.wap; wiki/syntax.md):
  - atoms: `Number` (int, or float when written with a point or a negative exponent; `-1` glued at an item's start
    is a negative Number, `a-1` is not), `Char` (a text of one code point), `Text` (escapes read; a template's `${…}`
    and an extension's `\:name` kept as written; a URL, a word glued to `://` up to a blank, bracket or separator),
    `Symbol` (a word, or an operator: a glyph with its repeats and one `=`, `<=` `==` `...`; `=>`, `and`,
    `yes`, `null` are all plain Symbols);
  - four keys (reader.md Q1, Q11, Q13): `Key(key, Op.Colon, value)`, `Key(key, Op.Assign, value)` and
    `Key(key, Op.Define, value)` by the same rules, `a:1` `a=1` tight, `a: b c` the rest of the phrase, `a b : c` and
    `x = a + b` all before and after; `=` and `:=` split before `:` (`x: int = 3` is `(x: int) = 3`);
    `Key(head, Op.None, group)`, a head glued to a bracket, `f(x)` `a{x:1}` `xs[1]` `f(x)(y)`, and to a type list,
    `list<int>` (reader.md Q14);
  - `List(items, bracket, separator)` in three uses: a phrase, items with blanks between, separator Space
    (`a + b` is `[a, +, b]`); a glued run of no head and bracket, separator None (`a.b`, `3ms`, `a-b`, `-x`); a
    bracketed list, Curly, Square or Round, with the loosest separator inside. Separators cascade (glue < space <
    `,` < `;` < tab < newline), the loosest splitting first; a list never has one item unless bracketed. An
    indented block is a Curly list with separator Newline, glued to the line before it like any bracket;
  - `Empty` for an empty text and for `{}` and `()` (wiki/node.md: no items is the empty list whatever the bracket).
    Facts in the metadata (core/stage.wap): positions; `comment` (a comment, on the next atom or on the atom ending
    the line); `meta` (the `@annotations` before an item, without `@`); `warning` (a duplicate key in `{…}`). No
    `True`, `False`, `Type`, `Data` or `Error`: a text it cannot read is refused.
- **operated:** notation in which every operator phrase is read by the table: `a + b * c` is
  `(Call + a (Call * b c))`, every alias replaced by its canonical word (`≤` → `<=`), a prefix or postfix operator
  a `Call` of one argument, by the one minus rule. A mix of unrelated groups is refused. Juxtaposition that is no
  operator (`print x`, `square 3`) stays a phrase: the lowering makes it a call, and typing refuses one whose head
  holds no function. `=` keys are the call `(Call = x 1)`; a glue key `Key(f, Op.None, (args))` stays, for the
  lowering to read as a call or a constructor. core/rules/lowering.wap reads exactly these: a glued call, an operator
  call (`=` → Set, `:=` → Define, `=>` → Fn), a phrase headed by a word, `{…}`; words such as `yes`, `break` or
  `global` are rules (sugar/).
- **surface:** any warp: operated, with the spellings of stage 1 rewritten (`for`, `unless`, `a if c` …). What remains
  is either kernel or needs a declaration to decide.
- **declared:** surface, unchanged, plus the fact `uses` on the program, the files its `use "path"` statements bring
  in (core/analyze/declarations.wap). Beside the code, the Module holds one record of each top-level function, value
  and record, its Signature (name, key, kind, defining name, parameter types, written result, module), which stage 2,
  binding and modules read, and which typing holds by key and reads the definition as it is now through
  (core/analyze/types.wap define_of). Each used file is declared once, after the files it uses; a
  program is bound inside the types module's declarations and those of the modules it uses itself, and the modules'
  statements run before its own. Modules may use each other: a cycle is cut where it closes, so of two such modules
  the one reached first runs last. A used `.wasm` that wap compiled is declared from its wap section, the module's
  declarations as warp text (wiki/wasm-representation.md; card wasm-module-import).
- **kernel:** only the forms of kernel/forms.wap, literals (`Number`, `Char`, `Text`, `True`, `False`, `Empty`) and
  `Symbol` as a name. Every phrase decided: no phrase, no operator word, no keyword is left.
- **bound kernel:** kernel, unchanged, plus two facts on each name: `binding`, what it refers to (`local`,
  `parameter`, `capture` of an enclosing function's name, `global`, `function` or `library`), and `defined_at`, the
  defining name itself, positioned (core/analyze/scope.wap); a library word is one the types module declares, a name
  nothing defines is refused. Each `Define` and `Fn` also learns `captures`, the defining names it reads from the
  functions around it, its nested functions' reads included.
- **typed kernel:** bound kernel plus each value's `type` (`int`, `text` …, as a program writes types; no fact for
  code that gives no value) and each function's `signature` on its name, `(int, text) -> int`; a `Call`'s
  `defined_at` is the one function it means, chosen among its `candidates` by argument types, then the type wanted.
  A function whose parameters have no type stands as one Define per tuple of argument types it is called with; one
  nothing calls is gone. The program comes first after the types module's functions it calls: one Block
  (core/analyze/types.wap). Every node with a position also has its `file` (core/stage.wap `file_of`).
  A function value is typed `fn<key, captures…>`, its own type, and called directly while it stays one; where it meets
  a typed place or another value it is typed by its signature `(A…) -> R` and carries the facts `adapted` (the
  instance typed for that signature; a λ's instance takes its closure as `any` and casts it itself) and
  `function_value` (its own type). The emitter makes such a value a funcref with a captures struct and calls it through
  the module's table by `call_indirect`, in both layouts (core/emit/function_values.wap value_call_code).
- **emit** reads the typed kernel's `type` and `binding` facts and decides nothing about them: it may choose its code
  by them, but computes no type (test_guardrails.wap emit-infers-type).

**Facts live in Meta, never in the shape.** Positions (line, column), the rule or stage that built a node, a name's
binding, a type, the overload, a tail call, `@gpu`: each is a named fact in the node's metadata, read and written
through core/stage.wap (`with_fact(n, name, value)`, `fact_of(n, name)`), so a kernel form keeps the same holes from
stage 2 to the emitter and a pattern written for one stage matches in the next. A stage that only learns facts
(declare, bind, type) never rewrites; elaborate, in the same walk as type, is the one analysis step that writes: one
Define per tuple of argument types, dispatchers and lambdas, `prim box`, `prim cast` and `!`, the unknowns settled; a stage that rewrites gets positions and provenance from the walker. A
rewrite's result stands for what it replaced: it takes that node's position and facts (a definition's declaration
survives its lowering), while the new parts inside it take only the position.

**Handoffs.** A worker hands a stage over with an outcome test in test/wap/ (a program compiled by wap, run, its output
checked) and a line here when its language changed. The lead reviews it against this table before it lands.

## Operators: a core feature done properly

- **One operator table, in lib/.** Each row gives:
  - the symbol and its canonical name;
  - the fixities it has: infix, prefix, postfix;
  - its associativity;
  - its precedence group.

  `operator` declarations extend the table.
- **Precedence as relations, sorted topologically.** Precedence is not a number. It is a set of relations between
  groups: `multiplicative > additive`, `additive > comparison`. A topological sort gives the levels (as in Swift's
  precedence groups and Fortress).
  - Two operators with no relation between them, mixed without brackets, are refused with a fix-it, never guessed.
  - A cycle is refused when the table is loaded.
  - The wiki's rule that superscripts bind tighter (`x²⁺³ == x⁵`) is one relation in this table.
- **Juxtaposition and calls.** A spaced call takes the whole operator phrase after it: `square 3 * 3` is
  `square(9)` (wiki/precedence.md, decision spaced-call-precedence). Juxtaposition is a precedence group with its own
  relations like any other, not a parser branch.
- **Aliases, one mechanism with its nuances:**
  - word aliases (`through` for `to`) and symbol aliases (`…` for `to`, `≤` for `<=`);
  - aliases limited to one fixity (a word that is only infix);
  - discouraged aliases, which work with a got-it note;
  - type aliases.

  Each is an alias → canonical row. Spelling never carries meaning.
- **Meaning is overloading.** `a + b` is a call of the overloaded `+`. Built-in overloads lower to wasm ("Built-ins are
  declared like any function"), user overloads are ordinary functions, and units and vectors overload like any type.
- **Minus, one general rule for every operator with both a prefix and an infix form:**
  - Spaced on both sides, or on neither: infix (`a - b`, `a-b`).
  - Attached to what follows, after a space or at the start of an element: prefix (`[a -1]` is `[a, -1]`, printed so
    by `warp format`).
  - A literal number with an attached sign (`-1`) is the prefix operator applied to a literal, folded to a constant.
    There is no separate token rule.

  The same rule holds for `+` and every operator that can be both prefix and infix. Nothing is specific to minus.
- **Ranges** (`to`, `upto`) show the pattern: their spellings are aliases, and their meaning is one overloaded
  operator returning an immutable `Range`.
  - `for` walks anything that has `next()`.
  - A float range is an interval only, so `for` over it is refused by the general rule.

## What is reused and what is rewritten

- **Rewritten:** everything between the reader and the wasm bytes: spelling rules, prescan, binding, typing, the
  rule engine, kernel lowering and the emitter.
- **Reused as they are:**
  - the value layout (notes/self_hosting.md);
  - the runtime words;
  - the host words and the native driver;
  - the test harness;
  - lib/, as far as it is plain warp.
- **The reader** comes first and gets special care: wap/core/parse/reader.wap, a data reader inspired by wasp's node parsing
  (not a copy). Three strictly separate steps: (1) the data reader parses any data into Node and knows no language;
  (2) then structural language matching (spelling rules); (3) then the analyzer (user 2026-11-17).
- **The reader, settled:** wap has its own pure notation reader (core/parse/), knowing no keyword; keywords are
  spelling rules (sugar/).
- **The old compiler** is a frozen fallback: wap builds itself from its seed.

## Milestones

0. **The emitter's lower half** (wasm module builder, instruction encoding, type and function sections, the value
   layout, runtime words) behind a clean interface that knows no surface forms: met.
1. **Hello:** `print "Hello"` through the new stages, with the emitter accepting only the kernel: met.
2. **The new compiler builds itself.**
   Done when all of these hold, each measured by a script, never by eye (user 2026-11-18):
   1. the gauge, `warp scripts/wap-census.warp`, says every function of every wap file typed and emitted
      ("typed n of n functions" on each line, the total likewise); test/wap/test_census.sh holds that count and
      only lets it rise;
   2. **met:** test/wap/test_self.sh has one line per wap file outside types/, "wap compiles <file> and the result loads",
      all green; the types module is no program of its own but part of every program, so every test compiles it, and
      the gauge types its functions with the types module as their library;
   3. wap, run by the old compiler, compiles wap/compiler.wap to wap1.wasm; wap1 compiles it to wap2.wasm, and wap2
      compiles a hello that runs; the stages need not be the same bytes (user 2026-11-20);
   4. test/wap/run.sh passes with wap2 as the compiler;
   5. wap1 compiling wap/compiler.wap takes under a minute on the Mac;
   6. wap's source uses no word only the old compiler knows: compiled with no old-compiler library, it still builds;
      **met:** wap resolves names only against wap/types and the files a program uses, no `use` leaves
      wap/, and test_self.sh's "the compiler wap makes of itself compiles a program that runs" runs it from a folder
      holding only types/ and kernel/;
   7. no boxed `any` is left in wap's own source: the boxed-any allowlist of test/wap/test_guardrails.wap is empty.
      **met:** test/wap/guardrails_allowed.txt has no boxed-any line.
   Until then nothing lands that turns no function of wap green, unless it fixes a wrong value.

## Architecture changes, in order (user 2026-11-20)

From data/review/architecture-review.md. wap work comes from these
steps and the open milestone-2 points. A step starts when the one before it has landed; work in files the steps before
don't touch may run beside them. One owner per file, as below; a part in another owner's file passes that owner's
review.

1. **wap2 is wap's seed, and the compiler under test is a parameter** (milestone 2 points 3, 4, 5). Owner
   wap-operators: compile.sh `--compiler <module>`, run.sh `--stage <n>`, test_self.sh's wap2-runs-hello
   and timed lines, the census on wap2, wap2 published through refresh-seed's A B C stages. Old warp stays a frozen
   fallback and still builds the native warp and the playground. Done when test/wap and the census run on wap2.
2. **The old-warp Debts paid as one batch, facts that replace first**, test/wap on wap2 before and after:
   - lead: `with_fact` replaces a fact of its name and `with_facts_of` merges by name (stage.wap; nodes.wap with the
     reader); `compact` into types/lists.wap; `staged` and `replaced` one name; EmptyMap no kernel form (with the
     emitter);
   - wap-reader: `NOTHING_WRITTEN`, nodes.wap's copy of core/node.warp, Op spellings and format's brackets written
     once, the reader writing Error, `EMPTY_BRACES`;
   - wap-binding: the binder's Empty marker (`without_fact`), a default of ø, helpers named apart;
   - wap-emitter: `===` as identity, so stage 1 and stage 3 agree on enum tags.
3. **Stage 2 on the rule engine:** a hole test that reads declarations (`$f: function`, `$p: predicate`).
   - wap-reader: the hole test (rules/stages.wap); `is pred` and `is not` as sugar/ rules (nothing rewrites by arity
     today, so no arity rule);
     the parser's defined_words, local_words and double read gone (operator-spelling aliases stay there).
   - wap-binding: a word alias as binding's fallback for a name nothing in scope defines; the `is`/`not` rewrites gone
     from scope.wap; typing's `print`/`show`/`set`/`#` found by a role the types module marks, not by spelling (the role
     words are a question for the user).
4. **One Signature record from declare**, read by every stage and printed as the wap section: wap-binding (analyze/),
   wap-emitter (Placed by definer id), text keys become definer ids. Then wasm-module-import resumes.
5. **Primitives as opcode mnemonics; the kernel the emitter's input only:**
   - wap-emitter: a Prim names a mnemonic of opcodes.wap, one host table with its WASI types, the special names one
     kernel/primitives.wap table;
   - wap-reader: the types module's prim spellings (`prim i64.add`), helpers that are plain warp moved into the types module,
     `@global`/`@local` rules in place of Variable, Item into core/rules/;
   - wap-binding: typing writes Call for a function-key Get, and the emitter's branch for it goes;
   - lead: kernel/forms.wap exactly what the emitter takes; its reading helpers into core/stage.wap or
     core/statements.wap.

Paused work comes back with its step: the rest of stage 2 with step 3, EmptyMap with step 2, wasm-module-import after
step 4. Overload specificity and `"x" * yes` stay Debts.

After that, the test pass rate is a ballpark of how well the engine works, nothing more. Then the user and the
interviewer go through the ugly forms the tests show: each is either standardised, because it arises from the
principles, or dropped.

## Guardrails, measured every day

`scripts/vitals.py` gets a backbone section:
- lines per layer (kernel, core, extensions, library);
- the number of kernel forms and primitives;
- how many non-kernel forms the emitter refused;
- build cost.

A kernel addition, a debt or a rise in core lines shows up there the day it happens.

## Theory and prior art for the design

- **Spritely Hoot / Guile:** a small kernel (Tree-IL), then CPS, then wasm GC. The shape of this plan.
- **The nanopass framework (Keep and Dybvig):** many small passes, each with a formally declared input and output
  language. That is principle 11.
- **Racket's "sets of scopes" hygiene (Flatt) and syntax objects:** hygiene, and positions carried through
  rewriting.
- **Scala 3 typed quotes, Lean 4 elaborators:** typed rewriting whose output must type-check.
- **Bidirectional type checking:** local, predictable typing with good error messages, a better fit than global
  inference for "refuse, never guess".
- **Swift precedence groups, Fortress:** precedence as a partial order, with unrelated mixes refused.
- **Term rewriting, termination orderings and critical-pair checks:** rules that provably terminate and don't
  conflict.
- **A-normal form (ANF):** a candidate for the kernel's internal shape. Every intermediate value gets a name, which
  makes the emitter trivial.

## Open, not built yet

- **Methods, the rest of wiki/class.md:** a getter without parentheses (`double := v * 2`), and a method a class
  extending another writes again, called on a value typed by the base: the base's runs, the call is not dispatched by
  the value's class (wiki/function.md, `speak` of a Dog).
- **Module scoping** (user 2026-11-19): a name is looked up local > parameter > program > used module > types, the
  nearest scope that defines it wins and shadows the rest; two used modules defining the same name are a loud clash
  naming both places, called or not, never overloads of one name; `m.f` picks one module's word explicitly. Not
  built yet.
- **`#` of a text:** counts its characters (UTF-8, not bytes), as warp does; `#"abc"` is refused until then.
- **Enums, the rest of wiki/enum.md:** `as index` and `as position`, cases with spellings (`Error = "error"`),
  `2 as Coin`, and `==` of cases with fields (by their fields). Built so far: `enum Coin { Penny, Dime }`, cases with
  fields `Circle(r: int)`, a case named by its enum (`Coin.Dime`, and `Coin::Dime` its alias), `match` by case with
  patterns in the fields (`Two(Circle(r), 0)`), `x is Circle`, `Dime is Coin`, and `==` of a plain enum's cases.

## Debts

open debts are `# DEBT:` comments at their code, `grep -rn 'DEBT:' wap/`

- **`use "m.wasm"` is not read yet** (card wasm-module-import, wiki/wasm-representation.md): a compiled module can't
  be used as its source is. Paused (user 2026-11-19) until architecture step 4. Branch wasm-module-import has
  the exports and the `wap` section of header lines; the reader, the body-less `export` declaration and the import
  are left (card note).
- **Stage 3 serves only the rules programs write** (decision hole-types): no rewrite of wap's own moves into it. The
  char read as a text depends on the type its place wants (binding's conversion), `x is w` on what w means (scope);
  a typed rule sees only its hole's type.
- **any compares other references by identity:** inside an `any`, refs other than boxes and texts compare by
  identity (a record compared directly compares by fields); by type via dispatch, as show does, when code needs it.
- **A named function is refused where a function type is written for a variable** :
  `g: (int) -> int = inc` says it gives fn<"… inc">, while the same `inc` in a `map<text, (int) -> int>` literal is
  taken. Paid off when a function's value fits a written function type wherever it is given.
