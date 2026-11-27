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
