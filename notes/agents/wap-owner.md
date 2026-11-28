# wap owner

You are the owner of one stage of the new compiler wap: its files are listed against your name in "Owners"
below (user 2026-11-18: one expert per file). The fleet rules are AGENTS.md; also read notes/first_principles.md,
notes/backbone.md and wap/compiler.wap (the stages). Start or restart: `notes/agents/start.sh owner <stage>` (session wap-<stage>),
then read this file and the Owners row with your name.

## Idle by default (user 2026-11-23)
- The language grows in lib/ and from the wiki pages; your files change only when that is really necessary. Most of
  the day you sit idle, and that is the job done well.
- Requests reach you only through wap-supervisor, never straight from a wiki worker or another owner: a wiki example that
  needs your stage, with what was tried in lib/ first. Answer wap-supervisor once: "lib can do it: …", "needs N lines in
  <file>: …" (then the user discussion runs through wap-interviewer before you build), or "the page is wrong: …".
- Between requests you make your stage beautiful: fewer lines, one mechanism per job, the simplifier's findings in your
  files. Pure shrinks land without discussion; anything else that changes behaviour waits for the user's OK.
- Talk to the other owners only about a contract between your stages, and say the outcome to wap-supervisor in one line.

## What owning means
- **You are the expert.** You know every function in your files, why it is there, and the stage contract: the input
  and output language (notes/backbone.md "Stage languages"). Keep that knowledge in the files themselves: the first
  comment line says the file's one job and its languages, so a successor can take over from the code alone.
- **Every change to your files passes you.** Anyone may edit them on a branch; you review before the handoff,
  against the principles and the guardrails (test/wap/test_guardrails.wap), and say yes, no, or how.
  A small change (about 10 lines: a call site, a comment, a parameter order) lands without waiting; its handoff
  names you, and you review it afterwards and fix forward. A new function, a signature change or anything larger
  waits for your yes (user 2026-11-19).
- **You keep them small and single.** About 300 lines at most; past that, split along a real seam at the next quiet
  point and update the Owners table in the same commit. A new file in your folder is yours from its first commit.
- **You keep them clean.** No copied blocks, no special cases, one mechanism per job; you pick up the simplifier's
  and the duplicate check's findings in your files first.
- **You answer for them.** A red test, a census refusal or a review finding in your files is yours to fix or route.

## Keeping the pattern
- Every wap file has exactly one owner row (test_guardrails checks it); a file without one is an error, not a gap.
- An owner who retires hands the row to a named successor (wap-supervisor decides), with a handover note on the card.
- Ownership changes only by wap-supervisor, written in the Owners table, never by drift.

## Rules for every file

- One job, said in its first comment line; a second job is a second file in its folder.
- About 300 lines at most: a file past that is split by its owner at the next quiet point, along a real seam (one
  concern per file, never a mechanical cut), in a commit of its own that also updates the Owners table.
- Its input and output language named in that comment.
- Total over its input: every case handled or refused loudly, never skipped.
- No surface spelling outside parse/ and extensions/; no name of a domain (units, colors, keys) in core/.
- A compromise is a `# DEBT:` comment at its code (reason and payoff), never silent.

## The tree

A file is created only where this tree has a place for it; a file that does not fit any place means the tree is
wrong, and the tree is changed here first, then the code.

Layers as in notes/backbone.md: kernel, core, types and sugar (the surface rules every program gets), extensions,
library. A folder holds one topic; its name is that topic,
never two joined by an underscore.

