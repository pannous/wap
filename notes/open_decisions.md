# Open decisions for the user

Shapes waiting for the user's discussion, each with its core lines, the case against, and why no hook or library
does it. Line counts are estimates from reading the code, marked as such; the measured size comes with the branch.
An entry goes once decided (its decision then lives on its card, in the wiki or notes/debts.md).

## The top debts still open (notes/debts.md); the "5" + 3 warning is parked (card digit-text-compile-warning)

## Pending questions

- wap-emitter: a C import clash is refused (A, about +3 core host.wap); a block argument with a defaulted
  parameter is run instead of passed ("no run takes (ø)").
- wap-fixer: a standard-module word refused across feeds/random (drop the refusal at standard bind, ±3 core);
  indexing an any parameter gives an internal error (recommend a clear refusal); `try` of value ø (recommend
  refuse).
- wap-native-maps: +2 analyze for native maps (a); wap-headless `--no-window` returning (a, +33 extension).
- Template typing: any joins every type, (a) 3-5 core.
- List positions from 1 in lib/list.wap (wap-reviewer, library-port-rest).
- funcref-calls-by-table: function values called through one shared table slot instead of a funcref (self compile −8.4%); built dbb342af: core/emit +6, kernel +3, extensions/native +1, +99 nodes, all checks green; morning, recommend yes. Signatures sharing one wasm type is an edge case, accepted (interviewer).
- class-spaces-wap: format writes one-line braces spaced `{ a: 1 }` (A, +2 core, ~10 test expectations in test_reader/test_operators rewritten: needs the user's test grant) or tight (B, 0 core, 312 class lines reformatted); morning, recommend A.
- import paths from the output folder: a module compiled with a relative compiler path imports its library by a path the runner can't find; (a) imports name the library by the path from the module's own folder, +9 core (path_from moves to types after a seed refresh, ~+2 left); (c) leave it, an absolute compiler path works; morning, recommend (a).
- extensions growth unused by any library (about 3,600 lines in 24 h, 93% in extensions/theory and extensions/prove; only tests and `wap verify` reach it); removing parts deletes tests, so the user's OK: (a) remove what the plan already retires: elaborate/lifted.wap and the run door (lower.wap, terms.wap) with test_theory_lifted.wap and test_theory_run.wap, −231 now (−361 with the T6 port budget), core 0; (b) also the linear, induction and apart provers (−544) with test_theory_arithmetic.wap, bounds stay run-time checks; (c) keep all until T7. Report: data/extensions-audit/report.md. Morning, recommend (a).
