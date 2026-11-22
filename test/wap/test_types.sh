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
# a name given a value of another type holds any from its first value on, said with a warning; a let keeps its type
# (decision variable-retyping, wiki type.md "Representation")
check "a name given another type holds any, with a warning" "$(ran retyped 'x = 1
print "${x + 1}"
x = "ab"
print x' | sed 's/.*: this name/this name/')" "this name held int and now text, so it holds any from here on: write \`let\` for a name that keeps its type
2
ab"
check "an int given a float holds the float, said nothing" "$(ran widened 'y = 2
y = 2.5
print "${y * 2}"')" "5"
# a map's value type that would hold itself settles as any, so untyped nested maps work (decision untyped-nested-maps)
check "a map holding a map of its own type holds any" "$(ran nested_maps 'out = {}
section = out
section = {}
out["a"] = section
section["k"] = "v"
print "${out.keys} ${out["a"] is map}"')" "[a] yes"
# a word a blank parts from the map after it is two items, said with the glued call (decision spaced-is-two,
# wiki/significant-whitespace.md)
check "a word spaced from a map is two items, with a warning" "$(ran parted 'pair = [1, 2]
x = pair {a: 1}
print "${#x}"' | sed 's/.*: a blank/a blank/')" "a blank parts pair from the map after it, so these are two items: write pair{…} for the call: pair {a: 1}
2"
exit $((failures > 0))
