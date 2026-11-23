#!/usr/bin/env bash
# wap's modules: `use "file"` brings in a file's definitions and runs its statements first (notes/backbone.md "Stage
# languages", declared; core/analyze/declarations.wap). Run it with bash test/wap/test_modules.sh
source "$(dirname "$0")/compile.sh"

printf '%s\n' 'say(t: text) := print(t)' 'say("loaded")' >"$stage/speak.wap"
printf '%s\n' 'use "speak.wap"' 'greeting = "hi"' 'welcome() := say(greeting)' >"$stage/greet.wap"

check "a used module's function, its statements run first" "$(ran use_one 'use "speak.wap"
say("Hello")')" "loaded
Hello"
check "a module uses its own modules and variables" "$(ran use_nested 'use "greet.wap"
welcome()')" "loaded
hi"
check "a module used twice runs once" "$(ran use_twice 'use "greet.wap"
use "speak.wap"
welcome()
say("both")')" "loaded
hi
both"
printf '%s\n' 'use "pong.wap"' 'ping() := print("ping")' 'serve() := rally()' >"$stage/ping.wap"
printf '%s\n' 'use "ping.wap"' 'pong() := print("pong")' 'rally() := {' '	ping()' '	pong()' '}' >"$stage/pong.wap"
check "modules may use each other" "$(ran use_each_other 'use "ping.wap"
serve()')" "ping
pong"
# a module may hold only rules
printf '%s\n' 'rule twice $x => $x + $x' >"$stage/doubling.wap"
check "a module of rules only" "$(ran use_rules 'use "doubling.wap"
print "used"')" "used"
# a used module's rules build the language the program is written in (wiki kernel.md)
check "a used module's rule" "$(ran use_rule 'use "doubling.wap"
twice 4')" "8"
# a used module's enums and classes are the program's to use; a program's own case hides the module's
printf '%s\n' 'enum Tree { Leaf(value: int), Named(name: text), Nothing }' 'class Box { n: int }' >"$stage/trees.wap"
check "a used module's case with fields" "$(ran use_cases 'use "trees.wap"
print match Named("x") { Named(name) => name; _ => "o" }')" "x"
check "a used module's class and bare case" "$(ran use_class 'use "trees.wap"
b = Box(2)
t = Tree.Nothing
print text(b.n + 3)')" "5"
check "a program's own case hides the module's" "$(ran use_hidden_case 'use "trees.wap"
enum Side { Leaf, Root }
print text(Side.Leaf == Leaf)')" "yes"
check "a used module's case matched with its field" "$(ran use_case_field 'use "trees.wap"
leaf = Leaf(3)
print match leaf { Leaf(v) => text(v + 1); _ => "o" }')" "4"
printf '%s\n' 'pattern Pair = (Pair $left: Node $right: Node)' >"$stage/pairs.wap"
check "a used module's pattern builds its shape" "$(ran use_pattern 'use "pairs.wap"
n = Pair(Text("a"), Number(1))
print text(match n { List(items, bracket, separator) => #items; _ => 0 })')" "3"
check "a pattern builds its shape, a rest hole taking a list" "$(ran pattern_rest 'pattern Run = (Run $first: Node $rest...: Node)
n = Run(Text("a"), [Text("b"), Text("c")])
print text(match n { List(items, bracket, separator) => #items; _ => 0 })')" "4"
check "a pattern held in a map is a Node wherever one is wanted" "$(ran pattern_in_map 'pattern Pair = (Pair $a: Node $b: Node)
shown(n: Node) as text := text(n)
held: map<text, Pair> = {}
held["p"] = Pair(Text("x"), Text("y"))
for each in held.values { print shown(each) }')" "(Pair \"x\" \"y\")"
check "a pattern's rest hole read as its part" "$(ran pattern_rest_part 'pattern Run = (Run $first: Node $rest...: Node)
count_rest(r: Run) as int := #r.rest
print text(count_rest(Run(Text("a"), [Text("b"), Text("c")])))')" "2"
check "a used module's pattern takes its shape apart in an arm" "$(ran use_pattern_arm 'use "pairs.wap"
n = Pair(Text("a"), Number(1))
print text(match n { Pair(Text(t), right) => t; _ => "no" })')" "a"
check "a pattern's rest hole takes the rest of its shape in an arm" "$(ran pattern_rest_arm 'pattern Run = (Run $first: Node $rest...: Node)
n = Run(Text("a"), [Text("b"), Text("c")])
print text(match n { Run(first, rest) => #rest; _ => 0 })')" "2"
mkdir -p "$stage/inner"
printf '%s\n' 'use "../speak.wap"' 'shout() := say("HEY")' >"$stage/inner/loud.wap"
check "a module in a folder uses one beside its folder, loaded once" "$(ran use_up 'use "inner/loud.wap"
use "speak.wap"
shout()')" "loaded
HEY"
# a name means local > parameter > program > used module > types; two used modules defining one name clash
printf '%s\n' 'twice(n: int) as int := n * 2' 'show(n: int) as text := "a " + text(n)' >"$stage/a.wap"
printf '%s\n' 'twice(n: int) as int := n + n' >"$stage/b.wap"
check "a used module's word hides the types module's of the same parameters" "$(ran module_over_types 'use "a.wap"
print(show(3))')" "a 3"
check "a.twice is the used module a's word, beside the program's own twice" "$(ran module_named 'use "a.wap"
twice(n: int) as int := n * 10
print(text(a.twice(3)))
print(text(twice(3)))')" "6
30"
check "two used modules defining one name are refused naming both, even where nothing calls it" "$(ran module_clash 'use "a.wap"
use "b.wap"
print("x")' | grep -o 'a.wap line [0-9]* and b.wap line [0-9]* both define twice')" "a.wap line 1 and b.wap line 1 both define twice"
printf '%s\n' 'twice(n: int) as int := n * 2' >"$stage/c.wap"
check "two used modules defining one word identically are no clash" "$(ran module_identical 'use "a.wap"
use "c.wap"
print(text(twice(4)))')" "8"
check "a variable named like a used module is the variable: a.twice() is twice(a)" "$(ran module_hidden 'use "a.wap"
a = 7
print(text(a.twice()))')" "14"
# a type's name means the record its code sees: a used module's class beside the program's own of that name
printf '%s\n' 'class Box { n: int }' 'boxed(n: int) as text := text(Box(n).n)' >"$stage/boxes.wap"
check "a used module's code keeps its own class where the program declares another of that name" "$(ran module_class 'use "boxes.wap"
class Box { name: text }
print(boxed(3))
print(Box("x").name)')" "3
x"
# a case name two enums share: the case taking as many values as the call gives, though another hides it by scope
printf '%s\n' 'enum Token { Atom, Key }' >"$stage/tokens.wap"
check "a call of a case name picks the case taking its values: Key(a, op, b) is Node's beside a used module's fieldless Key" "$(ran case_by_count 'use "tokens.wap"
shown(n: Node) as text := match n { Key(left, op, right) => "key"; _ => "other" }
token = Key
print(shown(Key(symbol("a"), Op.Colon, Number(1))))
print(if token == Token.Key then "token" else "other")')" "key
token"
check "a module is one module however often a program names it" "$(ran use_named_twice 'use "speak.wap"
use "speak.wap"
say("once")')" "loaded
once"
# include (wiki/use.md): a file's text in place, as it is, so its words are the program's own, and a use inside it
# is read beside the included file
mkdir -p "$stage/parts"
printf '%s\n' 'use "../speak.wap"' 'twice(x: int) as int := x * 2' >"$stage/parts/twice.wap"
check "an included file's definitions are the program's own; its use is found beside it" "$(ran included 'include "parts/twice.wap"
say(text(twice(21)))')" "loaded
42"
# a module exports each function under its header line (wiki/wasm-representation.md "Export names"), so a host calls
# one overload by that name
called_export() {
	command -v wasmtime >/dev/null || { echo "no wasmtime on PATH, the host these lines call exports with"; return; }
	printf '%s\n' "$2" >"$stage/$1.wap"
	$wap "$compiler" "$stage/$1.wap" "$stage/$1.wasm" 2>&1 && wasmtime run -W gc=y,function-references=y,exceptions=y --invoke "$3" "$stage/$1.wasm" "${@:4}" 2>/dev/null
}
check "a host calls an exported overload by its header line" "$(called_export overloads 'add(a: int, b: int = 1) as int := a + b
add(a: text, b: text) as text := a + b' 'add(a: int, b: int = 1) → int' 2 3)" "5"
check "a program uses a compiled module as it uses its source" "$(printf '%s\n' 'add(a: int, b: int = 1) as int := a + b' 'twice(t: text) as text := t + t' >"$stage/compiled.wap" && $wap "$compiler" "$stage/compiled.wap" "$stage/compiled.wasm" 2>&1 && ran uses_compiled "use \"$stage/compiled.wasm\"
print text(add(2, 3) + add(4))
print twice(\"ab\")")" "10
abab"
check "a compiled module that exports no function declares nothing" "$(printf '%s\n' 'x = 1' >"$stage/no_functions.wap" && $wap "$compiler" "$stage/no_functions.wap" "$stage/no_functions.wasm" 2>&1 && ran uses_no_functions "use \"$stage/no_functions.wasm\"
print(\"ok\")")" "ok"
# a module compiled once carries what wasm erases as source in its wap section (wiki/wasm-representation.md): a class,
# a generic function and a value travel along, the functions compiled once are called through its exports
check "a compiled module's classes, generic functions and values work in the program using it" "$(printf '%s\n' 'class P { n: int, name: text }' 'names(ps: list<P>) as text := ps.map(p => p.name).join(",")' 'made(n: int) as P := P(n, "p" + text(n))' 'second(xs: list<T>) as T := xs#2' 'LIMIT = 7' >"$stage/carried.wap" && $wap "$compiler" "$stage/carried.wap" "$stage/carried.wasm" 2>&1 && ran uses_carried "use \"$stage/carried.wasm\"
print names([made(1), P(2, \"q\")])
print second([\"a\", \"b\"])
print text(LIMIT)")" "p1,q
b
7"
# a value assigned twice is one global, exported once
check "a value a compiled module assigns twice is one value in the program using it" "$(printf '%s\n' 'LIMIT = 7' 'LIMIT = 8' >"$stage/twice.wap" && $wap "$compiler" "$stage/twice.wap" "$stage/twice.wasm" 2>&1 && ran uses_twice "use \"$stage/twice.wasm\"
print text(LIMIT)")" "8"
# the program changes a used module's variable, which the module's own functions then read
check "a program changes a used module's variable" "$(ran reassign_used 'use "greet.wap"
greeting = greeting + "!"
welcome()')" "loaded
hi!"
# a word's one function is exported under its plain word too
check "a host calls a word's one function by its plain word" "$(called_export plain 'twice(x: int) as int := x * 2
add(a: int, b: int) as int := a + b
add(a: text, b: text) as text := a + b' twice 21)" "42"
check "a program uses a compiled module whose one function is exported by its plain word too" "$(printf '%s\n' 'twice(x: int) as int := x * 2' >"$stage/plain_twice.wap" && $wap "$compiler" "$stage/plain_twice.wap" "$stage/plain_twice.wasm" 2>&1 && ran uses_plain_twice "use \"$stage/plain_twice.wasm\"
print(text(twice(21)))")" "42"
# a recursive record's recursion group holds only the types that refer to it, so a list or text the module shares
# with the program is the program's own type
check "a program calls a list and a text function of a module declaring a recursive record" "$(printf '%s\n' 'class Tree { kids: list<Tree>; name: text }' 'total(xs: list<int>) as int := xs.sum()' 'shout(t: text) as text := t + "!"' 'size(t: Tree) as int := 1 + t.kids.map(size).sum()' >"$stage/recursive_module.wap" && $wap "$compiler" "$stage/recursive_module.wap" "$stage/recursive_module.wasm" 2>&1 && ran uses_recursive_module "use \"$stage/recursive_module.wasm\"
print(text(total([1, 2, 3])))
print(shout(\"hi\"))
print(text(size(Tree([Tree([], \"b\")], \"a\"))))")" "6
hi!
2"
# a used module raises by the library's tag, so the program's main catches it though it calls nothing of the library
check "a raise in a used compiled module is caught by the program" "$(printf '%s\n' 'positive(x: int) as int := if x > 0 then x else raise "not positive"' >"$stage/raising.wap" && $wap "$compiler" "$stage/raising.wap" "$stage/raising.wasm" 2>&1 && ran uses_raising "use \"$stage/raising.wasm\"
print(text(positive(-1)))" 2>&1)" "not positive"
# a used compiled module's top level runs once before the program, so a value it computes is set when the program reads it
check "a value a used compiled module computes at its top level is set for the program" "$(printf '%s\n' 'answer = [40, 2].sum()' >"$stage/answering.wap" && $wap "$compiler" "$stage/answering.wap" "$stage/answering.wasm" 2>&1 && ran uses_answering "use \"$stage/answering.wasm\"
print(text(answer))" 2>&1)" "42"
# wiki/use.md "folder, package and project scope": use folder brings in every source file beside the using one
mkdir -p "$stage/shapes" && printf '%s\n' 'area(side: int) as int := side * side' >"$stage/shapes/square.wap"
check "use folder brings in a word of a file beside it" "$(printf '%s\n' 'use folder' 'print(text(area(3)))' >"$stage/shapes/main.wap" && $wap "$compiler" "$stage/shapes/main.wap" "$stage/shapes/main.wasm" 2>&1 && $wap "$stage/shapes/main.wasm" 2>&1)" "9"
# wiki/use.md "Library folders": use name brings in the module of that name, here the one beside the program
check "use name brings in the module of that name beside the program" "$(ran use_name 'use speak
say("by name")')" "loaded
by name"
check "use name brings in a standard module from the library beside the compiler" "$(ran use_library 'use ordering
print(text(natural_compare("a2", "a10") < 0))')" "yes"
# the library's own module comes before one of that name in its folders: lib/regex.wap, not lib/crates/regex.warp (wiki/use.md)
check "use name finds the library's own module before its folders'" "$(ran use_library_root 'use regex
print(text(escaped_code("n")))')" "10"
# a folder right in the library holds modules too, lib/native's C bindings among them; import is use
check "import name brings in a module from a folder of the library" "$(ran use_library_folder 'import z
print(text(compressBound(100)))')" "113"
# ini: keys before any section stay at the top level beside the sections (lib/ini.warp, card lib-ini-toml)
check "ini keeps the keys before any section" "$(ran use_ini 'use ini
print to_ini(parse_ini("top = 1
[db]
host = x"))')" "top = 1

[db]
host = x"
# list: the standard list words beyond the types module's, typed (lib/list.warp, notes/lib_coverage.md)
check "the list module's words take typed lists" "$(ran use_list 'use list
print text(chunk([1, 2, 3, 4, 5], 2))
print text(median([3, 1, 2, 4]))
print text(combinations([1, 2, 3], 2))')" "[[1, 2], [3, 4], [5]]
2.5
[[1, 2], [1, 3], [2, 3]]"
# path's glob classes and machine_math's powers of two (lib/path.warp, lib/machine_math.warp, notes/lib_coverage.md)
check "path globs a class of letters, machine_math raises two" "$(ran use_path_math 'use path
use machine_math
print text(path_matches("b.txt", "[a-c].txt"))
print text(round(two_to(10.0)))')" "yes
1024"
# a library word given an any reaches its definition for the type the any holds (decision any-values, warp-reviewer)
check "a library word takes an any holding its type" "$(ran use_any 'use ini
a: any = parse_ini("top = 1")
print to_ini(a)')" "top = 1"
# a module's alias lines name its words other ways, in the module and in the files using it (wiki/alias.md)
printf '%s\n' 'sine(x: int) := x * 2' 'alias sin => sine' 'alias magnitude <= mag' 'magnitude(x: int) := x + 1' 'twice_sin(x: int) := sin(x) * 2' >"$stage/trig.wap"
check "a module's alias reads in the module and the file using it" "$(ran use_alias 'use "trig.wap"
print(sin(3))
print(mag(3))
print(twice_sin(1))')" "6
4
4"
# an alias of a rule's word starts that rule's phrase too (wiki/alias.md, wiki/declaration.md)
check "an alias of a rule's word starts its phrase" "$(ran alias_rule 'alias fun => def
fun halved(n: float) { n / 2 }
print halved(3.0)')" "1.5"
# a used module's global keeps its place among the module's globals, whatever the module using it adds of its own
mkdir -p "$stage/kept" && printf '%s\n' 'global names: list<text> = []' 'named(t: text) := names.add(t)' >"$stage/kept/names.wap" && printf '%s\n' 'use "names.wap"' 'setsockopt(fd: i32, level: i32, name: i32, value: bytes, size: length): i32 from '"'"'c'"'"'' >"$stage/kept/socket.wap"
check "a module runs whose used module's module has a global, beside a C binding of its own" "$(ran kept_global 'use "kept/socket.wap"
print 1')" "1"
exit $((failures > 0))
