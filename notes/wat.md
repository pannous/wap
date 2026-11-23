# [[wasm]] text formats

# wast vs wat

https://webassembly.github.io/wabt/demo/wat2wasm/

The .wast extension is now used for the scripting language used by the WebAssembly test suite.

Binaryen wasm-as is ahead with implementing features like reference types, struct, array, stringref, i8, i16
wabt wat2wasm has better more forgiving syntax (no brackets needed) but understands no wasm 2.0

wabt wat2wasm --version 1.0.32 (mozilla …)
binaryen wasm-as --version 111 

# recursive types and inheritance

(rec
(type $5 (sub (struct (field (mut i32)))))
(type $6 (sub $5 (struct (field (mut i32)) (field externref))))
(type $7 (sub $5 (struct (field (mut i32)) (field (ref func)))))
(type $8 (sub $5 (struct (field (mut i32)))))
)

# exception tags

Tags are part of the exception handling proposal in WebAssembly and are used to define custom exception types.

```wat
(tag $tag$0 (param i32 (ref eq) (ref $0) i32))

(block $block (result (ref null $kotlin.Unit))
  (try
   (do
    (call $main)
    (br $block
     (global.get $kotlin.Unit_instance)
    )
   )
   (catch $tag$0
     (pop (ref null $kotlin.Throwable))
    (throw $tag$0
     (local.get $t)
    )
   )
```

# eqref

eqref is suggar for (ref eq): A reference to any equality-comparable object.

# stack via table

(export "$trampoline-tag" (tag $tag$0))
(export "$raw-stack" (memory $0))
(export "$scm-stack" (table $1))
(export "$ret-stack" (table $2))
(export "$dyn-stack" (table $3))