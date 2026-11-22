#!/usr/bin/env bash
# wap's records (wap/kernel/forms.wap Record; wiki/class.md): a class a used module declares, its constructor and fields
# there for the program (the rest is test/test_records.wap; a second module file needs a script).
# Run it with bash test/wap/test_records.sh; its modules run on the native wap on PATH
source "$(dirname "$0")/compile.sh"

printf '%s\n' 'class Point { x: int; y: int }' >"$stage/points.wap"
check "a used module's class" "$(ran module_class 'use "points.wap"
p = Point(4, 5)
p.y')" "5"
# a class is told apart by its tag, its name's, never by its shape alone: two classes of one shape stay two
check "an any holding a class of another's shape shows its own class" "$(ran same_shape 'class P { x: int }
shown(x: any): text := show(x)
class Box { n: int }
print(shown(Box(3)))')" "Box{n: 3}"
# a program whose first record holds a list of itself: the record's type and its list are one recursion group
check "a first record holding a list of itself" "$(ran first_tree 'class Tree { n: int; kids: list<Tree> }
t = Tree(1, [Tree(2, [])])
#t.kids')" "1"
exit $((failures > 0))
