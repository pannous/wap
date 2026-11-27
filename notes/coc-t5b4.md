# T5b4 and T5b5: a match's term and the dotted lookup of a type's word

coc-t5b.md's rows T5b4 (match) and T5b5 (the recursor), planned on what unify-typers holds. T5c3 waits on T5b4 (its
course term is a match's term with a dependent motive). T5c4 waits on both (nat's cases in a match, `nat.recursor`).
Read on unify-typers 2b0e87be.

## What unify-typers already holds

- **Enums are kernel blocks** (T5b2, core/analyze/inductives.wap). Every enum whose fields' types are settled fills
  its word with an inductive block. `case_term` (inductives.wap:91) makes a case's value its constructor's term, and
  `TYPES.enums` says which enums are defined.
- **`if` is bool's recursor** (T5b3, core/analyze/terms.wap:132 `choice_term`). The recursor constant gets a
  constant motive `λ _: bool. T`, the else arm and then arm as minors, the condition as major.
- **`term_of` (terms.wap:87-98) has no `Case`.** A function whose body is a `match` gets no value and stays an
  assumed constant of its signature.
- **A dotted call** `a.f(x)` is `Call(f, [a, x])`. `module_call` (core/analyze/scope.wap, via modules.wap:66-71)
  reads it as a used module's word (`module_word`) or an enum's case (`qualified_case`, scope.wap:312). Any other
  subject leaves `f` looked up as a plain word. `nat.recursor(…)` is refused today: "nothing defines this name"
  (test/results.txt:2218).

## T5b4: a match's term

The Case form (kernel/forms.wap:60): `Case(subject, Arm(pattern, result)…)`. `match_term(n, subject, arms, x)`, a
`term_of` arm beside `choice_term`:

1. **Case arms.** The subject's kernel type is an enum that `TYPES.enums` says is defined. Each arm's pattern is a
   case of that enum, bare (`Dime`) or with its fields (`node(l, r)`). The minor for each case, in the block's order,
   is the arm's result under lambdas over the case's fields. A recursive field also gets its below-value binder,
   unnamed and unused: recursion is T5c3's course, not this. The field names' keys join `Entering.binders` (with a
   placeholder for each unnamed binder), so `binder_term` finds them.
