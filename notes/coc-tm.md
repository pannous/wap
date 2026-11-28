# TM, one environment per module: how it is built

notes/coc-plan.md step TM (between T2 and T3), from notes/audit/2026-11-25-2.md R1. Each module is read with its
own environment, built from the modules it `use`s. A declaration applies from where it stands on, in its own file and
in the files that use it, never in a file that does not. A file's text is scanned once. The restart after a standard
module is brought in goes. Line counts are `grep -vc '^\s*#'` on main 13163e6a.

## The split of Language

core/language.wap `Language` has 23 fields and is a parameter of 193 functions in 19 files. It holds four things.
They become three records:

| record | fields | lives |
|---|---|---|
| **Grammar**, what one module is read in | groups, operators, looser_than, group_names, operator_names, circumfix, phrase_words, shape_rules, declared_rules, typed_rules, patterns, declarations, reading (the alias rows), unparsed, words (the names the file defines at its top, today `defined_words`), uses (the keys of the modules it uses, in written order) | one per module, kept for the whole compile |
| **Language**, one compile | grammar (the module being read now), grammars: map<text, Grammar> by module_key, base: Grammar (the types module's rows, kernel/forms.wap and sugar/), operated, modules, lowered | per compile |
| **Build** | readers, memory, standard, use_free_modules | handed in by compiler.wap |

- Build is a field of Language (`language.build`), set once by compiler.wap. The four fields are read in 9 places
  (compiler.wap, pipeline.wap, warm.wap, compile-steps.wap, data.wap).
- The 193 functions keep their `language: Language` parameter. A grammar field is read as `language.grammar.x`
  instead of `language.x`. That is about 60 accesses in 12 files, mechanical, and no new lines. Passing the Grammar
  alone to the functions that read nothing else (the operator stage, the rule stage) is possible later. It is not
  part of TM, because those functions also call `operated_file`.
- `aliases_of` and `handed` go (3 lines): a module's alias rows are its grammar's `reading`, and the files that use
  it get them through the merge below. The kernel's Environment (wap/kernel after T2) keeps its name; core's record
  is Grammar, so the two never meet.

## Where each table lives

- **Per module (Grammar):** everything a declaration in a file can add to: operators and their groups, circumfix
  glyphs, phrase words, the rules of the three stages, patterns, the declarations stage 2 reads, alias rows,
  unparsed words. Also the file's own defined words, so `programs_own` asks the grammar of the file whose rule head
  it is.
- **Per compile (Language):** the grammars by key, and what is read or made once: operated code, declared modules,
  lowered modules.
- **The base grammar:** the rows of types/operators.wap and the rules of kernel/forms.wap and sugar/ (today
  `rules_files_loaded`). Every module starts from it.

## How `use` builds a module's grammar

```
grammar(file) = base, then each used file's grammar merged in written order, then the file's own declarations,
                each from where it stands on
```

- **Transitive.** A `use` brings in the used module's whole grammar, including what that module uses, so syntax
  carries on through each `use`.
- **Merged** means rows are appended and maps are updated, the way `operators_declared` and `rules_loaded` add to
  the one table today. A row that comes twice (a diamond `use`) is the same row, and is kept once, as
  `rules_loaded` already keeps a rule loaded twice once. The name indexes and `looser_than` are rebuilt once per
  merge (`related_groups`), not once per row.
- The grammar is **copied** for each module, not shared. The tables are small: about 120 operator rows and about
  300 rules, and about 150 modules in the compiler's own build. A shared, persistent table would cost more lines
  than it saves time. TM measures the copy against the 3% speed guard.
- **A warm module** (extensions/warm.wap) brings its operated code. Its grammar is folded from the declaration
  statements in that code (operators, rules, patterns, aliases are all statements), once per compile. So the warm
  state carries nothing new: the compiled module carries its environment, as R1 asks.
- **The seam with T2d stage 3:** a module's direct uses in written order are `Module.uses`, keyed by module_key
  (core/pipeline.wap). Core declares no other field for a reader's scopes.

## Reading a file: one scan, declarations in order

Today a file's text is scanned three times: its `use` lines (`uses_written`), its raw and phrase words
(`unparsed_written`), and the full read. Then its tree is walked four times before it is operated: `words_named`,
`used_files`, `operators_declared` and `aliases_taken`.

After TM:

1. **The reader scans once.** It reads the file top-down. At a `use` line it asks the pipeline for that file's
   grammar, through a function value the reader is given (`used(file) -> map<text, text>`, the used file's unparsed
   words). The pipeline operates the used file then, as `notation_of` does today, and the reader goes on with those
   words added. A definition line that takes a `raw`, `phrase` or `word` parameter adds its word from that line on,
   which is the same test `unparsed_written` makes today, now made on the line being read. `uses_written` and
   `unparsed_written` go (11 lines). This puts a callback into the reader: core/parse gets a function parameter, not
   a new table.
2. **One walk, statement by statement.** `operated_once` takes the top-level statements in order. For each one:
   - its operator, placement or circumfix declaration, or its alias line, joins the grammar;
   - the statement is operated with the grammar as it is now;
   - its rule or pattern is loaded (`rules_loaded` on the one statement), and its phrase words join the grammar;
   - it is shaped by the shape rules loaded so far.

   `operators_declared` and `aliases_taken` become per-statement calls in that loop, and `shaped_program`'s
   `rules_loaded` moves into it. `words_named` stays as one walk, because a program may call a function above its
   definition, and that order is not part of TM. The promise at core/pipeline.wap:35 ("each file read with the rules
   of the files before it loaded") then holds, and the DEBT at core/rules/stages.wap:134 is paid (4 lines).
3. **Using an operator above its declaration is refused,** by the grammar as it stands: the operator stage reads
   no row there. The refusal is the one the operator stage gives an unknown spelling today. If its wording needs to
   name the declaration below, that is one line, which the plan counts.

**Includes** are read into the including file where they stand. Their declarations are the including file's from
there on, as wiki/use.md says of `include`.

## The restart that goes

`typed_modules` (core/pipeline.wap:200-202) lowers and binds every module. It then collects the words the program
named from a standard module without its `use` (`standard_named`), and starts over with those modules brought in
(`standard_brought`, `standard_used`). That second round binds the namers again, against the brought module's own
words.

After TM, binding brings the module the first time. When `standard_word_bound` (core/analyze/scope.wap:271) meets a
standard word, it asks the pipeline for that module through a function in the Scope (`brought(file) -> Module`). The
module is declared once per compile (`used_module`), and its signature binds the word as a `use` would. The hint and
the refusal of a module with rules stay where the binding happens. The brought modules are prepared before the
first module that named them.

- Gone: `standard_brought`, `standard_used`, `standard_named` and the restart in `typed_modules`, 18 lines. Added:
  the Scope field and the call, about 4.
- `ruled`, `standard_file` and `standard_module` stay, called from the binding.

## Measured core lines

| piece | gone | added | net |
|---|---|---|---|
| Language split (language.wap: three classes, `handed`/`aliases_of` out) | 3 | 6 | +3 |
| one scan (`uses_written`, `unparsed_written`, notation_of's loops; reader's `use` callback, the raw word on its line) | 11 + 4 | 6 | −9 |
| one walk in order (operated_once, operated_program, shaped_program's load, the DEBT) | 4 + 6 | 6 | −4 |
| grammar per module (merge, base, the warm fold) | 0 | 14 | +14 |
| the restart | 18 | 4 | −14 |
| `defined_words` / `words_listed` into the grammar | 3 | 1 | −2 |
| **total** | | | **≈ −12** |

The audit counted about −70. The difference is the per-module grammar, which the audit did not price (+14), and the
four walks of the tree: only one of them really goes away, since three become calls inside the one loop rather than
deletions. These numbers come from reading the code, not from a build. Each step below reports its measured diff
when it lands.

## Steps

Each is one landing, careful path (reader, self build, seed), measured against the speed guard.

| step | what | test (outcome) |
|---|---|---|
| TM1 | the split: Grammar, Language, Build; one grammar for the whole compile as today, no behaviour change | `--stage 2` a fixed point |
| TM2 | a grammar per module, built from its uses; the DEBT paid | a rule declared in one file does not fire in a file that does not use it |
| TM3 | one scan and one walk, declarations in order | an operator used above its declaration in the same file is refused |
| TM4 | the restart goes | the existing `use`-free standard word tests stay green (wiki/use.md "Library folders") |

**The seed rule.** TM3 changes what the compiler's own source may write: an operator, rule or alias used above its
declaration, or used in a file that does not `use` its module, stops reading. Before TM2 and TM3 a census of the
tree lists every such place, and those places are edited in the step's first commit. If the seed's own source
needs the old reading, the step lands after a seed refresh.

## The wiki before TM2 and TM3

The user approves each wiki change, sent through wap-interviewer with the old and the new text.

- **wiki/use.md** says nothing on syntax. wiki/wasm-representation.md:32 says "A use brings in syntax too". Before
  TM2, use.md needs a sentence of its own:
  > "A module's operators, rules and aliases reach the files that use it, and the files that use those in turn; a
  > file that does not use the module never sees them."
- **wiki/operator.md:146** says "A declared operator binds like `+` and is known in the whole file". TM3 makes it
  "known from its declaration on, in its file and in the files that use it". This is a rewrite of the spec, so it
  needs the user's approval before TM3.

## Open

- Does any library or test rely on a rule or operator reaching a file that does not `use` it? TM2's census
  answers that. A file found doing so gets its `use`, and is never kept working by widening the grammar.
