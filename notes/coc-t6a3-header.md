# T6a3 header: enums with parameters and a sort

wiki/enum.md "Arguments and result types" and wiki/proposition.md: what is written after an enum's name is the same in
every case, and the sort after the colon says what its values are, data or proofs:

```wap
enum Boxed(T: Type): Type { box(item: T) }
enum And(a: Prop, b: Prop): Prop { intro(left: a, right: b) }
enum Exists(T: Type, P: T -> Prop): Prop { intro(witness: T, proof: P(witness)) }
enum False: Prop { }
```

Indices, a sort that is a function type (`enum Even: nat -> Prop`, `enum Equal(a: T): T -> Prop`), are not this part:
their cases each give their own result type, the next step. Such a header is read, and its enum stays the assumption
it is today, counted open.

## Order
The sort comes first and alone: `enum False: Prop {}`, `enum True: Prop { intro }`, `enum Single: Type { star }`. The
sort goes onto the name as `@inductive(Prop)`, the record's word is declared in that sort (core/type_notation.wap
record_sort), and its block's header is that sort. The parameters need generic records first, `enum Boxed<T>` with T
filled at each use (notes/coc-generic-records.md): today a header with parameters is not read at all.

## Where it stops today
- sugar/records.wap's enum rule reads only `enum $name { … }`, a bare name or `list<T>`.
- core/rules/lowering.wap lowers a curly Key only under a bare name, so a header left unread is refused there.
- core/analyze/inductives.wap declares every block `InductiveBlock([], 0, types)`, at Type, and a field naming a
  parameter (`item: T`) is an open type, so the enum is counted open.

## The change
1. sugar/records.wap, two rules before the enum rule: the header goes onto the name as an annotation, the way a class
   says what it extends (`@extends`), and the enum is read as any other:
   `enum $name($parameters...): $sort { $cases... }` → `enum @inductive([$parameters...], $sort) $name { $cases... }`,
   `enum $name: $sort { $cases... }` → `enum @inductive([], $sort) $name { $cases... }`. No core reads a new form.
2. core/analyze/inductives.wap reads the annotation: the parameters are the block's parameters, binders around the
   header and every case's type, a field naming one (`item: T`, `proof: P(witness)`) bound to it; the sort is the
   block's sort, `Type` data, `Prop` a proposition. `InductiveBlock([], #parameters, types)`, the header
   `Π parameters, sort`, each case `Π parameters, Π fields, word(parameters)`. A sort that is a function type (an index)
   stays open, counted.
3. A case's value as a term (inductives.wap's case term): the constructor applied to the enum's parameters, read off the
   value's type, then its fields.

## Tests that pin it
The test_theory* lines that write such headers without indices: `enum And(a: Prop, b: Prop): Prop`,
`enum Couple(A: Type, B: Type): Type`, `enum False: Prop`, `enum True: Prop`, `enum Rose(T: Type): Type`,
`enum Or(a: Prop, b: Prop): Prop`, `enum nat: Type`, `enum bool: Type`, `enum Tree: Type`, `enum Single: Type`.
Their reds in test/reds.txt that turn green leave it in this branch's commits.

## Cost
sugar +2 rules (spec: wiki/enum.md), core/analyze/inductives.wap about +25, no kernel change: the kernel takes
parameters and Prop already (equality.wap's Equal, logic.wap's False and True).
