### Mantra

How is the battery included approach compatible with the good old Python mantra:
**There should be one -- and preferably only one -- obvious way to do it.**

### [[significant whitespace]]
Not directly an ambiguity but something to be aware of:  
⚠️ Wap has a few situations where a white space changes the semantics

### resolution: interactive

Ambiguity should ideally be resolved by the compiler by asking questions.

`a {x=1}` Did you mean a:{x=1} or [a,{x=1}] ?

`a>b:c` Did you mean `a>b : c` or `a > b:c` ?

### significant whitespace

[[significant-whitespace]] / semantic resolution

### single element lists

in general in wasp lists plus element means extending the list:
`(x,y)+z=(x,y,z)`
in general in wasp lists of one element are identical to the element:   
`(x)=x`  
however this might lead to conflicts, eg in list extensions:  
`(x)+y=(x y) ≠ x+y`  
resolvable by the parser?

Different [[list]] separators have different bindings: While 1,2,3 binds as one expression, 1;2;3 yields the last element as return value.

### grouping vs application
Consider `a b` `(a) (b)` `{a} (b)` and `{a}(b)`.  
Are they the same? A group with one element is identical to the element itself:  
Axiom `(a) == a`
Is a block with one element identical to the element itself?  
{a} == a ?
Is `{a} (b)` a list with elements {a} and b or is it b [applied](evaluation) to {a} `{a}(b)` ?

### grouping

while the precedence of ',' and '; is clear:
`1,2;3,4 == ((1,2);(3,4))
the precedence of ',' and ' ' less is clear:
`1 2 3 , 4 5 6` and
`1,2,3 4,5,6`
both seam like reasonably natural groupings.

Problematic is the [[ambiguity]] in mixing 'and', comma and other operators

```text
# two readings of one expression
x, y == a, b 
x, (y == a) , b   
```

The last reading is sometimes the desired one, e.g. in argument lists

```text
# readings, not a program
x, y as point == x, (y as point) or x, y as point == (x, y) as point == point(x,y)

```

[[Todo]]! What to do?

For colons the situation is dire as well:
`a b c:d` versus
`to skin a cat: do something` 
[[significant-white]] space to the rescue!

### burden of calls withoug parens
`square 3` yields a certain [[beauty]]
However when mixing function calls and operators, things can get ambiguous quickly:
`square 3 * 3 ` can be read as `square (3 * 3)` or `(square 3) * 3`   
`square 3 + square 3` can be read as `square (3 + square 3)` or `(square 3) + square 3`

Operators [bind](precedence) more tightly than functions.
Only the last case where functions are inter-mixed needs special attention:

### resolution: braces via IDE
One way to resolve ambiguities is by making the IDE suggest and insert braces
```text
# sketch: the braces an IDE would show
square 3 + 4 times 3
square(3 + (4 times 3))
```

Even though there might not be an ambiguity to the compiler, it can be helpful to insert braces to make it easier for the user to parse the meaning:
`a or b and c   =>   a or (b and c)`

The reasoning behind this is that the developer might not always we be aware of the [[function]] [[operator]] [[precedence]].

### ambiguity in c
```while (char c = dest[i] and i>0) ```
sets c to 0 or 1 because and binds stronger than assignment!!

## ambiguous referenceIndices
### ambiguous it keyword

In [lambda](closures) expression, the `it` keyword refers to the first (implicit argument), otherwise it refers
to [[self]] or the last [[result]], which can be very ambivalent:

```text
twice=it*2 # ok, [interpret](evaluation) immediately?
twice:it*2 # may interpret to anything later
twice:=it*2 # ok, implicit argument for function 'twice'
```

### functions or functors
```map [1 2 3] square``` could be read as
```map [1 2 3] :square``` symbolic function pointer 
```map ([1 2 3] square) == map [1 4 9]``` 

## variables vs functions
ambiguous [[assignment]] concepts:
```
name, age, source = "Crystal, 123, GitHub".split(", ") # deconstruction assignment
name age, source := "Crystal, 123, GitHub".split(", ") # function 'name' with arguments age, source
```
The last case is especially problematic with 

# Multi word variable names and typed variables
name age := age+1 The function 'name' with parameter age could also be read as name_age or age(type=name)

### block evaluation

Ideally we could reconcile `f={a:1 b:2} f[a] == 1` with the current mechanism `f(a=3) == {a:3 b:2}` or `f(a=3) == b:2`
or `f(a=3)==2`  because the last expression of the block is returned.
[[Map]] [[match]]ing versus [[block]] [[selection]] versus [[construction]].

### is not

`a is not b // ambiguity: a == !b vs a != b`

Wap reads it as `a != b`: `3 is not 4` is true, and so is `3 isn't 4`.

### Broadcasting

Broadcasting applies to functions but not to basic operators:

```text
# sketch: list operators (list + item is an ambiguity error now)
[1,2,3]+4 == [1,2,3,4]
[1,2,3]>>1 == [2, 3]
[1,2,3]++ == [2, 3]
```

### operators √ ^

Because √ and ^ lack graphical [[grouping]] or closure in text, their usage is ambivalent:

```text

√1+2 ≠ √(1+2)
2^x+1 ≠ 2^(x+1)

```

The default is that they are strongly [[binding]] (high precedence), but a warning shall be emitted! <!-- planned: the warning (card root-power-warning) -->

### [[similar]] operators

3 ≈ 3.1
`In an early talk Ken was explaining the advantages of tolerant comparison.
A member of the audience asked incredulously, “Surely you don’t mean that when A=B and B=C, A may not equal C?”
Without skipping a beat, Ken replied, “Any carpenter knows that!” and went on to the next question.`

### implicit multiplication

2x == 2*x OK only without space:
[2 x] = [2,x]
BUT 2 km??

### modifying functions

Can wasp solve the problem of recognizing mutating functions vs pure functions?
The problem: it is a priority not known whether a method modifies the object or returns and new object.

```text
"abc".upper()
[1,2,3].append(4)
```

There are some soft guidelines:
• if a method returns something it's unlikely to also modify the object
and conversely
• if a method does not return anything it's highly likely that the object was modified.

However there are exceptions to the rule (like pop() in python) and it remains a constant source of confusion and
errors.

	// todo 'do' notation to modify versus return different list!
	assert_emit("pixel=[1 2 3];do add 4 to pixel; pixel", Node(1, 2, 3, 4, 0));
