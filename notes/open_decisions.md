# Open decisions for the user

Shapes waiting for the user's discussion, each with its core lines, the case against, and why no hook or library
does it. Line counts are estimates from reading the code, marked as such; the measured size comes with the branch.
An entry goes once decided (its decision then lives in the wiki or notes/debts.md).

## The top debts (notes/debts.md), 2026-11-22, warp-fixer

### 1. Function values without a written type: one funcref type for every value of a signature

- Debt: analyze/function_values.wap:22, partly paid already. A value of a written signature, `f: (int) -> int`, is a
  funcref beside its captures and is called by call_ref (emit/function_values.wap). A value without one,
  `g = x => x + 1`, still gets a type of its own, fn<key, captures…>. So a name holds one lambda only, `if c then (x
  => x) else (x => x + 1)` gives no value, and a function's name is no value when it has several overloads.
- Shape: typing gives every function value the signature type of its parameters and result once they are known
  (the lambda's own type turns into its signature where it meets another value or a typed place). The direct call
  stays as the fast path where only one function can reach the call. One conversion in core/analyze/fits.wap, its
  emit in function_values.wap.
- Core: estimate +30 to +50 lines, of which some 10 come back out of the special cases for values of their own type.
- Pays with it: types.wap:28 (a field's function value called), calls.wap:334 (protocol dispatch), types.wap:412
  (late reads through a value), and
  native function values (wap-help had to use an enum Action) once native memory has a funcref table.
- Against: the largest of the four. Each changed call site risks the self-build census, and a call through a
  reference is slower than a direct call (kept where only one function can reach it).
- No hook or library: a value's type is typing's own decision. A library cannot make two lambdas one type.

### 2. Op comes from the operator table: each spelling once

- Debt: wap/nodes.wap:24. The Op enum spells 63 operators beside types/operators.wap's table, and 48 cases have no row
  of their name. The note says it is paid "when old warp no longer reads wap's source". wap compiles itself from
  its own seed now (wap-seed-*), so that condition may already hold; to be checked first (does any script or test
  still compile wap's source with old warp?).
- Shape: Op's cases are the table's operators by their English names (Add from `+`'s row "add"), declared from the
  table by one rule or a declaration form, not written out. The 108 `Op.` uses in wap/ follow the renames (sub →
  subtract, lt → less …). The compound assignments (`+=`) stay derived, as operator_table.wap does already.
- Core: estimate −60 to −70 lines (the enum's spelled list goes), plus a mechanical rename across about 108 uses. A
  declaration that builds an enum from table rows needs a rule able to write an enum from a list: estimate +5 to
  +10 lines in rules/templates.wap, unless an `enum Op { (cases of operators)... }` template already works.
- Against: a large rename churn across the compiler for no change in behavior; the seed must compile the renamed
  source (one seed refresh in between).
- No hook or library: the table is library data already. The duplicate is the core enum, so only core can drop it.

### 3. Hygienic rule templates: a template's words bind where the rule is written

- Debt: sugar/conditions.wap:42. A template's words bind in the program's scope where the rule fires, so a local
  named `missing` hid the types module's predicate (calls.wap renamed its own to `lacking`).
- Shape: each word a template writes that its pattern did not bind carries the rule's file (a fact, as DERIVED
  is carried now); binding looks such a word up in that file's scope first, then the program's.
- Core: estimate +10 to +15 lines (rules/templates.wap marks them, analyze/scope.wap reads the mark). With it,
  templates.wap:27's DERIVED-on-every-word can likely become the same mark (−3).
- Against: a rule that means to call the program's own word (a deliberate hook through a template) would need to
  say so; none of wap's own rules does today, to be checked across sugar/.
- No hook or library: name binding is core. A library can only rename its words to dodge locals, which is the
  workaround the debt names.

### 4. A template's output has the shape its text parses to

- Debt: sugar/records.wap:15, rules/templates.wap:27. A template writing `($head: $type := $body)` builds a Define,
  while the same text in a program reaches the rules as its phrase. So a rule's output never fits another rule
  written for the source text: a method's `as` and `:` forms are two rules, and the operator `as` result type
  (dropped from general-overload-mechanism) could not be written as one rule.
- Shape: a template is built by the reader and operator stage from its text, as the program is, and fires the rules
  again (the termination check already guards that). The template builder's own Define and Set construction goes.
- Core: estimate −10 to +10 lines: the builder's special cases go, a re-reading of the built phrase comes in.
- Against: every sugar rule's output is read once more (compile time). The termination check must hold for chains
  that now fire; stages.wap:235 (a rewrite looping forever hangs) becomes more likely, so it should be paid first
  or with it.
- No hook or library: the template builder is the rule engine's core.

## Also open from 11-22

- `"5" + 3`'s compile-time warning: a rule cannot test a literal's content (a hole like `$t: is_digits` matches the
  name of a test function, it does not run it). Options: a hole that runs a compiler test on a literal (+10 to +15
  core, with `=> warn` +4), or keep the run-time hint, now once per run (digit-hint-once, lib only, built).
