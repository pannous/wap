# T6a6: the logic in wap/types

Read on the batch 5285eb86. The int-takes notation (`natural | negative`) changes nothing here.

## What it is

Programs get the logic's words from the types module: `True`, `False`, `And`, `Or`, `not`, `implies`, `Decidable`,
`and_swap`, the axiom `proposition_extensionality`, and `use classical`'s `excluded_middle`. The kernel's logic
(kernel/logic.wap: `·False`, `·True`, `·True.intro`, `·false_elim`, `·negated`) stays internal and is not copied: the
types words name it or are built on it.

What already landed:
- T6a7 delivered types as values and Prop binders, the old row's "core +20 and +10".
- t6a3-sort delivered `enum …: Prop`.
- T6a3a delivered proposition_of and the bridges.
- The kernel already has Imax, so `(A: Prop) -> A` is a Prop.

## The parts

1. **True and False name the kernel's blocks.**
   - Spelled `CoreWord` rows in type_notation.wap's CORE_WORDS, through `word_keyed(word, key)`, so `True` shows as
     `True` and means `·True`. That is core +3.
   - Not a second `enum False: Prop {}` in types: `·false_elim` and `·negated` would then talk about a different
     False than programs do.
   - `True.intro` comes from the same row (the case name follows its block).

2. **lib/logic.wap, plain wap, about 25 lines** (a `use` word, so a library file).
   ```wap
   enum And(a: Prop, b: Prop): Prop { intro(left: a, right: b) }
   enum Or(a: Prop, b: Prop): Prop { left(h: a); right(h: b) }
   not(x: Prop): Prop := x -> False
   implies(a: Prop, b: Prop): Prop := a -> b
   enum Decidable(p: Prop): Type { yes(h: p); no(h: not p) }
   law and_swap(a: Prop, b: Prop, h: And(a, b)): And(b, a) := And.intro(h.right, h.left)
   axiom proposition_extensionality(a: Prop, b: Prop, ab: a -> b, ba: b -> a): a == b
   holds(b: bool): Prop := b == yes
   ```
   - `holds(b)` reads a bool as a proposition, written where it is meant: no word is named as the universe, so no
     conversion makes a bool a Prop unasked.
   - `not` on a bool is the prelude's `not(x): bool`, `not` on a proposition the Prop overload.
     The overload test (calls.wap:405, fewer converted positions win) then picks the bool one for `not bool.yes`. No
     new rule is needed.
   - **Build check:** reads_as reads `s.records`. Prop is a sort term, not a record. If `read_type` finds no function
     named Prop, the fix is to look the conversion up by `type_word(held)`, at most core +2.
   - `use classical` is a library file, lib/classical.wap:
     ```wap
     axiom excluded_middle(a: Prop): a or not a
     ```
     It is one line, and the verdict's "rests on excluded_middle" comes from V1's axiom report.

3. **`and` and `or` over propositions.**
   - sugar/conditions.wap:29-30 rewrites `$a and $b` to `If($a, $b, no)` before typing, so an `and` of two
     propositions becomes an `If` on a Prop, which T6a5 refuses.
   - Recommended, (A): `and` and `or` become prelude functions with a block second parameter, as lazy-implies does
     for implies (d3c5b1f9: `implies(a: bool, b: block)`), each with a Prop overload giving `And(a, b)` or `Or(a, b)`.
     Sugar −2 rules, plus the two refusal lines :33-34 (calls of `and(...)`), which a function makes moot. Core 0.
   - (B), if lazy-implies' three build checks show that a block argument in an infix call does not hold: a kind rule
     at stage 3 turns an `If` whose operands are typed Prop into `And` or `Or`. Sugar +2, core 0.
   - (A), decided (wap-supervisor), unless lazy-implies' build shows a block argument in an infix call cannot work.

