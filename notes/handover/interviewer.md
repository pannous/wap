# Interviewer handover (2026-11-23, fleet restart)

Role file: warp repo notes/agents/interviewer.md. The morning queue is warp repo notes/open_decisions.md
("## Pending", newest first): ask it with AskUserQuestion popups, 4 per batch. The user wants multiple-choice
popups, not prose lists ("I don't see the multiple choice questions"); re-ask with plain input → result when the
user says they don't understand.

## Standing user rules from 11-22
- Core and extension changes: discussed with the user first (shape, core lines, case against, why no hook/lib).
  Never OK one yourself (AGENTS.md "Core and extensions"). A user-approved change may land at night.
- Pure shrinks (fewer core lines, no new form or behaviour, reviewer-approved) land without discussion; list them
  for the user afterwards ("## Shrinks landed").
- At night core growth waits, built and measured, for the morning (night.md).
- 11-22 evening direction: no new features; harden the architecture and pay debt; real library work starts 11-23.
  `x not in xs` is rewritten as `not x in xs`, with no new form.
- Board: agents may add cards again (ban lifted 11-22). Warp is frozen; all cards live on the wap board (projects/10).

## Mid-discussion (all in the Pending queue with counts)
- any-char-equality: option (a) refusal (~+30 nodes) vs (b) item-wise == through anys (+126 nodes, core +10 −5,
  tip 4a2b3ba). The bare fix alone gives a wrong value, so never land it alone.
- dispatch-rounds +10 nodes (the reviewer's condition on any-values).
- module-functions-held, ready: compiler 4.3% smaller, speed equal, core +12 −2.
- any-name-silent +2 core (a name written `any` retypes silently).
- warn-rule-impossible: the approved `=> warn` rule cannot see a literal's content. Recommend (a), a run-time hint
  once per run, lib only.
- untyped-map-any: `{}` is map<any, any>, 2 tokens + 1 changed core line.
- uniform-lists card: explain it to the user (they asked).
- native-text-match: core equality bug, size not measured.

## To confirm with the user
- library-embedded: a compiled module names the library by an absolute path, so it is not portable to another machine.

## Landed 11-22 on the user's OK (try lines were run and shown)
one-memory, wap-help, any-values (+ twice { 4 }), any-char-is-text, retype-message, operator heads + free glyphs,
native hooks (core −11 lines, +245 nodes), map print, library-embedded, the line editor (1594 → 1300 nodes).
