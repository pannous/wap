# T6a1 and T6a2, re-read on unify-typers

coc-t6a.md's rows T6a1 (proofs of bool laws) and T6a2 (hypotheses and connectives) were planned before
unify-typers took the theory's reader out. This note is what those rows become on unify-typers 2b0e87be, plus
t6a3a's propositions (t6a3a 3cbeccc5, landing onto it). The rows' wiki passages, their test lines and the table
"The 19 statements T6a1 holds" in coc-t6a.md stay as written. What changes is where the code goes and what is
already there.

## What unify-typers already holds

- **Hypothesis binders.** T6a2's first half has landed: 4f6716f7, 36f4536e and dc6a1487 on unify-typers.
  - verify/laws.wap's `hypotheses_split` makes a binder `h: a <= b` a function of the other binders, and
    `law_statement` puts it as a Π premise.
  - A refused hypothesis skips its own law only.
- **Equal, refl and the equality laws are kernel.** kernel/equality.wap has `equal_symmetric`, `equal_transitive`
  and `equal_congruent`. T6a1's kernel +20 (Equal and refl in core_environment) is already spent.
- **The provers take named laws.** `proof_found(el, statement, named)` (goals.wap:14-18, :106 `laws_of`) is what
  `by a, b` needs.
- **The statement in wap spelling** is t6a3a's `proposition_of` and `bridge_of` (kernel/equality.wap). An int `==` is
  `Equal(int, l, r)`, and any other truth is `b == yes`.
- **A law with a proof gets nothing.** `rule law($head := $proof) => ()` is in both law_statements.wap (verify's
  front) and law_runs.wap (the run). So `double_three := refl`, `swap := by add_zero, add_commutes`, a `chain`, a call
  of a law, and `assume` all go unread.
- **Hypotheses in the run.** law_runs' `law_trials` gives every binder trial values, a hypothesis `h: a <= b`
  included. Its type is a statement, so `trial_values() as list<…>` of it does not type. T6a2's "the law run's skip"
  is still to do.

## T6a1 on unify: a law with a proof, checked by verify

The proof is checked where the statement is made, in verify. Core gains nothing for `wap verify`:

1. **The statement of a law with a proof.** law_statements.wap's rule for `law($head := $proof)` writes the law's
   bool function as it does for a law without one, `law_double_three(): bool := double(3) == 6`, plus the proof as a
   second function of the same binders, `law_double_three proof`, in the hypotheses' naming. `laws_typed` pairs the
   two. extension +3.
2. **The proof forms**, each a term of the statement `law_statement` makes:
   - `refl`: `Equal.refl` at the statement's left side, which the kernel checks by computing;
   - `by a, b`: `proof_found` with the named laws as `named`;
   - `chain`: each line's step proved by its `by` from the line before, joined by `equal_transitive`;
   - a call of a law: its instance as a fact for the provers, rule H in coc-t6a.md;
   - `assume`: V1 (notes/coc-v1.md part 2). Its rule must come before `law($head := $proof) => ()`.

   The kernel's `declared` checks each resulting theorem (typing.wap:169). A wrong one is refused by value type.
   verify about +35.
3. **`type of` a law in a program** (test_proof_wanted:19, `type of add_commutes(1, 2)` is `1 + 2 == 2 + 1`). A
   program that calls a law needs it as a word. A law with binders is a function giving its statement's truth, and
   its type is shown as the statement at the arguments. This is the one core part, +10, the row's "shown statement".

Estimate: verify about +35, extension +3, core +10, kernel 0, types 0. The row had core +80, kernel +20 and types
+20. The glue laws are kernel theorems now. `chosen_decided` and `chosen_at_yes` are T6a2's, for `implies`.

## T6a2 on unify: what is left

1. **The run's skip.** A hypothesis binder takes no trial values: `law_trials` reads `($binder: $statement)` with a
   statement type as a condition on the trials before it. A trial where it computes to no is skipped. One rule in
   law_runs.wap, with the same `is_hypothesis` test the verify side uses, written as a rule pattern. extension +4.
2. **`implies` with hypotheses.** `law x > 0 and y > 0 implies x * y > 0` (law.md) and its curried form with
   `h:` binders are one proposition by `chosen_decided`. That is a kernel theorem over bool's recursor, beside
   equality.wap's laws. kernel +10.
3. **`not`, `and`, `or` of propositions** are Not, And and Or, chosen by the operands' sort: one row each in
   types/operators.wap, with the sort as the parameter type. types +3, core 0. They need Prop binders, which are
   T6a6's, so this part lands with T6a6, never before. Until then no test reads it.

Estimate: extension +4, kernel +10, types +3 (with T6a6). The row had core +40, of which hypothesis binders, +25,
have landed.

## Order

- T6a1 after unify-typers and t6a3a.
- T6a2's (1) and (2) with it, or right after.
- T6a2's (3) with T6a6.
- V1 shares `assume` with T6a1. Whichever lands first writes the rule, and the other uses it.

The red lines stay as coc-t6a.md's rows list them:
- the 19 statements of T6a1, of which 3 are green with T6a1 alone;
- T6a2's 13 lines.

The builder confirms each line against the run of the tree before counting it.
