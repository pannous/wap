# Open decisions for the user

Shapes waiting for the user's discussion, each with its core lines, the case against, and why no hook or library
does it. Line counts are estimates from reading the code, marked as such; the measured size comes with the branch.
An entry goes once decided (its decision then lives in the wiki or notes/debts.md).

## The top debts (notes/debts.md), 2026-11-22, warp-fixer; 1 and 3 decided 2026-11-23 (cards signature-function-values,
own-type-overloads), the "5" + 3 warning parked (digit-text-compile-warning)

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
- wap-reviewer 2026-11-23: misconception. Only 5 Op cases are named in wap/ (Colon 77, None 48, Assign 3, Define 2,
  Add 2): no 108-use rename, and an enum built from the table makes core name library operators. Better shape: Op
  keeps the structural cases the reader and kernel need (: . := = -> None), every other operator rides as its
  spelling through Other; Op.Add's 2 uses go through the table row. Estimate −55 to −60, no enum-from-list rule.
  Check first: does scripts/wap-census.warp (old warp) still parse nodes.wap?

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
- wap-reviewer 2026-11-23: right goal, wrong place: read and normalize each template once when its rule is declared
  (per build), not per firing; compile-time cost ≈ 0. Pay stages.wap:235 with it. Estimate −10 to +5.
