# A function type over named binders, as a value and as a statement

`(n: nat) -> n + n == 2 * n`, `(A: Prop) -> A`, `(n: int) -> text`: an arrow whose parameters are named binders, with
its result reading them. It is a type, so it is a value (wiki/universe.md:24-31). Where its result is a comparison, it
is the proposition "for every n" (wiki/proposition.md:20, :34). Card dependent-types.

## Where it is written

- As a value: `type of ((n: int) -> text)` and the other universe lines.
- As a statement in a type's place, as the law rules write it:
  - sugar/definitions.wap:54 makes `law doubled_again(n: nat): …` into `law(doubled_again: ((n: nat) -> n + n == 2 * n))`;
  - law_for.wap makes the `for` lines of `law doubled:` into the same arrow;
  - law_for.wap's law_proof gives a proved law with `for` lines `@proof doubled(): ((n: nat) -> …) := proof`. Its result
    type is the arrow over a statement.

## What stops it today

- scope.wap:72 refuses `->` wherever a value stands: "-> writes a function type; a function value is written with =>".
  This is why the universe lines fail.
- type_notation.wap:301 function_type_of reads the parameter list's types only, so the binder names are dropped and the
  result is read as a closed type. A result reading `n` is unbound, and a comparison there is not a statement.
- term_of has no arm for an arrow: its kernel term, a pi over the binders, is never built.

## The plan (core about +25)

1. **Scope (about +6).**
   - An arrow whose parameters are all named binders, `(x: T, …) -> R`, is a type, both where a value stands and in a
     type's place.
   - Its binders are a layer of their own: `within(scope, parameter_definitions(parameters, depth + 1))`, the same call
     applied_type makes for an alias's parameters (scope.wap).
   - The result is bound in that layer. A statement result is bound by is_code_call and the AS_CODE reading (proof-words),
     every other result by type_bound.
   - Names in the result take DEFINED_AT from their binder, through t4e-2's condition_bound, which binds Parameter,
     Local and Capture kinds by declaration. So `n` means the arrow's n, never a global of that spelling.
   - The refusal stays for an arrow without named binders where a value stands, `(a, b) -> a + b`, with its fix-it.
     An unnamed arrow in a type's place, `(int) -> text`, reads as today.
2. **Typing (about +8).**
   - type_value_written gets one arm: an arrow of named binders is a type value.
   - Its result is typed under a frame holding the binders as parameters, the way body_typed types a function's
     declared result: proof-words' statement_typed for a statement result, written_type for any other.
   - A statement result types as STATEMENT_TERM, proof-words' stand-in, so the arrow over it is a statement too. Every
     proof fits it, and the kernel checks the proof when it enters it.
3. **Term (about +8).**
   - term_of of such an arrow enters each binder in order on the reading's checker, `entered(x.c, name, kernel_type(T))`.
     Each binder's type is read under the binders before it, as parameters_entered does for a function's parameters.
   - The result is read under them: `x.under(locals, keys)`, with keys the binders' place keys. This is the entering
     T6a4's minor_of uses for a case's fields and hypotheses.
   - The term is `pis(locals, result)`, the result a statement's proposition (proposition_of), as statement_term gives it.
   - No new kernel code: pis, entered and under are all there.
4. **Its universe (about +3).** `type of` an arrow is the kernel's type of its pi, shown by universe_of. The kernel's
   pi rule already gives Prop for `(A: Prop) -> A`, Type(1) for `(A: Type) -> A`, and Type for data to data.

Mechanisms reused:
- T6a4's binder entering: minor_of's `entered` then `under`; parameters_entered's binders read in order.
- t4e-2's condition_bound and declared_scope: names bound by declaration.
- proof-words' STATEMENT_TERM, statement_typed and is_code_call: a statement read after its names are bound.
- applied_type's parameter layer.

It needs no new form: the arrow and the named binder are both notation that exists.

## Tests it turns green

From wiki pages:
- test/test_universe_wanted.wap:11-13:
  - a function type between data is a Type;
  - a function type over every type is a Type(1);
  - a statement about all propositions is a proposition.
- test/test_type_wanted.wap:58, "a function type".
- test/test_proposition_wanted.wap:9-12, `law doubled:` with its `for` line, and `law doubled_again(n: nat): n + n == 2 * n`,
  the arrow the law rules write. They are red on main with "nothing defines this name" (line 12:5). If the cause is a
  law rule not firing in that build rather than the arrow, the arrow's part is still needed once the rule fires.
- test/test_laws_wanted.wap:5-8, `law twice_doubles:` with `for x: int`.

One line to add, backed by wiki/proposition.md:20 and :34 ("a function giving a proof for each x", "the same as a
parameter"): `check("a statement over every n is a proposition", type of ((n: nat) -> n + n == 2 * n), Prop)` in
test_proposition_wanted.

## Path and order

- Path: careful. It changes scope, and the compiler's own source writes `->` types.
- Order:
  - after proof-words lands (STATEMENT_TERM, statement_typed, is_code_call);
  - after t4e-2's condition_bound and declared_scope;
  - after T6a4's riders, for minor_of's entering as written there.
- None of them is changed, only called.
- The one risk is in scope: the compiler's own `(T) -> U` types are unnamed arrows and keep today's path. Only an arrow
  whose every parameter is `name: type` takes the new one, and that test is read from the form, not from a word list.
