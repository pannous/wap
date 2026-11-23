# Reviewer taste: which wording catches round-spaced-list (2026-11-23)

Task: notes/reviewer-taste-task.md. The specimen is merge 013faf9 (round-spaced-list). Its `measured()` reads exactly two
spaced items, a number and a word, as a measure, so `(1 x)` is `1 * x` while `(1 2 x)` is a list. The user's target:
implicit multiplication only when glued (`2x`, `5m`), spaced items always a list, and nothing for units in core: the
unit library overloads `*(n: number, u: Unit)` and the glued product uses it.

## Harness
`data/reviewer-taste/` (ignored). `run.sh <variant> <diff> <model> <n>` runs one headless review: `claude -p`, the variant
appended as system prompt, tools Read/Grep/Glob only, cwd a worktree detached at 013faf9 (AGENTS.md as of the
landing). `judge.sh` scores one review with sonnet, and `score.sh` judges every unscored run and prints the table.
- **a**: flags the two-item number-word reading as a special case.
- **b**: says units need nothing special in core.
- **c**: proposes glued-only multiplication plus a `*(number, Unit)` overload, not a typed `number word` rule.
- **wolf**: on a clean diff, raises a special-case or misconception finding.

Three judge scores were checked by hand against the reviews; they hold.

## Results (specimen; a/b/c = runs that hit, out of 3)
| variant | model | a | b | c |
|---|---|---|---|---|
| v0 current reviewer.md | haiku | 1 | 0 | 0 |
| v1 + "count or position decides → special case" | haiku | 1 | 0 | 0 |
| v2 + "domain words in core → missing mechanism" | haiku | 0 | 0 | 0 |
| v3 + "would an existing mechanism give this?" | haiku | 0 | 0 | 0 |
| v4 + "name the general rule for each special case" | haiku | 0 | 0 | 0 |
| v5 three-question checklist | haiku | 0 | 0 | 0 |
| v6 taste preamble | haiku | 3 | 0 | 0 |
| v0 current reviewer.md | opus | 2 | 1 | 0 |
| v2 domain line | opus | 1 | 1 | 0 |
| v3 mechanism line | opus | 3 | 0 | 0 |
| v6 preamble | opus | 2 | 2 | 0 |
| v7 preamble + domain + mechanism | opus | 3 | 1 | 0 |
| v8 + "an exception kept for an old reading goes" | opus | 1 | 1 | 0 |
| v9 v7 + exception line | opus | 2 | 2 | 0 |
| v11 v0 + exception + question-the-spec (generic) | opus | 2 | 1 | 0 |
| v12 v9 + question-the-spec, no mechanism names | opus | 3 | 2 | 1 |
| **v10 v9 + question-the-spec "(glued, an overload)"** | opus | **3** | **3** | **3** |

## Findings
- Haiku screens nothing useful: it reviews the hunk's arity details and `is_value`, whatever the wording. Only the
  preamble moved it (a 3/3). The reviewer's model, opus, is the one to tune.
- Without new wording, opus flags the count rule two times in three, and then proposes exactly the fix the user
  rejected. Every flagging run goes the same way: a typed `[number, Unit]` rule in the unit library, the
  `parted_map` → `parted_rewritten` precedent right beside the hunk. Two things anchor it there. The precedent is
  one. The other is that the wiki promised the special case: wiki/unit.md:17 and number.md:82 say "only a unit
  multiplies when spaced (`5 m` is 5m)". The reviewer followed the spec.
- So taste lines alone (count, domain, mechanism, exception) reach a and b but never c. Reaching c also takes the
  line that a wiki promise needing a special case is questioned, not built. And the mechanisms to fall back on have
  to be named: without "(glued, an overload)" c drops to 1/3. Those two words are the language's general
  mechanisms, not this specimen's answer, but a sharper probe (a second specimen whose fix is a different
  mechanism) would show whether they overfit.
- False-positive control, one opus run per clean landed merge. The diffs are c8c60ea spread-only, 4252daf
  byte-count-fix and f217dce template-parameters. A wolf is a special-case or misconception finding.

  | variant | wolf, of 3 diffs | note |
  |---|---|---|
  | v0 current | 2 | |
  | v9 | 2 | |
  | v10 | 1 | gave c8c60ea "nothing" |

  The f217dce finding (a second binding path where name lookup is the fault) looks like a fair improvement in all
  three, not a false alarm. The new wording does not make the reviewer cry wolf.
- Caveat: the runs could Read the main checkout too (wiki/ lives only there). No review cites the task file, the
  card or today's notes, but reads are not logged.

## Proposed reviewer.md change (v10, the heading kept)
After `# Reviewer`, a first line:
> Taste first: the best change is often a deletion. A branch that makes the same spelling mean two things, by count
> or by what word follows, is ugly however well it is tested; find the existing mechanism that already says it and
> ask for the branch to go.

At the end, a section:
> ## Taste
> - Domain meaning handled in core (units, keys, colors, any one library's words) is a missing mechanism: name the
>   library-side mechanism (an overload, a type) that removes it.
> - For every new branch or condition ask: would a mechanism the language already has (a glued form, an operator
>   overload, a library type) give this without the branch? If yes, the branch goes.
> - A new general rule that keeps an exception for an old reading: the exception goes. The old meaning survives in a
>   spelling an existing mechanism already gives (another written form, an overload in the library), never in a new
>   rule that brings the exception back.
> - A wiki promise that needs a special case is questioned, not built: recommend to wap-interviewer the spelling the
>   general rules already give (glued, an overload), with old and new wiki text.

That is 5 lines and about 140 words on an 84-line file. Budget used: 21 haiku and 39 opus reviews, plus a sonnet
judgement for each.
