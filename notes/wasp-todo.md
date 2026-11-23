# Todo

[Todo issue](https://github.com/pannous/wasp/issues/3)

# open [[questions]]

# open [[bugs]] and [issues](https://github.com/pannous/wasp/issues/)

# open tasks

• print result (even without wasp abi):
assert_emit("√3^2", 3);// should print 3 via wasmtime test.wasm:
// assert_emit("42", 42);// does print 42 via wasmtime test.wasm OK

# cleanup test only imports

these are part of wasp-hosted.wasm :
(import "env" "assert_expect" (func $assert_expect (type 3)))
(import "env" "async_yield" (func $async_yield (type 5)))
should only be used in TEST config!

(import "env" "download" (func $download (type 2)))
per APP!

(import "env" "js_demangle" (func $js_demangle (type 2)))
todo("__cxa_demangle in wasm");

# norway-problem

https://www.bram.us/2022/01/11/yaml-the-norway-problem/
countries = [ de, gb, no ] => no==false

solution 1: distinguish between symbol and expression context / mode.
in expression context countries = [ de, gb, no ] would throw because de is not a known symbol

solution 2: add special syntax for lists of strings / symbols within expression contexts:
similar to ruby %w[de gb no] maybe [[de gb no]] == [[de, gb, no]] ?

solution 3: add special context in which
countries = [ de, gb, $no ] would access variable $no
countries = [ de, gb, ${no} ] would access value no => false … if desired ;)

# extern "c" all imports

# split and name micro data segments for debugging

(data $wasp_data (i32.const 65536) "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\18\00\01\00\06\00\00\00canvas\00"))
=>
(data $wasp_data (i32.const 65536) "\00\00\00\00\00\00\00\00\00\00\00\00\00\")
(data $wasp_data__canvas_string (i32.const 65536+12) "\00\00\00\18\00\01\00\06\00\00\00canvas\00"))


# USE OWN POW:

ƒ19 _
Z3powIilENSt3__29enable_ifIXaasr3std13is_arithmeticIT_EE5valuesr3std13is_arithmeticIT0_EE5valueENS0_9__promoteIS2_S3_vEEE4type4typeES2_S3_
≈
ƒ19 std::__2::enable_if<(std::is_arithmetic<int>::value,)
ƒ19 std::__2::enable_if<(std::is_arithmetic<int>::value) && (std::is_arithmetic<long>::value), std::__2::__promote<int,
long, void> >::type::type pow<int, long>(int, long) ≈
ƒ19 std::__2::enable_if<( «todo» ?) ⇨ number

Node::
int capacity = 30;// TODO !!! lol lists>100 elements;)
int MAX_NODE_CAPACITY = 800;// TODO !!!

# [[AMBIGUITY]]

Different list separators have different bindings: While 1,2,3 binds as one expression, 1;2;3 yields the last element as
return value.

## merge todo with questions?

in that: every question is a todo?

# [[bugs]]

# update wasmtime for speed gain:

https://github.com/bytecodealliance/wasmtime/pull/4431
unload modules:
https://github.com/bytecodealliance/wasmtime/issues/2210

### Norm unicode

We should follow Julia's splendid approach to norm unicode:
Exemplary the following should be treated identical early on:
0x0041 65 LATIN CAPITAL LETTER A A 0x0410 1040 CYRILLIC CAPITAL LETTER A А 0x0391 913 GREEK CAPITAL LETTER ALPHA Α
0xFF21 65313 FULLWIDTH LATIN CAPITAL LETTER A Ａ

0x0061 97 LATIN SMALL LETTER A a 0x0430 1072 CYRILLIC SMALL LETTER A а 0xFF41 65345 FULLWIDTH LATIN SMALL LETTER A ａ
0x0251 593 LATIN SMALL LETTER ALPHA ɑ

As for signs which are _near identical_, but still distinguishable, one could also argue to unify them:
U+1EFE Ỿ Latin Capital Letter Y with loop U+1EFF ỿ Latin Small Letter Y with loop

However diacritic marks should distinguish symbols: Ḁ ≠ A ≠ Ⓐ

omicron 'ο' is needs special care (later!)

