# Wap symbolism specification

⚠️ **Evaluation timing is specified in [[charged]].** Where this page disagrees with [[charged]] (especially §§4–6: `{}` data by default, a block run by `x()`, groups vs blocks), [[charged]] wins. Bracket roles, left/right application, and other design notes below are historical or aspirational unless they match [[charged]].

Many details of the symbolism/data shape are in separate articles like [[data]], [[list]], [[block]] …

## data=code format
```Wap
cat{
    length:7cm
    hair-color:{r=1 g=0 b=0}
    form{
        dimensions=(3, length*2)
    }
    kill{print '🕱'}
}
```

The data format is a superset to (a subset) of emascript,json,css,wasp,…

While it looks very different to lisp, it is in fact a very similar

*Data calculous* "lisp with builtin assignment and hashes"

With very few axioms and primitives:

## Operators:
* `:` pair : turn two node_pointer into a pair, `a:3` (hashed+symbolic). almost identical to:
* `=` value : turn two node_pointer into a variable pair, `a=3`
* `,` list : turn two node_pointer into a list. Append if one is a list. 'cons' in lisp
* `;` list : end expression/statements, list inside a block. if 1 : 0 ;
* `.` `#` `of` `in` `'s` selection: garden of house == house.garden == house's garden xs.1 xs#1
* `|` pipe/then : output of last command as input for next command. `ls ~ | sort`
* ` ` space acts as comma/concatenator in lists (a b c) == (a,b,c) == a->b->c
* ` ` newline, dedent: acts as comma in lists or closing 'bracket' if matching block start usual math
  operators `add` `plus` `times` `power` `^` … and logical `and` `or` `xor` `not`

Question: substraction|concatenation|range  hair-color vs a-b vs 2001-2020

for static content `,` `;` ` ` are identical
{1 2 3} == {1,2,3} == {1;2;3}

## brackets: lists maps blocks

In a **data file**, `[]`, `()`, `{}` are similar (lists / maps), as [[data]] describes:

`[1,2,3]==(1,2,3)=={1,2,3}`
`[a:3]==(a:3)=={a:3}`

In a **program** they differ ([[charged]] §6):

| bracket | in a program |
|---|---|
| `( … )` | group or call, **evaluated on the spot** |
| `[ … ]` | list of **evaluated** elements; plain words are symbols |
| `{ … }` | **data by default**: an object ([[charged]] §4) or a [[block]] of statements |

If attached to objects, surface roles still differ (attributes / params / body):

`[export]square(a:int){a*a}`

### brackets
* […] attributes meta modifiers decorators annotations adjectives adverbs
* (…) groups parameters signatures attributes lists head
* {…} maps / objects / statement blocks (not “always deferred”: see Evaluation time)
* «…» quotes its content as data that is not evaluated, a quasi-quote: `«x + 1»` is the expression, not its value; it prints as written and equals its text where a text is expected <!-- planned, today a plain text, card quasi-text -->
* x[…] index patterns selectors matches 

### optional order
[a]b == b[a] == a b  if a is modifier/operator
a + b == + a b   if feasible 

### optional brackets
f a b = f(a b) if f is a method/operator/functor

All kinds of brackets are often optional thanks to operator prescedence
`a:=1 2 3` == `a=(1,2,3)`
`[extern]void()` == `extern void`

Each line is treated as a group by default, unless escaped with \
so in lisp `(add (1 2))` is just `add 1 2` in Wap

Brackets have different semantics depending on their context, this is NOT reflected in the data structure, only in its evaluation: 

[…]object vs object[…]
[attributes] are commonly written on the left side of objects [indices] on the right site.
 e.g. `[mutable]list xs` but `xs[1]=7`

Question: what about xs[mutable]=7?

### Indexing
the preferred way to index properties in objects to use the 'of' / 'in' notation
`show color of cat` or dot notation
`show cat.color`
list items are indexed from 0 in ordinary [] notation `items[0]`
list items are accessed from 1 in selector # notation `item#1`

#### value indexing | symbolic indexing

x=color
cat{color:red}
cat.color // red
cat.x // ø
cat#x // red
cat[x] // red
cat#color // red unless color is a variable
cat[color] // red unless color is a variable

Question: how is value indexing done in english? `property=color; get this property from cat`

<!-- cat$x // red later -->

car(list)=list#1
cdr(list)=rest of list=list…


### Evaluation time

Authority: [[charged]] §§4–6 (and [[evaluation]], [[block]]). Spot-check against that page, not the older notes in this file.

`{}` is **data by default** in a program:

* `key: value` — uncharged ([[block]] / literal / symbol); run with `o.key()` when it is a block
* `key = value` and `key := value` — **values**, evaluated **now** where the object is written (`:=` inside an object is the same as `=`)
* bare statements — a [[block]]: `x = {1+2}` is the block `1+2`; `x()` → 3
* control flow already takes `block` parameters: `if c {…}`, `while c {…}`, `for x in xs {…}`, `def f {…}`

```wasp
a = 7
x = {a+1}     // block of statements
print x       // the block a+1
print x!      // 8 — x! forces once ([[charged]] §5)
a = 8
print x!      // 9 — names resolve where ! is written
```

**Groups vs braces** (not “everything in `{}` is deferred” / “everything in `()` evaluates blocks”):

* `(a+1)` — group, evaluated on the spot → value
* `{a+1}` — statements → block; run by a call, `b = {a+1}; b()`
* `{s: a+1}` — object; `s` uncharged; `s()` runs the block
* `{s = a+1}` — object; `s` is the value evaluated now

**Call arguments** are evaluated before the call unless the parameter is declared `block` ([[charged]] §5). Bracket shape alone does **not** defer: `print(x)` and `print x` both pass the value of `x`. `print{x}` is not “pass x deferred”; write a `block` parameter (or use control-flow forms) for unevaluated arguments.

