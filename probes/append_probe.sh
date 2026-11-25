#!/usr/bin/env bash
source "$(dirname "$0")/../test/wap/compile.sh"
check "+= grows a list in place" "$(ran grow 'xs = [1, 2, 3]
ys = xs
xs += [5, 6]
print ys')" "[1, 2, 3, 5, 6]"
check "+= an item grows in place" "$(ran grow_item 'xs = [1]
ys = xs
xs += 2
print ys')" "[1, 2]"
check "+ still copies" "$(ran plus_copies 'xs = [1]
ys = xs + [2]
print xs')" "[1]"
check "int += still adds" "$(ran int_plus 'i = 1
i += 2
i')" "3"
check "text += still joins" "$(ran text_plus 't = "a"
t += "b"
print t')" "ab"
check "a fresh [] each call" "$(ran fresh 'grown(x: int): list<int> := { out = []; out += [x]; out }
grown(1)
print grown(2)')" "[2]"
check "a field default is each instance's own" "$(ran field_default 'class Bag { items: list<int> = [] }
a = Bag()
b = Bag()
a.items += [1]
print b.items')" "[]"
check "a field += grows" "$(ran field_grow 'class Bag { items: list<int> = [] }
a = Bag()
a.items += [1]
a.items += 2
print a.items')" "[1, 2]"
exit $((failures > 0))
