# Open decisions for the user

Shapes waiting for the user's discussion, each with its core lines, the case against, and why no hook or library
does it. Line counts are estimates from reading the code, marked as such; the measured size comes with the branch.
An entry goes once decided (its decision then lives on its card, in the wiki or notes/debts.md).

## The top debts still open (notes/debts.md); the "5" + 3 warning is parked (card digit-text-compile-warning)

## Pending questions

- T8b (user 11-28 asked: "can we have covariant shared but immutable, copy on write?" A discussion. Measured by wap-tree-wap: a one-way "shared" bit, core +15, lists.wap +10, a check on every write (1-3%, guessed), about 60 copy lines go, but it clashes with sharing (`grown(positives)` would not change the caller's list while `grown(ints)` does). Re-asked 11-28: "Discuss later"; t8b-rows stays unlanded): a wiki addition to subtype.md. "A list of a subtype is not a list of its parent, because a list can change: a list<positive> given where a list<int> is wanted is refused, with the fix `xs as list<int>`, which copies it. `ys as list<positive>` checks every item and copies. A list written out in place fits either way: `[1, 2]` is a list<positive> or a list<int>, as the place wants." (a) this rule, core about +40, already on the branch (rec); (b) lists are covariant and copy silently, and a callee's change to the copy is lost; (c) lists are covariant and share, which is unsound (-1 ends up in the positive list).
