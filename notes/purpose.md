# Purpose: what language taste agents and humans share

An agent can tolerate Rust’s verbosity, ownership machinery, compiler errors, and other syntactic or semantic friction much more easily than a human can. But that raises a deeper question: as coding agents become more intelligent, should their taste in programming languages converge toward human taste—preferring shorter, more expressive, elegant code—or diverge because agents have different cognitive costs?

My current view is that both pressures exist.

More intelligent agents should increasingly value many things humans also value:
- less redundancy
- clearer abstractions
- fewer incidental details
- strong locality
- compositionality
- semantic density
- code whose intent can be inferred quickly

So there is a real reason to expect convergence toward something like elegant code.

But agents also have different costs. Humans dislike Rust partly because lifetime and ownership constraints impose cognitive load. An agent may find these constraints comparatively cheap while valuing the additional static information highly. Likewise, an agent may tolerate generated boilerplate if it improves verifiability.

So "more intelligent" does not imply "more terse".

APL is an interesting boundary case. Extreme terseness minimizes token count but can reduce redundancy and locality of meaning. Maximum compression and maximum comprehensibility are different objectives.

The likely optimum is:

    very verbose, explicit, mechanically checkable
                    ↕
    compact, regular, strongly compositional
                    ↕
    ultra-dense symbolic golf

The target should probably be the middle:
high semantic density, but not maximum syntactic density.

A useful information-theoretic framing is:

    useful semantic information for prediction / verification
    ---------------------------------------------------------
                   representation cost

Good code is not necessarily the shortest code.

Redundancy is often useful. Descriptive identifiers, type information, delimiters, intermediate values, and structural cues act somewhat like error-correcting information. They help humans and machines detect mismatches between the written program and its likely intended semantics.

Likewise, very dense code can have poor error localization: a small mistake may change a large expression, while intermediate named steps provide more points at which the compiler, debugger, or reader can identify where the wrong value or type first appears.

However, many of Rust’s visible semantics should probably be abstracted away.

A lot of Rust machinery exists because Rust exposes concerns that higher-level languages deliberately hide:
- allocation
- copying
- moving
- borrowing
- ownership
- aliasing
- reference counting
- stack vs heap
- deterministic lifetime
- synchronization
- memory layout

Many of these concerns affect constant factors rather than asymptotic complexity.

For example, all of these may be O(n):

    copy n objects
    move n references
    scan contiguous memory
    scan pointer-heavy data

Yet their runtimes may differ by 2x, 20x, or more.

Rust exposes these choices because it wants predictable performance without a garbage collector.

But ordinary application code should probably not have to specify these decisions.

Instead, a language should let the programmer write:

    x = transform(data)

and infer whether `data` should be:
- borrowed
- moved
- copied
- reference-counted
- uniquely owned
- stack allocated
- heap allocated

using static analysis, escape analysis, profiling, whole-program analysis, or runtime specialization.

Only when inference cannot satisfy some constraint, or when the programmer explicitly cares, should syntax descend into something like:

    borrow x
    move x
    shared x
    pin x

Ownership is not merely optimization, however. It also expresses semantic guarantees:
- no use-after-free
- controlled aliasing
- deterministic resource lifetime
- race prevention
- mutation exclusivity

But even here, the compiler should ideally prove these properties rather than forcing the programmer to annotate them unnecessarily.

So the better formulation is:

    Rust-like guarantees underneath,
    high-level inferred semantics on top,
    explicit ownership/resource control only as an escape hatch.

There are many genuine trade-offs in programming-language design:

- explicitness ↔ concision
- static guarantees ↔ flexibility
- abstraction ↔ control
- predictable cost ↔ automatic optimization
- simple language ↔ expressive language
- local reasoning ↔ powerful implicit context
- uniformity ↔ specialized notation
- beginner accessibility ↔ expert density

The mistake is forcing the programmer to choose one side globally for the whole language.

A better language should use progressive disclosure of semantics:

    ordinary code
        ↓
    compiler infers almost everything
        ↓
    optional assertions / constraints
        ↓
    explicit representation / ownership / allocation
        ↓
    unsafe / raw machine control

These should not be separate languages.
They should be different resolutions of the same semantic model.

For example:

    xs = load("data")
    ys = xs.map(f)

The default semantics should specify what result is intended, not how memory must be managed.

The compiler might choose:
- borrowing
- moves
- SIMD
- parallelism
- allocation elimination
- loop fusion
- stack allocation
- reference counting

When the programmer cares:

    ys = xs.map(f) @parallel

or:

    ys = xs.map(f) @noalloc

or eventually:

    ys = xs.map(f) @borrow(xs) @simd(8)

Low-level details become constraints on compilation, not mandatory ceremony.

The key distinction is:

Rust often asks:
"Tell me enough about the implementation strategy that I can prove safety."

An ideal language should more often ask:
"Tell me the semantics you require. I will find an implementation and prove it. Tell me implementation details only when they matter."

