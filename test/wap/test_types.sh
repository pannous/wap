#!/usr/bin/env bash
# wap's typing stage (core/analyze/types.wap): every value's type, and the function each call means. A call picks
# among a name's definitions by its arguments' types, then by the type wanted; a parameter without a type makes one
# version of the function per tuple of argument types. Source: the lead's typing interface (notes/backbone.md).
# Run it with bash test/wap/test_types.sh
source "$(dirname "$0")/compile.sh"

# the rest is test/test_types.wap and test/test_types_own.wap; this check fails there, beside class P { x: int }: an
# any holding Box(3) shows as P{x: 3}, the first class of the same fields
check "a value in an any shows itself by its own type's show" "$(ran shown_any 's(x: any): text := show(x)
class Box { n: int }
print s(1) + " " + s(2.5) + " " + s("ab") + " " + s(yes) + " " + s(Box(3))')" "1 2.5 \"ab\" yes Box{n: 3}"
# a call typed only once a map's item type settles names the instance it gets: `!` of a value whose type settles to
# text? (warp-wap-reader's `a ?? b` report)
check "a call deferred till its unknowns settle" "$(ran deferred_settled 'm = {}
maybe(s: text) as text? := if s == "a" then "yes" else ø
h(b: bool) := if b then maybe("a") else m.get("a")!
print(h(yes) ?? "x")')" "yes"
exit $((failures > 0))
