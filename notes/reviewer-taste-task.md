# Task: a reviewer whose own taste catches a misguided implementation (wap-reviewer-taste)

Asked by the user 2026-11-23 via wap-interviewer. You are a wap session (AGENTS.md applies); report to
wap-interviewer, questions go there too.

## The specimen
Merge 013faf9 (round-spaced-list, core/rules/lowering.wap +19/-2, test/test_lists_page.wap, test/wap/test_reader.wap):
"values parted by blanks are a list, (1 2) is [1, 2]; a number before a word still measures, 5 m". In it,
measured() reads exactly two items, a number and a word, as a measure: `(1 x)` is 1 * x while `(1 x y)` is a list
and `(1 2 m)` is [1, 2, m]. The reviewer at the time passed it; only later wap-reviewer flagged it (a unit special
case in core lowering, readings decided by item count) and proposed a typed `number word` rule from the unit library.

The user's answer, the target the experiment should reach:
- implicit multiplication only without a space: `2x`, `2m`; `x = 7; 2x == 14` already works by the glued mechanism;
- spaced items are always a list: `(1 x)`, `(1 2 m)`, `5 m`;
- nothing special for units: the unit library overloads `*(n: number, u: Unit)`; the glued product uses it;
- a warning for the spaced variant is welcome, not required.
(Card glued-multiplication-only.)

## What to do
1. Read notes/agents/reviewer.md (the current reviewer role) and AGENTS.md "Principles" (no special cases,
   vocabulary is library, plain wap first, refuse never guess).
2. Build an experiment harness in data/reviewer-taste/ (ignored; scripts you keep go in scripts/ only if reusable):
   a headless `claude -p` run (no tools beyond Read/Bash read-only, `--no-window` irrelevant) given a reviewer prompt
   variant plus the specimen diff (`git show 013faf9^2` against its base, or the branch's diff), asking for a review.
   Run each variant several times (≥3) for noise. Use a cheap model for screening, the reviewer's own model to confirm.
3. Variants: the current reviewer.md; reviewer.md plus single added lines (e.g. "a reading decided by item count or
   position is a special case", "domain words (units, keys, colors) in core are a missing mechanism", "ask: would the
   general mechanism already give this? (glued multiplication + an operator overload)", "for each special case name
   the general rule that makes it unnecessary"); a taste checklist; a short "taste" preamble. Keep every variant small:
   the role file must not bloat.
4. Score each run: (a) flags measured()'s two-item case as a special case / ugly; (b) says units should need nothing
   special in core; (c) proposes glued-only implicit multiplication plus a `*(number, Unit)` overload (the user's
   solution) rather than a typed `number word` rule. Also a control: run the winning variant on 2–3 clean landed diffs
   to check it does not cry wolf.
5. Result: notes/reviews/2026-11-23-reviewer-taste.md with the table (variant × score × runs), the winning wording,
   and the false-positive control. Send wap-interviewer the proposed reviewer.md diff (old → new); the interviewer
   brings it to the user. Do not edit reviewer.md or AGENTS.md yourself.

Budget: keep it small (tens of runs, cheap model first). Commit the note on a branch named reviewer-taste and push it.
