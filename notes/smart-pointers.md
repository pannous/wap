# [[multi-value]] allows riddence of [[smart-pointer]]s

[[multi-value]] is supported by modern [[wasm]] engines and makes many of the following ideas **obsolete**!

We can still share the headers of [[type]]s :
0x00000000 undefined / int 0x00000000 undefined

Multi-value shifts the focus of smart-pointers to include a bit (flag) for [[optional]]ity. This might even become a
compiler only feature, making (type,value) pairs completely straight-forward.

We might still sprinkle some magic on the type section of the (type,value) pair:
Type 0 should mean `undefined or long`
Type 0x00…01 etc wasp types: ValueType strings etc Type 0x01…7F etc wasm types: Valtype i32u etc Type 0xDADA… pointers
to Nodes representing Data [[schema]]s Type 0xC0DE… pointers to Nodes representing Code Type 0xF1… pointers to Nodes
representing Types Type 0xF8… pointers to Functions calculating types(!)

But we are getting ahead of the old story:

# Smart Pointers at interface return

Since wasm 1.0 only has one return type to js, int32, this return type is highly context sensitive: It can mean a
number, an offset into wasm memory or something else. One might use the highest bit (excluding sign) to indicate whether
the result is a number or a pointer. If it is a pointer we can use further bits to denote different types of pointers.

# Smart Pointers

Because web assembly is currently only a 32 bit machine, but offers 64 bit long values usable as pointers we can use
those extra bits to store type information.

