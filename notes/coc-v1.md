# V1: one verdict per law

coc-plan.md's V1 row: `wap verify` prints proof.md's six verdicts, and a plain compile computes each law. Read on
unify-typers 2b0e87be. V1 lands after it (verify reads analyze's environment there) and after T6a1 (the row's wait).

## The wiki passages

- proof.md "Checking proofs: `wap verify`", the six verdicts:
  - Proved, and "rests on" the axioms it uses: `uses_choice: Proved, rests on choice`;
  - Tested;
  - `FAILED, counterexample n = 1`;
  - Untested;
  - Assumed ("only an `assume` makes a law Assumed");
  - Axiom.
- proof.md "What a proof rests on": `axioms of double_even // []`, `axioms of hard // [hard], an assume`, and
  `axiom name: statement` as the only way to add an axiom.
- law.md:9-10 and "Checking a law": a law is a hint, tested where it can be, and it never stops the program.
  `wap verify` gives the verdicts.

## What unify-typers does now

- **verify.wap** prints three verdicts from the kernel: Holds → Proved, Breaks → FAILED, Open → Untested.
  `typed_verdict` (verify/laws.wap:125-133) gives them. A law over an assumed function is refused, and the refusal is
  printed in its place.
- **native/driver.wap** `laws_checked` joins the run's verdicts with the kernel's (`verdicts_joined`, :132-138). The
  laws command (extensions/law_runs.wap) makes each law a function that tries its binders' trial values. The run
  gives Tested, or FAILED with the counterexample, and that turns an Untested into Tested. `VERDICT_WORDS` already
  holds all six words.
- **Axioms are not listed.** `laws_typed` takes only the `law_` functions, so `axiom choice: Prop` gets no line.
- **`assume` is no word.** Nothing reads it outside the retired theory.
- **`axioms of` is no question in core.** kernel/environment.wap:273-277 has `axioms_of` and `axioms_shown`. The
  second is on kernel-length's dead list, and V1 is its caller, so it stays.
- **A subtype binder's trials break the run.** `law_values $type => trial_values() as list<$type>` converts int's
  trial values to `list<nat>`. A negative one fails the narrowing, so `broken(n: nat)` stops instead of showing
  `n = 0`.

## The plan

1. **Axiom.** `laws_typed` lists the program's axioms beside its laws, in program order. Their declarations are
   Axiom, so each prints `name: Axiom`. verify +6.
2. **`assume`.** `law hard(n: nat): n * n >= n := assume` is the law declared as an axiom of its own name, marked as
   an assume.
   - A rule in sugar/definitions.wap turns `($head := assume)` in a law into the law's axiom with the mark. sugar +2.
   - The mark is a set of names in the TypingState, `assumed`. core +3.
   - `axioms of hard` is then `[hard]`, as the wiki says.
3. **Assumed and "rests on".** A law's verdict once the kernel holds it:
   - its own declaration is an assume → Assumed;
   - it is proved (Holds, or a theorem with a value), and `axioms_of` names an assume → Assumed, so `uses_hard` is
     Assumed (test_theory_verify:15);
   - it is proved and rests on other axioms → `Proved, rests on a, b`;
   - else as today.

   verify +12.
4. **`axioms of name`.** It joins core's question table beside `type of` and `effects of` (calls.wap, the T5b1
   table). It prints `axioms_shown`. core +4.
5. **A subtype's trials.** A binder of a subtype is tried on the parent's trial values that hold its condition:
   `law_values $type` filters by `is $type` before the conversion. That is one rule line in law_runs.wap, and it
   holds for every type: for a type with no condition the filter keeps every value. extension +1.
6. **The kernel's refusal beside a run's verdict.** `law tested(x: float): x * 1.0 == x` alone is red on
   wap/test_proof_wanted:9. Beside another law it is green (test_law_runs:15). The builder reads first whether the
   refusal said on standard error lands in the line `wap_said` checks. If it does, the refusal of a law that the run
   gives a verdict goes to `wap verify --explain`. That is verify +5, and it keeps the refusal said, never dropped.

### The plain compile: cut

The row also has a plain compile compute each closed law and report it Proved or FAILED. No wiki page shows a
report on a plain compile. law.md says only that a law never stops the program, and that `wap verify` gives the
verdicts. The row's test, `law double(3) == 6` Proved on a plain compile, has no passage behind it.

Recommended: leave it out. That saves the row's core +25 and keeps verdicts in one command. If the user wants laws
reported on every compile, it comes back as its own step, with a wiki passage first.

## The red lines it turns green

| line | form | part |
|---|---|---|
| wap/test_proof_wanted:10 | `broken(n: nat): n * n > n` FAILED, counterexample n = 0 | 5 |
| wap/test_proof_wanted:11 | `hard: Assumed` | 2, 3 |
| wap/test_proof_wanted:9 | `tested: Tested` alone | 6, once its cause is read |
| test_proof_wanted:20, :22 | `law hard … := assume`; `axioms of hard` is `[hard]` | 2, 4 |
| test_proof_wanted:21 | `axioms of double_even` is `[]` | 4, with T6a4 |
| wap/test_theory_verify:15 | `hard: Assumed`, `uses_hard: Assumed` | 2, 3 |
| wap/test_theory_verify:16 | `choice: Axiom` | 1 |
| wap/test_theory_verify:17 | `[]`, `[hard]`, `double_even: Proved`, `hard: Assumed` | 1-4, with T6a4 |
| wap/test_theory_verify:25 | `fact: Axiom`, `given: Axiom`, `uses_given: Proved, rests on fact, given` | 1, 3 |
| test/wap/test_native.sh:294, :299 | `choice: Axiom` from any folder, and from a standalone wap | 1 |

**Not V1's:**
- wap/test_proof_wanted:16, "a tested law proves nothing", refused by unproved law: a proof that calls a law not
  proved. That is V3, where proved laws become facts.
- wap/test_proof_wanted:17, an axiom with `exists`: T6a5.
- wap/test_proposition_wanted:13, `use classical`: T6a6.

## Estimate

| part | lines |
|---|---|
| 1 axioms listed | verify +6 |
| 2 `assume` | sugar +2, core +3 |
| 3 Assumed and rests on | verify +12 |
| 4 `axioms of` | core +4 |
| 5 a subtype's trials | extension +1 |
| 6 the refusal beside a verdict | verify +5, if needed |
| **total** | **core +7, sugar +2, verify about +23, extension +1** (the row: core +25, verify +30) |

Kernel 0. Normal path: test_law_runs, test_proof_wanted, test_theory_verify, test_native. One builder; the row names
wap-primitive-lookup-tables after t5b-effects, whose question table part 4 extends.
