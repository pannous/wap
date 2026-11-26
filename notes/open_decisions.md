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
- import paths from the output folder: a module compiled with a relative compiler path imports its library by a path the runner can't find; (a) built on relative-compiler-library-path c3d42937: a relative import path is rewritten to hold from the folder of the module being written, a path from the root stays; +13 net core code (+6 comment) in core/paths.wap, core/emit/wasm.wap, core/emit/emitter.wap; about −10 after the next seed refresh moves path_from and rooted to types/host.wap (net ~+3); modules, cli, os, files 110 ✓, test_self 95 ✓; (c) leave it, an absolute compiler path works; morning, recommend (a).
- extensions growth unused by any library (about 3,600 lines in 24 h, 93% in extensions/theory and extensions/prove; only tests and `wap verify` reach it); removing parts deletes tests, so the user's OK: (a) remove what the plan already retires: elaborate/lifted.wap and the run door (lower.wap, terms.wap) with test_theory_lifted.wap and test_theory_run.wap, −231 now (−361 with the T6 port budget), core 0; (b) also the linear, induction and apart provers (−544) with test_theory_arithmetic.wap, bounds stay run-time checks; (c) keep all until T7. Report: data/extensions-audit/report.md. Morning, recommend (a).
- use bundles: wiki/sound.md promises `use music` and `use audio` are other names of `use sound`, but a `use` passes on only operators, rules and aliases, so `use music; midi(A4)` works only through the standard-module fallback, with a hint to write `use sound`; (A) a module that declares nothing and only uses others is a bundle: using it gives what they give, core/pipeline.wap +4 net (+2 comment), branch use-bundles (prints 69 and 523.25, no hint), uses: lib/music.wap, lib/audio.wap, wap/extensions/rules.wap, a future graphics umbrella; (B) the sound page drops the alias promise, music/audio go (spec change, 0 core); (C) leave it with the misleading hint; morning, recommend (A).
- class setters (signals): writing to a name can't run code of the class it holds, so wiki/signal.md (on change / whenever / once) can't be plain wap: `x = Cell(1); x = 5` rebinds x to an int (or is refused when x: Cell). (A) a class may define `set(c: Cell, v: int)`: `x = v` on a name holding such a record, v not of that class, is that call; core/analyze/types.wap name_set_typed, ~+5 (estimate, not built); uses: signals (lib/signals.wap Signal<T>, on/whenever/once as block-parameter functions), reactive UI state, a debugger's watch; also wiki/property.md setters for fields; (B) no setters, signals stay red. Sub-question: the page writes `x = 0` then `on change x`; (i) the name is declared a signal, `x = signal(0)` (wiki spelling change, 0 core, no action at a distance); (ii) a listener naming x makes x watched (more core, non-local). Morning, recommend (A) with (i).
