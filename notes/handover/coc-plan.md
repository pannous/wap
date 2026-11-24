# Dependent types: the design authority's handover (2026-11-24)

Session wap-coc-plan. The user ordered the fleet to build notes/coc-plan.md; wap-supervisor owns the board and the
assignments (topic `dependent-types`, one card per milestone, keys `theory-…`). This session is the design
authority: it keeps notes/coc-plan.md (the plan) and notes/theory.md (the contract between the kernel's files),
answers design questions, reviews every theory branch, and built terms, levels, the environment and typing.

Worktrees: /Volumes/Worktrees/coc-plan (branch coc-plan: the two notes, handed to wap-integrator after each
change, the branch is kept) and /Volumes/Worktrees/theory-typing (landed; it holds an uncommitted stand-in
wap/extensions/theory/show.wap for probes, which theory-explicit's file replaces). Probes of the kernel are throwaway
programs in the session scratchpad that build terms by hand.

## Who builds what

| part | file | builder | state |
|---|---|---|---|
| K0 measurements | notes/theory.md "Costs" | wap-simplifier | done |
| terms, levels, environment | terms.wap, levels.wap, environment.wap | this session | on main |
| computing | compute.wap | wap-emitter | on main, reviewed: right |
| equality | equal.wap | wap-fixer | on main, reviewed: sound; asked to compare heads without unfolding |
| typing, declarations | typing.wap | this session | on main (35 probe lines) |
| inductive checks | inductive.wap | wap-binding | on main, reviewed: right; asked for rests_on, binders as written, `is ø` |
| the door | show.wap, explicit.wap, check.wap, test/wap/test_theory.wap | wap-reader | building; every kept test waits on it |
| recursors, iota, K | recursors.wap, compute.wap | wap-emitter | building to the shape sent 2026-11-24 |
| numbers | lib/magnitude.wap, numbers.wap | wap-simplifier | building; statements in notes/theory.md |
| the logic | prelude/logic.wap, test/wap/test_theory_logic.wap | wap-wiki-tidy | on main, red until the door and K2 |
| pages | wiki: universe, proposition, subtype, type, proof, quotient, enum's recursor | wap-wiki-tidy | on the wiki |

## Decided by the user (2026-11-24)

Retyping is rebinding, with the union where paths meet. The theory's refusal tests pin `refused by <rule>` only.
The six open decisions of the plan's section 13 are with wap-interviewer.

## Owed by this session

- Review each theory branch as it is pushed: the door, recursors, numbers, then K4 (structures: the projection's
  typing rule goes into typing.wap), K5 (quotients), K6 (nested).
- The elaborator's contract, notes/elaborate.md, before E1 and E2 are handed out: its files, its state (holes and
  their answers), how it is reached (the door first, beside today's typing at S1), and the order of its rules.
- Keep the plan true: what a review or a decision changes goes into notes/coc-plan.md at once.
