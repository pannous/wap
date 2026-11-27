# Effect as a types enum

The wish: `enum Effect { State; Allocation; IO; FFI; Async; Unsafe; Div; Eval; Fail }` in wap/types/, replacing
core/analyze/effects.wap's text constants (EFFECT_ORDER, PURE_WORD, STATE_EFFECT, DIVERGING_EFFECT, FAILING_EFFECT,
IO_EFFECT, FOREIGN_EFFECT).

## What reads cleanly

Core already reads a types enum by its cases: core/format.wap writes `Fixity.Infix`, `Fixity.Prefix`, `Side.Right`,
enums of types/operators.wap. `Effect.State` in effects.wap is the same pattern, and the mechanism cases (State, Div,
Fail, IO, FFI) are named by the walker the way Fixity's are. Nothing in core has to enumerate the cases.

## The seed does not block it

core reads types/operators.wap by `use "../types/operators.wap"`, the tree's own file, not through the seed's types
module; `use "../../types/effects.wap"` does the same for Effect. The enum needs no seed refresh to be read.

## Plan

Step 1 (done): wap/types/effects.wap holds `enum Effect`.

Step 2, all together: the table OPERATION_EFFECTS moves from kernel/primitives.wap into types/effects.wap, keyed by
Effect (a host operation's effect is vocabulary); the kernel keeps only the operations. Then core/analyze/effects.wap
drops EFFECT_ORDER, PURE_WORD's list use and the five effect constants for `Effect` cases (the order is the enum's
order; the claim words are the case names), extensions/wasm/modules.wap and extensions/theory/elaborate/effects.wap
(if it survives unify) read the enum the same way. Checks: test_effects and test_hello.

Step 2 (done, unbuilt): the table and EFFECT_ORDER live in types/effects.wap, effects.wap reads Effect, and
kernel/primitives.wap keeps the operations. extensions/wasm/modules.wap names no effect (it moves the EFFECTS text fact
as is), so it needs no change; theory/elaborate/effects.wap stays for unify. A claim's words stay text where they are
read (effect_words), turned into cases by effects_named.
Open: `Effect(word)` and `Effect(at)` are the enum's generated constructors (sugar/records.wap), `map<Effect, list<text>>`
keyed by enum cases is untried, and types.wap does not include effects.wap (a program naming `Effect.IO` would need it,
then check core's `use` of the same file declares nothing twice).

# Commas in a claim

`f(x) := … ! IO, FFI` and `t := nat ! IO, FFI` read as a definition whose value row is `[(… ! IO), FFI]`: the comma is a
row separator, not an operator of the table, so no precedence entry can bind it. core/parse/operators.wap
definition_row already puts the bare items after a definition into its last value; `last_joined` now also puts them
into a claim at the end of that value (`claim_joined`: the claim becomes `IO FFI` in round brackets, as `! (IO FFI)`
reads). The claim group's name is `claim_group` beside compound_assignment_group in types/operators.wap.
Should turn green (unbuilt): test/wap/test_effects.wap "several effects claimed are written with commas", and in
test/wap/test_theory_effects.wap "several effects are written with commas" and "a bound of several effects is written
with commas".
