# Generic records: `enum list<T>`, `class Pair<A, B>`

wiki/enum.md "Arguments and result types" (`enum list<T> { empty, item(first: T, rest: list<T>) }`) and wiki/class.md:
a record's letters are the same in every value, and each use names them, `Pair<int, text>`, or a value finds them,
`Boxed.box(3)` is a `Boxed<int>`. T6a3's parameters (notes/coc-t6a3-header.md) rest on it: the kernel block takes the
letters as its parameters.

## Where it stops today
- sugar/records.wap's class and enum rules take `$name` of the name shape: `enum Boxed<T> {…}` is refused when read,
  "`Boxed<T>` stands where a name is wanted" (core/rules/templates.wap:63).
- A letter written only in the fields, `enum Boxed { box(item: T) }`, is read but never filled: `unbox(Boxed.box(3))`
  is refused, "this gives int, the field holds T" (core/analyze/types.wap case_call_typed checks each field against
  its written T).
- A record's word is declared without parts (type_notation.wap declared_word, `word_keyed(…, parts = 0)`), and a
  written `Boxed<int>` names the bare word by its text (type_term → `word_term(text(parts#1))`), not the record's own.
- record_named and declared_by read a word alone (`is_word`): a value of `Boxed<int>` finds no record.

## The change: one mechanism, a record's letters filled by its type's parts
1. sugar/records.wap: `enum $name<$letters...> {…}` and `class $name<$letters...> {…}` put the letters on the name,
   `@parameters($letters...)`, and read on as any enum or class (the sort's `@inductive` beside it). The enum rule's own
   functions (`text(self: $name)`, `==`) take the bare word, which takes any of its types as a bare `list` does
   (calls.wap takes_any_item). Generally: a bare word whose declaration has letters takes any instance of them;
   takes_any_item reads that, never a list of record names, and CONTAINER_KINDS shrinks to the built-in words declared
   with parts where that falls out.
2. type_notation.wap: a record's word is declared with `#letters` parts (word_keyed's `parts`, there already); a
   written `Boxed<int>` takes its head by word_named, the record's own word; `record_term(record)` is the word applied
   to its letters, `Boxed<T>`.
3. stage.wap record_named and type_notation.wap declared_by read `head_of(type)`, so `Boxed<int>` finds Boxed.
4. One function, `field_type_of(field, holder: Term)`: the field's written type with the record's letters substituted
   by the holder's parts, all substituted at once (letters.wap `substituted`), so a function's own T in the holder,
   `f(b: Boxed<T>)`, is never caught by them; used where a field's type is read for a value: calls.wap:184 (a
   field read), data.wap:55/65 (a class made), fits.wap:82, dispatch.wap:201, the match bindings.
5. A case or a constructor call is a call of a definition with letters: its Signature's parameters the field types,
   its result `Boxed<T>`; letters_bound (letters.wap) fills T from the arguments, the same inference a generic
   function's call gets, no second one. case_call_typed's result is the answered record term. A case without fields,
   `Boxed.empty`, binds nothing from its arguments: its letters stay unknown and are settled by the value's later uses,
   the deferred path `[]` takes (calls.wap deferred_typed), never by a binding from the expected type.
6. Emit: one struct per record as today (values.wap struct_of); a field of a letter has the layout of any, and
   `fitted` boxes on writing and reads it back at the use's type. Structs per instance (`Boxed<int>` its own) are a
   later speed step, measured.

7. The kernel: this step lands with T6a3's parameters, on one branch, the typer's commits first and then the kernel
   block's: a generic enum's letters are its block's parameters (notes/coc-t6a3-header.md), never a record left out
   of the blocks. One careful run covers both, with the measures.

## Tests that pin it
test_type_wanted's `class Pair<A, B> { first: A; second: B }`, test_theory_elaborate's "a numeral in a case's field is
read at the type an overload's parameter wants" (`enum boxed<T> { box(item: T) }`), and new lines in test/test_enum_page.wap
from wiki/enum.md: `enum list<T>`'s item read back at its type, `Boxed.box(3)` of type `Boxed<int>`, and `==` and `print` of a `Boxed<int>` comparing and showing the int its any-laid
field holds.

## Cost (track T, no limit; measured at the end)
sugar +2 rules (spec: wiki/enum.md); core about +30 lines: type_notation ~6, stage ~2, field_type_of and its six uses
~10, the case as a Signature ~8, emit's letter layout ~4.
