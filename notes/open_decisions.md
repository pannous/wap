# Open decisions for the user

Shapes waiting for the user's discussion, each with its core lines, the case against, and why no hook or library
does it. Line counts are estimates from reading the code, marked as such; the measured size comes with the branch.
An entry goes once decided (its decision then lives on its card, in the wiki or notes/debts.md).

## The top debts still open (notes/debts.md); the "5" + 3 warning is parked (card digit-text-compile-warning)

## Pending questions

- Property setter (user 11-28 corrected "no setter": "we need a setter, but the syntax seemed wrong; queue it for later"): writing `x.f = v` should call something the type declares, so `canvas.width = 320` resizes (wiki/graphics.md "Sizes" stays). The shape `f=(x, value)` was wrong; a better spelling is needed, after T.
- GitHub ruleset against agent-named commits on main (user 11-28: "discuss later"): require author and committer emails to be the owner's; today only the Mac hooks and the cloud routine's own check guard it. Check the rule exists on the repo's plan before asking again.