4. **Or and Exists eliminate into Prop only.**
   - The kernel's recursor today takes a motive at any level. A block in Prop with two cases, or with a field that is
     data, gets its motive fixed at Zero; that is Lean's rule.
   - The rule is about 8 lines in kernel/inductive.wap, where the motive's level is chosen.
   - It refuses `match` on an `A or B` into bool (proposition.md:95, "a proof decides no data") with the kernel's
     argument-type refusal. The test's word "refused by elimination" is the analyze message that names it, about +2.
   - Decided by the kernel owner (wap-supervisor): the standard CIC restriction, built with T6a6.

5. **A comparison's type.** proposition.md:6-7 says `type of (2 + 2 == 4)` is Prop. :55 says a comparison where a
   bool is wanted is decided.
   - Today a comparison is a bool, and a law reads it as its proposition (proposition_of, verify/laws.wap:232).
   - (A), recommended: the comparison stays a bool. Where a Prop is wanted it reads as one through `holds(b)`,
     proposition_of making `Equal(T, l, r)` at a bridged type. Core 0. `type of (2 + 2 == 4)` then says bool, so
     proposition.md:6-7 becomes `type of (2 + 2 == 4) // bool, and a proposition where one is wanted`. That is a wiki
     rewrite: old and new text go to warp-interviewer.
   - (B): `type of` reports a comparison of a bridged type as its proposition, core about +5 in type_of_typed. That is
     one phrase special-cased, against "no special cases".
   - (C), Lean's way: comparisons are Prop, decided to bool through a Decidable instance. Every `if` goes through
     instance search (C1). Core +40 or more, and the self-compile slows.
   - (A) is the default. The wiki text of proposition.md:6-7 waits for the user; until then the wiki and the two red test lines stay as they are.

## Needs

- generic records with T6a3's parameters (And, Or and Decidable take parameters).
- unify-axioms (`@axiom` without a body).
- lazy-implies (part 3).
- T6a5 for the Exists lines.
- V1 for "rests on".

## Tests it turns green

- wap/test_theory_logic.wap, once its `logic = ""` reads the types module:
  - "And.intro takes both proofs", "Not is a function to False", "a law's statement is its type", "Decidable is
    data", "Equal at a level", "Or eliminates into Prop only", "the axiom is the only door".
  - "Exists eliminates into Prop only" with T6a5.
  - "a recursor's computing is refl's to prove" writes `negated(bool.no)`, the prelude's internal word. Rewritten to
    `not bool.no` in its own commit, why given; the word is no program's.
- wap/test_theory_connectives.wap:
  - "both of two propositions hold", "one of two propositions holds", "and joins …", "or joins … nothing decides"
    (parts 2 and 3).
  - "not of a bool is a bool", "not of a proposition is a proposition", "a goal stated with not is proved by a law
    concluding False", "an overload taking the value's own type wins" (part 2's conversion).
  - "a proposition implies itself", "a law stated with implies applies" with lazy-implies.
  - "a choice by a comparison is a choice of data" (part 5 (A): it is a bool).
- test_proposition_wanted.wap:
  - "True has its proof" (part 1).
  - "an equation is a proposition" and "a false equation is a proposition too" turn green only with part 5 (B) or
    (C). With (A) they are rewritten after the wiki's new text.
- wap/test_proposition_wanted.wap: "a proof decides no data" (part 4), "excluded middle comes with use classical"
  (with V1).
- wap/test_theory.wap: "a statement about all propositions is a proposition". The kernel has Imax; T6a6 checks that
  core's `type of` of a pi into Prop reports Prop (core 0 to 3).

## Cost

| | core | kernel | types | sugar |
|---|---|---|---|---|
| T6a6 | +3 (+2 if reads_as needs the type word, +2 for the elimination message) | +8 (Prop-only elimination) | +26 (logic.wap 25, classical.wap 1) | −2 (A) or +2 (B) |

This is against the old row's core +30 and types +38. One builder, on the careful path: the elimination rule is
kernel code every enum's recursor passes.