A theoretically strong language would therefore have a small semantic core:
- algebraic data types
- functions and closures
- traits / typeclasses / interfaces
- pattern matching
- generics
- effects
- ownership/resource semantics
- modules
- explicit unsafe boundary

But most of this should not have to appear in normal source code.

The language should aggressively infer:
- types
- effects
- ownership
- borrowing
- allocation strategy
- safe coercions
- lifting / broadcasting
- overload resolution
- parallelization opportunities

Example surface syntax:

    def mean(xs: Numbers) =        # plural for list [Number]
        xs.sum / xs.count

    people
        .filter(_.age >= 18)
        .map(_.name)

    or just

    name of people with .age >= 18


Type annotations should be optional when inferable:

    square(x) = x*x

but expressible when useful:

    square(x: Real) as Real = x*x

Optional values:

    User?

Error types:

    User!? ≈ None | User | Error

Algebraic data types:

    Result<T,E> = Ok(T) | Error(E)  ( this specific case is so fundamental that its syntax must be hidden from users )

Pattern matching:

    match result
        Ok(x)    => use(x)
        Error(e) => report(e)

Effects could be inferred internally.

The programmer writes:

    load(path)

while the semantic IR knows something equivalent to:

    load(path): File ! IO, Error

Ownership should work similarly.

The programmer writes:

    f(x)

while the compiler determines whether `x` is:
- borrowed
- moved
- copied
- shared
- stack-allocated
- heap-allocated
- eliminated entirely

Only ambiguous or deliberately constrained cases should require:

    f(move x)
    f(ref x)
    f(copy x)

This is analogous to type inference.

We no longer normally require:

    Integer x = Integer(3)

because the compiler obviously knows the type of `3`.

Ownership inference should eventually feel similarly obvious in many situations.

Parallelism should also be inferred when semantics permit:

    result = items.map(expensive)

with optional constraints:

    result = items.map(expensive) @serial

or:

    result = items.map(expensive) @parallel

Cost semantics should ideally be queryable and constrainable:

    cost sort(xs)

could expose something like:

    time: O(n log n)
    memory: O(n)

and source-level contracts could eventually support:

    @memory <= 4MB
    @latency < 5ms
    result = process(data)

Optimization then becomes partly a constraint-solving problem.

An especially important architectural idea:

The canonical program representation should not necessarily be source code.

There should be a richer semantic IR:

    semantic IR
      ├── concise human view
      ├── explicit systems view
      ├── mathematical view
      └── optimized machine representation

Source code is a projection of this richer model.

This means there is no requirement that human-readable source contain every fact needed by the optimizer or verifier.

This is especially relevant in an agent era.

A compiler may include an agent-assisted semantic elaborator, but the result must become deterministic typed IR.

The agent may help interpret concise or partially ambiguous source, but after elaboration there should be a stable, reproducible semantic representation.

For example, a high-level surface form:

    delete old files

might elaborate once into a deterministic representation equivalent to:

    files
        |> filter(age > threshold)
        |> delete

with explicit types, effects, ownership, and contracts recorded in the semantic IR.

Naturalness is allowed at the input layer.
Reproducibility is enforced at the semantic layer.

This avoids both extremes:

- Rust: mechanically explicit everywhere
- natural-language programming: semantically unstable everywhere

I also have two existing language experiments that should inform this design.

First: https://github.com/pannous/rust-script

The philosophy there is roughly:
"Beauty without compromising correctness."

It keeps Rust’s underlying semantics but attacks avoidable syntactic cost.

Examples include:
- implicit main / scripting support
- optional trailing semicolons
- optional commas
- `#` comments
- `:=` / `var`
- `def`
- `class`
- simpler return-type notation
- `i++`, `i--`
- arrow functions
- `and`, `or`, `not`
- Unicode boolean operators
- Unicode comparisons
- `in`
- exponentiation
- approximate equality
- implicit multiplication such as `2π`
- built-in `π` and `τ`
- int-float coercion
- simpler strings
- string interpolation/concatenation conveniences
- `T?` optionals
- optional chaining
- `??`
- shorthand unwrap
- `nil`
- simpler lists/maps
- iteration conveniences
- simpler type aliases and casting

Some of these are particularly important conceptually.

`i32?` is arguably better surface notation than `Option<i32>` because nullability is a common semantic concept that should not require exposing its implementation representation.

Likewise:

    x?.foo
    x ?? default

express common intent directly.

The general principle is:

Common semantic concepts deserve syntax proportional to their conceptual complexity, not their implementation complexity.

Similarly, `and`, `or`, and `not` may be preferable to historical C operators `&&`, `||`, and `!`.

Unicode mathematical notation such as:

    ≤ ≥ ≠ π τ ≈

should be considered seriously rather than rejected for historical ASCII reasons, provided ASCII equivalents remain available.

Safe numeric coercion is also desirable where there is a unique, canonical, non-surprising widening.