2. **The catch-all.** A last arm that fits any value (`_`, or a name holding the subject) fills every case no arm
   names. A name's arm is let-bound to the case's value (the case applied to the minor's fields).
3. **The motive** is constant, `λ _: E. T`, with T the match's kernel value type. A dependent motive is T6a4's.
4. **One helper with `if`.** `recursor_applied(type, result, minors, major, x)` makes the recursor constant at the
   result's level with the constant motive, then applies the minors and the major. `choice_term` becomes its first
   user (bool's two minors), and `match_term` its second.
5. **Literal arms** (`match n { 0 => "zero"; _ => "many" }`). The subject is no enum, or the patterns are literals.
   The arms become a chain of choices on the row's equality, `if n == 0 then … else …`, each condition through
   `row_term`. The last arm must fit any value, or the match gets no term (covering refuses it before this, as for
   any match).
6. **Guards and nested patterns** (`n if n < 0 =>`, `node(leaf, r)`) give no term in T5b4. The function stays
   assumed, as today. They return with T5c4's case reading.

Covering is not touched: typing already refuses "match on Coin misses Dime" (wiki/enum.md:81), and a match that
reaches `match_term` covers its enum.

## T5b5: a type's word, `E.word(…)`

**The lookup.** `T.f(args)`, with T a type word (an enum's, a class's, or a subtype's such as `nat`), is the call
`f(args)` restricted to f's definitions that take a T. Bare `Side.Right` (a case by its enum) is the case this
already covers. modules.wap's chain gains a third reading after `module_word` and `qualified_case`:
- `type_word`: the subject is a symbol the scope defines as a type. The call keeps its other arguments and carries
  the type as an `OWNER` fact.
- The overload choice (calls.wap) takes, of the word's definitions, those with a parameter of exactly that type.
  For a subtype that is the subtype itself, so `nat.recursor` never takes an int's or a bool's recursor.

This is wiki/enum.md:102's `nat.recursor` and the same mechanism for any type's function. It needs no names: the
rule holds for every type word and every word.

**An enum's recursor.** A sugar rule beside the enum rule (sugar/records.wap `recursor_of`), plain wap, no analyze:
each enum E gets the overload `recursor(on_case…, value: E): T`, a minor per case (a bare case's is a T, a case with
fields takes them, then a T for each field whose type is E, to T), written as a match on the value whose arm for a case
calls the minor on the fields and on `recursor(on_case…, field)` for each such field. The lookup above picks it by its
parameter of type E, so no `OWNER` fact is needed for it, and a program's own `enum nat` has its own beside types'.
The typed body is a structural recursion, which T5c3's course reading takes as the kernel definition: the course
term, definitionally the recursor. About +2 core instead of the +47 of analyze; the plan's route needed plumbing for a
function the program never wrote.

**nat's recursor in plain wap** (types/integers.wap, types +3). Written as a guard, so it runs now and the kernel takes
it with T5c4's guard reading (coc-t5c4.md (3)), without nat's case patterns:
`recursor(base: T, step: (nat, T) -> T, n: nat): T := if n == 0 then base else step(n - 1, recursor(base, step, n - 1))`

## The red lines they turn green

| line | form | wiki | step |
|---|---|---|---|
| test_proof_wanted:23 | `nat.recursor(0, (k, double_k) => double_k + 2, 3)` is 6 | enum.md:102-111 | T5b5: the lookup and nat's recursor |
| test_proof_wanted:24-25 | `recursive_double(3)` is 6 | enum.md:109 | the same |
| wap/test_theory_elaborate:50 | a recursor called takes its motive from the type wanted, on a program's own `enum nat` | enum.md:102 | T5b5: an enum's recursor |
| wap/test_theory_elaborate:51 | `bool.recursor(…, n)` with n a nat is refused | enum.md:102 | T5b5's overload restriction refuses it. The builder reads which refusal the line names ("by pattern") against what the lookup says |

T5b4 has no red line of its own: a match function runs today (test_matching.wap:78-84 `cents`), only its law is
Tested where it could be Proved. One line pins that. A builder adds it to wap/test_law_runs (enum.md:78, law.md
"Checking a law"): `enum Coin { Penny, Nickel, Dime }`, `cents(c: Coin) := match c { Penny: 1; Nickel: 5; Dime: 10 }`,
`law dime: cents(Dime) == 10` prints `dime: Proved`. Beyond that, T5b4 is T5c3's base: coc-t5c3.md's red lines go
green with T5c3 on it.

## Estimates (core)

| part | file | lines |
|---|---|---|
| T5b4 (1)-(3): case arms, the catch-all, the constant motive | analyze/terms.wap | +35 |
| T5b4 (4): `recursor_applied`, `choice_term` through it | analyze/terms.wap | +1 (+4, −3) |
| T5b4 (5): literal arms as a chain of choices | analyze/terms.wap | +10 |
| **T5b4** | | **about +46** (the row said +60) |
| T5b5 the lookup: `type_word` and the `OWNER` fact | analyze/modules.wap, scope.wap | +8 |
| T5b5 the overload restriction to the owner's type | analyze/calls.wap | +6 |
| T5b5 an enum's recursor: its signature with T found | analyze/inductives.wap | +25 |
| T5b5 its kernel value and its runtime definition | analyze/inductives.wap | +22 |
| nat's recursor | types/integers.wap | types +3 |
| **T5b5** | | **about +61, types +3** (the row said +50) |

Kernel 0 for both: the blocks' recursors exist.

## Before unify-typers lands?

- **T5b4: no.** It reads the blocks of T5b2 and builds on T5b3's `choice_term`. Both exist only on unify-typers. It is
  built on a branch from unify-typers and lands right after it.
- **T5b5: in two halves.**
  - **The lookup and nat's recursor can land on main before unify.** They need no block. `nat.recursor` is a plain
    wap function found by the lookup, and it runs. test_proof_wanted:23-25 go green at once: their checks are run
    values. That is about +14 core and +3 types. The builder checks first that main's modules.wap and calls.wap have
    the shape read here (the dotted chain at `module_call`).
  - **An enum's recursor** (+47) needs the blocks, so it lands after unify-typers, with or after T5b4. It shares
    `recursor_applied` with T5b4.

Order: T5b5's lookup half now; unify-typers; T5b4; then T5b5's enum half and T5c3 in either order; T5c4 last. Normal
path for the lookup half (scope and calls are every program's), careful for T5b4 (every match function's kernel
value changes, and so the census).
