# V3: proved laws are facts

coc-plan.md's V3 row: a law proved earlier is a fact for the laws after it and for obligations. An obligation the
provers prove under `wap check` loses its run check and its Fail. Read on unify-typers 2b0e87be.

## The wiki passages

- law.md:36-44: "A law proved before is a lemma of the laws after it." `fact(n) > 0` is Tested alone, and Proved with
  the helper `law x > 0 and y > 0 implies x * y > 0` first.
- proof.md:47 "By other laws": "A proved law is used by calling it, like a function."
- type.md "Proved or checked", items 2 and 3. The compiler finds an obligation among the facts it knows there, "a
  proved law" among them, or proves it.

## What unify-typers holds

- **Laws as lemmas are there.** The provers' facts are `laws_of(goal)`: the named laws plus `proved_laws(el.c)`, every
  law the kernel holds as a theorem (goals.wap:99-106). `law_proved` declares each proved law as a theorem of its own
  name (verify/laws.wap:135-140). The law.md pair's red line (wap/test_theory_connectives_wanted:9) waits on its parts:
  - `fact` as a kernel definition: T5c4's guard reading;
  - `implies` with a hypothesis: T6a2's `chosen_decided`;
  - the induction along fact's recursion: there, test_theory_induction:14.
- **A law's call** is T6a1's (notes/coc-t6a12.md).
- **Obligations never meet the provers.** `wap check` is a compiler command, and the compiler never loads
  extensions/prove.

## The plan

1. **A proof that calls an unproved law is refused.** In T6a1's call of a law, the law must be a theorem the kernel
   holds. A law that is only Tested or Untested is the bool function of its binders, and its call proves nothing.
   It is refused: `refused by unproved law: guess is Tested, so it proves nothing`. verify +4.
2. **`wap check` through the proof door.** check moves from a compiler command to a door beside verify.wap. It shares
   `door_arguments` and the typed front (`laws_typed`'s first half), and loads extensions/prove.
   - It types the program, proves its laws as verify does, so proved laws are facts, then makes each obligation left
     a Goal: the narrowing's condition at its value, under the facts at its place (T4b's findings, the parameter's
     condition).
   - The provers run on it with the proved laws.
   - A proved obligation is not listed, and it passes `--strict` (V2).
   - check door +25, prove +15 (an obligation as a Goal), core −6 (the compiler's check command, moved). The native
     driver runs the door as it runs verify, +3.
3. **The plain build keeps its run checks: decided.** The row also had a plain compile drop the run check and the
   Fail of an obligation matched against a proved law's conclusion. A plain compile never loads the provers and has
   no verdicts (V1 cut its report), so it does not know which laws are proved. The ways it could know:
   - (a) the stamps of a module built with `wap build --wasm`, which carry its laws' verdicts, read with the proved
     statements;
   - (b) laws with written proofs, checked by the kernel in a plain compile.

   Both are new mechanisms. Recommended: leave the plain build as it is (correct and cheap), and let `wap check`
   show what is proved. A build that uses the proofs comes back as its own step, with T5g's compiled libraries,
   whose stamps are (a). The row's line, `effects of` with no Fail through a proved law, waits for that step.

## The red lines it turns green

| line | form | part |
|---|---|---|
| wap/test_proof_wanted:16 | a tested law proves nothing, refused by unproved law | 1 |
| wap/test_theory_connectives_wanted:9 | law.md's pair both Proved | 0 lines here; with T5c4 and T6a2 |
| test_laws_wanted:9-11 | `law fact(n) > 0` beside fact's run value | the run value is T5c4's; Proved as above |

Gap line for a builder, test/wap/test_check.wap (type.md item 2, "a proved law"):
`checked("check_law", "law square_positive(x: int): x * x + 1 > 0\nf(y: int where it > 0): int := y\ng(x: int): int := f(x * x + 1)\nprint g(2)")`
lists nothing. Before V3 it lists `x * x + 1 > 0`'s obligation.

## Estimate

verify +4, check door +25, prove +15, native +3, core −6, kernel 0. The row had core +30 and prove +15: its +30 was
the plain build's matching, which (3) leaves out. Normal path: test_check, test_proof_wanted, test_law_runs,
test_theory_verify. V3 after V2, T6a1 (a law's call) and T4d1 (the obligations in the state).