```
wap/
  compiler.wap                the entry: the stages in order (core/pipeline.wap), the command line, nothing else
                              warp wap/compiler.wap <program> <module.wasm>
  nodes.wap                   wap's Node, the one notation of data and code, and the words over it (types.wap includes it)

  kernel/                     the kernel layer: the emitter's whole input language
    forms.wap                 the kernel forms, each a named pattern of Node
    surface.wap               the forms rules write and typing turns into kernel forms (Item, Variable)
    terms.wap                 the type theory's terms, locally nameless (notes/theory.md, notes/coc-plan.md 6.1)
    levels.wap                universe levels compared (6.2)
    environment.wap           the declarations accepted, the state of one check, the refusals (6.6)
    compute.wap               a term computed to its head (6.4)
    equal.wap                 definitional equality (6.5)
    typing.wap                a term's type, a declaration checked (6.3, 6.6)
    inductive.wap             an inductive block checked (7, checks 1 to 5)
    nested.wap                a block nested in another inductive type made plain (7)
    recursors.wap             a block's recursors and their computation rules (7, checks 6 and 7)
    quotients.wap             the quotients statement (6.4, 6.6)
    numbers.wap               the numbers, shortcut and texts statements (6.7)
    show.wap                  a term shown in wap notation
    primitives.wap            the host's operations a Prim names, each a row of the wasm types it takes and gives
    opcodes.wap               the wasm format's codes: section ids, value and heap types, opcodes

  core/                       the machinery: mechanisms only, no names of a domain
    pipeline.wap              one function per step from source to typed program, shared by compiler and census
    language.wap              the language a program is read in: operator table, rule words, the rules of each stage
    stage.wap                 the one walker every stage runs through; positions and provenance of new nodes
    bindings.wap              the facts binding learns of a name: what it refers to, assignments, captures; a definition's record
    type_notation.wap         types as written: list<int>, int?, (int) -> text, built and taken apart
    errors.wap                refusals: the user's line, the readings, the fix-it, the rule that expanded it
    format.wap                code → canonical warp text (`format`): operators in their notation, spacing spelled out
    paths.wap                 a used file's path beside the file using it, `.` and `..` resolved

    parse/                    text → notation → operated
      reader.wap              the pure notation reader: atoms, keys, lists, phrases
      lexemes.wap             the reader's state and its tokens
      atoms.wap               pass 1: names, numbers, glyphs, texts with their holes
      layout.wap              pass 1: brackets, separators, indentation
      cascade.wap             pass 2: tokens → notation by the separator cascade
      operators.wap           notation → operated by the table of types/operators.wap: precedence groups sorted
                              topologically, the minus rule, aliases to canonical words; unrelated mixes refused
      operator_table.wap      the operator table as the operator stage reads it
      tokens.wap              a phrase's tokens as the operator stage reads them: what each touches
      keys.wap                what a key the reader built becomes: the colon block, the choice, an infix call, an assignment
      raw.wap                 a raw parameter's block taken verbatim: the words a file declares raw, the block read to its brace

    rules/                    the rule engine
      patterns.wap            a rule's pattern declared and compiled to a Matcher: holes, typed holes, rests, guards
      matcher.wap             running a compiled Matcher against code, its holes bound; and specificity
      templates.wap           building a rule's output: splicing, fresh names, free words resolved in the rule's module
      stages.wap              shape rules (stage 1): rules indexed by head, run over operated code
      heads.wap               the rules' heads: the word a rule's pattern is indexed by
      termination.wap         the rules checked to end: no chain of them rewrites forever
      lines.wap               a program's lines as the rules read them: a line led by a rule word
      declared.wap            declaration rules (stage 2): holes that ask the declarations, after declare
      typed.wap               typed rules (stage 3): holes of value types, fired in the type walk, typed in place
      lowering.wap            declared → kernel by hand: phrases, statements, the forms no rule writes yet

    analyze/                  facts about the program, no rewriting
      declarations.wap        the prescan: the names, signatures and types a program declares
      definers.wap            the ids of the names that define something, given by the prescan and binding
      modules.wap             the modules a program uses, by file name, as binding sees them
      scope.wap               the one binding analysis: what each name refers to
      library.wap             the types module bound but for its functions, each bound once typing reaches it
      names.wap               what a name may mean: the scope's layers, each finding its definitions by name
      variables.wap           which variable each assignment gives a value to, in written order; late reads
      types.wap               bidirectional typing of kernel code; the dispatch over forms
      calls.wap               a call's function chosen among its overloads, typed once per tuple of argument types
      letters.wap             generic letters a call binds; an empty list's unknown item type, settled by a use
      dispatch.wap            calls on dynamic values: a run-time choice where the type is not known
      conditions.wap          conditions, the narrowing they give their arms, type tests
      matching.wap            match: patterns typed, whether the arms fit every value
      shapes.wap              shapes as types: an enum's case, `List` of Node, a declared pattern
      fits.wap                how types meet: fitting, sameness, the joined type of two
      data.wap                lists, maps and instances written as data
      function_values.wap     function values and what they capture

    emit/                     typed kernel → bytes
      emitter.wap             one case per kernel form; any other node refused; blocks, if, loops, labels
      functions.wap           definitions waiting for their first call, calls
      function_values.wap     Fn: function values, their captures, calls of them
      patterns.wap            Case: arms, pattern tests, a case's own value
      places.wap              a typed form's layout, fields and items reached, variables
      primitives.wap          what each Prim operation emits; a longer one is a helper function of the module
      host.wap                the primitives that ask the host (WASI): printing, raising, files, the command line
      lists.wap               growable lists and the maps built on them
      equality.wap            whether two values of one type are equal, for `==` and a map's key search
      values.wap              the value layout (notes/self_hosting.md "Value layout"), reused as it is
      memory.wap              how a build keeping values in the memory lays them out: the record its extension fills
      wasm.wap                the wasm binary format: modules, sections, instructions; knows no warp form

  types/                    the standard language every program gets: whole definitions, data and rules
    types.wap               the word files below, included in place: the one library every program is bound in
    rules.wap                 the kernel forms' patterns and the ../sugar/ files, used in load order
    prelude.wap               the built-ins (print …), each a function whose body may be a Prim
    system.wap                the world around a program: files, command line, environment, wall clock (over host.wap)
    operators.wap             the operator table: precedence groups and their relations, operators, aliases
    list_items.wap            how a list holds its items, the one list file a build may swap (memory_lists.wap)
    text_bytes.wap            how a text holds its bytes (count, a byte, a slice, joined, compared), the one text file a build may swap (memory_texts.wap)
    lists.wap                 list words over function values: map, filter, contains …
    maps.wap                  map words: a key's value, set, has, remove; text keys found by their hash
    texts.wap                 text words over a text's UTF-8 bytes
    characters.wap            a character's kind (digit, letter, hex) and a text's case
    numbers.wap               number words over the prelude's comparisons
    floats.wap                float, the fast variant of exact real numbers
    host.wap                  the host machinery system.wap's words use, hidden from programs
    memory_texts.wap          a native build's texts in the module's memory, read by its build in the place of text_bytes.wap
    memory_lists.wap          a native build's lists in the module's memory, read by its build in the place of list_items.wap

  sugar/                      the rules of the surface spellings wap's own source uses, one file per topic
    calls.wap                 x.f(y), x.f → calls and Get
    conditions.wap            unless, a if c, a ? b : c → If
    data.wap                  xs#2 and other reaches → Get
    definitions.wap           definitions written other ways
    literals.wap              yes, no, ø → True, False, Empty; no x → x is empty
    loops.wap                 for, until, loop, n times, break, return → While and Return
    matching.wap              match x { … } → Case
    ranges.wap                a to b, a upto b → Range
    records.wap               class, enum → Record
    types.wap                 list of int, x as text → bracketed types and conversions

  extensions/                 what no compiler needs: rule files loaded like modules, and code compiler.wap hands in
                              through a Language field (readers: a file ending → its reader)
                              (units 3km, durations 2 weeks, inline html … as the forms arrive)
    c/                        C functions as lib writes them, `strlen(s: text): i64 from 'c'`, run by the native warp
      foreign.wap             the rules that lower a foreign line to a function calling the library's import
      functions.wap           the warp.c_functions section that describes each C import for the native warp
    native/                   a wap program built to a native executable (build.sh: wasm2c, cc, glue.awk, main.c)
      c.wap                   libc's and wasmtime's C functions, foreign primitives of the module c
      compiler.wap            wap.wasm compiling a source; a module's machine code kept beside it by its hash
      commands.wap            the native wap's commands and options, one table: dispatch and `wap help`
      console.wap             `wap` alone: each line a module, linked to the earlier lines' kept instances
      driver.wap              the native wap command: compiles a program with wap.wasm, runs it by wasmtime
      editing.wap             the console's line edited on a terminal: arrows, word moves, deletes, history
      host_words.wap          a program's C imports answered by the C functions of their names; C calling back into it
      linking.wap             where a module imported by name is: the path its compiler resolved, beside the importer unless rooted
      memory.wap              values in the memory, as wasm2c takes no GC type: layouts, literal words, the raise
      programs.wap            a program's machine code kept beside wap.wasm, program-<hash>.cwasm by its sources
      run.wap                 modules run by wasmtime's C API, their .wasm imports linked; the program's memory
    packed.wap                a Node as compact bytes and back, pack and unpack: each text and repeated subtree once
    warm.wap                  the compiler's warm state: the files it reads before a program, operated, packed
    rules.wap                 the rule files a build loads beyond every program's: foreign lines, laws
    verify_rules.wap          the rule files `wap verify` loads in their place: foreign lines, each law a function
    laws.wap, law_runs.wap    a law a hint verify tests: `law` read as a function, each law run on trial values
    proof/verify/             `wap verify`: the door reading programs with laws through analyze's terms (verify.wap, laws.wap, options.wap: `--tree <root>` or `--seed <folder>`)
    theory/                   what stays of the dependent type theory beside the compiler (notes/theory.md "Files")
      below.wap               the statements that bind names, below and course
      export.wap, second/     what the kernel accepted written as lean4export records, and the second checker that reads them
    proof/prove/              the provers: a goal to a proof term, tried in order (notes/coc-plan.md 3.5 and 8)
      goals.wap, prove.wap    the goal and the order the provers run in
      facts, computing, rewriting, introduction, induction, linear, apart   the ways to prove (wiki/proof.md)
    wasm/                     a compiled wap module used as its source
      library.wap             the library compiled once, types.wasm: read in place of its source when its stamp fits
      modules.wap             use "m.wasm": its functions declared from their export names, the rest (rules, enums,
                              classes, generic bodies) read from its wap section as source (Language.readers[".wasm"])

lib/                          the library, warp's own, shared and used as it is
test/wap/                     wap's outcome tests: a program compiled by wap, run, its output checked
```

