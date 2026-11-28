# Open decisions for the user

Shapes waiting for the user's discussion, each with its core lines, the case against, and why no hook or library
does it. Line counts are estimates from reading the code, marked as such; the measured size comes with the branch.
An entry goes once decided (its decision then lives on its card, in the wiki or notes/debts.md).

## The top debts still open (notes/debts.md); the "5" + 3 warning is parked (card digit-text-compile-warning)

## Pending questions

- T4c (user 11-28 asked: "ideally isomorphic types with different representations, the protocol char implemented as either code point or one-character text; probably for later?" A discussion, still open), how a char reaches text (char stays a 32-bit code point, ruling 2026-11-27). A (recommended): a mark on the conversion function, `@read text(c: char): text := …`, `@read list(r: range): list<int>`; core's conversion table goes (measured on t4c 1335aa9e: core about +5, 28 added and 23 removed), used by char, range, later code points or units; conversion.md gets one line for the mark. B: `type char < text`, no new spelling, but a `<` subtype is stored as its base, so a char becomes text, against the ruling; today it would also pass char → text unconverted and text → char unchecked, so B needs a conversion arm for subtypes stored differently (core about +5 net). Both cost the same, so A stays recommended because it keeps the ruling.
- T8b (user 11-28 asked: "can we have covariant shared but immutable, copy on write?" A discussion, still open; the cost of copy on write is being measured): a wiki addition to subtype.md. "A list of a subtype is not a list of its parent, because a list can change: a list<positive> given where a list<int> is wanted is refused, with the fix `xs as list<int>`, which copies it. `ys as list<positive>` checks every item and copies. A list written out in place fits either way: `[1, 2]` is a list<positive> or a list<int>, as the place wants." (a) this rule, core about +40, already on the branch (rec); (b) lists are covariant and copy silently, and a callee's change to the copy is lost; (c) lists are covariant and share, which is unsound (-1 ends up in the positive list).
