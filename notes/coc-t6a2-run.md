# T6a2: hypotheses in the law run

Handover for the run's skip of a hypothesis binder (notes/coc-t6a12.md "T6a2 on unify: what is left" 1).

1. Reading is not what refuses `law f(a: int, h: a <= 3): P`. Verify's front reads it as `law_f(a: int, h: a <= 3): bool := …`
   and verify/laws.wap `hypotheses_split` then splits it. The run's rules (extensions/law_runs.wap) turn every binder into
   `trial_values() as list<$type>`, and for `h` that type is a statement, which does not type.
2. The run is `compiler laws <program> <module>`, whose only hooks are rules. By the time law_runs' rules fire, a law is
   `law_trials $statement [] [binders…]`, written by sugar (`law f(a, h: …)`) or by law_for.wap (`law name: {for …}`): a
   node pass on the written form covers only the first.
3. A rule cannot tell a statement from a type. Shape decides wrongly: `x: int | text` is an operator call too, and
   `v: vector(n)` mentions an earlier binder as `h: a <= 3` does. A statement is a type whose universe is Prop, which only
   typing knows.

The fix is on the typed route: the run takes its binders from verify's typed hypotheses split, a trial where the
hypothesis computes to no holding trivially (`h implies P`).

## How the run gets the split
`compiler laws` types the law before it builds trials, as verify's `laws_typed` does: each law's function is typed with
its hypotheses split off (a binder whose type has universe Prop), the Prop binders are removed from the law, and only
then do law_runs' rules build `law_trials`, from the remaining binders (the laws command runs verify's front and typing
first; the rules never see a hypothesis binder). A fact typing writes on each binder (its universe) would be read too late: law_runs' rules fire in the shape stage,
before typing. So the cost is in the laws command, not in the rules: the front `laws_typed` builds is shared with the
run (its typing call moves to one place both use), about +10 lines, the rules' `law_trials` untouched.

## The hypothesis runs first
A trial evaluates each hypothesis on the values before the conclusion, and a trial whose hypothesis computes to no holds
without the conclusion ever running: `h: b != 0` guards `a / b`, so the run never divides by zero.

## Handing the typed split to the run's rules (design, not yet code)
Typing (verify's `laws_typed`, run on its own front language) gives each law its accepted hypotheses, `TypedLaw.given`
(binder names). The laws command has to turn that into the run's code before its rules fire, and rules cannot ask. The
one hook that takes data is `rule_added(language, written, pattern, template, fact)` (core/rules/stages.wap:108), which
takes Nodes: for each law with hypotheses the command adds a rule of its own, pattern the law as the sugar rules leave it
(`law(f: ((binders) -> statement))`, the form both `law f(…): …` and `law f: {for …}` reach), template the same law with
the hypothesis binders removed and the statement `hypothesis implies statement`, so `law_trials` meets only ordinary
binders. A rule of a literal name beats the generic one by specificity, no special case per law. Unknown to settle by
building: the exact Node of the canonical form (read it from a built compile, not from the shape rules' text), and
whether compiler.wap may `use` verify/laws.wap for `laws_typed` (it grows the compiler by the verify extension; the
alternative is the native driver running verify first and passing the hypothesis names in a file the laws command reads).
