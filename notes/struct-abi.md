# struct alias record


A struct is a collection of [[primitive]]s (int, string, ...) and other structs into a data tuple.
While struct is a [[node]] type, when reading or writing a struct, the [[abi]] omits the node header and directly
handles the primitives on stack or in memory.

# class
struct are [[class]] are very similar on the surface, but may have very different implementations.
<!-- TODO -->

# primitive
primitive struct / primitive class
Data layout as in C in linear memory!

# wit

Wasp uses [[wit]] as schema, all wit constructs are valid wasp, as "prefix notation" in [[wit]] files or with common
wasp syntax:

```
struct point{
  x:int
  y:int
}
point(1,2).y == 2
```

### [[struct]]s and named tuples

structs are instances of classes without the [[header]] in memory.
Or put the other way round: classes are thin meta wrappers around structs.
While the type information for struct instances is only available at compile time, the [[header]]
of [[class]] [[instances]] is part of the data in memory.

# [[Todo]] pass by reference or [[multi-value]]?

The wasp abi can return structs either as multi-value or as references to linear memory

The `struct` keyword in Wap is very similar to c and swift.
The main differences are: Meta information about all structs is stored in a custom type table, and or carried via
return [[type]]s. structs can be part of function dispatch, the only limitation being that they need to be determined at
compile time, because unlike class instances, structs do not know their own type.

# struct pointers as type [[scheme]]s
multi-value returns allows to carry meta information about results in the form of smart pointers. 



Each class has one corresponding `raw type` corresponding to the struct definition of its fields.
[[?]] structs can contain non primitive values while classes can only contain reference types.
That is, in classes int is really resolved as type Integer (or [[int60]][[?]]),
```
class example{
  level:int 
}
```

whereas in structs, int is really resolved as type int32

```text
# sketch
struct example{
  level:int #int32
}
```

This internal distinction however is almost completely invisible to the developer.

Compare with NamedTuple(x: Int32, y: String) in ruby and [[record]] in C#

# node_pointer as implicit structs

Todo: can Wap distinguish between un-[[charged]] data and implicit struct template prototypes?

```text
# sketch
f:{time:now} # passive declaration syntax
f.time! ≈ now!

f{time:now}  # active construction syntax (or passive if f is not know or passive)
f(time:tomorrow) # active construction depending on existing symbol f
f(tomorrow) == f{time:tomorrow}
```

# unification of structs enums and interfaces prototypes and classes

interfaces are just classes without concrete fields and without implementations
(implemented as [[trait]]: Comparable, Equatable and declared traits)

structs are just classes without header internally, so they should ONLY be used in extern FFI abi calls, right?

structs are just named tuples?

Alternative one can call and access foreign libraries functions and data just by (IMPLICITLY) applying the right abi.

Currently `record` is just an alias for `struct`

record pair {
x: u32,
y: u32,
}

record person {
name: string,
age: u32,
has-lego-action-figure: bool,
}

A `flags` statement defines a new `record`-like structure where all the fields
are booleans.

https://raw.githubusercontent.com/WebAssembly/component-model/main/design/mvp/WIT.md

# Wit variant

### Item: `variant` (one of a set of types)

A `variant` statement defines a new type where instances of the type match
exactly one of the variants listed for the type. This is similar to a "sum" type
in algebraic datatypes (or an `enum` in Rust if you're familiar with it).
Variants can be thought of as tagged unions as well.

Each case of a variant can have an optional type associated with it which is
present when values have that particular case's tag.

All `variant` type must have at least one case specified.

```wit
variant filter {
    all,
    none,
    some(list<string>),
}
```

An `enum` statement defines a new type which is semantically equivalent to a
`variant` where none of the cases have a payload type.

A `union` statement defines a new type which is semantically equivalent to a
`variant` where all of the cases have a payload type and the case names are
numerical.

## Item: `resource`

Resources represent a value that has a hidden representation not known to the
outside world.

This means that the resource is operated on through a "handle" (a
pointer of sorts). Resources also have ownership associated with them and
languages will have to manage the lifetime of resources manually (they're
similar to file descriptors).

Resources can also optionally have functions defined within them which adds an
implicit "self" argument as the first argument to each function of the same type
of the including resource, unless the function is flagged as `static`.

```wit
resource file-descriptor

resource request {
    static new: func() -> request

    body: func() -> future<list<u8>>
    headers: func() -> list<string>
}
```

Types

```wit
type number = u32
type fallible-function-result = result<u32, string>
type headers = list<string>
```

Types in wit, however, cannot be recursive:

# Auto Marshalling

Example:

```c
struct point{
  int x
  int y
}
void stretch_y(point& p){p->y*=2;}
```

```wasp
stretch_y {1,2}  # unsave 
stretch_y {1,2}  # file if reflected upon c with canonical abi
stretch_y point{1,2}  # extra file, don't pass class, but just POINTER to data according to abi
```

# gnu style

Both old and new gnu style initialization of instances is valid, the later giving more savety:

```text
# sketch
ParserOptions{use_tags = true, kebab_case = true}
ParserOptions{.use_tags = true, .kebab_case = true}
```

# struct extensions

Expandable structures enforce a scheme, but also allow extra elements.

Example:

```
extendible struct Point{ int x, int y}

Point test{y=7, x=8, z=9} // ok extra elements are stored behind ordered fields 
```

Upon using extendible structs in abis the behaviour for the extra elements needs to be specified.

⚠️ The extra data will be LOST in external receivers of the struct and are only valueable for read-compatibility or for internal meta handling.

⚠️ Wap classes are similar to extendible structs!
However since [[Wap]] [[class]]es are of type [[node]], the extra members will be handled transparently.

That is: while usage of structs in abi calls require strict memory layout, internal (or external) passing of node_pointer is always just a reference / pointer to a wasp node tree.

# aliases
extendible structs are just called `extendible` or `expandable`
extendible struct are also called `open struct`

Currently the keyword `record` is aliased to struct but may receive specific semantics in the future.

# wit interfaces types as implemented in v8 (node v20) :
```text

(module
(type ${f64_f64} (struct (field f64) (field f64)))
(type $f64_f64_=>_ref|{f64_f64}| (func (param f64 f64) (result (ref ${f64_f64}))))
(type $ref|{f64_f64}|_=>_f64 (func (param (ref ${f64_f64})) (result f64)))
(export "create_point" (func $0))
(export "length" (func $1))
(func $0 (param $0 f64) (param $1 f64) (result (ref ${f64_f64}))
(struct.new ${f64_f64}
(local.get $0)
(local.get $1)
)
)
(func $1 (param $0 (ref ${f64_f64})) (result f64)
(f64.add
(f64.mul
(struct.get ${f64_f64} 0
(local.get $0)
)
(struct.get ${f64_f64} 0
(local.get $0)
)
)
(f64.mul
(struct.get ${f64_f64} 1
(local.get $0)
)
(struct.get ${f64_f64} 1
(local.get $0)
)
)
)
)
)

```
