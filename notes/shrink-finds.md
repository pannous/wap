# Shrink and speed finds

Read-only scan of wap/core, wap/types, wap/extensions (not theory, kernel), 2026-11-27, nothing built or run: every
speed estimate is a guess for whoever measures it (standing OK speed needs ≥1% measured, no net lines).
A pure shrink or speedup changes no behavior unless the line says so.

## Ranked

1. **`export_names` filters every own definition per exported function** — wap/core/emit/functions.wap:158
   `#own.filter(other => plain_word(other) == name) == 1`, run for each exported definition from functions_exported
   (:146), and each `plain_word` is a fact_of scan plus `text()`. Quadratic in the exported × own definitions.
   Change: count the plain words once in functions_exported (`words = own.map(plain_word)`, a map word → count, or
   sort once) and pass the counts to export_names. Net about +2 lines. Pure speedup. Big only where many definitions
   are exported (a module compiled with `exports`, the library); with `exports = []` only the `EXPORTED_AS` ones loop.
   Measure first: emit a module with the types module's exports.
2. **`with_facts_of` builds a list per original fact** — wap/core/stage.wap:60
   `held.map(fact_name).contains(fact_name(fact))` allocates a list for each fact of the original; `replaced`
   and `placed_like` run it for every rewritten node (allocation is the GC half of self-compile).
   Change: `held.any(other => fact_name(other) == fact_name(fact))`. Net 0 lines. Pure.
3. **`has_fact` builds a Range and a closure per call** — wap/core/stage.wap:99
   `(META_FACTS to #data).any(at => …)`, called from is_exported, the emitter and the binder. fact_of (:103)
   already loops without allocating; write has_fact as the same loop (`yes` on a name match, ø-valued facts count).
   Net 0 to +1. Pure.
