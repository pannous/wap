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
