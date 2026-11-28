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

## Ruling: a letter only the result writes (wap-supervisor)
Allowed, as Lean's `nil: Vector(T, 0)`. The letter is an implicit binder; the call solves it from its arguments' types,
then from the type wanted at the use; where neither tells which, the use is refused ("cannot tell which n it means"),
never the declaration. Outcome lines: test_theory_elaborate `anywhere_wanted` (solved) and `anywhere_unknown`
(refused at the use).

## Built (unbuilt, GUESSes)
inductives.wap: `Found`, `found_written`/`found_in` (the letters, an index's type from the family's header, else a
type), `case_read` and `index_read` (a family applied to numerals, constructors and `+`, text-keyed values no longer),
`case_type` (found letters as `·`-marked binders before the fields, the written result at the end, a result that is
no member of the enum refused), `found_count`, `found_applied` (holes for the letters, the arguments' kernel types
unified with the field types, the type wanted where a letter is left, the use refused where still open). GUESSes:
`case_fields(item)` gives a constructor call's arguments; `n` and `T` as a case's letters arrive as bare symbols with
no DEFINED_AT; typing's own type for a family case's call stays the bare enum, so `found_applied` reads the kernel's
type of the arguments and compares nothing against `value_type(n)`.

## Review rulings folded in (wap-theory-plan)
- P2: step 3 reuses `holder_made` (fits.wap), widened by the case's Signature `member`, so `letters_bound` binds the found
  letters (`letter_holes` adds `found_names`); `found_applied` stays only for the kernel term, whose found values typing's
  text-keyed indices cannot give.
- P1: `converted` accepts two members of one family whose indices the kernel finds equal (`same_family_member`, +6).
- P3: `is_found_name` stays a one-letter rule: `letters_in` takes uppercase letters only (`is_letter`), `n` is lowercase.
- P4: a match on an indexed family gives no term until T6a4/T5c4 (`case_minor` returns ø for a case that finds letters).
- F1: a case's own field names are no found letters (`pair(m: nat, e: Even(m))`); outcome line `paired_wrong`.
- F2: the argument loop steps with `instantiated(body, term)`. F4: a letter found with two domains is refused naming the case.
- F3 open: reading an index through `term_of` needs typed forms (`typed_form`, a TypingState), which `enum_cases` does not
  have; `index_read`/`constructed` stay until the block is read with typing's state.

## Language question: a lowercase one-letter name as a found letter (P3)
`is_found_name` takes any one-letter name no definition or field holds (`n` of `Even(n)`); `letters_in` knows uppercase
letters only (`is_letter`). Whether a lowercase one-letter name is a letter of the language is the user's to say; until
then the one-letter rule stands.

## Plan: indices read by term_of (F3), not coded yet
`types.wap` has the TypingState at the call (`enums_entered(s.records.items)`), so `s` is threaded
`enums_entered → enum_read → enum_cases → case_read`: about +6 lines. Then an index is read as `family_read` reads a
function's result (terms.wap): `term_of(typed_form(item, s, frame, ø), reading)`:
1. Each found letter gets a definer: its first occurrence in the case, set as DEFINED_AT on every occurrence of the name
   (`found_written` already walks them): about +5.
2. The frame is `TypeFrame` with a `Binding(place_key(definer), typing domain)` per found letter, and the reading is
   `fresh_reading(checker, {}, s).under(locals, keys)` with the locals entered at the kernel domain: about +6.
3. `case_read` reads each index through `term_of` under it; the found letter is then the reading's variable, and
   `block_named`'s constants-by-id replacement is replaced by the abstraction over the locals: about +4, and
   `index_read`/`constructed` go: about −12. Net about +9..+15, and `Even(2 * n)` and `Even(double(n))` come with it.
Risks (unbuilt): typed_form on an index whose letter's DEFINED_AT is a node no typing pass met may refuse the symbol as
unknown; `by_key` is empty at this point (functions are given, `distinct_instances` ran), so a user function in an index
needs `s.functions` as `by_key`.

## F3 built (unbuilt, GUESSes)
`enums_entered(records, s)` threads the TypingState down to `case_read`. `index_read(item, case, found, s)` reads an index
as `family_read` reads a function's result: each found letter of a value type is substituted by a definer (`found_definer`:
a parameter named by the case's name, DEFINED_AT itself), typed by `typed_form` in a frame binding those definers, read by
`term_of` under an Entering over locals at the letters' domains (functions from `instances_keyed(s.functions)`), the
locals then replaced by the letters' constants for `block_named`. `index_read`'s number/`+` reading and `constructed` are
gone. GUESS: typed_form on a constructor of a not yet declared block (`Even(nat.zero)` inside its own block) may refuse.
