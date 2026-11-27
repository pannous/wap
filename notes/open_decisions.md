# Open decisions for the user

Shapes waiting for the user's discussion, each with its core lines, the case against, and why no hook or library
does it. Line counts are estimates from reading the code, marked as such; the measured size comes with the branch.
An entry goes once decided (its decision then lives on its card, in the wiki or notes/debts.md).

## The top debts still open (notes/debts.md); the "5" + 3 warning is parked (card digit-text-compile-warning)

## Pending questions

- After track T: a general property setter (writing `x.f` calls a declared `f=(x, value)`), so `canvas.width = 320` resizes as wiki/graphics.md "Sizes" says. Core ~10-20 (estimate); against: a new mechanism; no library does it without a quiet compensation. Recommend: build it after T.
- Comma claims `f(x) := … ! IO, FFI` (wiki/effects.md:77, three test lines): today only IO is claimed. A (recommended): a `gathers` column on operator groups, the claim group sets it, and the parser gathers the comma items into its right operand; core +11 (core/parse/operators.wap, core/language.wap), a general mechanism with no group named in core; `! IO, 3` is refused. B: 0 core, write `! (IO FFI)`, the comma form leaves the wiki and its tests stay red. Branch effects-enum 11524edb (wap-tree-wap).
