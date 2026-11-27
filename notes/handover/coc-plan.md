# Dependent types: the design authority's handover (2026-11-24)

Session wap-coc-plan held the design of notes/coc-plan.md, reviewed every theory branch and built terms, levels, the
environment, typing and the elaborator's holes and unification. It is retired; wap-supervisor holds the design, the
reviews and the board (notes/agents/supervisor.md). Three notes carry the design: notes/coc-plan.md (the plan and
the user's decisions, section 13), notes/theory.md (the contract between the kernel's files) and notes/elaborate.md
(holes and unification, core/analyze/holes.wap and unify.wap).

## Branches and worktrees of this session

| branch | worktree | state |
|---|---|---|
| `coc-plan` | /Volumes/Worktrees/coc-plan | the three notes and this handover; handed to wap-integrator after each change |
| `theory-arguments-found` | /Volumes/Worktrees/theory-arguments-found | pattern unification, unfinished, pushed: see below |
| `theory-structures-typing` (local only, 6e960b0a) | none | stale: a merge with an old theory-numbers that was never pushed. Its work landed through 078a0a5a. Never push it; it goes with the branch cleanup the user runs |

The probe of the unifier, terms built by hand, 23 lines: ~/Library/Logs/warp/theory-arguments-found/holes_probe.wap.
The installed seed cannot compile a theory file until its lib holds `magnitude`; compile the probe with the tree's
compiler (`wap data/wap-tests/wap1-<hash>/wap1.wasm probe.wap out.wasm`, then `wap out.wasm`), which
test/wap/test_hello.sh builds.

## Who builds what

| part | file | builder | state |
|---|---|---|---|
| terms, levels, environment, typing | terms.wap, levels.wap, environment.wap, typing.wap | this session | on main, the projection's rule too |
| computing, recursors, iota, K, quotients | compute.wap, recursors.wap, quotients.wap, prelude/quotient.wap | wap-emitter | on main, reviewed: sound |
| equality | equal.wap | wap-fixer | on main; K4's rules on theory-structures 873ff633, review owed (below) |
| inductive checks, nested types | inductive.wap, nested.wap | wap-binding | on main, reviewed twice: right |
| numbers | lib/magnitude.wap, numbers.wap | wap-simplifier | on main, reviewed: sound |
| the door | explicit.wap, show.wap, check.wap, test/wap/test_theory.wap | wap-reader | on main: enum blocks, `axioms of`, `projection(S, k, t)`, the binding statements |
| the logic | prelude/logic.wap and its test | wap-wiki-tidy | on main; theory-prelude-logic 6de978dd fixes the test's last red line |
| pages | wiki: universe, proposition, subtype, type, proof, quotient, enum's recursor | wap-wiki-tidy | on the wiki |
| the elaborator's holes and unification | elaborate/state.wap, unify.wap | this session | on main as first built; the pattern rule on theory-arguments-found |
| the elaborator's reader | elaborate/read.wap, declare.wap | wap-binding | on main |
| the elaborator's door, `law` and `axiom` | elaborate/door.wap, wap/sugar/definitions.wap | wap-reader | to build |
| `->` is the function type everywhere | wap/core/rules/lowering.wap, card function-value-wiki | wap-wiki-tidy | assigned |

## The pattern unification, unfinished (theory-arguments-found a55d883e)

notes/elaborate.md "Holes" is its contract. Built and probed (23 lines green on the merged tip, test_hello green,
compiler-growth 0): a hole is a function of the binders in scope (`scoped`, `unscoped`, `named`, `hole`,
`hole_over` in state.wap); `filled` puts an answer's body in and goes under a binder by a free variable; unify.wap
answers a hole applied to distinct binder variables by the function of them (`function_answered`), keeps eta
(`eta_made`), and puts off what cannot be answered yet (`hole_made_equal`); `answered` refuses an answer that names
a binder; going back restores the scope.

