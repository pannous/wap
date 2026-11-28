# T6a3 steps 2b and 3: a family's cases and their calls

Read on t6a3-indexed-families + t6a3a (unbuilt). wiki/proposition.md `Even`, wiki/enum.md "Arguments and result types".

## Where the code stands
- stage.wap `case_result(case)` reads a case's written result (`step(e: Even(n)): Even(n + 2)`); nothing calls it.
- inductives.wap `block_entered` declares a family's word with its indices (`record_sort`, T6a3 step 1), but every case's
  type is `case_type`: `Π keys, Π parameters, Π fields, enum.whole`. The result is always the enum applied to its
  parameters, so `Even.zero: Even` and the index is never written. `enum_cases` drops a case's result and a field naming
  `n` is open (`closed_type` has a letter that is none of the enum's), so the enum stays counted open.
- `case_term` (a constructor called) types `fields_given(...) == value_type(n)`: first order, no letters, no index.

## Step 2b: a case's own result and the letters it finds
In `enum_cases`/`CaseTyped` (inductives.wap, core about +30):
1. `CaseTyped` gains `result: Term?` = `closed_type(written_type(case_result(case)), letters + found)`; ø where the case
   writes none (then `enum.whole`, today's reading).
2. `found: list<text>` = the one-letter names a case's fields and result use that are no parameter of the enum, in the
   order written (`n` in `step`). Their types come from where they stand: a letter in the family `Even(n)` takes the
   index type from the header (`nat`); a letter as a field type (`x: T`) is a `Type`. A letter found twice with two
   index types is refused naming the case.
3. `case_type` folds the found letters in front of the fields as binders (implicit), then fields, then
   `case.result ?? enum.whole`. A result that is not the enum's own word applied to its parameters then indices is
   refused naming the case (`zero: Nat` inside `Even`). The block's header sort has the index domains already
   (`domains_of(header_of(enum))`), so the kernel's inductive check sees an indexed family; kernel 0.
4. `case_fields` consumers that count a case's fields (`fields_given`, `case_minor`, `enum_cases` lengths) count the
   written fields only; the found letters are bound by the call (step 3), never written by the caller or the pattern.

## Step 3: a constructor call typed from its fields
`case_term(n, called, arguments, x)` (inductives.wap, about +25), for a case with found letters or an index in its result:
1. Take the constructor's type with the enum's parameters filled from `parts_of(value_type(n))` as today.
2. Open the found letters as unknowns (analyze has `hole`/`unified` on an `Elaboration`; `letters_bound` is the
   existing first-order solver and takes a definition's `Signature`: reuse it by giving the case its Signature
   rather than writing a second solver).
3. Unify each field's domain with `value_type(argument)`, left to right. `Even.step(Even.zero)`: the field domain is
   `Even(?n)`, the argument's type is `Even(0)`, so `?n := 0`. A letter no argument settles is refused naming it
   (`fill it by writing the argument that fixes it`).
4. The call's type is the case's result with the letters filled: `Even(0 + 2)`. It is not unified with the type the
   node wants; the kernel's conversion then compares `Even(0 + 2 + 2)` with `Even(4)` (the reason is in coc-plan
   T6a3 step 3: a first-order unify cannot solve `?n + 2 = 4`). So `case_term` today's last test
   `fields_given(...) != value_type(n)` becomes "the kernel judges the two equal", `kernel_settled` of both sides.
5. The term is the constructor applied to the enum's parameters, the found letters' values, then the fields.

## Pins
test_proposition_wanted "an enum of proofs proves its cases" and four_is_even; wap/test_theory enums-named-each-other
(Even/Odd). One line per rule: a letter found from the argument, a letter nothing settles refused, a result that is no
family member refused. Estimates: core +55, kernel 0, sugar 0.

## Open for the user
Whether a case's found letter may also appear only in its result (`zero: Even(n)`, no field). Recommended: refused,
the letter is then nothing's value; wiki/proposition.md writes none.
