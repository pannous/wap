#!/usr/bin/env bash
# wap's shape rules (notes/first_principles.md "Holes"; wap/kernel/forms.wap: `unless c { b }` is a rule writing If): a
# spelling written as other code by a rule, from sugar or from the program itself, compiled and run.
# The rest is test/test_rules.wap; these rules' templates write the prints themselves, and a template's own names are
# its own (a template cannot add to a list of the program's). Run it with bash test/wap/test_rules.sh
source "$(dirname "$0")/compile.sh"

# repetition (wiki/rule.md): `($k => $v)...` takes each arm, `print($v)...` writes one print per arm
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
# a comprehension (wiki/keyword.md for … if)
check "a comprehension lists a value for each item its condition keeps" "$(ran comprehension 'print(text([x * 2 for x in 1..4 if x > 1]))
print(text([#w for w in ["a", "bb"]]))')" "[4, 6]
[1, 2]"
# a comprehension over two lists, the second walked for each item of the first (lib/list.warp cartesian)
check "a comprehension over two lists" "$(ran pairs 'print(text([[x, y] for x in [1, 2] for y in [3, 4]]))
print(text([x * y for x in [1, 2] for y in [1, 3] if x < y]))')" "[[1, 3], [1, 4], [2, 3], [2, 4]]
[3, 6]"
# a typed rule's template builds a kernel form it calls by name, as a shape rule's does (core/rules/stages.wap)
check "a typed rule writing a kernel form" "$(ran typed_form 'rule twice $x: int => If($x > 2, $x + $x, 0)
print(text(twice 3) + " " + text(twice 1))')" "6 0"
# a typed rule's template that defines a name: each firing its own, fresh (core/rules/typed.wap)
check "a typed rule holding a value under a name" "$(ran typed_held 'rule twice $x: int => { held = $x; held + held }
held = 10
y = twice 4
print(text(y + (twice 1) + held))')" "20"
# a list pattern matches the list whatever separates its items, `[a b]` and `[a, b]` being one list (wiki/list.md)
check "a list pattern, spaced or with commas" "$(ran list_separators 'rule firsts [$a, $b] => print("$a")
rule lasts [$a $b] => print("$b")
firsts [1 2]
lasts [3, 4]')" "1
4"
||||||| 1ccac64
exit $((failures > 0))
