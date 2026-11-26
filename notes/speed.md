# Speed of the compiler

## Measuring

- The benchmark is the self-compile, run from a built compiler's folder (data/wap-tests/wap1-<hash>/):
  `bin/wap bin/wap-seed/wap.wasm --sources compiler.wap <out.wasm>`. Without the output file the compiler only prints
  its usage, which measures startup alone.
- Speed is instructions retired (`/usr/bin/time -lp`), from warm runs; run-to-run noise is about ±1.5%.
- Two compilers are compared on the same sources; a costly source line is found by one compiler on two copies of the
  sources that differ in it.
- Per-function time: merge bin/wap-seed/wap.wasm with a glue module whose `_start` calls `main` only (wap.wasm runs its
  own `warp/start` from its start section), run the merged module with wasmtime from inside bin/wap-seed
  (`--dir=.::$PWD --dir=/ --profile perfmap`, `-O gc-heap-initial-size=2147483648`, `-C collector=copying`), sample it
  with /usr/bin/sample and name the JIT addresses from the perf map. Self time is the "Sort by top of stack" section.
  wasmtime's guest profiler is no guide: it puts half the time in closure adapters, which run 1% of it.

## Where the self-compile's time goes

Running self time, the self-compile of a2107d22 (256 G instructions natively):

| share | where |
|---|---|
| 26% | wasmtime's garbage collector |
| 14% | text equality, `==(a: text, b: text)` |
| 10% | `hashed(t: text, size: int)`, the name tables' hash |
| 7% | `fact_of`, a node's facts read by name |
| 4% | `meta_unwrapped` |
| 3% | `%` of ints, most of it in `hashed` |
| 1% | closure adapters, 0.5% the lambdas themselves |

Names dominate: comparing and hashing texts is a quarter of the time, so a fact or name read by a number instead of a
text is the biggest lever after the garbage collector.

## Overloads

Choosing a definition reads every overload of the word called: a word with a hundred more overloads makes every call
of it slower to choose. Giving each class a generated `#(self, key)` (a hundred classes, so `#` of lists and texts
among a hundred more definitions) costs the self-compile 18.8% more instructions; the choosing alone
(chosen_definition, its filter over the signatures, takes) grows 70-80%, a fifth of the growth; the rest is more
typing overall (body_typed +49%).
