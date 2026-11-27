# T6a5: False, Exists, and what no proof can be

coc-t6a.md's T6a5 row: `False`, a proof's effects checked pure and total, `exists … where`, and an `if` on a
proposition nobody can decide refused. This plan reads the row on unify-typers 5495afde with t5b-effects 68ade1fe on
top (the effect facts, enum Effect). Core about +12, sugar +2 rules, types +3.

## The wiki passages and the wanted lines

- proof.md:109-121: a loop or a raise is no proof; only what is proved proves. effects.md:81: the refusal names the
  chain.
- proposition.md:22 and :28: `exists x: T where P(x)` is a proposition, its proof an x and a proof of P for it.
- proposition.md:66: `if exists n: nat where n * n == 2 { … }` is refused, wap cannot decide it.

Lines it turns green, each pinned already:

- wap/test_proof_wanted.wap:15 "a loop is no proof", `loop(): False := loop()` then `law oops: False := loop()`,
  refused by effect.
- wap/test_proof_wanted.wap:16 "a raise is no proof", `law oops: False := raise "no"`, refused by effect.
- wap/test_proposition_wanted.wap:8 "an if on a proposition nobody can decide is refused", refused by undecidable
  condition.
- test/test_proposition_wanted.wap:8 `law some_sum: exists n: nat where n + n == 4` (it reads and compiles).

The row's "effects 15 and 16 (spin, loop)" are T5b1's Div lines, green on t5b-effects (test_effects.wap:13): T6a5
reads them and adds nothing there.

## What is there already

- **The effect facts.** core/analyze/effects.wap `effects_written` puts EFFECTS on each typed function after the
  whole program is typed (typed_among, analyze/types.wap:220). A written claim, `f() := … ! Pure`, is checked
  against them, refusing "f is declared ! Pure but has Div via …" with the chain (effects.wap:216). That is the
  check a proof needs, whole.
- **False.** The kernel's `·False` (kernel/logic.wap:13), in Prop, hidden from programs. A program's `False` today
  is an unknown word, which type_notation's word_declared makes an opaque data type, so
  `loop(): False := loop()` compiles with the wrong False.
- **Laws on a plain compile.** sugar/definitions.wap:51-55 reads `law name: S := proof` as `law(name: S := proof)`;
  extensions/laws.wap:4-5 then erases every law, proof included, so a proof never reaches analyze. `wap verify`
  checks proofs (coc-t6a12.md, T6a1 in verify).
- **Exists and the undecided `if`.** Nothing: no word, rule or kernel constant for exists; condition_typed
  (analyze/conditions.wap:116-137) wants a bool, coerces by truth_of, refuses "a condition is yes or no".

## The parts

1. **A proof is a definition claimed pure** (stage 1 rules, extensions/laws.wap). proof.md:22 already says a
   theorem is a function. The build's rule for a law or theorem with a proof keeps the proof as that function, with
   a claim no effect beyond its value: `law(name: S := proof)` becomes `name: S := proof ! Pure`, and with binders
   `name(binders): S := proof ! Pure`. A law without a proof stays erased. The existing claim check then refuses a
   loop (Div) and a raise (Fail) and names the chain: core 0 for the check.
   - The refusal says "refused by effect": the test helper reads the rule after "refused by ". The claim refusal at
     effects.wap:216 gets the kernel's rule word in front, `refused by effect: f is declared ! Pure but has Div via
     …`, through a constant EFFECT_RULE beside REFUSED (kernel/environment.wap:16-44). Core +2, kernel +1.
   - Pure is right for a proof: one that acts on the world (IO), allocates or keeps state proves nothing either
     (proof.md:111).
   - verify keeps checking the proof's type (T6a1); the plain compile checks only what it can, that the proof
     computes and ends. A wrong proof's type is refused by verify, as coc-t6a12.md plans.
   - Extension +2 lines (the two rules, with binders and without), placed before `rule law($statement) => ()`.
2. **False** (types). `False` is a types word naming the kernel's ·False, declared in types/logic.wap beside the
   kernel names T6a6 brings (coc-t6a.md "T6a5 re-read": +2 here, not +8). With it, `loop(): False := loop()` is
   typed at the kernel's False, and `law oops: False := loop()` meets part 1's claim.
3. **Exists** (types + sugar). A one-case structure with a parameter and no index, so it needs no T6a3:
   `enum Exists(T: Type, P: T -> Prop): Prop { intro(witness: T, holds: P(witness)) }` in types/logic.wap
   (types +1). `exists n: nat where body` is a sugar rule, `Exists(nat, (n: nat) => body)`, in sugar/ (a spelling
   plain wap cannot parse: the binder after a word, spec: wiki/proposition.md). T5b2's blocks declare an enum with
   parameters already; a field whose type applies a parameter, `P(witness)`, is the one thing to check first. If
   blocks refuse it, this part waits for T6a3's dependent fields and parts 1, 2 and 4 land without it.
4. **The undecided `if`** (analyze, conditions.wap). condition_typed refuses a condition whose type is a
   proposition (its universe is Prop, universe_of from T6a7) with "refused by undecidable condition: wap cannot
   decide whether …; prove it, or compute a bool". The rule word goes beside part 1's in the kernel's rule list.
   Core +6. A bool condition, an equation of ints included, stays a bool (T6a3a's proposition_of reads `==` as
   Equal only where a proposition is wanted).

## Where it sits, and what it waits for

- Stages: part 1 in the build's stage 1 rules (extensions/laws.wap) and analyze's effect check (after typing);
  part 2 and 3 in types (the preload) and sugar; part 4 in analyze's typing of conditions.
- Core files: core/analyze/effects.wap (+2), core/analyze/conditions.wap (+6), kernel/environment.wap (+2, two rule
  words). Extension: extensions/laws.wap (+2). Types: types/logic.wap (+3, new unless T6a6 is first). Sugar: one
  rule for exists.
- It waits for t5b-effects on main (the facts and the claim check) and T6a7 (universe_of for part 4). Part 3 checks
  T5b2's blocks first.

## Open

- Part 1 makes a proof a program definition on every build, so a program can call `oops()`. proof.md:47 wants
  that ("a proved law is used by calling it"). Its value is the proof, which a plain compile never runs.
- Whether the claim refusal's new "refused by effect:" prefix reads well on a plain function's claim too, or only
  on a proof's. The plan gives it to every claim refusal (one rule, no special case): a claim is the effect rule.
