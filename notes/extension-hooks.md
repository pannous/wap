# Extension hooks

A language feature outside the core is an **extension**, and the core names none. A rule extension is a rule file
loaded like a module. An extension that needs code is a field of `Language` that the compiler's entry (compiler.wap)
fills and the core walks: `readers` maps a file ending to its reader, so `use "m.wasm"` reads a compiled module
through `readers[".wasm"]`. warp's static hook table (`class Extension`, extensions/extensions.warp) is the same idea,
one row per extension; the hooks below are its fields.

Every field but `name` is optional. List fields and map fields of all rows are joined once into one row (`hooks()`):
lists in row order, maps with a later row's entry winning. `passes`, `prescans` and `source_passes` are walked row by
row instead. Row order in `EXTENSIONS` therefore matters where two rows act on the same thing.

```wap
Extension{name: "degrees", atom_readers: {"°": read_degree}}
```

This page covers the hooks from `operator_rows` through `passes`, in the order the class declares them. A reader that
answers `ø` means "my form is not here"; the parser then tries the next reader or its own rules.

| hook | type | consulted by | example extension |
|---|---|---|---|
| [operator_rows](#operator_rows) | text | parser, operator table | uncertain |
| [library_words](#library_words) | map | emitter, runtime words | gpu_lists |
| [host_exports](#host_exports) | list | emitter, host exports | gpu_lists |
| [constant_tables](#constant_tables) | map | emitter | gpu_lists |
| [atom_readers](#atom_readers) | map | parser, atoms | degrees, attributes |
| [number_readers](#number_readers) | list | parser, numbers | radix_numbers, time_literals |
| [number_suffix_readers](#number_suffix_readers) | list | parser, after a number | durations, float_suffixes |
| [suffix_readers](#suffix_readers) | list | parser, after an operand | superscripts, percent, times_loops |
| [type_readers](#type_readers) | list | parser, type declarations | sum_types |
| [infix_readers](#infix_readers) | list | parser, expressions | declared_operators |
| [prefix_readers](#prefix_readers) | list | parser, expression start | pipe_lambdas, circumfixes |
| [glyph_owners](#glyph_owners) | list | parser, symbols | declared_operators, circumfixes |
| [prescans](#prescans) | map | parser setup | declared_operators, circumfixes |
| [keyword_readers](#keyword_readers) | map | parser, statement heads | phrase_definitions, shader_blocks |
| [block_words](#block_words) | list | parser, glued blocks | tasks |
| [source_passes](#source_passes) | list | before parsing | entities |
| [text_escape_readers](#text_escape_readers) | map | parser, texts | entities |
| [value_settlers](#value_settlers) | map | prelude words, emitter | tasks |
| [text_passes](#text_passes) | list | interpolation | typed_templates |
| [passes](#passes) | map | pass list | function_clauses, class_methods |

<!-- Status: all twenty hooks are built and in use on main (2026-11-04): each has at least one row in
`extensions/extensions.wap` and a call site in the core. The roadmap's design named them in four groups: operator
rows (1), name → handler (2, keyword_readers, block_words), list kinds (3), and one registration per extension (4,
the readers, the passes, the runtime words and host exports). GPU lists were the first extension through the table
(card gpu-lists-extraction). -->

## operator_rows
`operator_rows: text = ""`. The extension's operators as rows in lib/aliases.wap's format, its file's text
(`bundled_module`). The parser builds its operator table from lib/aliases.wap and then every extension's rows
(`extension_operator_rows()`, parser.wap).

```wap
Extension{name: "uncertain", operator_rows: bundled_module("extensions/uncertain/operators.wap")}
```
extensions/uncertain/operators.wap:
```wap
"±" { aliases: ["+-"], declared: yes, power: [140, 141] }
```
<!-- Status: roadmap hook 1 (operator rows); built. -->

## library_words
`library_words: map = {}`. A program's word → the runtime word it calls. The emitter merges these into its own table
(`extended_library_words`, emitter/runtime_words.wap).

```wap
gpu_lists_extension = Extension{name: "gpu_lists", library_words: {gpu_zeros: "gpu_zeros", gpu_put: "gpu_put", gpu_list_of: "gpu_list_of"},
	host_exports: ["gpu_list_place", "gpu_list_cell"], constant_tables: {GpuCell: GpuCell}}
```
<!-- Status: built with GPU lists (card gpu-lists-extraction). -->

## host_exports
`host_exports: list = []`. Runtime words every program exports under their own names, for a host. The emitter
exports each (`extension_host_exports()`, emitter/host.wap). Example: gpu_lists above, `["gpu_list_place",
"gpu_list_cell"]`. <!-- Status: built with GPU lists. -->

## constant_tables
`constant_tables: map = {}`. Tables whose numbers the extension's runtime words read by name, `GpuCell.I32`. Merged
into the emitter's constant tables (`extended_constant_tables`, emitter.wap). Example: gpu_lists above,
`{GpuCell: GpuCell}`. <!-- Status: built with GPU lists. Seed limit: runtime code may read only constant-table keys the
seed knows (roadmap). -->

## atom_readers
`atom_readers: map = {}`. The first character of an atom → its reader, given the parser there; the reader reads the
atom and moves past it (`°C`). Glued after a number or a name, such an atom multiplies it: `30°`, `x°`. The parser
asks `atom_reader(c)` when it reads an atom and after a number or name.

```wap
degrees_extension = Extension{name: "degrees", atom_readers: {"°": read_degree}}
attributes_extension = Extension{name: "attributes", atom_readers: {"@": at_atom}, suffix_readers: [read_trailing_attribute]}
```
<!-- Status: roadmap "atom glyph"; built. -->

## number_readers
`number_readers: list = []`. Functions reading a number form at a digit (`0xff`, `2024-01-31`), each `ø` where its
form is not. The parser tries them before its decimal number.

```wap
radix_numbers_extension = Extension{name: "radix_numbers", number_readers: [read_radix_number]}
time_literals_extension = Extension{name: "time_literals", number_readers: [read_time_literal]}
```
<!-- Status: roadmap "atom glyph" for radix numbers, time literals; built. -->

## number_suffix_readers
`number_suffix_readers: list = []`. Functions reading what follows a decimal number, given the parser after it and
the number both as decimal_number wrote it and as the source did (`0.1f`, `1 month`), each `ø` where its form is not.

```wap
durations_extension = Extension{name: "durations", number_suffix_readers: [read_duration]}
float_suffixes_extension = Extension{name: "float_suffixes", number_suffix_readers: [read_float_suffix]}
```
<!-- Status: roadmap "atom suffix"; built. -->

## suffix_readers
`suffix_readers: list = []`. Functions reading what follows an operand, given the parser after it, the operand and
the binding power the context needs (`x²`), each `ø` where its form is not or binds looser. The parser asks
`read_suffix` in its expression loop.

```wap
superscripts_extension = Extension{name: "superscripts", suffix_readers: [superscript_power]}
percent_extension = Extension{name: "percent", suffix_readers: [read_percent]}
times_loops_extension = Extension{name: "times_loops", suffix_readers: [read_times]}
```
<!-- Status: roadmap suffix rows (`x²`, `5%`) and statement head (`n times`); built as readers. -->

## type_readers
`type_readers: list = []`. Functions reading a type declaration's body after its head, given the parser there, the
type's name and its parameters (`type Opt = Some(int) | None`), each `ø` where its form is not.

```wap
sum_types_extension = Extension{name: "sum_types", keyword_readers: {"enum": read_enum_with_values}, type_readers: [read_sum_type]}
```
<!-- Status: roadmap "declaration"; built. -->

## infix_readers
`infix_readers: list = []`. Functions reading an operator after an operand inside an expression, given the parser
there, the operand and the binding power the context needs; each answers `ø` where its form is not, or
`OPERAND_ENDS` where it binds looser and so ends the operand (`a ⊕ b` of a declared `⊕`).

```wap
declared_operators_extension = Extension{name: "declared_operators", prescans: {"declared_operators": scanned_operators}, infix_readers: [read_declared_infix], prefix_readers: [read_declared_prefix], glyph_owners: [declares_glyph], keyword_readers: {"operator": read_declaration, "infix": read_declaration, "prefix": read_declaration, "suffix": read_declaration, "postfix": read_declaration}}
```
<!-- Status: roadmap "operator table" plus "declaration" (declared operators); built. -->

## prefix_readers
`prefix_readers: list = []`. Functions reading an operator and its operand where an expression starts, each `ø`
where its form is not (`√16` of a declared `√`).

```wap
pipe_lambdas_extension = Extension{name: "pipe_lambdas", prefix_readers: [read_pipe_lambda]}
circumfixes_extension = Extension{name: "circumfixes", prescans: {"circumfixes": scanned_circumfixes}, prefix_readers: [read_circumfix], glyph_owners: [is_circumfix_glyph], keyword_readers: {"circumfix": skip_circumfix_statement}}
```
<!-- Status: built (Ruby bars `{ |x| … }`, circumfix `|x|`, declared prefix operators). -->

## glyph_owners
`glyph_owners: list = []`. Functions telling whether this parse reads a glyph as the extension's, never a free
symbol (`owned_glyph`, parser.wap). Examples: `glyph_owners: [declares_glyph]` (declared_operators),
`glyph_owners: [is_circumfix_glyph]` (circumfixes), above. <!-- Status: built. -->

## prescans
`prescans: map = {}`. A name → the function scanning a source before it is parsed; the parser keeps its value under
the name (`Parser.scans`: the operators a program declares). Run per row when the parser is made
(`extension_scans`). Examples: `prescans: {"declared_operators": scanned_operators}`,
`prescans: {"circumfixes": scanned_circumfixes}`, above. <!-- Status: built. -->

## keyword_readers
`keyword_readers: map = {}`. A word → the reader of the phrase it starts, given the parser at the word and the word;
`ø` where its form is not there, nothing read. A reader that read its statement to nothing (applied by a prescan)
answers `ø` past it (`emit alarm`). The parser asks `keyword_reader_of(word)` at a statement's word.

```wap
phrase_definitions_extension = Extension{name: "phrase_definitions", keyword_readers: {"to": read_phrase_definition, "To": read_phrase_definition}}
shader_blocks_extension = Extension{name: "shader_blocks", keyword_readers: shader_readers()}
event_phrases_extension = Extension{name: "event_phrases", keyword_readers: event_readers()}
```
<!-- Status: roadmap hook 2 (name → handler: statement heads, raw blocks, definition heads); built. -->

## block_words
`block_words: list = []`. Words that take a block glued to them as theirs, `go{…}`, never the tagged block
`go:{…}`. The parser checks `extension_block_words()` beside its own glued block words.

```wap
tasks_extension = Extension{name: "tasks", block_words: ["go"], value_settlers: {"task_go": "task_awaited"}}
```
<!-- Status: roadmap hook 2; built. The row lives in extensions/go_tasks.wap, since an extension's file never takes a std
module's name (roadmap, row pitfalls). -->

## source_passes
`source_passes: list = []`. Functions run on the source before it is parsed, each giving `[the new source, its
shifts]`: where the new source got shorter, `[offset after the change, columns taken out]`, so nodes keep their
written columns (`passed_source`, parser.wap).

```wap
entities_extension = Extension{name: "entities", source_passes: [expanded_entities], text_escape_readers: {":": entity_escape}}
```
<!-- Status: roadmap "text pass" (HTML entities `&amp;`); built. -->

## text_escape_readers
`text_escape_readers: map = {}`. The character after a `\` in a text → the reader of the escape, given the text, the
offset of the `\` and its length, giving `[the characters, the length read]`, `ø` where its form is not (`\:alpha`).
Asked by `text_escape_at` while the parser reads a text. Example: entities above, `{":": entity_escape}`. <!-- Status: built. -->

## value_settlers
`value_settlers: map = {}`. A word starting a value that comes later → the word a place declared as a value calls on
it, brought wherever the program calls the first (`task_go` → `task_awaited`: `n: int = go f(3)` awaits). Read by
prelude_words.wap and the emitter. Example: tasks above. <!-- Status: built. --> Write the keys as texts, `{"task_go": …}`:
a bare key is read as a free word <!-- card key-map, roadmap row pitfalls -->.

## text_passes
`text_passes: list = []`. Functions a program goes through before its texts interpolate (`sql "… $name"` built as a
query), in row order (`with_text_passes`, parsing/interpolation.wap).

```wap
typed_templates_extension = Extension{name: "typed_templates", text_passes: [injected]}
```
<!-- Status: roadmap "text prefix" (typed templates `sql "…"`, `sh "…"`); built. -->

## passes
`passes: map = {}`. A core pass's name → the extension's pass running right after it <!-- decision extension-passes -->. A
name of no core pass is refused loudly. The pass list is made once, with every row's passes in row order
(`with_extension_passes`, passes/passes.wap). Its twin `passes_before` runs a pass right before the named one.

```wap
function_clauses_extension = Extension{name: "function_clauses", passes: {"arity_overloads": clauses}}
multiple_assignments_extension = Extension{name: "multiple_assignments", passes: {"arity_overloads": multiple_assignments}}
	# right after definition_heads, in this order: a class's conversions become the program's before conversions runs
	Extension{name: "class_methods", passes: {"definition_heads": classes_rewritten}}
	Extension{name: "int_types", passes: {"definition_heads": int_types}}
```
<!-- Status: roadmap "pass list"; built. -->

See also: [[use]] modules, [[standard library|standard-library]].
