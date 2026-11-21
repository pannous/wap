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
exit $((failures > 0))
