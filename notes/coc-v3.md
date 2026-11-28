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

## Re-read on 5285eb86: the functions, the substitutions, the cost

**What 5285eb86 holds.**
- Laws as lemmas work as the plan above says.
  - law_proved (verify/laws.wap:171) proves a law with `proof_found(elaboration(e, []), statement, [])`
    (prove/prove.wap:18) and declares the proof as a Theorem of the law's name.
  - laws_of (prove/goals.wap:106) gives every later goal `proved_laws`: Theorems, plus axioms stating a proposition.
  - instance_of (goals.wap:50) instantiates a law's binders with holes, and applied_law unifies its conclusion with the
    goal.
- An obligation is only a line of text.
  - `obligations: list<text>` is a global in core/analyze/dispatch.wap:26.
  - `obliged(at, type)` (:290) keeps the warning line alone: no argument, no enclosing function, no term.
  - The two callers:
    - dispatching (:36) passes the callee node, and its argument nodes are not in scope (it takes `types`);
    - narrowed_call (:271) has the value as `n`.
- `wap check` is the compiler's `checked` (compiler.wap:139-146): it types, then prints the lines. Its `--strict`
  raises on the first line.
- Each obligation the compiler can already discharge by itself (an if's finding, a parameter's own condition;
  test_check:9-12) never reaches the list. V3 only has to prove what is left.
- law_statement (verify/laws.wap:228-236) already states a function of binders as "yes for every value", with a
  subtype binder's condition as a hypothesis (hypothesized, :238-243).

**The one decision.** An obligation is a law of the function it sits in: "for every value of that function's
parameters, the condition holds of the argument".
- Its statement is law_statement's, so parameter conditions, binder names and the kernel's check come for free.
- The provers see it as they see any law, with every proved law in laws_of.
- No new statement form, no new prover.

1. **An obligation keeps its parts** (core, dispatch.wap).
   - `class Obligation { line: text; argument: Node; type: Term; within: text? }`, with `obligations: list<Obligation>`.
   - `line` is today's warning text. `within` is the key of the function being typed: TypeFrame gains `function:
     text?`, set by body_typed, and ø at the top level.
   - `obliged(at, argument, type, f)`. narrowed_call passes `n`. dispatching passes `given#at`, so it takes the
     argument nodes beside `types`.
   - core +5.
2. **An obligation's statement is entered with the functions** (core, analyze/terms.wap, beside conditions_entered at
   types.wap:222).
   - `obligations_entered(by_key, s)`, for each obligation with a `within`:
     - the enclosing function's parameters are read as definition_of reads them (with T6a4: its `typed.reading`);
     - `value = lambdas(parameters, beta(condition_value, [term_of(argument, reading)]))`.
   - condition_value is the Defined lambda of `condition_name(e, type)`, which condition_entered declares as
     `it => condition`.
   - The substitution is beta's, `it` replaced by the argument's term, so a law's conclusion meets the condition itself,
     never `x holds`, which unify would have to unfold.
   - An argument with no term (a global, an impure call) gives no value, and the obligation stays listed.
   - The pair kept is `o.function_type = pis(parameter domains, BOOL)` and `o.value`.
   - core +8.
3. **The check door** (extensions/proof/verify/check.wap, beside verify.wap).
   - laws_typed's front (:53-60, up to `typed_modules`) becomes `program_typed(wap_folder, program)`, shared by both
     doors: 0 net.
   - The door proves the laws first, `laws.map(law => verdict(law, assumed))`, with the verdicts not printed. Each proved
     law is then a Theorem in TYPES.environment.
   - Then, for each obligation with a value:
     `statement = law_statement(e, o.function_type, o.value, [])`, `proof = proof_found(elaboration(e, []), statement,
     [])`. Any proof is declared as law_proved declares one, which the kernel checks, under a name no program writes
     (the line, marked ·).
   - A proved obligation is dropped. The rest print their line, and `--strict` raises on the first as today.
   - check door +22.
4. **The compiler's check command goes, and native runs the door** (driver.wap:250 `Action.Check` as Verify's).
   - core −6 (compiler.wap:139-146), native +3.
5. **A proof calling an unproved law is refused** (verify/laws.wap proof_term's call branch).
   - A proof term whose head names a law with no Theorem in e (`declaration(e, name)!.kind is not Theorem`) is
     refused: `refused by unproved law: guess is Tested, so it proves nothing`.
   - It is the same lookup `by_named` already does (:202), with its refusal text. verify +4.

**What it costs.** core +7 (+5 +8 −6), verify +4, check door +22, native +3, prove 0. The old row had prove +15 for
"an obligation as a Goal". law_statement and proof_found already are that Goal, so it falls to 0.

**Needs.**
- T6a1 and T6a2: a law's call, and hypotheses (landed on 5285eb86 as coc-t6a12.md says).
- V2: `--strict` as a check option.
- T6a4's `typed.reading` for part 2. If V3 builds first, it builds `parameters_reading` and T6a4 takes it over: one
  function either way.

**Green.**
- wap/test_proof_wanted:17 "a tested law proves nothing" (part 5).
- The test_check gap line above: square_positive proved, then g's `f(x * x + 1)` obligation is no line (parts 1 to 4).
- wap/test_theory_connectives_wanted:9 needs T5c4 and T6a2 as the plan above says; this step adds nothing to it.

Normal path: test_check, test_proof_wanted, test_law_runs, test_theory_verify, test_native (the door).
