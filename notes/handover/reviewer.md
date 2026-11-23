# Reviewer handover (2026-11-23)

Role: notes/agents/reviewer.md rules, applied to pannous/wap. Log: ~/Library/Logs/warp/reviews/2026-11-22.md.

## Last reviewed
- wap main up to d00b034 (library-embedded 1b09da9 included). Start the next review at `git log --first-parent d00b034..origin/main`.

## Open review points (sent, not yet on main)
- library-embedded 1b09da9 (via warp-supervisor, owner unknown):
  1. linked_name() hashes the whole embedded library on every call: a constant of the compiler, hash it once.
  2. modules link the library by its absolute path; moving the compiler folder breaks older modules: write the trade-off down.
  3. 250a8ad (user) dropped the declarations.wap DEBT on module cycles (a top-level read of the other module's value
     before it is set) with no code or test: pin it with a two-module test, or bring the DEBT back.
- native-hooks 365233e (card native-hooks, owner warp-wap-lang): stale "core/stage.wap MemoryLayout" references
  (the class is core/emit/memory.wap); built_by's text keys → list_words / record_words fields.
- native-plain-enum follow-ups (on that card, warp-fixer; wait for the user's discussion): refuse an enum case with
  fields natively; refuse a native optional of a memory value (box index -1 today); writing_function takes a memory text;
  native `print [1, 2]` emits a GC type.
- overload-lib 90eb4a2: text joins only int (a general `+(t: text, x: T)` pair would cover float/char/bool); the
  digit hint is a run-time eprint (once per run), better at compile time for literals.
- waiting in the user's morning queue, already reviewed sound: any-name-silent d2f6259 (written `any` retypes
  silently), dispatch-rounds f3ba13f (boxed_known once a round + DEBT for precompiled-module dispatchers).
- simplify-28 parked until card enum-index-constant-time (enum ↔ int via sugar's indexed rule builds a list per call).

## Logged, not sent
- map-print fbce670: text(m) looks up m#key per key (quadratic for non-text keys).
- lib-coverage: cumulative_sum lost scan() for a hand loop.

## Architecture (user 11-22)
Libraries should not write their own extensions: 126 rules in lib/ stand in for missing features (block
parameters, lazy parameters, labelled phrase calls, call-site names, names from the expected type, overloadable
as/in/juxtaposition, observable places, member hook, definition annotations, tasks as a compiler mechanism).
native-hooks and any-values' block arguments provide two of them.