These rich pointers / valued pointers / [tagged pointers](https://en.wikipedia.org/wiki/Tagged_pointer) would allow
distinctions between different typed [[null]]s, and different [[missing]] / [[unknown]]
/ [[undefined]] [[null]] [[values]], all with the same return type.

We can distinguish between

```javascript
[0, 1].find(el => el == 0) == 0
[0, 1].find(el => el == 2) == undefined
```
To achieve this, on can split 64 bit pointers into two parts: A type part and a value part.
The first 32 bits could be used for types, the second 32 bits for values.
so 'find' would return (for example) :

```text
0x00000000.00000000 == int60,0,null OR
0x00000000.10000000 == int32,2^28)  
0x7F000000.FFFFFFFF == signed int32,2^32-1   OR
0x7FFFFFFF.FFFFFFFF == signed int60,2^32-1   NOTE: 0x7F==-1 in LEB128
0x7F00F000.FFFFFFFF == pointer to int32
0x7E00F000.DEADBEAF == pointer to i64
0x7D000000.FFFFFFFF == float32
0x7C00F000.DEADBEAF == pointer to float64
0xC0000000.00000048 == char 'A' 
0xC8000000.00001D4x == unicode charpoint 0x1D4x 'ᵀ' for primitives
0xB7010203.04050607 == seven bytes: DOS file names ;)
0xC000A000.DEADBEEF = pointer to char array (with or without length bytes)
0x10000000.DEADBEEF = pointer to string (with type header)
0xA0000000.DEADBEEF = pointer to Wap data string {order:'irrelevant',year:2018} (arguments maps etc)
0xAA000000.DEADBEEF = pointer to analyzed Wap node tree.
missing,
0xFA000000.00000000 == error:failing, x fail
0xFE000000.00000000 == error:missing, x fehl
0xFE000001.00000123 == exception:type 1, payload at 123  maybe 0xE0 ?  
0xFF000000.00000000 == undefined,x Folgefehler
0xFFFFFFFF.FFFFFFFF == ? -1 vs 0x00000000.FFFFFFFF
etc
```
The first byte expresses the internal type

One not so striking reason to use a 64 instead of a 32 bit scheme is that UTF60 codepoint1 are repräsentable.

To prevent overflow errors in [[int28]]/[[int60]] and float28/float60 additions, the heading hex 0x01 and 0x03 should be
reserved/unused.
As for multiplication, the expected type of int28*int28 should be int60 and int60*int60->[[bignum]].
For signed/negative int, maybe the hex 0xF / 0xFF should be reserved.

```text
0xB0123456.789ABCDE = i60 number : i64 minus 4 bit 0xB header for BigNum ;)
0xD0000000.DEADBEEF = 32 bit pointer to i64 value in linear memory 
0xE0000012.DEADBEEF = pointer to object of type 12 ([[Node]] of [[real]]s or custom ⁽ᵘˢᵉʳ⁾ class)
0xFB000000.DEADBEEF = pointer to [[LEB128]] arbitrary precision number in linear memory
0xEB010000.00000000 = number 1 represented as i56 subset of [[LEB128]] arbitrary precision number stored in value pointer
```

[[int60]] is a [[smart pointer]] 0xB000.... in which 7 of the 8 hexes are used for the numeric value and the first [[hex]] 0xB is used to denote the type

Since very big numbers are rarely used, and the transition to [[numbers]] with arbitrary precision should be completely seemingless and hidden from the user, one could also encode i30 and i60 within i32 and i64 to store some extra information and be compatible with above scheme.

0x00000000 = 31 bit numbers - 0xEFFF.FFFF (2 billion)
0x01234567 = 28 bit numbers - 0x0FFF.FFFF (268 million) [[int28]]
0xF0000000 = 31 bit pointer to Node in linear memory, representing _anything_.

Because usually programs have less then 2^24 ≈ 16 million pointers, the marker 0xF0 would be distinguishable (for debugging). This ABI convention would also
allow straight-forward passing of value pointers to and fro JS, which only supports i32 args and returns from wasm imports+export_section.

OR

leading bits: 00=unsigned i30
leading bits: 01=signed i30
leading bits: 10=null of some kind
leading bits: 11=pointer i30

A similar scheme is already part of wasm specification:
https://en.wikipedia.org/wiki/LEB128  // little endian 257 = 0x81 (001) + 0x02 (256)

By convention all i64 operations with and within the Wap ABI are smart pointers. Numbers bigger than [i28](int28)/[i60](int60) (0xB0… 'pointers') need to be represented as pointers to arbitrary precision numbers, or [[LEB128]] in linear memory.

An alternative to 64 bit smart pointers would be: 
all i32 > 0xF000.0000 are pointers to linear memory, look there to see the type (use i64 for long/int).
Whenever interacting with other (c-compiled) code, any ABI breaks anyways. It is per se impossible to know if the other end treats i64 as long or pointer.

In this 32 bit smart pointer scheme only a very limited number of primitive types could be declared:
* 0x0 [[int28]]
* 0x1 or 0xF [[signed int28]]
* 0x10 long pointer (i64*/i64*)
* 0x1E little endian something vs 0xBE
* 0x2 float28 (really?)
* 0x3 byte[3]/char[3] ABC (why lol) see 0x4, 0x7
* 0x4 ASCII-4 : 4 letters à 7 bit in 7 hexes à 4 bit (28 bit)
* 0x5 Json5 string (vs 0xA Wap string / 0xD data / 0xF pointer to object!)
* 0x6 pointer to [[int60]]
* 0x7 Septet : 7 hexes see 0x3, 0x4
* 0xA String pointer (vs 0xF pointer to string object!)
* 0xA Wap string (vs 0xD data / 0x5 Json5 / 0xCA chars / 0xF pointer to object!)
* 0xB Bytes (char*)
* 0xBE Big Endian something vs 0x1E
* 0xC0 Code/Closure
* 0xC1 Code/Closure indirection
* 0xC2 Char UTF24 Unicode
* 0xCA Char array
* 0xCC Char* c-style array
* 0xC8 Char pointer to UTF8 vs ([[LEB128]]-encoded)+chars
* 0xD Data pointer (direct typed data instead of 0xF any pointer)
* 0xE Error/Exception (including values Nil,NaN,Infinity,-Infinity,[[unknown]],[[missing]],[[undefined]] ...
* 0xEF [[Exception]] pointer: check all returns until catch block is reached
* 0xF0 Pʰointer
* 0xF1 Function pointer (indirection, call immediately)
* 0xFF negative signed int24 ?

I LIKE IT!

One big advantage off small smart pointers is that they are more easily debuggable.
One disadvantage is that they may not be future proof for large code bases.



### [[Data]] layout in memory

For reasons of ABI security, stability and debuggability, typed struct values (class instances) in linear memory also have a redundant header denoting their type.

Typically it starts with 0xDADA0000 followed by same the header as a smart pointer.
so `0x0xDADA000010000007` would denote a string of length 7 following immediately after.
Problem: we now have 
* wasm strings = length ([[LEB128]]-encoded)+chars
* chars 0-terminated (c-style)
* char[7] value pointers (0xB7…)
* [[string]] classes
* [[node]]s of type string with string field
* Wap-wasm instance structs of each above type. 'classed' data.
* indirect type headers 0xE0000012 ... to string classes.

(MAYBE: change the second [[hex]] to 'E' for extended, so `0x1E000007` would denote a string of length 7, following
immediately in linear memory. Problem: when passing this string, it would have to be transformed to a string pointer
0x1000DADA to that string. 0x1E is a good choice for the header as it rarely occurs in usual UTF8: '\x1e': ASCII/Unicode
U+001E (category Cc: Other, control)

# Whole node_pointer?

one could go full crazy an split all fn(Node) calls into fn(node_name,node_type,node_value) after moving children to
value. Why though? node_pointer reside in memory anyways, so getting node.name ... on demand is FINE.