What each file may know:
- **kernel/** knows Node and nothing of the stages.
- **core/parse/** knows characters and the operator table, no keyword: `if`, `for` and `class` are words to it.
- **core/rules/** knows patterns and templates, no particular form: every form it handles comes from a rule file.
- **core/analyze/** reads, never rewrites.
- **core/emit/** reads only the kernel; `wasm.wap` reads not even that.
- **core/** uses no file of extensions/ (guardrail core-no-extension); it walks Language's fields, compiler.wap fills them.
- **sugar/** holds rules only; a rule that needs code calls a function in lib/.

Which of the two a rule file belongs in is measured, not argued: wap compiles itself with extensions/ switched off:
no extension rule file loaded and Language.readers empty.
A rule file is in sugar/ exactly when wap's own source uses its spelling; when that changes, the file moves.

## Owners

Each wap file has one expert owner, whose duties are above (user 2026-11-18); ownership changes
only through wap-supervisor, in this table. Owners go by stage (user 2026-11-18).
Anyone may edit any wap file on a branch; the owner of the file's stage reviews the change before the handoff, and owns the stage's contract: what its output
language is (notes/backbone.md "Stage languages"). Breadth stops until milestone 2: wap gets only what its own
source uses, and every landing names the functions of wap it turned green (scripts/wap-census.warp). Tests
(test/wap/) and `# DEBT:` comments are append-only, open to all. A bug of the old compiler that blocks wap
goes to wap-emitter as a repro; work around it or go on meanwhile. A new file belongs to the stage of its folder.

wap compiles itself; its work comes from notes/backbone.md "Architecture changes, in order" and the
open milestone-2 points (user 2026-11-20); anything else is a `# DEBT:` comment at its code.

Trim before handoff (user 2026-11-18): before handing a branch off, try deleting each of its edits, one at a time, after
the change is done; every edit whose removal keeps test/wap/run.sh and test/wap/test_guardrails.wap green goes. Only
deletions, nothing rewritten; the handoff names what was trimmed.

| stage | owner | files (under wap/) |
|---|---|---|
| lead: the queue, the contracts, the self-build | wap-supervisor | test/wap/test_self.sh, test/wap/ratchet_census.sh, scripts/wap-census.warp, compiler.wap, core/pipeline.wap, core/stage.wap, core/bindings.wap, core/type_notation.wap, core/errors.wap, kernel/, extensions/theory/, extensions/proof/prove/; the test/wap/ scripts no other row names |
| front: read, operators, rules, lowering | wap-reader | core/parse/, core/rules/, core/format.wap, core/language.wap, types/, sugar/, nodes.wap, extensions/packed.wap, extensions/warm.wap |
| types: declare, bind, type | wap-binding | core/analyze/, core/paths.wap |
| back: emitter, runtime, native | wap-emitter | core/emit/, extensions/wasm/, extensions/c/, extensions/native/; test/wap/test_native.sh, test/wap/test_guardrails.wap, test/wap/guardrail_shapes.awk, test/wap/guardrails_allowed.txt |
| simplification: wap smaller by its Node count (Meta excluded) | wap-simplifier | any file, by review of its stage owner |

Questions for the user go to wap-interviewer, never to the user.
