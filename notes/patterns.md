# Patterns over Node: why the compiler's node kinds are patterns, not classes

The compiler's kinds of node (If, Call, Pair …) are patterns over the one Node type (wiki/pattern.md), never classes:

```
pattern Pair = Key(key, Op.Colon, value)            // every `a:b` is parsed as this key-value pair
pattern If = (·if condition then_block else_block)  // code with holes via `List`
```

## class vs pattern

### class
A type, in the class or nominal sense:

A value is made as that type: Call(f, args) produces a value tagged Call, and it stays a Call forever.
Membership is declared once, at creation. Checking it is just reading the tag.
One value has exactly one class.
It needs somewhere to hold the tag and the fields, which is why it usually becomes a struct.

### pattern
A pattern, in the structural or view sense:

Nothing is tagged. A pattern is a test, a way to take the value apart and a way to build it, over a representation that already exists: here, a plain Node.
Membership is observed: a Node is an If if it looks like (·if c a b), no matter who built it. The reader, a rule or a quote all count.
One value can match several patterns at once, for example If and also “any round list”.
It adds no storage. So everything the Node already carries comes along for free: metadata and positions, printing as code, quoting and splicing, wap format.

## strength
* **One kind of value, from the reader to the kernel.** [[rule]]s and rewrites take a Node and give a Node: one walker, one printer, one equality, one serializer for every stage. Nothing is converted into objects and back, and no visitor class per node kind repeats the same tree walk.
* **No classes inheriting from Node.** Node is a closed [[enum]] of a few variants, not a class hierarchy: a class `Call` would not be a kind of Node but a second, separate kind of tree. What we mean by "a Call" is "a Node of this shape", and that is exactly a pattern.
* **Positions for free.** A Node's [[meta]] data rides along through every rewrite: a node a rule builds takes the position of the node it replaced, so errors point at the user's line. A class instance has no meta data and would need an `origin` field in every class.
* **What classes would give, patterns give too:** named fields (`node.condition`), types (typed holes, `condition: Node`), and a closed union `kernel = If | Call | …` the compiler checks for completeness.

What classes would cost:

Two worlds of values. The reader produces Nodes, and the lowering would produce Call, If and Define objects. Every stage would convert in and out, and every tool would need two versions: printing, wap format, equality, quoting, the serializer.
Rules stop working. Rules and rewrites match Nodes and produce Nodes. With classes, each rule would also need to understand class objects.
Positions get lost. A source position lives in a Node’s metadata, and a class object has none: a class object would need an origin field.
Boilerplate. Object-oriented compilers end up writing a visitor class per node type, with the same tree-walking code repeated for every class.

Where they meet: a pattern can still be used as a type: f(n: If), or if n is If with the type narrowed after that check. That’s a refinement type, “a Node where this shape holds”. So patterns aren’t “not types”; they are types defined by shape over an existing type, rather than new kinds of values.

Only by patterns can we fully embrace our philosophy as code as data! 
Why is Wap the better Lisp? Because we have types and maps built in as first-class citizens!
