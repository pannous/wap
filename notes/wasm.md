# wasm

Wap is wasm native: 

Everything is in the language is designed around the capabilities and constraints of WASM, and maps natively and directly wherever it makes sense, without being limited by the current state, see [[wasm-representation]] for how wap lowers to wasm.

Since wasm is [supported](https://caniuse.com/?search=wasm) pretty much universally for some time now we can now ask for
the next steps after the MVP:

https://wasm-feature-detect.surma.technology/

Supported wasm features as of 2021:

<!-- https://webassembly.org/roadmap/ ! now same as: -->

https://webassembly.org/features/ implementation tracking and roadmap!

https://github.com/WebAssembly/proposals

# HOSTS BROWSERS
 Node20  | Chrome | Safari | WebKit | Firefox | Feature                                                                                                                                                                            
---------|--------|--------|--------|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 ✔️	     | ✔️	    | ✔️	    | ✔️	    | ✔️	     | [multiValue](multi-value)                                                                                                                                                          
 ✔️	     | ✔️	    | ✔️	    | ✔️	    | ✔️	     | bigInt                                                                                                                                                                             
 ✔️	     | ✔️	    | ✔️	    | ❌	     | ✔️	     | bulkMemory                                                                                                                                                                         
 ✔️		    | ✔️	    | ✔️	    | ❌	     | ✔️ 	    | [exceptions](https://github.com/WebAssembly/exception-handling/blob/main/proposals/exception-handling/Exceptions.md)                                                               
 ✔️		    | ❌	     | ❌	     | ❌	     | ❌ 	     | extendedConst                                                                                                                                                                      
 ✔️		    | ❌	     | ❌	     | ❌	     | ❌ 	     | memory64                                                                                                                                                                           
 ✔️	     | ✔️	    | ✔️	    | ✔️	    | ✔️	     | mutableGlobals                                                                                                                                                                     
 ✔️[1] 	 | ✔️	    | ✔️	    | ❌	     | ✔️	     | referenceTypes (externref)                                                                                                                                                         
 ✔️	     | ✔️	    | ✔️	    | ❌	     | ✔️	     | saturatedFloatToInt                                                                                                                                                                
 ✔️	     | ✔️	    | ✔️	    | ✔️	    | ✔️	     | streamingCompilation                                                                                                                                                               
 ✔️	     | ✔️	    | ✔️	    | ✔️	    | ✔️	     | signExtensions                                                                                                                                                                     
 ✔️	     | ✔️	    | ❌	     | ❌	     | ✔️	     | SIMD ⚠️ ⇨ [Flexible Vectors](https://github.com/WebAssembly/flexible-vectors/blob/main/proposals/flexible-vectors/FlexibleVectors.md) relaxed-simd                                 
 ✔️      | ✔️	    | ❌	     | ❌	     | ❌ 	     | tailCall                                                                                                                                                                           
 ✔️	     | ✔️/❌   | ❌	     | ❌	     | ❌ 	     | threads                                                                                                                                                                            
 ✔️      | ✔️     | ❌ 	    | ❌ 	    | ✔️ 		   | GC: reference-types type struct (Chrome 108, FF 111)                                                                                                                               
 ?	      | ?	     | ?	     | ?	     | ?	      | GC: interface types <= webidl ≠ reference-types                                                                                                                                    
 ?	      | ?	     | ?	     | ?	     | ?	      | [type imports](https://github.com/WebAssembly/proposal-type-imports) [Overview](https://github.com/WebAssembly/proposal-type-imports/blob/main/proposals/type-imports/Overview.md) 
 ?	      | ?	     | ?	     | ?	     | ?	      | [function-references](https://github.com/WebAssembly/function-references)                                                                                                          
 ?	      | ?	     | ?	     | ?	     | ?	      | [import/script type=module](https://github.com/WebAssembly/esm-integration/tree/main/proposals/esm-integration)                                                                    
 ?	      | ?	     | ?	     | ?	     | ?	      | https://github.com/tc39/proposal-import-reflection import module Foo from "foo.wasm";                                                                                              
 ✔️	     | ?	     | ?	     | ?	     | ?	      | typeReflection ?                                                                                                                                                                   
 ❌	      | ❌	     | ❌	     | ❌	     | ❌	      | [multi-memory](https://github.com/WebAssembly/multi-memory)                                                                                                                        
 ❌	      | ❌	     | ❌	     | ❌	     | ❌	      | jspi (Java Script Promise Integration: async!)                                                                                                                                     
 ❌	      | (✔️)	  | ❌	     | ❌	     | ❌	      | [stringref](https://github.com/WebAssembly/stringref/blob/main/proposals/stringref/Overview.md) KILLED :( GC?                                                                      
 ?	      | ✔️	    | ?	     | ?	     | 🚩	     | builtins: [js-strings](https://github.com/WebAssembly/js-string-builtins/blob/main/proposals/js-string-builtins/Overview.md)                                                       

# binaryen

[binaryen](http://github.com/WebAssembly/binaryen.git) `wasm-as --all` is always first to implement proposals:
✔️ multi-memory
✔️ GC
✔️ GC non-null locals
✔️ strings
✔️ extended const

[[wit]] / wasm world [Component Model](https://github.com/WebAssembly/component-model/tree/main/design/mvp) MVP
[Canonical ABI](https://github.com/WebAssembly/component-model/blob/main/design/mvp/CanonicalABI.md)
[webidl]()
[strings](https://github.com/WebAssembly/stringref)
[SharedArrayBuffer] has lately been DISABLED in all browsers!

# TOOLS

Binaryen | Binaryen | Wabt | Feature  
wasm-as | wasm-objdump| wat2wasm |
---------|-------------|----------|----------
✔️ | ✔️ | [multiValue](multi-value)
✔️ | ❌ | stringref https://github.com/WebAssembly/wabt/issues/2144

# RUNTIMES

Wasmer  |Wasmtime|Wasm3 |Wasmedge |Feature
--------|--------|------|---------|-------  
✔️	|✔️	 |✔️	| ✔️	|	|[multiValue](multi-value)
✔️	|✔️	 |✔️	| ✔️	| 	|bigInt
✔️	|✔️	 |✔️	| ✔️	| 	|bulkMemory
❌	|✔️	 |✔️	| ✔️	|  	|exceptions
❌	|❌	 |❌	| ✔️	| 	|extendedConst
?	|❌	 |❌	| ✔️	| 	|memory64
✔️	|✔️	 |✔️	| ✔️	| 	|mutableGlobals
✔️[1] 	|✔️	 |✔️	| 	| ✔️	|referenceTypes (externref)
✔️	|✔️	 |✔️	| ✔️	| 	|saturatedFloatToInt
✔️	|✔️	 |✔️	| ✔️	| 	|signExtensions
✔️⚠️	|✔️⚠️	 |❌	| ⚠️	| ✔️⚠️	|SIMD ⚠️ ⇨ [Flexible Vectors](https://github.com/WebAssembly/flexible-vectors/blob/main/proposals/flexible-vectors/FlexibleVectors.md) 
❌	|✔️	 |❌	| ✔️	| 	|tailCall
✔️	|✔️/❌   |❌	| 	| ❌ 	|threads
?	|?	 |?	|  ?	|  ?	| typeReflection
?	|?	 |?	|  ?	|  ?	| [funcReferences](https://github.com/WebAssembly/function-references)
✔️[1]	|✔️[2]	 |?	|  ✔️	|  ?	| interface types / reference-types component model <= webidl
?	|?	 |?	|  ?	|  ?	| [type imports](https://github.com/WebAssembly/proposal-type-imports) [Overview](https://github.com/WebAssembly/proposal-type-imports/blob/main/proposals/type-imports/Overview.md)
?	|?	 |?	|  ?	|  ?	| [import/script type=module](https://github.com/WebAssembly/esm-integration/tree/main/proposals/esm-integration)
?	|?	 |?	|  ✔️	|  ?	| [multi-memory](https://github.com/WebAssembly/multi-memory) error: only one memory block allowed

# Garbage Collection GC Proposal
GC is working in V8 (d8,deno,node) but not in other runtimes:
https://github.com/WasmEdge/WasmEdge/issues/1122 (soon!)
https://github.com/bytecodealliance/wasmtime/issues/5032 (baby steps)
https://github.com/wasmerio/wasmer/issues/357 (NOT worked on)
https://github.com/wasm3/wasm3/issues/432 (Bombed by Russians)

Most importantly [[multi-value]] is supported on all platforms

[1] : https://github.com/wasmerio/interface-types see [[struct]]
[2] :

threads & tailCall are supported by [wasmedge](https://wasmedge.org), together with interruptible aot instruction-count
gas and time metering.

⚠️ SIMD harmful proposal should be avoided in favour of much cleaner extension:  
[Flexible Vectors](https://github.com/WebAssembly/flexible-vectors/blob/main/proposals/flexible-vectors/FlexibleVectors.md)
great proposal!

Wasmtime supports Memory64, Multiple memories, Module Linking

https://github.com/WebAssembly/module-linking/ see

https://github.com/WebAssembly/component-model
https://github.com/WebAssembly/component-model/blob/main/design/mvp/WIT.md
https://github.com/WebAssembly/component-model/blob/main/design/mvp/CanonicalABI.md
https://github.com/WebAssembly/component-model/blob/main/design/mvp/canonical-abi/definitions.py

[https://github.com/WebAssembly/annotations](https://github.com/WebAssembly/annotations/blob/main/proposals/annotations/Overview.md)
WasmEdge OK
supported by wat2wasm but not wasm-as

```wasm
(module (@name "Gümüsü")
  (func $lambda (@name "λ") (@js ignore) )
)
```

https://github.com/WebAssembly/relaxed-simd/issues/ CANCER proposal, please stop it and add
abstract vector ops `i32.vector_add(a,b,out,length)`

assemblyscript :
https://www.assemblyscript.org/status.html

Most importantly [[multi-value]] is supported on all platforms

Apple is intentionally limiting the mobile web to force your hand to create an app.

# wasix and witx

To try out cutting edge or extended functionality try this:
https://docs.rs/wasix/latest/wasix/index.html

# annotations

[https://github.com/WebAssembly/annotations](https://github.com/WebAssembly/annotations/blob/main/proposals/annotations/Overview.md)

(module (@name "Gümüsü")
(@custom "my-fancy-section" (after func) "contents-bytes")
(func $lambda (@name "λ") (param $x (@name "α") i32) (result i32) (get_local $x))
)

# shared memory

Shared memory works in many environments even with 'threads' proposal not fully implemented.

```wasm
(import "env" "memory" (memory (;0;) 1 1 shared))
…
const memory = new WebAssembly.Memory({ initial: 1, maximum: 1, shared:true });
```

# atomics

https://webassembly.github.io/threads/core/syntax/instructions.html#atomic-memory-instructions

# struct and array

The [GC proposal](https://github.com/WebAssembly/gc) has types like struct and array, which are a subset of interface
types.

[interface types](https://github.com/WebAssembly/interface-types) are different from
[reference types](https://github.com/WebAssembly/reference-types/blob/master/proposals/reference-types/Overview.md)

# Interface Types

## motivations

With the newly-added externref, WebAssembly can import JavaScript functions that create JavaScript values that can be
passed to the Web IDL functions via the ECMAScript Binding, but the performance of this approach may be even worse than
the JIT-optimized glue code.

```wasm
(type $Coord (record (field "x" s32) (field "y" s32)))
```

```text
intertype ::= u8 | s8 | s16 | u16 | s32 | u32 | s64 | u64 | f32 | f64
			|  char
			|  (list <intertype>)
			|  (record (field <name> <id>? <intertype>)*)
			|  (variant (case <name> <id>? <intertype>?)*)
```

While core wasm's type contains reference values which refer to mutable state, intertype compound values are
transitively immutable.

https://github.com/WebAssembly/interface-types/blob/main/proposals/interface-types/Explainer.md

```text
the following abbreviations only exist in the concrete formats:
bool ≡ (variant (case "false") (case "true"))
string ≡ (list char)
( tuple <intertype>*) ≡ (record ("𝒊" <intertype>)*) for 𝒊=0,1,...
(flags <name>*) ≡ (record (field <name> bool)*)
( enum <name>*) ≡ (variant (case <name>)*)
( option <intertype>) ≡ (variant (case "none") (case "some" <intertype>))
( union <intertype>*) ≡ (variant (case "𝒊" <intertype>)*) for 𝒊=0,1,...
(expected <intertype>? (error <intertype>)?) ≡ (variant (case "ok" <intertype>?) (case "error" <intertype>?))
```


# .wit file format

The intention of the [wit format](https://github.com/bytecodealliance/wit-bindgen/blob/main/WIT.md) is that it maps down to interface types, so the goal of name resolution is to effectively create the type section of a wasm module using interface types. Definitions of named types such as record foo { ... } are intended to map roughly to declarations in the type section of new types.

```text
record person {
  name: string,
  age: u32,
}
hello: function(who: person) -> string
```


# interface type adapter module with adapter functions

```wasm
(adapter_module
  (module $CORE
	;; …
  )
  (instance $core (instantiate $CORE))
  (import "duplicate" (adapter_func $dup (param string) (result string string)))
  (import "print" (adapter_func $print (param string)))
  (adapter_func (export "print_twice") (param string)
	call_adapter $dup
	call_adapter $print
	call_adapter $print
  )
  (adapter_func $return_one_of (param string string i32) (result string)
	i32.eqz
	(if (param string string) (result string)
		( then return)
		( else drop return))
  )
)
```

# adapter instructions

```text
rotate $n : [ Tn+1 ... T0 ] -> [ Tn ... T0 Tn+1 ]
call_adapter $f : [ P* ] -> [ R* ]
<it>.lift_<ct> : [ ct ] -> [ it ]
<ct>.lower_<it> : [ it ] -> [ ct ]
char.lift : [ i32 ] -> [ char ]
char.lower : [ char ] -> [ i32 ]
list.lift $List $done $liftElem $destructor? : [ T:<type>* ] -> [ $List ]
list.lift_count $List $liftElem $destructor? : [ T*, count:i32 ] -> [ $List ]
list.has_count : [ (list T) ] -> [ (list T), maybe_count:i32, condition:i32 ]
list.is_canon : [ (list E) ] -> [ (list E), maybe_byte_length:i32, condition:i32 ]
list.lift_canon $List <memidx>? $destructor? : [ T*, offset:i32, byte_length:i32 ] -> [ $List ]
list.lower_canon <memidx>? : [ offset:i32, (list E) ] -> []
record.lift $Record $liftFields $destructor? : [ T:<type>* ] -> [ $Record ]
record.lower $Record $lowerFields : [ T:<type>*, $Record ] -> [ U:<type>* ]
variant.lift $Variant $case $liftCase? $destructor? : [ T:<type>* ] -> [ $Variant ]
variant.lower $Variant $lowerCase* : [ T:<type>*, $Variant ] -> [ U:<type>* ]
```

```wasm
(module
  (func $foo (param i32 f32))

  (@interface func $adapter_foo (export "foo") (param s32) (param f32)
	arg.get 0
	s32-to-i32
	arg.get 1
	call-core $foo)
  (@interface func (export "bar") (param s32) (param f32)
	arg.get 0
	arg.get 1
	call-adapter $adapter_foo)
  (type $tf (func (result funcref)))
  (type $tg (func (result (ref $proc))))
	)
```

# Typed Function References

https://github.com/WebAssembly/function-references

Unlike funcref and the existing call_indirect instruction, typed function references need not be stored into a table to
be called (though they can)

## Heap types

part of Typed Function References

https://github.com/WebAssembly/function-references/blob/master/proposals/function-references/Overview.md#types

heaptype ::= <typeidx> | func | extern reftype ::= ref null? <heaptype>

ref.func creates a function reference from a function index call_ref calls a function through a reference func.bind
creates or extends a closure by binding one or several parameters let … locally binds operands to variables

ref.func $f : [] -> [(ref $t)]
0x14 call_ref : [t1* (ref null $t)] -> [t2*]
0x15 return_call_ref : [t1* (ref null $t)] -> [t2*]
0x16 func.bind $t' : [t0* (ref null $t)] -> [(ref $t')]
0x17 let <blocktype> (local t)* instr* end : [t1* t*] -> [t2*]
ref.null ht: [] -> [(ref null ht)]
ref.is_null 0xd3 ref.as_non_null : [(ref null ht)] -> [(ref ht)]
0xd4 br_on_null $l checks for null and branches if present 0xd6 br_on_non_null $l : [t* (ref null ht)] -> [t*]

# Type Imports

https://github.com/WebAssembly/proposal-type-imports/blob/master/proposals/type-imports/Overview.md

```wasm
(import "..." "..." (type $t))
(export "..." (type <heaptype>))
(type $t (private <type>*))
```

E.g. a file API might look like

```wasm
(import "file" "File" (type $File any))
(import "file" "open" (func $open (param $name i32) (result (ref $File))))
(import "file" "read_byte" (func $read (param (ref $File)) (result i32)))
```

with private implementation

```wasm
  (type $File (export "File") (private i32))  ;; file handle
```

Instructions type <typetype> is an import description with a type constraint sub <heaptype> describes the type of a type
import, with an upper bound

private <type>* is a new form of type definition private.new <typeidx> creates a value of private type
private.get <typeidx> <fieldidx> reads a field from a private value

### wasm binary format

	deftype is a new category of defined types that generalises the contents of the type section
	 	eftype ::= <functype> | <privatetype>
	 	odule ::= {..., types vec(<deftype>)}

# module-linking

https://github.com/WebAssembly/module-linking/blob/main/design/proposals/module-linking/Explainer.md

# esm-integration

https://github.com/WebAssembly/esm-integration/tree/main/proposals/esm-integration

```text
import {foo} from "./myModule.wasm";
<script type=wasm src="myModule.wasm"> 

`import {foo} from "./myModule.wasm";`
` (import "./counter.js" "getCount" (func $getCount (func (result i32)))) `
` (import "./counter.wasm" "count" (global i32))`

```

[wasm-check](https://awesomeopensource.com/project/MaxGraey/wasm-check) code

wasm-ld --shared-memory if compiled with 'atomics' or 'bulk-memory'

# bulk-memory

```text
table.value: copy a region from an element segment

memory.value: copy a region from a data segment
top-2: destination address
top-1: offset into the source segment
top-0: size of memory region in bytes

memory.copy
top-2: destination address
top-1: source address
top-0: size of memory region in bytes

memory.fill
top-2: destination address
top-1: byte value to set
top-0: size of memory region in bytes

table.copy
data.drop: discard the data in an data segment
elem.drop: discard the data in an element segment
```

# memcpy => memory.copy

replace any exported function called memcpy or memmove with a new function with the following contents:
`
(func (param $dst i32) (param $src i32) (param $size i32) (result i32)
local.get $dst
local.get $src
local.get $size
memory.copy
local.get $dst)
`
Alternatively connect directly to v8's MemMove function

# example data to memory

```wasm
(import "a" "global" (global i32))  ;; global 0
(memory 1)
(data (i32.const 0) "hello")   ;; data segment 0, is active so always copied
(data "goodbye")               ;; data segment 1, is passive

(func $start
  (if (global.get 0)

    ;; copy data segment 1 into memory 0 (the 0 is implicit)
    (memory.value 1
      (i32.const 16)    ;; target offset
      (i32.const 0)     ;; source offset
      (i32.const 7))    ;; length

    ;; The memory used by this segment is no longer needed, so this segment can
    ;; be dropped.
    (data.drop 1))
)
```

# Combining two wasm files

Combining two wasm files is still absurdly hard, tools regularily get removed and renamed
https://github.com/bytecodealliance/wit-bindgen/issues/298
Also they never work on basic standard wasm but need custom sections (wasm-ld) or non-standard binaries (wasm-tools compose). Wasp tries to fill this gap by
allowing arbitrary arguments:
`wasp main.wasm lib.wasm` generates out.wasm without preconditions.

# Administrative Instructions

https://webassembly.github.io/spec/core/exec/runtime.html#syntax-instr-admin

```wasm
trap
ref funcaddr
ref.extern funcaddr
invoke funcaddr
label … end
frame … end
```

# Tool conventions

https://github.com/WebAssembly/tool-conventions

see [[debug]]

# SharedArrayBuffer

SharedArrayBuffer has been turned off by default after Spectre:
https://developer.chrome.com/blog/enabling-shared-array-buffer/
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer
only available to pages that are cross-origin isolated.
WebAssembly.Memory can still be used to get an instance of SharedArrayBuffer!

# package registries

wasmer is now able to run WAPM packages directly via `wasmer run`

# wast vs wat

https://webassembly.github.io/wabt/demo/wat2wasm/

The .wast extension is now used for the scripting language used by the WebAssembly test suite.

Binaryen wasm-as is ahead with implementing features like reference types, struct, array, stringref, i8, i16
wabt wat2wasm has better more forgiving syntax (no brackets needed) but understands no wasm 2.0

wabt wat2wasm --version 1.0.32 (mozilla …)
binaryen wasm-as --version 111 

# builtins

Proposal to offer JS builtins as wasm functions:
https://github.com/WebAssembly/js-string-builtins/blob/main/proposals/js-string-builtins/Overview.md

Now standardized, first for strings:
WebAssembly.compile(bytes, { builtins: ['js-string'] });

For engines that don't support builtins, any compile options passed to the JS-API will be ignored (due to WebIDL rules
for extra parameters). For engines that do support builtins, any imports that refer to a builtin are not looked up on
the instantiation import object.

Together this means that it's safe for users to request builtins while still providing a polyfill for backup behavior
and the optimal path will be chosen.

# Ad hoc GC data

(global $global$1 (ref $1) (struct.new $2
(i32.const 7)
(i32.const 0)
(i32.const 1)
))

(array.new_fixed $0 3
(i32.const 110)
(i32.const 117)
(i32.const 108)
)

(global $global$40 (ref $62) (struct.new $62
(i32.const 33)
(i32.const 0)
(global.get $global$38)
(i64.const 200)
(array.new_fixed $8 200
(global.get $global$1)

(table $0 874 funcref)
(elem $0 (i32.const 0) $166 $165 $165 $164 $164)
(elem $1 (i32.const 6) $166 $166 $166)

(local $12 (tuple (ref $1) (ref $11)))
(block $block
(try $label1
(do
(local.set $3
…
)
(br $block)
)
(catch $tag$0
(local.set $12
(pop (tuple (ref $1) (ref $11)))
)
(block
...
)
(rethrow $label1)
)
)
(catch_all
(call $228
(block (result (ref $11))
(local.set $scratch_11
(call $67)
)
(call $228
(call $230)
)
(local.get $scratch_11)
)
)
(rethrow $label1)
)  
# WebGPU
On a lower level imperative wap looks into implementing a direct sub/superset of webgpu:
https://gpuweb.github.io/gpuweb/wgsl/#matrix-types. Mixing and emitting webgpu binaries would be challenging.
