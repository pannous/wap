# Open decisions for the user

Shapes waiting for the user's discussion, each with its core lines, the case against, and why no hook or library
does it. Line counts are estimates from reading the code, marked as such; the measured size comes with the branch.
An entry goes once decided (its decision then lives on its card, in the wiki or notes/debts.md).

## The top debts still open (notes/debts.md); the "5" + 3 warning is parked (card digit-text-compile-warning)

## Pending questions

- After track T: a general property setter (writing `x.f` calls a declared `f=(x, value)`), so `canvas.width = 320` resizes as wiki/graphics.md "Sizes" says. Core ~10-20 (estimate); against: a new mechanism; no library does it without a quiet compensation. Recommend: build it after T.
- Comma claims `f(x) := … ! IO, FFI` (wiki/effects.md:77, three test lines): today only IO is claimed. A (recommended): a `gathers` column on operator groups, the claim group sets it, and the parser gathers the comma items into its right operand; core +11 (core/parse/operators.wap, core/language.wap), a general mechanism with no group named in core; `! IO, 3` is refused. B: 0 core, write `! (IO FFI)`, the comma form leaves the wiki and its tests stay red. Branch effects-enum 11524edb (wap-tree-wap).
- `Effect.cases`: an enum's cases as a list in declaration order, so types/effects.wap stops restating the nine Effect cases. One `indexed` rule in sugar/records.wap (sugar, ~0 compiler lines) plus a wiki line in enum.md; a new form, so the user's. Recommend: yes, after T (sugar waits for theory), unless effects needs it for T.
- `type of (2 + 2 == 4)` (wiki/proposition.md:6-7 says Prop). A (recommended, core 0): a comparison is a bool and reads as a proposition wherever one is wanted (law, a type, `A and B` of propositions); the wiki lines become "bool; where a proposition is wanted it is one", two red test lines rewritten. B (+5): `type of` special-cases comparisons as Prop, wiki stays. C (+40, slower self build): comparisons are Prop everywhere, as in Lean, decided at each `if`. From wap-theory-plan, plan notes/coc-t6a6.md part 5; work goes on with A.
