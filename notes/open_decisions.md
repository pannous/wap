# Open decisions for the user

Shapes waiting for the user's discussion, each with its core lines, the case against, and why no hook or library
does it. Line counts are estimates from reading the code, marked as such; the measured size comes with the branch.
An entry goes once decided (its decision then lives on its card, in the wiki or notes/debts.md).

## The top debts still open (notes/debts.md); the "5" + 3 warning is parked (card digit-text-compile-warning)

## Parked by the user (to discuss later)

- Traits: `class Job { act: () -> int }` (function fields only) is read as a trait today, so `show(Job(…))`
  recurses until the stack runs out (timers library). warp declared traits only by trait/protocol/interface,
  structural conformance for those; a class of function fields stayed a class. Recommend: the same (0 core,
  a port of warp's extensions/protocols.warp).

## Pending questions

- wap-emitter: a C import clash is refused (A, about +3 core host.wap); a block argument with a defaulted
  parameter is run instead of passed ("no run takes (ø)").
- wap-fixer: a standard-module word refused across feeds/random (drop the refusal at standard bind, ±3 core);
  indexing an any parameter gives an internal error (recommend a clear refusal); `try` of value ø (recommend
  refuse); native-function-values A/B/C.
- wap-native-maps: +2 analyze for native maps (a); wap-headless `--no-window` returning (a, +33 extension).
- Template typing: any joins every type, (a) 3-5 core.
- List positions from 1 in lib/list.wap (wap-reviewer, library-port-rest).
- The cli.md lines for `wap format` (lint), `wap fix` (lint + structural suggestions), `wap optimize` (strip
  unused), from wap-reader / wap-simplifier.
- Cleanup: the merged wiki branch `wiki-tidy` (local in /Volumes/Worktrees/wap-wiki and remote); the hook refuses
  agents' branch deletes.

## To present (keep or change)

- template-shape: the approved "normalize templates at declare" wasn't needed. The fix is +2 lines in
  core/rules/matcher.wap: a form pattern `rule q ($a + $b)` now fits the program's grouped `q (x + 1)`, while an
  argument group `f(x + 1)` stays a group. `m() as T := body` now uses the same rule as `m(): T := body`.
- one-primitive-table (night decision): the emitter keeps its if-chain for primitives; the one-table refactor cost
  +181 nodes, so it was dropped. Undo: land branch one-primitive-table-2 26bf51c7 and raise the ceiling.
- previous-line (night decision; extension growth, lands after the morning OK): in the console `f(x: int) := 1`
  then `f(x: int) := 2` makes later lines call the new f (about 5 lines in extensions/native/console.wap); today it
  is refused with the console's internal file names. Undo: keep the refusal, worded without those names.
