An [ABI](https://en.wikipedia.org/wiki/Application_binary_interface) Application binary interface is the low level
convention with which machine code interacts with each other.

Since WASM is pretty primitive and language agnostic, there is a unique opportunity to define a new ABI! One which at
least contains a minimal concept of classes.

That is: the data representation of types and the calling convention how these [[types]] are passed.

designing and ABI is no simple feat. if only all the smart hats that design the wonderful swift could get together and
create a slightly different new ABI from all the mistakes & things that they've learned:  
https://gankra.github.io/blah/swift-abi/

# Wap abi

⚠️ preliminary, subject to changing!

Wap [[data]] in the wasm linear memory (and in host memory) is stored in a canonical univeral format:

```c
struct Any_Header {
    Type header;// type / kind OF the object / container, e.g. Array, String, [[Node]]
    Type type;  // type WITHIN the container, e.g. generics or Node{.type=
    int length; // count of elements WITHIN the container, not sizeof()
    void *data; // ⚠️ continuation in memory OR pointer to data!
    // void *extra_fields… in objects without data continuation
};
```

The internal abi makes use of the memory layout of wasp [[node]]s.

# Calling convention

All non-primitive functions which take or return the univeral [[type]] [[node]], that is any class, object or data, uses
the following calling convention:

When multi-value is available, everything gets passed as a pair of ( [[Value]], [[Type]] )
When multi-value is not available, everything gets passed as a smart pointer.
See source code for details.

# Canonical ABI

The Wasm consortium grasped the unique opportunity by defining
a [Canonical ABI](https://github.com/WebAssembly/component-model/blob/main/design/mvp/CanonicalABI.md)
[[wit]] / wasm world [Component Model](https://github.com/WebAssembly/component-model/tree/main/design/mvp) MVP

Thanks to [[multi-value]] being already a defactor standard in [[wasm]], the [[Wap]] ABI fully makes use of it:

All functions are [[polymorphic]] in parameter and return types:
each value is a pair of TypedValue(int32,i64)
In fact the pair (int32 i64) is always easy to read as in the Wap [[ABI]]
int32 is always the type
i64 is always the value, now matter what.

Since our ValueType is different from the wasm-internal Valtype (int32 = 0x7f …), we can still use a sprinkle of magic
on them and treat them
as smart pointers. Another rationale for using i32 as pointers and i64 as numbers/values is that 99.9% percent of
functions handle types other than int32.

The value can still be a pointer (if the type indicates so), but it shouldn't be a 64bit smart-pointer as there is simply no need for them.

Internally, within functions i32 can still be used for counters, loops etc. So the trick would be to use long whenever the keyword int appears in Wap
variables, but use int whenever the variables are not exposed. Since users expect int only to represent i32 values, there is no loss in precision if long is
cast to int when calling external imports...

Interesting path: add wasm-unknown-unknown-[[Wap]] as target for rust etc

# C interops

⚠️ depending on optimization techniques and so on, there is no generic relyable interface to compiled c functions

<!-- # Memory layout

https://www.assemblyscript.org/runtime.html#memory-layout

Overall, AssemblyScript partitions liner memory as follows:
Region 	Start offset 	End offset 	Description
Static data 	0 	__data_end 	Contents of static strings, arrays, etc.
Managed stack 	__data_end 	__heap_base 	Present only if the incremental runtime is used.
Heap 	__heap_base 	memory.size() << 16 	Remaining space is used for dynamic allocations. Can grow.
 -->

<!-- 
# Header layout

Any kind of managed object in AssemblyScript utilizes a managed header for the runtime to operate on:
Name 	Offset 	Type 	Description
mmInfo 	-20 	usize 	Memory manager info
gcInfo 	-16 	usize 	Garbage collector info
gcInfo2 	-12 	usize 	Garbage collector info
rtId 	-8 	u32 	Unique id of the concrete class
rtSize 	-4 	u32 	Size of the data following the header			
	0 		Payload starts here


python already uses 3 different string encodings hidden from the user:
https://rushter.com/blog/python-strings-and-memory/
    1 byte per char (Latin-1 encoding)
    2 bytes per char (UCS-2 encoding)
    4 bytes per char (UCS-4 encoding)
we add "undecoded UTF-8" which may need costly transformations to UTF-32 for some algorithms!

 UTF-8 is a storage efficient encoding, but it has one significant disadvantage. Since each character can vary in length of bytes, there is no way to randomly access an individual character by index without scanning the string. So, to perform a simple operation such as string[5] with UTF-8 Python would need to scan a string until it finds a required character.

 Rust's approach (UTF-8 + iterator of grapheme clusters) is ideal.

Languages like Java and Python which have a fat runtime that they don't include with every program and can afford anything. In addition, Java / C # also has JIT compilation that allow them to speed up the whole thing by eliminating most of extra runtime checks. We cannot afford to complicate the runtime this way.

 -->

# WASI

https://github.com/WebAssembly/WASI/blob/main/legacy/application-abi.md

A command exports a function named _start, with no arguments and no return values.

_start is the default export which is called when the user doesn't select a specific function to call. Commands may also
export additional functions, (similar to "multi-call" executables), which may be explicitly selected by the user to run
instead.

Except as noted below, commands shall not export any mutable globals, tables, or linear memories.

Command instances may assume that they will be called from the environment at most once. Command instances may assume
that none of their exports are accessed outside the duration of that call.

All other modules are reactors. A reactor may export a function named _initialize, with no arguments and no return
values.