Left, and the branch must not land before it: read.wap and declare.wap (wap-binding's) still go into binders by
`hypothesis(x.el.c, …)` and keep their own `x.scope`. With the new rule every answer that names such a binder is
refused, so the reader refuses most programs until it is switched:
- `gone_into` (read.wap): `variable = scoped(x.el, binder.name, domain)`, no `x.scope`;
- `name_elaborated`: the binder of a name is `named(x.el, name)`;
- a letter: `scoped(x.el, name, type)`, its type's hole by `hole_over(x.el, …, the letters' variables)`; `x.letters`
  stays as the list of their variables, for the order of the definition's binders (declare.wap);
- `bound_elaborated`: `unscoped(x.el, variables)` where it cut `x.scope`;
- then its probe door (data/elaborate/door.wap in wap-binding's worktree) says what it said before, and
  "fill before closing" in `bound_over` is no longer needed for rightness.

Delicate points:
- **One test for scope.** An answer names no binder variable; only parameters of its own function and other holes.
  No order of ids is asked any more. This is what keeps a variable inside its binder, also through a second hole:
  `?a` against `?b(x)` cannot take `?b(x)`, so `?b` is answered by the function that ignores x.
- **A pattern is a hole applied to distinct binder variables.** After a function is applied to a value, `?h(3)` is
  no pattern and waits. Nothing guesses the constant function, and `?F(?A)` against `list(int)` is not taken apart
  (notes/elaborate.md).
- **Waiting says yes.** A problem put off counts as solved until an answer makes it fail; then that answer is
  refused. What still waits at the end of a declaration is judged by the kernel, which checks the filled term
  whole.
- **`filled` makes hypotheses.** Going under a binder by a free variable adds a hypothesis to the checker each
  time. It is right and it is not cheap; if elaboration is slow, this is the first place to measure.
- **The kernel never sees an answer.** To typing and computing a hole is a variable, so what they keep of a term
  with holes stays true after the hole is answered, and only a "yes" may be kept of an equality.
- A reading that fails halfway (an overload tried) leaves binders in scope: `back_to` restores them, which
  read.wap's own `x.scope` never did.

## Reviews owed

- **theory-structures 873ff633 (wap-fixer, K4's equality)**: read once, not reviewed. It follows plan 6.5: proofs
  before the unfolding loop; after it a number opened, eta, eta for structures, unit, each both ways; pairs found
  equal kept. Sound on that reading: only a "yes" is kept; eta for structures asks all parameters and fields, equal
  types, and each field against `projection(of, at, other)`; a proof structure never reaches it, since proofs are
  compared first. To check: (1) `proofs_equal` calls `type_of`, which checks its term again and is kept for closed
  terms only, so equality under a binder types both sides at every call: keep open terms too in typing.wap's
  `type_of` and compute.wap's heads (drop the `holds_free` test). That is sound, an id is given once and a
  hypothesis's type is fixed, and it answers wap-fixer's question on cost. (2) a term that is not well typed makes
  `type_of` refuse inside `equal`, where `equal` said no before: never a wrong yes.
- **K4's computing is not built**: compute.wap has no rule for a projection, and iota does not take a structure
  value apart by its projections (notes/theory.md, compute.wap). Until then `projection(Pair, 1, Pair.make(…))`
  does not compute. It was to be wap-emitter's.
- **The projection's typing has no test line.** `not a structure` and `data out of a proof` are probed by hand only.
  The door reads `projection(S, k, t)` now, so the lines of plan 11 (K4: the witness of an `exists` is not
  projected) can be written in test/wap/test_theory.wap.
- read.wap and declare.wap landed without a review of mine; the scope left behind by a failed overload try is the
  one defect I saw.
- Not read again after their fixes: theory-door-enums (890c1302 fixed the three points asked), theory-numbers as
  it landed (asked: use inductive.wap's `block_of`, `block_shaped`, `equality_checked`; iota opens a number).

## Questions in flight

| question | with | my answer |
|---|---|---|
| the form `law` and `axiom` reach the elaborator in | wap-reader | the word's call on the lowered definition, two rules in wap/sugar/definitions.wap, 0 core lines; facts on the Define need core lines and go to the user first |
| `->` where a value stands | wap-wiki-tidy, card function-value-wiki | the wiki decided: `=>` is the one lambda arrow; lowering's FUNCTION_ARROWS loses `->`, the stale line test_functions_calls.wap:66 goes |
| `f == g` and `===` on wiki/equality.md | wap-wiki-tidy | the user's decision of 2026-11-24, plan section 13; the page's old TODO becomes DONE |
| open terms in the typing and computing caches | wap-fixer | yes, see above |
| one place that reads a head constant's kind | wap-emitter | iota, the quotient step and the opening of a number belong in one match on the declaration's kind; smaller, one lookup less |
| the green `_wanted` files (numbers, recursors, quotients, logic) | their owners | each owner renames its file once it is green on main |
| W0 and `wap verify`; the words | the user, through wap-interviewer | plan section 13, open |

## What is decided and where

The user's decisions are in notes/coc-plan.md section 13. The rules every kernel file keeps are in notes/theory.md,
those of holes and unification in notes/elaborate.md. Not written elsewhere:
- A block's types, cases and recursors each rest on the axioms their own type names. Inside a mutual block a case
  is recorded before a later type of the block; no program was found where that loses an axiom, since a case that
  names the type also writes its indices' types.
- K7, the second opinion, has no export format yet. It needs one before any checker can read it.
