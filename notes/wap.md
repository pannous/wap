# wap: the pipeline and the state of the new compiler

wap's files, their tree and their owners: notes/agents/wap-owner.md. Plan and
principles: notes/backbone.md. The kernel: notes/kernel.md. Rules for every file: notes/first_principles.md.

wap is the new compiler; warp, in core/, is the old one, frozen. wap is an ordinary warp program, compiled by warp
until it compiles itself, so its names never clash with warp's compiler. Its sources end in `.wap`; the language they
are written in is warp.

## The pipeline

A program passes through stages. Each stage has one job, reads one declared language and writes one declared
language (nanopass style). A stage that meets a form outside its input language refuses it loudly, naming the form
and the stage that should have removed it.

```
text
 │ read                       core/parse/        the notation: data and code alike, no keyword meanings
 ▼
notation (Node: atoms, keys, lists, phrases)
 │ shape rules                core/rules/        stage 1: rules that ask only the shape
 ▼
surface (any warp)
 │ declare                    core/analyze/declarations.wap
 ▼
surface + declarations
 │ declaration rules          core/rules/declared.wap  stage 2: rules that ask the declarations in force
 ▼
surface + declarations
 │ lower                      core/rules/lowering.wap   writes the kernel forms: glued, operator and phrase calls,
 │                                              := = =>, data and blocks; a phrase stays a call, typing decides it
 ▼
kernel (kernel/forms.wap)
 │ scope, typing, kind rules   core/analyze/, core/rules/typed.wap   stage 3 fires on each node as typed
 ▼
typed kernel
 │ emit                       core/emit/
 ▼
module → bytes
```

Every stage runs through one walker (core/stage.wap), which also carries the metadata: a node a stage builds gets
the position of the node it rewrote, and the name of the rule or stage that built it. Nodes reused from the input
(the holes of a pattern) keep their own. No code ever attaches a position by hand.

## Rules for every file

- One job, said in its first comment line; a second job is a second file in its folder.
- About 300 lines at most: a file past that is split by its owner at the next quiet point, along a real seam (one
  concern per file, never a mechanical cut), in a commit of its own that also updates the Owners table.
- Its input and output language named in that comment.
- Total over its input: every case handled or refused loudly, never skipped.
- No surface spelling outside parse/ and extensions/; no name of a domain (units, colors, keys) in core/.
- A compromise is a `# DEBT:` comment at its code (reason and payoff), never silent.

## State

Milestone 1 (Hello) reached 2026-11-17; milestone 2 (wap builds itself, notes/backbone.md "Milestones") in progress.
Every stage of the pipeline runs (core/pipeline.wap); the sugar's rules write the kernel forms of words
(types/sugar/), lowering.wap the general ones (calls, definitions, data, blocks).

Tests: `bash test/wap/run.sh` (every test/wap script), `bash test/wap/test_guardrails.sh`.

## Road to self-build

The gauge is scripts/wap-census.warp: it runs the compiler's own stages on every wap file and counts the functions
typed alone; it also ranks the refusals that block the rest, the first a function meets, by family. On 2026-11-19
(main 4d51aa08b2) wap types 997 of 1157 functions, 15 of 69 files whole, and no place of its own source is typed any.
test/wap/ratchet_census.sh holds those numbers: the files typed whole may only rise, the untyped functions (cap 160)
may only fall. Rerun after each landing: `test/wap/run.sh --wait test/wap/ratchet_census.sh`; the census's ranking names what to build next.

## Size

wap's size is the number of nodes its own reader makes of every wap/*.wap file, Meta excluded
(scripts/wap-size.warp): comments, blank lines, line breaks and the length of names count nothing, so only a real
simplification makes it smaller. warp-simplifier lowers it; each landing's commit says the count before → after.
`warp --no-window scripts/wap-size.warp $(git ls-files "wap/*.wap")`

Baseline, origin/main 499e1d6abe (2026-11-18): **82145 nodes**.

| folder | nodes |
|---|---|
| . | 113 |
| core/analyze | 25641 |
| core/emit | 18791 |
| core | 5339 |
| core/parse | 12266 |
| core/rules | 10114 |
| kernel | 189 |
| types | 8814 |
| types/sugar | 878 |

The 20 largest top-level statements:

| file and name | nodes |
|---|---|
| wap/core/analyze/scope.wap bound | 717 |
| wap/nodes.wap text | 625 |
| wap/core/analyze/calls.wap call_typed | 584 |
| wap/core/analyze/calls.wap function_typed | 560 |
| wap/core/rules/lowering.wap lowered_form | 534 |
| wap/core/analyze/types.wap typed_form | 509 |
| wap/core/emit/host.wap arguments_function | 478 |
| wap/core/emit/emitter.wap code | 464 |
| wap/types/floats.wap float_digits | 438 |
| wap/types/operators.wap operators | 410 |
| wap/core/parse/atoms.wap quoted | 406 |
| wap/core/parse/atoms.wap number_read | 390 |
| wap/core/parse/reader.wap read_token | 390 |
| wap/core/emit/primitives.wap primitive_code | 359 |
| wap/core/parse/operators.wap tokens_read | 354 |
| wap/core/format.wap call_text | 337 |
| wap/core/emit/primitives.wap int_text_function | 324 |
| wap/core/analyze/calls.wap chosen_definition | 308 |
| wap/core/parse/layout.wap indentation | 308 |
| wap/core/emit/host.wap path_opened | 307 |
