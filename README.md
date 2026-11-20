# 𖣲 Wap

**WebAssembly Programming language**  

A data format that is also a programming language, compiled straight to Wasm GC.

```wap
contact{ name: James  age: 33 }
assert contact.age + 1 == 34
```

The same notation holds your config, your markup and your program. Wap compiles it to WebAssembly GC structs (no linear-memory runtime, no JS glue), and the wap compiler is itself a WebAssembly module [written in wap itself](#self-hosted)!

▶ **[Try it in your browser](https://warp.pannous.com/)**: nothing to install. The compiler runs locally in a Web
Worker.

## Why Wap
Even when 99% of code is written by AI, we can aim for the perfect programming language: ideal for humans and AI
alike, type safe but not verbose, universal and fast (compiled ahead of time to WebAssembly), highly structured and
expressive. Agents benefit from clean abstractions too.  
- **Data is code.** Like Lisp, but with types and maps.
  JSON-like, but no quotes around keys or symbols.
- **Wasm GC first.** A `class Person{name:String age:i64}` becomes a real `(struct …)` type
- **No [Footguns](https://github.com/pannous/wap/wiki/Footguns)** When code could mean two things, the compiler warns
- **Beauty and Batteries** Implicit `it`, inferred parameter and return types, Unicode operators, and English words for
  operators where they read better:
  ```wap
  square := it²
  square(3) + square 4              // 25

  fib := if it < 2 then it else fib(it - 1) + fib it - 2 
  fib(20)                            // 6765
  ```
- **Markup is just data.**
  ```wap
  html{ body{ h1: "Welcome"  p: "made of data" } }
  ```

## Install

**Nothing to install:** [wap.pannous.com](https://wap.pannous.com/) runs the compiler in your browser.

**Homebrew** (macOS, Linux):
```bash
brew install pannous/tap/wap
```

<!--
**Debian, Ubuntu, Fedora** (glibc 2.39 or newer: Ubuntu 24.04, Debian 13, Fedora 40): the `.deb` or `.rpm` of the
[latest release](https://github.com/pannous/wap/releases/latest), e.g.
-->
**Linux**:  
`sudo apt install ./wap-lang_*_amd64.deb` or `sudo dnf install ./wap-lang-*.x86_64.rpm`.

**Prebuilt binaries** (macOS arm64 and x86_64, Linux x86_64 and arm64): download the archive for your platform from the
[latest release](https://github.com/pannous/wap/releases/latest) and put `wap` on your `PATH`.

**From source** (wap builds itself, so it needs an installed `wap` first):
```bash
git clone https://github.com/pannous/wap && cd wap
wap rebuild                              # wap.wasm, the compiler written in Wap (core/), then the native wap command
```

## Run

```bash
wap               # interactive console "repl"
wap help                         # all commands
wap sample.wap   # run a file, server, webapp or gui
wap build sample.wap # the standalone executable (aot native and .wasm)
wap test              # the tests under test/
```

`samples/` contains classics (game of life, Dijkstra, Levenshtein, a JSON parser, a neural net) in both a
Python-like style and an idiomatic Wap style, one folder per chapter of the guide (samples/graphics, samples/sound …).

## Packages

[use](https://github.com/pannous/wap/wiki/use) loads a local module, or else a package of the registry
[wap-packages](https://github.com/pannous/wap-packages) by name, fetched once into `packages/`:
```wap
use colors
to_hex(mix(from_hex("#ff0000"), from_hex("#0000ff"), 0.5))   # "#800080"
```

## Wasm GC objects

```wap
class Person{ name: text  age: int }
alice = Person{ name: "Alice"  age: 30 }
alice.age + 1                      // 31
```
A class is a real GC struct, not a map in linear memory. The compiler emits (`wap compile`, simplified):
```wat
(type $Text (array (mut i8)))
(type $Person (struct (field $name (ref $Text)) (field $age i64)))
(func $main (result (ref $Person))
  i32.const 0  i32.const 5  array.new_data $Text 0   ;; "Alice" from the data segment
  i64.const 30
  struct.new $Person)
(data "Alice")
```
Texts are GC byte arrays; linear memory is used only to hand bytes to the host or C.
<!-- and for bootstrapping the native wap via wasm2c -->

Untyped data travels as one universal GC type, `$Node {kind: i64, data: anyref, value: (ref null $Node)}`. It mirrors
the `Node` enum (`Text`, `Symbol`, `Number`, `Char`, `Key`, `List`, `Type`, `Meta`, `Data`, `Error`) in
[core/node.wap](core/node.wap).

## Status

Proven to be (almost) **production ready** by being able to compile the whole language written in wap [itself](https://en.wikipedia.org/wiki/Self-hosting_(compilers))! Experimental and moving fast. Tests 100% samples passing, general progress viewable in this [dashboard](https://claude.ai/artifact/PupNqVoBxQGvBjVxkqxGuq)  

The language spec lives in the
[wiki](https://github.com/pannous/wap/wiki), and parts of it are not implemented yet. Wap began as a Rust rewrite of  
[Wasp](https://github.com/pannous/wasp) (C++), which followed the Python experiments  
[Angle](https://github.com/pannous/angle) and [english-script](https://github.com/pannous/english-script);  
its compiler is now written in Wap itself ([core](core)), and so is the native `wap` command, which runs programs through wasmtime's C API ([core/native](core/native)). The old Rust compiler is preserved on the branch [rust-bootstrap](https://github.com/pannous/wap/tree/rust-bootstrap).

The compiler has three layers:
- **core**: just enough for wap to compile itself
- **extensions**: every other language feature
- **libraries**: modules programs import

**[Try it in your browser](https://wap.pannous.com/)**: 
Feedback and issue reports are welcome.

## License
The compiler is licensed under the [GNU AGPL v3 or later](LICENSE); the runtime `crates/wap-runtime`, which goes into every program built with wap, under the [MIT license](crates/wap-runtime/LICENSE), so your programs are yours. Commercial licenses of the compiler: info@pannous.com. Contributing: [CONTRIBUTING.md](CONTRIBUTING.md).
