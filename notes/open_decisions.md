# Open decisions for the user

Shapes waiting for the user's discussion, each with its core lines, the case against, and why no hook or library
does it. Line counts are estimates from reading the code, marked as such; the measured size comes with the branch.
An entry goes once decided (its decision then lives in the wiki or notes/debts.md).

## The top debts still open (notes/debts.md); the "5" + 3 warning is parked (card digit-text-compile-warning)

## Pending questions (ask at 10:00; core growth waits for the morning, notes/agents/night.md)

Built and held by wap-integrator; wap-reviewer sound per integrator; recommendation: OK each. Per entry still to
show the user: the case against and why no library or hook does it (ask the branch owner before 10:00).

- foreign-globals-first 88f7063c, +8 core (core/emit/host.wap): every library global is imported before the
  program's own, so a global imported late no longer renumbers the program's globals (test_modules kept_global).
- valueless-argument 3e46a738, about +5 core: an argument, name or result that gives no value gives ø; a function
  giving nothing, used as a C callback, answers 0.
- is-equal 3b44e172, +3 core (analyze/names.wap): `x is y` with two variables compares their values (wiki/equality.md).
- map-pair-loop ad1794e9 (wap-reader), +7 core (rules/stages, parse/operators, parse/keys): `for key, value in
  scores { … }` walks a map's keys with their values (wiki/inventions.md "Typed iteration"); the rule walks the
  library's `pairs(m)`, so `for i, x in xs` gives a list's places counted from 1 (as xs#1 and index_of do) with its
  items. Plain wap can't parse the two-name head. wap-reviewer's fix is built in. Recommend: yes.
- glued-block-head e85e5478 (wap-reader), +8 core (rules/stages +2, lines +6; matcher unchanged): `class
  Point{x: int}` with the brace glued declares the class, as wiki/pattern-matching.md and type.md write it. Every
  rule is tried on the phrase as written, then once with the glued block split off its end (class, enum, trait,
  match). Option: write only `class Point {…}` in the wiki (0 core). wap-reviewer: sound; its nit is built in.
  Recommend: yes.
- module-alias-preload b739f052 (wap-reader), +13 core (core/language, parse/operator_table, parse/operators,
  pipeline): a file's `alias sin => sine` beats the preload's sin and reaches only that file and the files that use
  it. The user already decided the meaning (the alias wins, scoped); the OK asked is for the core lines. Careful
  checks green. Recommend: OK.
- wap-build e7ebfcb7 (wap-emitter), +12 in extensions/native (driver 9, commands 3): `wap build app.wap` makes a
  native executable `app`; a .wap output name is refused so the source is never overwritten. The user OK'd about
  5 lines via wap-lead; it came to 12 (9 without the refusal). Recommend: OK, with the refusal.

## To present (keep or change, at 10:00)

- template-shape: the approved "normalize templates at declare" wasn't needed. The fix is +2 lines in
  core/rules/matcher.wap: a form pattern `rule q ($a + $b)` now fits the program's grouped `q (x + 1)`, while an
  argument group `f(x + 1)` stays a group. `m() as T := body` now uses the same rule as `m(): T := body`.