`x()` runs a block once, `interpret x` fully ([[full-evaluation]]); `x!` only unwraps an optional (decision
blocks-run-by-call).

### Blocks

A **[[block]]** is unevaluated code meant to run later (`x : expr`, statement braces, `code`/`block` prefix, or a `block` parameter). Timing and `!` are in [[charged]] §§4–5; this subsection does not redefine them.

⚠️ **History / design notes** (pre-[[charged]]). Left/right application, treating every bracket shape as “a block at first”, and `(){}` vs `{}()` below are design history — not the current specification. Prefer [[block]] and [[charged]].

A block is unevaluated code (not “every `[…]` `(…)` `{…}` is a block at first”).

f a b = f(a b) if f is a functor
example functor:
if.signature == condition:block then:block [optional]otherwise:block
if(a=b){go!}{stop!}

`if` could be implemented within the language:
if(block condition, block body, block otherwise){
}

Having blocks as first class citizens makes a lot of code cleaner:
square(x){x^2}
{it^2}[1 2 3] == [ 1 4 9]

blocks can be applied to objects from left or from right
{a*a}(a=7) == 49

blocks run by a call <!-- decision blocks-run-by-call --> (`!` only unwraps an optional)
a=6;b={a*a};b() #36
ATTENTION
(){} has different semantics to {}()
the first is a deferred list [group(),block()]  
the second is an applied list [block(),group()] where the group is provided as context for the block

example:
(x){x*x}  a lambda (anonymous function)
{x*x}(x=5) #25 evaluated on the spot

This is particularily important because normaly () is just the empty object ø, but
{go}() will EXECUTE the block containing the statement 'go'; if 'go' was declared as function before, it will return the result of 'go'

# history (contradicts charged §4: `a=b` inside `{}` is a value entry evaluated now)
# Prefer: x = {a: b}  // uncharged; x.a! reads b where ! is written
#      or x = {a = b} // value now
b=7
x={a:b}
x.a    # the block b
y=x.a!
# y == 7; later b=5; x.a! == 5 (resolve at !)


blocks can be applied to lists from left or from right
{it^2}[1 2 3]

### Overlap with javascript

While some blocks might look identical to javascript, the underlying logic is much more unified. Read the rest of this document for details.


`a={b:1, c = d()}` — under [[charged]] §4, `b:1` is an uncharged literal entry and `c = d()` (or `c := d()`) is a **value** entry evaluated where the object is written. The JS-looking form `a={b:1,c:d()}` would keep `c` as the uncharged block `d()` (got-it warning on the computed `:`), not run `d()` at construction.

### Differences to json
json sucks, Wap is more like ecmascript:

### Differences to javascript

`a={b:1, c = d()}` legal Wap (value entry); the JS form `c:d()` is legal Wap too but **uncharged** under [[charged]], unlike JS.
legal syntax only in Wap:
`a:{b=1,c{d()}}`
`hello:world` root maps
`{1:i i^2:-1}` no restriction on map keys
`{a:b}` — under [[charged]], `:` entries are uncharged; a plain word `b` is a [[symbol]] (or a block if computed). Not “deferred by brace shape alone”.

Attention:

objects can be constructed with a{} a={} a:{} mostly equivalently 
in javascript '=' is used for variable setters and ':' is used for fields

Groups, blocks, lists (surface roles; program eval per [[charged]] §6)
() Node *param == group (evaluated on the spot) / attributes meta modifiers …
{} Node *children == object data by default, or statement [[block]]; not “always block body” — [[Setter Problem]] is design history
[] Node *list == selector pattern match / list of evaluated elements in a program
a[b]=c == a.b=c
a[[b]]=c (a that b)=c  a@b a~b=c (a.filter(b))=c


DANGER a,b=c,d TWO READINGS
1. (a;b=c;d) 2. (a,b)=(c,d)
a b:c d ==  a,(b:c),d   "short-binding"
a b=c d == (a,b)=(c,d)  "number- binding"

usually '=' is number-binding, meaning it has higher prescedence than other operations,
so the second reading is default.
Within Groups, '=' is shortbinding like ':' a(href='link' hidden)
BUT DANGER: group is default bag CONTRADICTION

Solution? '=' be left-short-binding  a b=c d == (a b):c,d  NO WAY
Solution: just write a(href:link style="")
Solution: short-binding in lists, but how do we know?


Diffenence of maps and constructors
   ` color:{r=1 g=0 b=0}` creates object called 'color' with r,g,b fields
   ` color{r=1 g=0 b=0}`  constructs instance of color class with r,g,b parameters
These are EQUIVALENT unless there is a constructor, e.g. 
`color{construct(r,g,b){this.rgb=r+g*2^8+b*2^16}}`

This is an example of class name as variable name. In this context color is both a variable with name 'color' and of type Color.

## Setter Problem

⚠️ **History / design notes** — not current eval rules. Object `=` / `:` / `:=` entries follow [[charged]] §4.
`cats=[cat{color=brown},cat{color=yellow}]` ok, two cats
`cats={cat{color=brown};cat{color=yellow}}` danger, cat property gets reassigned! really?
`cats(){color=green;sleep 1;color=blue}` ok, two setters in sequence

Then these two objects should still behave very similarily.
Especially the constructor arguments should be unmodified and are automatically accessible:
color.r==1 no matter what.


Assignment and object creation
foo{bar:3}  #object creation
foo(bar:3)  #object creation if (implicit) constructor, else function call
foo:{bar:3} #property assignment (nested objects)
foo={bar:3} #variable assignment (of calling context)

foo:=(x y){x+y} # function creation
:foo(x y){x+y} # function creation
to foo(x y){x+y} # function creation
