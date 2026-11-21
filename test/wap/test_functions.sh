#!/usr/bin/env bash
# wap's emitter: functions, locals and globals (wap/kernel/forms.wap: Define, Set, Call, a name's value): the checks no
# value can make, on what an uncaught raise, a refusal or a crash prints; the value checks are
# test/test_functions_calls.wap and test/test_functions_returns.wap
# Run it with bash test/wap/test_functions.sh
source "$(dirname "$0")/compile.sh"

check "code that never finishes adds nothing to a join: an arm that returns, raises or calls a function that always raises" "$(ran jumps 'f(n: int) as int := if n > 0 then n else raise("negative")
g(n: int) := { if n > 2 { return n * 10 }; n }
fail() := raise("always")
y = if f(3) > 9 then fail() else g(5) + g(1)
print text(y)
h(x: int) as text := match x { 1 => "one"; _ => raise("other") }
print(h(1))
print text(f(-1))')" "51
one
negative"
check "a refused function ends only itself: its siblings are typed anyway, each caller is refused naming it, all said together" "$(ran refused_alone 'bad(x: int) as int := x + "a"
worse(x: int) as int := bad(x) + 1
also(x: int) as text := 3
good(x: int) as int := x * 2
print(text(good(21)))' | grep -o 'line [0-9]*:\|calls bad' | tr '\n' ' ')" "line 1: line 2: calls bad line 3: "
check "a program statement wap refuses still lets the functions beside it be typed: all refusals said together" "$(ran refused_beside 'bad(x: int) as int := x + "a"
worse(x: int) as int := bad(x) + 1
also(x: int) as text := 3
print(text(worse(21)))' | grep -o 'line [0-9]*:\|calls [a-z]*' | tr '\n' ' ')" "line 1: line 2: calls bad line 3: line 4: calls worse "
# a module names its functions (wiki/wasm-representation.md: names by wasm convention), so a host's backtrace shows them
check "a crash's backtrace names the function it happened in" "$(ran crash 'class P { n: int }
g(x: int) as P? := if x > 0 then P(x) else ø
reads(x: int) as int := g(x)!.n
print text(reads(0))' | grep -o 'reads(x: int) → int')" "reads(x: int) → int"
# a definition's modifiers (wiki/keyword.md Modifiers, wiki/constant.md)
check "public and global before a definition change nothing" "$(ran modifiers 'public pad(t: text) := t + "."
global twice(t: text) as text := t * 2
print(twice(pad("a")))')" "a.a."
check "a const is a constant" "$(ran constants 'const z = 7
const tau := 2 * z
print(text(z + tau))')" "21"
check "a global given at the top is the program's variable" "$(ran top_global 'global n = 1
bump() := {
	global n
	n = n + 1
}
bump()
print(text(n))')" "2"
# a program's operators (wiki/operator.md): with parameters, without them (left and right; it), `operator` alone infix
check "a program's operator is the function of its name" "$(ran program_operators 'infix operator divides(d: int, n: int) := n % d == 0
operator ⇔(a: bool, b: bool) := a == b
infix operator times := left * right
prefix operator ⁻ := it * -1
print(text(3 divides 12) + " " + text((1 > 0) ⇔ (2 > 0)) + " " + text(3 times 4) + " " + text(⁻5))')" "yes yes 12 -5"
# a library function written as one wasm instruction, as lib's bits.warp writes them
check "functions written as wasm's bit instructions" "$(ran bits 'ones(n: int): int := prim i64.popcnt(n)
leading(n: int): int := prim i64.clz(n)
trailing(n: int): int := prim i64.ctz(n)
both(a: int, b: int): int := prim i64.and(a, b)
either(a: int, b: int): int := prim i64.or(a, b)
differ(a: int, b: int): int := prim i64.xor(a, b)
shifted(a: int, b: int): int := prim i64.shr_u(a, b)
left(a: int, b: int): int := prim i64.rotl(a, b)
right(a: int, b: int): int := prim i64.rotr(a, b)
print([ones(255), leading(1), trailing(8), both(12, 10), either(12, 10), differ(12, 10), shifted(-1, 60), left(1, 65), right(1, 1)].map(n => text(n)).join(" "))')" "8 63 3 8 14 6 15 2 -9223372036854775808"
exit $((failures > 0))
