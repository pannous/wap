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
- map-pair-loop b4af8ab8 (wap-reader), +7 core (rules/stages, parse/operators, parse/keys), +266 nodes:
  `for key, value in scores { … }` walks a map's keys with their values (wiki/inventions.md "Typed iteration").
  Plain wap can't parse the two-name head. Recommend: yes. Reviewer verdict: asked 2026-11-24.
- glued-block-head 342e6405 (wap-reader), +6 core (rules/matcher.wap): `class Point{x: int}` with the brace glued
  declares the class, as wiki/pattern-matching.md and type.md write it. General: when a list's parts don't fit, the
  matcher retries with the glued block split into head and block (class, enum, trait, match). Option: write only
  `class Point {…}` in the wiki (0 core). Recommend: the matcher retry. Reviewer verdict: asked 2026-11-24.

## To present (keep or change, at 10:00)

- template-shape: the approved "normalize templates at declare" wasn't needed. The fix is +2 lines in
  core/rules/matcher.wap: a form pattern `rule q ($a + $b)` now fits the program's grouped `q (x + 1)`, while an
  argument group `f(x + 1)` stays a group. `m() as T := body` now uses the same rule as `m(): T := body`.
