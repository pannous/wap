# wap's debts, ranked

Every `DEBT:` note in wap/ and lib/ (`git grep -n DEBT -- wap lib`), ranked by conceptual weight (how much of the
language or compiler it bends, and how many other debts wait on it) against cost (core lines it grows or shrinks, and
whether the user has to discuss it). Paid from the top, one branch each. A pure shrink lands at once; anything that
grows core goes to warp-interviewer with its shape first. When a debt is paid, its line goes; a new one is added
where it is found.

Owned elsewhere, not ranked here:
- native memory, to warp-wap-lang's hook table: analyze/data.wap:46 (core names the memory words), emit/places.wap:12
  (FIELD_BYTES twin), types/memory_lists.wap:6 and memory_texts.wap:5 (memory never freed)
- modules and the library, to warp-wap-arch: compiler.wap:22 (a used module's uncalled functions emitted),
  analyze/declarations.wap:117 (a module cycle reads a value before it is set), pipeline.wap:128 (one types file
  compiled alone), rules/stages.wap:125 (a module's rules reach files that don't use it), types/types.wap:3 (`use
  folder` brings a file twice), emit/values.wap:8 (top-level statements run in file order)

## 1. Foundations: several debts wait on each

| debt | weight | cost |
|---|---|---|
| analyze/function_values.wap:22, each function value its own type; no funcref | highest: blocks a variable holding either of two lambdas, overloads as values, protocol dispatch (calls.wap:334), a field's function called (types.wap:28), late reads through a value (types.wap:412), and native function values | large core (funcref + call_ref in the emitter, typing of a value's possible functions); user discussion |
| emit/emitter.wap:22, the emitter learns types by emitting | high: a second typing in the emitter, behind emitter.wap:236 (a second "does it fit") and the native text-match bug (equality picks by layout, a memory text is I32) | large; shrinks the emitter once done; user discussion |
| emit/lists.wap:70, one list layout per item type | high: list<int> can't stand for list, the list words exist per layout | large, touches the value layout; user discussion |

## 2. Typing and rules: medium weight, medium cost

| debt | weight | cost |
|---|---|---|
| analyze/calls.wap:287, overloads ranked by weights, not subsumption | medium: `text(1 to 3)` refused as two readings | built on branch subsumption-ranking, waits for self-build (4 more functions untyped) |
| analyze/function_values.wap:104, an overloaded function is no value (`parts.map(text)`) | medium | small, typing picks the overload by the expected function type (approved 11-22: the map(text) line) |
| analyze/calls.wap:5, typing names `#` and `!` | medium: core spells two types-module words | needs a hole asking "not this type" |
| analyze/data.wap:53, a local named like a method hides it (`source` for `map`) | medium: a name lookup bends | small typing change, then one rename back |
| analyze/scope.wap:196, bare field names only for the Block's own classes | medium | binding sees library Records |
| sugar/conditions.wap:42, rule templates bind names where they fire (no hygiene) | medium: a local can hide a library word a rule writes | template names bound in the rule's file |
| sugar/records.wap:15 and rules/templates.wap:27, a template's output is not the shape its text parses to (as/`:` two rules; DERIVED on every word) | medium: the operator `as` form needs it too (general-overload-mechanism) | templates built from their forms |
| rules/templates.wap:134, True()/False()/Empty() named beside types/nodes.wap | low | templates see declared Records |
| rules/stages.wap:235, a rewrite that loops forever hangs | medium: a hang, not a refusal | a step bound with a named refusal, small |
| analyze/types.wap:23, boxed any in the compiler's own source | medium: milestone 2 | the guardrail list shrinks entry by entry |
| parse/operators.wap:33, a program's own alias lines are not read | low | rule engine reads alias lines |
| wap/nodes.wap:24, Op's spellings twice (enum and operators table) | medium: 48 of 63 cases | Op from the table once old warp no longer reads wap's source: check whether it still must |

## 3. Behavior at the edges: low weight

| debt | weight | cost |
|---|---|---|
| emit/emitter.wap:49, a program's value shown only when an int | low-medium | show through the runtime's show words |
| emit/host.wap:106, a failed write traps without naming itself | low | a raise costs nothing unused |
| emit/primitives.wap:130, a slice past the end traps | low | bounds check in types' slice |
| types/prelude.wap:117, int + float refused | medium for programs | a conversion in typing |
| types/prelude.wap:266, `===` is value equality | low | ref.eq identity |
| types/floats.wap:8, no int `÷` or `%` | medium for programs | types module defines them |
| types/lists.wap:84, sum/product four lines of one shape | low | a numeric T naming its zero and one |
| parse/atoms.wap:68 and :119, decimals are f64, long ints read as floats | low until after self-build | exact numbers |
| core/format.wap:5, format prints no comments | low | the printer reads Meta |
| sugar/definitions.wap:17, `public` changes nothing | low | untyped words module-private |
| sugar/records.wap:8, the class rule's helper words are ordinary words | low | private words for rule files |
| lib/foreign.wap, C pointers dangle if the memory moves | low on wasmtime | — |
| extensions/native/commands.wap, a command's words one spaced text | low | a native list of texts (native memory) |
