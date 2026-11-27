# Effect as a types enum

The wish: `enum Effect { State; Allocation; IO; FFI; Async; Unsafe; Div; Eval; Fail }` in wap/types/, replacing
core/analyze/effects.wap's text constants (EFFECT_ORDER, PURE_WORD, STATE_EFFECT, DIVERGING_EFFECT, FAILING_EFFECT,
IO_EFFECT, FOREIGN_EFFECT).

## What reads cleanly

Core already reads a types enum by its cases: core/format.wap writes `Fixity.Infix`, `Fixity.Prefix`, `Side.Right`,
enums of types/operators.wap. `Effect.State` in effects.wap is the same pattern, and the mechanism cases (State, Div,
Fail, IO, FFI) are named by the walker the way Fixity's are. Nothing in core has to enumerate the cases.

## What blocks it

1. The seed rule. wap0 is the seed compiling the tree's compiler source beside the seed's own types module. An
   `enum Effect` in the tree's types is unknown to wap0, so effects.wap cannot name `Effect.State` before a seed
   refresh carries the enum. The enum can land in types first (nothing reads it); core's switch follows the refresh.
2. The kernel. kernel/primitives.wap OPERATION_EFFECTS is keyed by effect word (`"IO"`, `"Fail"`) and sits below
   types, so it cannot name the enum. The table keeps its text keys, and effects.wap maps the key to the case
   (`Effect.IO` by name lookup) — a second spelling of the nine words, or the table moves up into types.
3. extensions/wasm/modules.wap and extensions/theory/elaborate/effects.wap (its own PURE_WORD, effects_shown) write
   and read the words as text in a module's claim; they would read the enum the same way, after (1).

No workaround written; the order is: enum in types, seed refresh, then effects.wap, modules.wap and the theory
elaborate file switch together, and OPERATION_EFFECTS' place (kernel keys or moved) is the open choice.