4. **`instance_code` recomputes `fields_of(record)` and filters per field** — wap/core/emit/places.wap:60-61
   `fields_of(record).map(field => items.filter(…)#1)` then `fields_of(record)#at` again per field.
   Change: `fields = fields_of(record)` once, `items.find(…)!` instead of `filter(…)#1`, loop over `fields`.
   Net −1 line. Pure (a record literal's items name each field, as the `#1` already assumes).
5. **`[A, B].contains(x)` literals rebuilt on every call** — wap/core/emit/functions.wap:158 (inside the per-function
   path of 1), wap/core/rules/patterns.wap:93 (hole_stage, per rule hole), wap/core/type_notation.wap:402,
   wap/core/parse/operator_table.wap:76, wap/extensions/native/commands.wap:52.
   Change: a named constant at the file top (`UNPLAIN_EXPORTS = [MAIN_EXPORT, INIT_EXPORT, MEMORY_EXPORT]`). Net +1
   line each, saves one list allocation per call. The top-level upper-case constants (39 of them, the 134 may count
   locals) are globals, not rebuilt per use; the inline literals are what is rebuilt.
6. **`#xs.filter(p)` and `filter(p)#1` allocate to count or find** — wap/core/analyze/calls.wap:384
   (`#candidates.filter(other => more_specific(…))`), wap/core/parse/operator_table.wap:95
   (`declaring_words.filter(…)#1` → `find(…)!`), wap/types/lists.wap:22 (`count(xs, item)` → a counting loop or
   `xs.fold`), wap/extensions/wasm/modules.wap:136 (names-twice check, O(n²) with an allocation per name; a map of
   seen names). Pure, net 0.
7. **`exported` check rebuilds the export names per signature** — wap/extensions/wasm/modules.wap:92
   `fact_items(module.code, EXPORTS).map(name => text(name))` evaluated inside the signature filter; hoist it above
   the filter. Net +1, pure, module linking only (not hot).
8. **`nodes_in` copies at every level** — wap/core/stage.wap:77 `[n] + direct_parts(n).flat_map(nodes_in)`: a list
   per node, concatenated up the tree. An accumulating helper (`nodes_in(n, found)`) allocates one list. Net +2
   lines; callers in the binder may be hot: check their count first.
9. **Repeated code** (scripts/repeated-code.sh on every wap/ file outside theory/kernel found only three):
   - wap/extensions/prove/linear.wap:179 and :211 both write `[bound.left, bound.difference, bound.right]`: name it
     `sides(bound)`. Net −1.
   - wap/core/analyze/data.wap:94 and :99 write `parts += [placed_like(List(run, Bracket.Square, separator), n)]`
     twice in spread_typed: a local `flush` (or the last run appended after the loop by the same name). Net −1.
   - wap/core/analyze/dispatch.wap:115 and :129 write `generic_place(...) ?? return []` as the first line of two
     functions: not worth a name.
10. **Text repeat is linear copies** — wap/types/texts.wap:151 `for at in 1 to times { out += t }` copies `out` each
    time (quadratic in `times`); doubling halves the work. Rare use; net +2. Low rank.

## Not found

- Dead functions: none. Every top-level function of wap/ (outside theory/kernel) has a caller outside its own body
  in wap/ lib/ test/ scripts (name-token count, comment lines left out; `host_word` is the one export called from C).
  Functions called only from comments or from each other were checked for self-use only; a chain of dead callers was
  not looked for further.
- Lists grown by `+=` inside loops (66 sites in wap/ outside theory): all single-pass builders of short lists; none
  measured. The list<int> byte folds named in the gc-half-of-self-compile card (emitter, open_type) stay with that card.
- Interned fact names, map over Range, fact_of index, with_fact copies: already measured or parked on that card.

## Path keys

Read-only scan, 2026-11-27: where one file's path becomes a key or is compared, and which spelling it needs.

**What is normalized now.** `normalized_path` (core/paths.wap:24) is lexical only: it drops `.` and empty parts and
folds `..`, but never makes a relative path absolute, so `wap/types/x.wap` and `/Users/…/wap/types/x.wap` stay two
keys. It is applied in `beside` (paths.wap:6), `in_folder` (pipeline.wap:66), `module_key` (pipeline.wap:190),
`library_places` (paths.wap:21), `named_in` (declarations.wap:106) and `modules_used`'s first entry (declarations.wap:128).
Paths that enter without it: the program argument (`given#1`, compiler.wap) and `program.folder`
(types/system.wap:130, absolute: `folder_of(absolute_path(arguments()#1))`) against a program argument that may be
relative. With a relative program and the absolute `program.folder`, the types module (declared from `program.folder`) and
the files the program names (beside the program's own spelling) are the same files under two spellings.

**The one function.** Make `normalized_path` itself root a relative path at the current folder
(`normalized_path(absolute_path(path))`, types/system.wap:133; `absolute_path` keeps links, `real_path` is the
link-following one the host needs only for opening) and name it the single spelling of a file: every key below then
gets it through `beside`/`in_folder`/`module_key`, which already call it. Then give the two entry points the same
call so no raw spelling starts a compile: `program.folder` (system.wap:130) and the program file (`given#1…#3`,
compiler.wap:76-150, `file` in `compiled`/`formatted`/`called_beside`). Net about +1 line in paths.wap, +2 at entries.
If the types module must stay free of core, the alternative is one `file_key(path)` in core/paths.wap that calls
`absolute_path` and replaces `module_key` (pipeline.wap:190, one-line wrapper today) and the raw uses below.

**Keys and comparisons that take a raw spelling** (each should read `normalized_path(file)` or be fed only
normalized files; the first four are the likely cause of text_bytes declared twice):
- core/pipeline.wap:240 `library_around`: `module.file == types.file`. The types module gets its
  spelling from `in_folder(program.folder, …)`; a module reached through the program's own spelling does not match, so
  the types module's declarations are put around it again.
- core/pipeline.wap:269-271 `typed_modules`: `library_place(modules.last.file) == library_place(types.file)` is a
  second normalization (strips down to the folder holding the types file, which does `exists` calls) beside module_key;
  and `module.file in held` (:271) compares raw files of `used_modules(language, types.code)` with the program's modules.
  Same file, two spellings: not in `held`, so the types module's own files are prepared a second time.
- core/pipeline.wap:228 `file_of(name) == module.file` and :219 `file in standard_sources(name)`, :212 `file in
  standard_sources(name)`: raw `==`/`in` on files from `warm`'s standard entry (strings stored by `marked`) against
  files of this compile.
- core/analyze/declarations.wap:177 `module_of`: `module.file == file` (raw), and :134 `reached.files.contains(file)`
  (normalized only for the first file, :128, the others through `beside`, which does not root them).
- core/pipeline.wap:41, 47-49, 72, 79-80, 100, 112-121, 129-146, `language.operated/grammars/unparsed[file]`: all keyed
  by the raw `file` of the caller. warm.wap:40-48 packs those keys, `marked` (warm.wap:117) strips the wap-folder
  prefix by `starts_with(in_folder(wap_folder, "") + "/")`, so a state written from one spelling is not found under
  another (`unmarked`, :120). `warm_state`'s `file in placed` (warm.wap:42) and compiler.wap:140-144's
  `file in common` compare raw keys the same way.
- core/pipeline.wap:207 `language.lowered[module_key(module.file)]` and warm.wap:52/111: normalized key stored,
  but warm.wap:111 `lowered_brought` stores the text of the state's entry as is: it must go through `module_key`.
- core/stage.wap:189-191 `file_number` / core/errors.wap:31, 43 `sources_read[file]`, written at pipeline.wap:85 with
  the raw file: one source read under two spellings is numbered twice, so definer ids (`file#n`) differ per spelling.
  warm.wap `<numbers>` entry carries the same keys.
- core/emit/functions.wap:147 and core/emit/emitter.wap:184 `file_of(defined_name(…)) == p.source` / `!= p.source`:
  `p.source` is the emitted file as `emitted(program, file, …)` got it (compiler.wap:`emitted(typed, file, …)`), the
  node fact is the spelling the reader was given. A mismatch makes `own` and `in_place` wrong: the program's functions
  counted as library, or inversely, so library bodies are emitted for the program.
- core/analyze/variables.wap:59 `file_of(outer.definer) == file_of(place)`: both facts come from one reader, so equal
  when the file is one; two spellings of one file give a false "other file".
- core/analyze/modules.wap:23 `modules_found(name, file) == [normalized_path(module)]`: only one side normalized
  (the other side `named_in` is normalized lexically too, so it matches only when both are rooted alike).
- core/analyze/declarations.wap:85 `source != normalized_path(file)`: the using file itself excluded from `use folder`,
  by lexical normalization; fails when the using file is spelled relative and `beside` came out absolute or the reverse.
- compiler.wap:122-130 `called_beside`: `name != file_name(file)` and `used_files(...).contains(in_folder(folder, …))` match
  by last name and by the same two spellings.
- core/paths.wap:8-12 `placed_files` / `in_place`: matched by `ends_with("/" + end)`, so spelling-proof by
  construction, but applied after `normalized_path` only in `beside`; the program argument and `in_folder` paths skip
  it. warm.wap:87 reads `placed_files is not empty` once: a build with the files placed brings them in by the state's
  own spelling.
- extensions/wasm/modules.wap:43-52, 119 `held_modules[path]`, `inside.contains(written)`, `carried.contains(path)`:
  keyed by the path a module's `use` wrote, raw.
- extensions/native/run.wap:290 a second `beside(path, name)` (no normalization, no in_place) next to core/paths.wap:6:
  name clash between layers; native/linking.wap:56-57, 167 (`linked.path == path`) and programs.wap:63 use it and compare raw
  paths, so one file reached as `./a.wasm` and `a.wasm` is linked twice. It should call the core `beside`.

**Check without building.** Compare `language.operated.keys` (compiler.wap:140) printed from a relative and an absolute
run: any two keys ending the same way show the doubled files; a run (not made here) of the seed refresh with the keys
logged would tell whether the doubling is at :240/:271 or at the warm-state keys.
