# Open decisions for the user

Shapes waiting for the user's discussion, each with its core lines, the case against, and why no hook or library
does it. Line counts are estimates from reading the code, marked as such; the measured size comes with the branch.
An entry goes once decided (its decision then lives on its card, in the wiki or notes/debts.md).

## The top debts still open (notes/debts.md); the "5" + 3 warning is parked (card digit-text-compile-warning)

## Pending questions

- After track T: a general property setter (writing `x.f` calls a declared `f=(x, value)`), so `canvas.width = 320` resizes as wiki/graphics.md "Sizes" says. Core ~10-20 (estimate); against: a new mechanism; no library does it without a quiet compensation. Recommend: build it after T.
