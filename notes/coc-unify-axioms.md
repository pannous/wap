# Axioms in the one typer (card unify-axioms)

`axiom name: T` states a constant of type T that nothing defines: the kernel takes it as given (wiki/proof.md,
wiki/proposition.md). The one typer does not read it, so these are red (test/reds.txt):
- test/wap/test_native.sh "wap verify gives each axiom and law its verdict, from any folder" (Darwin and Linux, :294);
- test/wap/test_theory_verify.wap "an axiom is taken as true" (:16, `axiom choice: Prop` → `choice: Axiom`), and with it
  "a proof that uses an axiom is Proved and names what it rests on" (:25);
- and everywhere a test states its givens as axioms: about twenty of test_theory.wap's red lines (`axiom int: Type`,
  `axiom h: False`) wait on this card beside T6a7's universes and T6a3's headers.

## How the old reader did it (before 183716f2)
- extensions/theory/explicit.wap `declaration_read`: a head led by the word `axiom` takes no value, any other
  declaration word takes one (`(word == AXIOM_WORD) != (value is ø)` refused).
- elaborate/declare.wap `definition_elaborated`: a declaration without a value and with a written type is declared
  `DeclarationKind.Axiom`; `axiom` was one of REPORTED_WORDS, so verify gave it a verdict, `name: Axiom`.
- sugar/definitions.wap still holds the one rule that survives: `axiom f(x: A): B` is `axiom(f: ((x: A) -> B))`.

## The general home: a definition without a body
analyze already enters a function whose value the kernel cannot see as an axiom: core/analyze/terms.wap
instance_entered, `kind = if value == ø then DeclarationKind.Axiom else Defined(value!)`, then `axiom_added`. So an
axiom is no new kind of statement: it is a definition with its written type and no body, and everything after typing
(the kernel entry, `axioms of`, verify's `d.kind is Axiom` at verify/laws.wap:129, :171) already reads it.

- sugar/definitions.wap: `rule axiom($name: $type) => @axiom $name: $type := ()`, the parameter form above feeding it.
  One rule (spec: wiki/proof.md).
- core/analyze: a Define marked `@axiom` is typed by its written type alone, its body never read (where typed_alone and
  the definers read a body), and definition_of gives ø for it, so terms.wap declares it Axiom. About +4.
- emit: reading an axiom when the program runs traps, as `unreachable` does, but it brings no effect: an axiom's use is
  no Fail, so a proof that uses one is Pure (t6a5-pure's `! Pure` claim) and Proved (:25). About +2.
- extensions/proof/verify/verify.wap: each `@axiom` definition gets the verdict `name: Axiom`, in the order stated beside the
  laws (verify +6, outside the core count).

Not chosen: a declaration rule (stage 2). Declaration rules write facts on nodes; entering the kernel happens from
typed definitions in terms.wap, so an axiom held only as a fact would need a second path into the kernel.

## What it needs from T6a7
`axiom n: int` needs nothing new. `axiom choice: Prop` and `axiom int: Type` need a universe as a written type,
`Sort(u)`, `Type` and `Prop` (T6a7 step 1, on t6a7). `axiom given: fact` with `fact: Prop` needs a proposition used as
the type of a name, which T6a3a's propositions bring. So the card builds after T6a7 lands; its test_native line and
:16 go green with it, :25 with T6a3a.

## Cost
core about +6 (typing a marked definition by its type +4, emit's trap without effect +2), sugar +1 rule, verify +6.
Pinned by the lines above; no new test file: the red lines are the to-do.
