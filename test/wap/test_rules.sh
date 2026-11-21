#!/usr/bin/env bash
# wap's shape rules (notes/first_principles.md "Holes"; notes/kernel.md: `unless c { b }` is a rule writing If): a
# spelling written as other code by a rule, from types/sugar or from the program itself, compiled and run.
# The rest is test/test_rules.wap; these rules' templates write the prints themselves, and a template's own names are
# its own (a template cannot add to a list of the program's). Run it with bash test/wap/test_rules.sh
source "$(dirname "$0")/compile.sh"

# repetition (notes/rules.md): `($k => $v)...` takes each arm, `print($v)...` writes one print per arm
check "a repeated part matched and written once per match" "$(ran repeat 'rule show { ($k => $v)... } => { print($v)... }
show { 1 => "a"; 2 => "b" }')" "a
b"
check "a repeated key" "$(ran repeat_key 'rule show { ($k: $v)... } => { print($v)... }
show { a: "x"; b: "y" }')" "x
y"
check "a rule writing two statements" "$(ran sequence 'rule both $a $b => print($b); greet() := $a
both "first" "second"
print greet()')" "second
first"
check "a glued pattern rule writing a glued kernel form" "$(ran glued 'rule shout($x) => Block(print($x), print($x))
shout("hi")')" "hi
hi"
check "a repetition that takes nothing writes nothing" "$(ran empty_repeat 'rule klass $name { ($field: $type)... ($m := $b)... } => print "fields"; ($m := $b)...
klass P { x: int; y: int }
klass Q { x: int; g := "q" }
print g()')" "fields
fields
q"
exit $((failures > 0))
