# value

Internally [[node]]s have a field `value`.

It is used to hold primitive raw data and the value node of [[key]]-value [[pair]]s.

## Implementation details:

```c
union Value {
    Node *node = 0;
    String *string;
    void *data;// any bytes
    double real;
    long longy;
//  codepoint chary;// use longy
```

Number types such as [[bool]] [[byte]] [[int]] are using the same longy slot. Upon emission to wasm, these may or may not be reduced to i32 or i8; for example when handling arrays.

The [[type]] of the value struct corresponds to the internal [[kind]] of the node:

```cpp
enum Type {// todo: merge Node.kind with Node.class(?)
    // plurals because of namespace clash
    nils = 0,
    objects, // {…} block data with children closures
    groups, // (…) meta params parameter attributes lists
    patterns, // […] selectors matches, annotations! [public export extern] function mul(x,y){x*y}
    key, // key with value
    reference, // variable identifier name x
    symbol, // one / plus / Jesus
    operators, // TODO: semantic types don't belong here! they interfere with internal structural types key etc!!
    functor, // while(xyz){abc} takes 1?/2/3 blocks if {condition} {then} {else}
    expression, // one plus one
    declaration, // x:=1
    assignment, // x = 1 // really?? needs own TYPE?
    strings,
    codepoint1,
    arrays, // Node[] vs any[]? vs
    buffers, // int[]
    reals,
    longs, // the signature of parameters/variables is independent!
    //  ints, // use longy field, but in wasm longs are pointers!
    bools,
    errors, // internal wasp error, NOT to be used in Wap!
    call,
    classe, // as Java class,  primitive int vs Node(kind==int) == boxed IntegerType
    unknown //
}
```

The internal value [[type]] known as node “kind” corresponds losely with the node “type” which is a pointer to another node.
Example pseudocode:
```text
# sketch: an internal node layout
node{
    value.longy=1
    kind=longs,
    type=BoolType
}
node{
    value.longy=1
    kind=longs,
    type=Integer
}
```

## internal and user types (from wiki/type.md)

Wap and wasp have internal types which should mostly be isolated from users,  
as well as exposed types which should be the ones used by developers:

### user types

* [[number]]
* [[string]]
* [[any]] object, implicit default type 
* [[list]]s and [[map]]s often don't need their type exposed: `x=[1 2 3];y={a:1 b:2 c:3}`  

Having [[list]]s and [[map]]s as universal builtin types with no explicit type may come as surprise, but this is one of them main premises if not [[inventions]] of wasp.

How can any, list and map be the default type at the same time?  
Any node can have arbitrary children and thus act as a list.
Any node can have arbitrary properties and thus act as a map.
Any list can contain pairs and thus act as a map.
In fact map are just lists of pairs under the hood.


While every node is any node, there are specializations:

### Internal types

A node has these different **internal primitive** types(kinds),  
all aligning to 64 bits in the form of [[smart pointer]]s:

* [[nil]]s : Null types
* [[object]]s : {…} [[block]] [[data]]  with children denoted by {}, closures
* [[group]]s : (…) meta params parameter attributes lists denoted by ()
* [[pattern]]s : […] selectors matches, annotations! [public export extern] function mul(x,y){x*y}
* [[string]]s
* [[long]]s : also for storing ints and bools 
* [[real]]s : for storing floats and doubles
* [[pointer]]s : internal wasm [[pointer]]

Adding children to primitive types is allowed yet usually discouraged.
Since mostly primitive are held by [[reference]]s (in [[variable]] [[pair]]s), this is a non-issue as
properties can be added to references freely:
<!-- dropped: meta on plain values
```text
x=4
x.even=true // meta information
```  
-->
This will internally be represented as (psydocode:)

```text
# pseudocode (not runnable): internal node shape
{node name="x" value=4 kind=long children=[{even=true}]}
```

[[NodeTypes.h]] and [[NodeValues.h]]
To avoid name clashing, all type names end with s:

# Internal types

There are three types of type in Wap:
wasm types  (i32u etc)
wasp types  ([[kind]] of [[node]]) number, strings etc primitives Wap types (classes of [[node]] [[object]]s) Date,
Time, etc

## Internal [[value]] kind

The internal value [[type]] known as node “kind” corresponds losely with the node “type” which is a pointer to another
node.  
Example pseudocode:

```text
# pseudocode (not runnable): internal value kind vs type pointer
node{
    value.longy=1
    kind=longs,
    type=BoolType
}
node{
    value.longy=1
    kind=longs,
    type=Integer
}
```

Hereby [[enum]]s and other complex data with the same primitive value can still be differentiated unless the emitted
wasm is optimized.

### Typed [[list]]s / arrays
Internal representation 
Typed arrays have Node kind `Type::arrays` and any Node type.

In object space types are just references to [[Node]]
