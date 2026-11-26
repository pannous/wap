# Metaprogramming: programs that write programs and proofs

The layer after track T (notes/coc-plan.md T7). Lean's metaprogramming has three layers; wap's rules already hold the
first, and the other two grow out of them. What it builds on: holes are explicit facts of the one elaboration, types
are kernel terms, and the compiler is wap, so code run at compile time is ordinary wap run by the compiler.

| layer | what it does | wap now | missing |
|---|---|---|---|
| macros | syntax to syntax | `rewrite` rules (sugar/), the shape and declaration rules (stages 1, 2) | little |
| elaborators | code run while typing, the types in hand | the kind rules (stage 3) fire on typed nodes, as patterns only | a rule whose right side is a wap function |
| tactics | programs building a proof term toward a goal | none | goals, holes as values, terms quoted and unquoted |

## Steps

1. **Procedural rules.** A rule's right side may be a wap function, run by the compiler on the matched node: it reads
   the node, its type and the open holes, and gives a node or a term. A pattern rule is the case whose function only
   substitutes. One mechanism for the three stages, no stage-specific hook. About 150-300 core lines.
2. **Quoted terms.** A kernel term as a value and back: quasi-quote and splice (notes/symbolism.md `«…»`), checked so
   a spliced term has the type its place wants (as Scala 3's typed quotes, notes/backbone.md). About 100-200 core.
3. **Reflection.** A function's parameters, body, calls and reads as values (`f.params`, `f.body`), first wanted by
   lib/shaders.wap. Library words over step 2, about 100 lines.
4. **Goals.** A proof's open holes as goals: each one's context and wanted type, filled by a term or split into new
   goals. Library words, about 200-400 lines.
5. **Tactics.** `by` blocks running tactics in plain wap over step 4: `intro`, `apply`, `exact`, `induction`, `cases`,
   `rewrite`, `calc`. About 500-1000 library lines.
6. **Automation**, each its own project in the library: a simplifier (`simp`), linear arithmetic (`omega`, replacing
   the theory extension's linear prover), search (`aesop`). About 1000-3000 lines each.

Steps 1-5: about 1500-3000 lines, 400-800 of them core.

## Rules

- A tactic is a wap function; tactics are library, never core words.
- The kernel stays the only judge: whatever a procedural rule or tactic builds is checked by the kernel, so a wrong
  tactic gives a refusal, never a wrong proof.
- Steps 1 and 2 are core and go to the user first, with three libraries that use them (AGENTS.md Layers): shaders
  reflection, units or derived instances, tactics.