BUT 0x04D2 1234 CYRILLIC CAPITAL LETTER A WITH DIAERESIS Ӓ == German Ä

To avoid confusion, one may decide to *disallow* some historic or obscure alphabets:   
𐊆 66182 𐊆 10286 LYCIAN LETTER I 𐊇 66183 𐊇 10287 LYCIAN LETTER W 𐊈 66184 𐊈 10288 LYCIAN LETTER Z 𐊊 66186 𐊊 1028A
LYCIAN LETTER J 𐊍 66189 𐊍 1028D LYCIAN LETTER L 𐊎 66190 𐊎 1028E LYCIAN LETTER M 𐊏 66191 𐊏 1028F LYCIAN LETTER N 𐊐
66192 𐊐 10290 LYCIAN LETTER MM 𐊒 66194 𐊒 10292 LYCIAN LETTER U 𐊕 66197 𐊕 10295 LYCIAN LETTER R 0x0280 640 LATIN
LETTER SMALL CAPITAL R ʀ

### References as keys

`a=Mike(); my_map={a:b}; other_map={a:c}`
The reference problem is orthogonal to the Question:

### can children & value be merged?

[[it]] [[ambiguity]] in nested scopes fix [[bad]] language design and [[ambiguity]]
Refine the concepts of [[mutable]] values and variables

### Cleanup

## put special operators / functions into wasp library:

suffix operator ⁿ := c=it;while n-->0 : c*=it; c

isSetter ?

### operator ⋁ for bitwise or!?

### "^=" ≠ "!="

potence / logical and / logical not

# allow binary ops as unary

```text
# todo ideas
ø + 1 == +1 == 1
/7 = 1/7
```

# danger

Node& Node::fun(){return *this;} // danger can't turn a stack Node into heap Node reference!!

# out of control

### default args don't work in wasm! (how could they?)

float okf5(float f=0) {
return 41.5 + f;
}
assert_run("okf5", 41.5); /// … expected f32 but nothing on stack

# quality control

https://tmewett.com/c-tips/

# wit compliance

// Identifiers with the same name as keywords are quoted.
%bool: func()

# scratch

kids today grow up with scratch, the logo of this generation
todo: add scratch library to replicate scratch functions
https://scratch.mit.edu/projects/751647322

## multi dispatch

<>

### dynamic calls

[[Todo]]
Currently [[Wap]] is a compiled language. The (optional!) runtime does contain an interpreter (lacking in
implementation) sharing the same parse -> analyze pipeline. All dynamic calls should probably be passed through that
eval mechanism.

```text
getstatic java/lang/System/out Ljava/io/PrintStream;
invokevirtual java/io/PrintStream/println(F)V
```

### copy bug

changing
bool isGlobal(Node &node, Function& function)
to
bool isGlobal(Node &node, Function function)
makes tests fail!? But why? Function is not touched, no special copy constructor is defined.
the default shallow copy might duplicate the function object's values causing side effects. but which?

https://chatgpt.com/share/6756f3c2-e1dc-8005-abf6-42ecf6b011eb

# result

for i in 1 < 13 {print i*2} => 12 should be 24

# unnamed data sections without string len / termination 0 like scm

(memory $0 0)
(data $0 "exact integer in s64 range")
(data $1 "#<eof>")
(data $2 "hoot/exceptions.scm")
(data $3 "make-unrecognized-keyword-error")
(data $4 "string->utf8")

# stack via table

(export "$trampoline-tag" (tag $tag$0))
(export "$raw-stack" (memory $0))
(export "$scm-stack" (table $1))
(export "$ret-stack" (table $2))
(export "$dyn-stack" (table $3))

# coverage cleanup:

groupDeclarations
test a.b.c() / a.b=c setExternRefPropertyValuex
if (import or isFunction(expressiona))
for (Function *variant: function->variants)
groupForClassic


# [[node]]
Question: can children&value be merged? Not if we allow referenceIndices as keys: `[use:{a:b} reuse:{a:c}]`
The reference problem is orthogonal!

# illegal grouping?
#### only upon manual construction
future to do make sure Bracket::None with item (List of Bracket::None and Separator::None) forces some grouping?
