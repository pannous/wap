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
