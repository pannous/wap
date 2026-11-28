# T5f erasure: the emitter emits what typing decided

The plan of coc-t5.md's T5f row (coc-plan.md 9.7). The emitter today does three things it should not:
- it picks the build's strategies inline, at every site;
- it partly learns a value's type by emitting it;
- it answers "does it fit" a second time.

T5f takes each away. It is three steps, because they wait on different things.

| step | what | waits on | core (estimate) | elsewhere |
|---|---|---|---|---|
| T5f1 the build's strategies | one `Strategy` record, chosen once in `emitted`, replaces the `p.m.memory != ø` branches | nothing | about −20 | native +25 |
| T5f2 types read, not learned | the emitter reads each form's TYPE fact and emits the conversion typing wrote; emitter.wap:22's and :263's DEBTs are paid | T4d, T5b4 (every conversion and match typed) | about +20 −90 | |
| T5f3 what emits nothing | an argument or binder whose type is a proposition, or a level, emits nothing | T6a1b (`by` as a term), T4e (value arguments) | about +30 | |

Together they come to about −60 core plus native +25. The row's emit +200 −150 counted the strategies as new emitter
code; T5f1 moves the memory side out to the native extension instead. T8c waits on T5f1 only, because the int layout
is one of the build's strategies (coc-plan.md "T8c after … T5's erasure stage").

## T5f1 the build's strategies (it can start now)

The memory build is filled by extensions/native/memory.wap into `MemoryLayout` (core/emit/memory.wap). Core then asks
`m.memory != ø` at each site:

| file | sites |
|---|---|
| emit/values.wap | :37 memory_layout, :67 compound_layout, :72 memory_kept, :100 missing_value, :102 missing_tested, :143 captures_layout, :217/:219 fixed_text |
| emit/places.wap | :24 field place, :41 struct_made, :61 record made |
| emit/function_values.wap | :25 capture read, :45 captures made, :81 signature_part |
| emit/primitives.wap | :109 box_opened, :112 present |
| emit/host.wap | :90 raising_function |

The general form is a record of the strategy's answers, `class Strategy { missing: …; missing_tested: …;
captures_layout: …; struct_made: …; field_read: …; fixed_text: …; box_opened: …; present: …; raised: … }`:
- core holds the GC one;
- the native extension gives the memory one, beside the layouts it already fills;
- `MemoryLayout` folds into it.

Each site becomes one call of `p.strategy.<answer>`, and core no longer knows which build it emits. This is the same
shape as T1's primitive table: one lookup, the variants as data.

- Path: careful (emit, the self build). test_native and test_hello must be green before and after, and the census
  must be unchanged.
- Test lines: no new green line. All tests stay as before, test/wap/test_native.sh above all: the memory build is
  what this step moves.
- Owner: emit is core, so the change goes to warp-interviewer first. It is a shrink that adds no form.
- debts.md:10 ("native memory … emit/places.wap:12") is paid with it.

## T5f2 types read, not learned

- **emitter.wap:22.** An `if` joins its arms' emitted layouts, and a primitive takes its operands' emitted layouts.
  - After the step, both read `typed_layout` (places.wap:14), the TYPE fact typing wrote.
  - choice_fitted (emitter.wap:225) already does this for the chosen part; the join and the primitives follow it.
- **emitter.wap:263, the second "does it fit".** `fitted` decides on wasm layouts whether a value needs a cast, a
  box or nothing.
  - Typing already writes the boxing (`prim box`) and T4a's Same and Narrowed. T4d writes every obligation's verdict.
  - Once a T5b4 match arm also carries its conversion, the emitter emits only the conversion it is handed, and
    `fitted` goes.
  - The debts.md:22 row goes too, with its native text-match bug: equality picks by layout, and a memory text is I32.
    Equality then picks by the TYPE fact.
- Functions with statements keep today's path while T5d is parked (coc-t5.md's re-read): their nodes carry TYPE facts
  but no kernel term, and TYPE is all this step reads.
- Test lines: no wiki line names this step. Its outcome is the suite unchanged, and the native text-match bug, which
  has no test line yet. Add one from wiki/text.md's equality examples, run by test_native.sh on the memory build.
- Estimate: −90 is the join, the operand layouts and `fitted` with its helpers (emitter.wap:263-294); +20 is reading
  the facts.

## T5f3 what emits nothing

coc-plan.md 9.7: types, levels and proofs emit nothing.
- **Laws** emit nothing already: the build rules drop them, and `wap laws` makes each one a function for verify.
- **Proofs.** T6a1b's `by` as a term puts proofs inside functions, in match arms, chain steps and lets. A binder
  whose type is a proposition (`law widened(h: a ≤ b)`, wiki/theory.md:3) then exists in a function that runs.
  Erasure drops it: the kernel's sort of its type is Prop, read once per binder. Its argument at every call goes
  too.
- **Levels** are not values: `Type(u)`'s u emits nothing.
- **Types used as values stay.** wiki/universe.md:52 `identity(int)` gives `int`, a type as a run-time value. So a
  type argument is erased only where nothing in the body uses it as a value.
  - The test is the binder's uses, not its sort.
  - This is where wap differs from Lean, which erases every type.
- **T4e's value arguments** (`vector(T, n: nat)`): n is an index, used in the type. It emits nothing unless the body
  reads it.
- Test lines, from wiki pages, once those forms run:
  - wiki/universe.md:50-53 (`identity(3)`, `identity(int)`, `identity(Type)`);
  - a function with a proof parameter called with `by`, from the T6a1b wiki lines.

  Each test checks the value it runs to, never the module's shape.

## Reused landed mechanisms

- T1's primitive table: one row lookup, the variants as data. T5f1 is that shape for strategies.
- `typed_layout` and choice_fitted: the emitter already reads a TYPE fact.
- Typing's `prim box` and T4a's Same and Narrowed: conversions typing writes.
- The build rules, which already drop laws.
- `MemoryLayout`, filled by the native extension: it becomes the memory Strategy.

## Open, for warp-interviewer

- **T5f1 now.** It waits on nothing and is a core shrink of about 20 lines that adds no form. It is also all that T8c
  needs from T5f. Recommendation: build it now, ahead of T5b to T5d.
- **T5f3's type-value rule.** A type argument is erased by its uses, because `identity(int)` gives `int`. This keeps
  wiki/universe.md as written, and erasure reads uses rather than only the sort. The other reading erases every type,
  which would refuse `identity(int)` at run time and needs a wiki change. Recommendation: by uses.
