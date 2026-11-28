# T6a3: a family's cases and their calls

wiki/proposition.md `Even`, wiki/enum.md "Arguments and result types".

## A case's own result and the letters it finds (inductives.wap)
- `CaseTyped.result` is the case's written result read against the enum's letters and the ones it finds; a case that
  writes none gives `enum.whole`. A result that is no member of the enum's family is refused naming the case.
- A found letter is a one-letter name a case's fields or result use that is none of the enum's parameters and none of
  the case's own field names (`n` of `step(e: Even(n))`, not `m` of `pair(m: nat, e: Even(m))`). Its domain comes from
  where it stands: an index place of the family takes the header's index type, a letter under a call that is no family
  has DATA_TERM. Two different domains given to one letter are refused naming the case.
- `is_found_name` takes any one-letter name, lowercase too; `letters_in` (type letters) takes uppercase only.
- `case_type` is `Π keys, Π parameters, Π found letters (·-marked, implicit), Π fields, result`. A value letter is a
  local of the case's checker and the case type is abstracted over it (`found_closed`); type letters keep `block_named`.
- Field counts (`fields_given`, `case_minor`, `enum_cases`) count the written fields only; the call binds the found
  letters.
- `case_indexed` reads each case's types inside `block_entered`, after earlier groups registered their constructors;
  `enums_entered` orders the groups by their headers' index domains too. An index reads through `typed_form` and
  `term_of`, as `family_read` reads a function's result: numbers, operators and constructors of earlier blocks. An index
  naming a constructor of its own block (induction-induction) is refused; no function of the program is entered yet.

## A letter only the result writes
Allowed, as Lean's `nil: Vector(T, 0)`: the letter is an implicit binder, solved from the arguments' types, then from
the type wanted at the use; where neither tells which, the use is refused ("cannot tell which n it means"), never the
declaration. Outcome lines: test_theory_elaborate `anywhere_wanted` and `anywhere_unknown`.

## A constructor call typed from its fields
- Typing binds the found letters through `holder_made` (fits.wap) with the case's Signature `member`, so
  `letters_bound` solves them; a letter left unbound is refused.
- `found_applied` builds the kernel term: holes for the letters, the arguments' kernel types unified with the field
  types left to right, then the type wanted where a letter is left. The call's type is the result with the letters
  filled (`Even(0 + 2)`), never unified with the type wanted: the kernel's conversion compares `Even(0 + 2 + 2)` with
  `Even(4)`, since a first-order unify cannot solve `?n + 2 = 4`.
- `converted` accepts two members of one family whose indices the kernel finds equal (`same_family_member`).
- A match on an indexed family gives no term until T6a4/T5c4: `arm_minor` returns ø for a case that finds letters.

## Equality's shape
An enum of one index and one case without fields is tried as the core's Equal (`equality_bound`): its word and its
case are defined as Equal and Equal.refl at its first parameter's type, the kernel's check of the two definitions being
the shape check (wiki/enum.md:98). A refused check takes both back, the enum declares its own block, and a hint says why.

## Pins
test_proposition_wanted "an enum of proofs proves its cases" and four_is_even; wap/test_theory enums-named-each-other
(Even/Odd); test_theory_elaborate `paired_wrong`, `anywhere_wanted`, `anywhere_unknown`; test_theory_verify
`own_equal_flipped`; test_enum_wanted's match on an equality-shaped enum.