For example, some conversions can be implicit while narrowing or lossy conversions remain explicit.

Strings are another example of abstraction leakage.

The programmer often means:

    "foo"

not:

    "foo".to_string()

The compiler should choose borrowed static storage, owned storage, copy-on-write representation, small-string optimization, etc. where possible.

However, some convenience features need caution.

For example:

    Some(3) == 3

may be reasonable as lifted equality, but should not imply arbitrary transparent auto-unwrapping.

Truthiness is also dangerous if generalized too broadly.

Optional presence may have a natural Boolean interpretation, but arbitrary integers, strings, empty collections, NaN, etc. create hidden language-wide semantics.

Likewise, automatically deriving `Copy` is more semantically consequential than automatically deriving something like `Debug`.

Second: https://github.com/pannous/Warp/wiki/inventions

Wap explores a deeper idea:
programming syntax should be shaped around semantic relations rather than around traditional compiler parsing conventions.

Examples include forms like:

    square of number = it*it

where `of` acts roughly as a linguistic inverse of `.`.

This permits choosing information order according to context rather than forcing one syntactic direction.

Another important Wap idea is typed iteration:

    for each byte in "Hello"
    for each char in "你好"

More generally:

    for grapheme in text
    for byte in text
    for line in file
    for row in matrix

The requested iteration variable type selects the view of the underlying object.

This is elegant because a string legitimately admits several traversals:
- bytes
- code points
- Unicode scalars
- grapheme clusters

Rather than inventing unrelated APIs, the noun/type participates in dispatch.

Wap also explores compile-time ambiguity resolution.

Traditional language design assumes:

    ambiguity = language design failure

But with IDEs and agents another model becomes possible:

    ambiguity
        ↓
    interactive disambiguation
        ↓
    persistent semantic annotation

The visible source may remain concise while the canonical semantic layer stores the resolved parse.

This is important.

It supports the idea that source text need not be the complete canonical program representation.

Universal broadcasting/lifting is another Wap direction:

    square 3
    square [1 2 3]

A good modern formulation would make this principled through the type system rather than through ad-hoc magic.

For example, a scalar function:

    square : Number -> Number

may obtain lawful structural lifting over containers where appropriate.

Wap's more aggressive gap-filling ideas are interesting but dangerous.

For example, inferring omitted arguments from nearby variables can reduce locality and resemble dynamic scope or implicit parameters.

A safer modern version is:
allow the compiler or agent to propose an inferred binding, but show and persist the resolved binding in semantic IR.

This leads to a possible synthesis:

    Wap-like expressive surface
        ↓
    rich typed semantic IR
        ↓
    Rust-like verified implementation

That is the main design direction.

The language should not simply be "Rust with prettier syntax".

It should define its semantics independently and use Rust-like guarantees as a lower-level target.

Implementation strategy:

Do not fork Rust as the language core.

Use Rust as:
- the compiler implementation language
- perhaps the initial generated backend
- a source of libraries/tooling
- potentially a semantic inspiration for safety guarantees

But define the new language from scratch.

Recommended architecture:

1. Surface syntax
2. Parser
3. AST
4. Name resolution
5. Type inference
6. Effect inference
7. Ownership/resource inference
8. Typed semantic IR
9. Optimization / constraint solving
10. Backend generation

Initial backend:

    new language
        ↓
    typed semantic IR
        ↓
    generated Rust
        ↓
    rustc / LLVM

Later:
- direct LLVM
- Cranelift
- WASM
- native code

Do not inherit Rust syntax or parser constraints unnecessarily.

The first implementation should deliberately support a small coherent subset:
- integers
- floats
- booleans
- strings
- variables
- functions
- function calls
- lists
- records
- `if`
- `match`
- optionals
- results
- basic traits
- basic type inference

The most important research contribution is not syntax.

It is the semantic elaboration layer:
can concise, partially implicit source reliably elaborate into explicit, safe, deterministic systems-level semantics?

Ownership is particularly important.

Do not expose the Rust borrow checker directly.

Start with something closer to:

- immutable values by default
- unique mutable values when provable
- reference counting as fallback
- explicit move/borrow only as optimization or control annotations

The compiler should choose among:
- stack value
- borrowed reference
- unique heap object
- Arc/Rc-like shared ownership
- copy
- move

without changing source semantics.

This is closer to Swift ARC + Rust guarantees + escape analysis than to Rust proper.

A very good first research milestone would be to support three equivalent levels of programmer control:

    x = f(data)

Compiler chooses ownership/allocation strategy.

    x = f(borrow data)

Programmer constrains ownership.

    x = f(data) @noalloc

Programmer constrains performance behavior.

The first allows inference.
The second constrains representation/ownership.
The third constrains cost.

The deeper objective is to create a language where correctness and high-level semantics are primary, while low-level representation is inferred unless the programmer explicitly chooses to care about it.

Please use all of the above as design context.