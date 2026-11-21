#!/usr/bin/env bash
# wap's records (wap/kernel/forms.wap Record; wiki/class.md): a class a used module declares, its constructor and fields
# there for the program (the rest is test/test_records.wap; a second module file needs a script).
# Run it with bash test/wap/test_records.sh; the warp under test is WARP (default the warp on PATH)
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
exit $((failures > 0))
