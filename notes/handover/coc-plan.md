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
| inductive checks, nested types | inductive.wap, nested.wap | wap-binding | on main, reviewed twice: right |
| the door | show.wap, explicit.wap, check.wap, test/wap/test_theory.wap | wap-reader | handed to the integrator (5f5072a6, 13 lines green); enum statements, the binding statements and number literals come next, `shown_for` asked |
| recursors, iota, K | recursors.wap, compute.wap | wap-emitter | reviewed: right after one fix (1a00016b), landing |
| numbers | lib/magnitude.wap, numbers.wap | wap-simplifier | reviewed: sound (234fb1e6); owes iota opening a number, after the recursors land |
| the logic | prelude/logic.wap, test/wap/test_theory_logic.wap | wap-wiki-tidy | on main, red until the door reads enums |
| pages | wiki: universe, proposition, subtype, type, proof, quotient, enum's recursor | wap-wiki-tidy | on the wiki |
| the elaborator's holes and unification | elaborate/state.wap, unify.wap | this session | built (theory-arguments-found, 17 probe lines); read.wap and declare.wap are wap-binding's, the door wap-reader's |

## Decided by the user (2026-11-24)

Retyping is rebinding, with the union where paths meet. The theory's refusal tests pin `refused by <rule>` only.
The six open decisions of the plan's section 13 are with wap-interviewer.

## Owed by this session

- Review each theory branch as it is pushed: the door's next parts, then K4 (structures, wap-fixer), K5
  (quotients, wap-emitter), and the elaborator's files as they come (notes/elaborate.md is their contract).
- typing.wap, this session's file: the projection's rule with its narrowing for proofs (plan 6.3, K4); its refusals
  through `shown_for` once show.wap has it; "1 level".
- Keep the plan true: what a review or a decision changes goes into notes/coc-plan.md at once.
