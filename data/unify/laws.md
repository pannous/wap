# The laws and theorems of test/ in the theory's own spelling

For card unify-typers (wap-theory-reads-types). Read on main ccf63462 by a one-line scan of test/**/*.wap and *.sh:
a `law` or `theorem` with a name, on its line or inside a test's program text. The scan finds 117 statements:
71 in the theory's spelling (below) and 46 in wap spelling (the appendix). A statement written over several
lines (`law doubled:` then `for n: nat`) shows its first line. The wap spelling is made mechanically: `Equal(T, a, b)`
is `a == b`, `add`/`subtract`/`multiply`/`divide`/`remainder`/`at_most` the operators, `nat.successor(x)` `x + 1`,
`nat.zero` 0, `bool.yes`/`bool.no` yes/no, `negated` and `Not` not, `And`/`Or` and/or, `count(T, xs)` `#xs`,
`Equal.refl(…)` refl, levels dropped. Numerals are int (user 2026-11-27), so `Equal(nat, add(2, 2), 4)` needs no nat:
it is `2 + 2 == 4`. A binder `n: nat` needs only `type nat = int where it >= 0` in wap/types.

## Classes

A statement lists every class it needs; one with only (a) reads in wap spelling as it is.

- **(a)** rewritable now: 23
- **(b)** needs Prop (a proposition as a type: hypotheses, proofs as terms, Equal at Type): 8
- **(c)** needs indexed families (Even, Odd): 13
- **(d)** needs Exists, False or implies: 4
- **(e)** needs levels (a written level to drop: an existing test, so wap-interviewer first): 23
- **(f)** needs a kernel construct as a wap value (a recursor, a projection, Pair, the computation types, a quotient's parts): 7

A statement of (e) alone (17 of the 23) is rewritable once its written level is dropped. The supervisor's earlier
count, 141 statements and 104 in the theory's spelling, counts what this one-line scan cannot see: statements
written over several lines, and a program text held in a constant (DOUBLE_EVEN, FACT_POSITIVE) used by several
checks, which is counted here once, at its line.

## The statements

| file:line | class | wap spelling | as written |
|---|---|---|---|
| test/test_proof_wanted.wap:8 | c | `law double_even(n: nat): Even(double(n)) := ` | `law double_even(n: nat): Even(double(n)) :=` |
| test/test_proposition_wanted.wap:15 | c | `law four_is_even: Even(4) := Even.step(Even.step(Even.zero))` | `law four_is_even: Even(4) := Even.step(Even.step(Even.zero))` |
| test/wap/test_proof_wanted.wap:7 | c | `law double_even(n: nat): Even(double(n)) := ` | `law double_even(n: nat): Even(double(n)) :=` |
| test/wap/test_proof_wanted.wap:12 | c | `law wrong(n: nat): Even(double(n)) := Even.zero` | `law wrong(n: nat): Even(double(n)) := Even.zero` |
| test/wap/test_proof_wanted.wap:13 | c | `law partial(n: nat): Even(double(n)) := match n { zero => Even.zero }` | `law partial(n: nat): Even(double(n)) := match n { zero => Even.zero }` |
| test/wap/test_proof_wanted.wap:15 | d | `law oops: False := raise "no"` | `law oops: False := raise "no"` |
| test/wap/test_proposition_wanted.wap:12 | c | `law two: Even(2) := Even.next(Odd.next(Even.zero))` | `law two: Even(2) := Even.next(Odd.next(Even.zero))` |
| test/wap/test_theory.wap:29 | e | `law bad: yes == no := refl` | `law bad: Equal[1](bool, bool.yes, bool.no) := Equal.refl[1](bool, bool.yes)` |
| test/wap/test_theory.wap:32 | ef | `law first: projection(Pair, 1, Pair.make(int, int, a, b)) == a := refl` | `law first: Equal[1](int, projection(Pair, 1, Pair.make(int, int, a, b)), a) := Equal.refl[1](int, a)` |
| test/wap/test_theory.wap:34 | ef | `law first: Pair.recursor(int, int, (q: Pair(int, int)) => int, (x: int) => (y: int) => x, p) == projection(Pair, 1, p) := refl` | `law first: Equal[1](int, Pair.recursor[1](int, int, (q: Pair(int, int)) => int, (x: int) => (y: int) => x, p), projection(Pair, 1, p)) := Equal.refl[1](int, projection(Pair, 1, p))` |
| test/wap/test_theory_connectives.wap:18 | a | `law both_equal: 1 == 1 and 2 == 2` | `law both_equal: And(Equal(nat, 1, 1), Equal(nat, 2, 2))` |
| test/wap/test_theory_connectives.wap:19 | a | `law one_equal: 1 == 2 or 2 == 2` | `law one_equal: Or(Equal(nat, 1, 2), Equal(nat, 2, 2))` |
| test/wap/test_theory_connectives.wap:21 | d | `law no_is_no_yes: not (no == yes)` | `law no_is_no_yes: not Equal(bool, bool.no, bool.yes)` |
| test/wap/test_theory_connectives.wap:22 | a | `law both_equal_and: 1 == 1 and 2 == 2` | `law both_equal_and: Equal(nat, 1, 1) and Equal(nat, 2, 2)` |
| test/wap/test_theory_connectives.wap:23 | a | `law one_equal_or: 1 == 2 or 2 == 2` | `law one_equal_or: Equal(nat, 1, 2) or Equal(nat, 2, 2)` |
| test/wap/test_theory_effects.wap:15 | d | `law spin: False := spin` | `law spin: False := spin` |
| test/wap/test_theory_effects.wap:16 | d | `law oops: False := loop()` | `law oops: False := loop()` |
| test/wap/test_theory_effects.wap:30 | ef | `law same: away(0) == away(0) := refl` | `law same: Equal(Eff[1](diverging, nat), away(0), away(0)) := Equal.refl(Eff[1](diverging, nat), away(0))` |
| test/wap/test_theory_elaborate.wap:50 | c | `law double_even(n: nat): Even(double(n)) := match n { zero => Even.zero; successor(k) => Even.step(double_even(k)) }` | `law double_even(n: nat): Even(double(n)) := match n { zero => Even.zero; successor(k) => Even.step(double_even(k)) }` |
| test/wap/test_theory_elaborate.wap:87 | c | `law double_even(n: nat): Even(double(n)) := match n { zero => Even.zero; successor(k) => Even.step(double_even(k)) }` | `law double_even(n: nat): Even(double(n)) := match n { zero => Even.zero; successor(k) => Even.step(double_even(k)) }` |
| test/wap/test_theory_elaborate.wap:96 | a | `law divided: 7 ÷ 2 == 3 := refl` | `law divided: Equal(nat, divide(7, 2), 3) := Equal.refl(nat, 3)` |
| test/wap/test_theory_elaborate.wap:97 | a | `law second: 1 + 2 == 2 := refl` | `law second: Equal(nat, add(1, 2), 2) := Equal.refl(nat, 2)` |
| test/wap/test_theory_elaborate.wap:98 | a | `law summed: 1 + 2 == 3 := refl` | `law summed: Equal(nat, add(1, 2), 3) := Equal.refl(nat, 3)` |
| test/wap/test_theory_elaborate.wap:100 | a | `law kept: 3 == 3 := add_zero(3)` | `law kept: Equal(nat, 3, 3) := add_zero(3)` |
| test/wap/test_theory_elaborate.wap:105 | e | `law kept: yes == yes := refl` | `law kept: Equal[1](bool, bool.yes, bool.yes) := Equal.refl[1](bool, bool.yes)` |
| test/wap/test_theory_elaborate.wap:107 | b | `law once: (nat or (bool or nat)) == (bool or nat) := refl` | `law once: Equal(Type, nat or bool or nat, bool or nat) := Equal.refl(Type, nat or bool)` |
| test/wap/test_theory_elaborate.wap:108 | b | `law one: (nat or nat) == nat := refl` | `law one: Equal(Type, nat or nat, nat) := Equal.refl(Type, nat)` |
| test/wap/test_theory_elaborate.wap:121 | a | `law nine: 3 * 4 - 3 == 9 := refl` | `law nine: Equal(nat, 3 * 4 - 3, 9) := Equal.refl(nat, 9)` |
| test/wap/test_theory_elaborate.wap:150 | a | `law counted: #[1, 2, 3] == 3 := refl` | `law counted: Equal(nat, count(nat, [1, 2, 3]), 3) := Equal.refl(nat, 3)` |
| test/wap/test_theory_elaborate.wap:153 | b | `law same: (nat or ø) == nat? := refl` | `law same: Equal(Type, nat or ø, nat?) := Equal.refl(Type, nat?)` |
| test/wap/test_theory_elaborate.wap:165 | a | `law b: "abc"#2 == "b" := refl` | `law b: Equal(text, "abc"#2, "b\` |
| test/wap/test_theory_induction.wap:10 | bf | `law successor_equal(a: nat, b: nat, h: a == b): a + 1 == b + 1 := Equal.recursor(Equal.refl(nat, nat.successor(a)), b, h)` | `law successor_equal(a: nat, b: nat, h: Equal(nat, a, b)): Equal(nat, nat.successor(a), nat.successor(b)) := Equal.recursor(Equal.refl(nat, nat.successor(a)), b, h)` |
| test/wap/test_theory_induction.wap:15 | a | `law zero_add(n: nat): 0 + n == n` | `law zero_add(n: nat): Equal(nat, add(0, n), n)` |
| test/wap/test_theory_logic.wap:15 | e | `law wrong: (not no) == no := refl` | `law wrong: Equal[1](bool, negated(bool.no), bool.no) := Equal.refl[1](bool, bool.no)` |
| test/wap/test_theory_logic.wap:18 | b | `law anything(a: Prop): a := proposition_extensionality(a, a, (x: a) => x, (x: a) => x)` | `law anything(a: Prop): a := proposition_extensionality(a, a, (x: a) => x, (x: a) => x)` |
| test/wap/test_theory_measures.wap:11 | a | `law r: fact(4) == 24 := refl` | `law r: Equal(nat, fact(4), 24) := Equal.refl(nat, 24)` |
| test/wap/test_theory_measures.wap:12 | a | `law r: fib(10) == 55 := refl` | `law r: Equal(nat, fib(10), 55) := Equal.refl(nat, 55)` |
| test/wap/test_theory_nested.wap:15 | e | `law two: count(Tree.node(list.item(Tree, leaf, list.empty(Tree)))) == ${TWO} := refl` | `law two: Equal[1](nat, count(Tree.node(list.item(Tree, leaf, list.empty(Tree)))), ${TWO}) := Equal.refl[1](nat, ${TWO})` |
| test/wap/test_theory_numbers_wanted.wap:11 | e | `law add_zero(m: nat): m + 0 == m := refl` | `law add_zero(m: nat): Equal[1](nat, add(m, nat.zero), m) := Equal.refl[1](nat, m)` |
| test/wap/test_theory_numbers_wanted.wap:12 | e | `law add_succ(m: nat, n: nat): m + (n + 1) == m + n + 1 := refl` | `law add_succ(m: nat, n: nat): Equal[1](nat, add(m, nat.succ(n)), nat.succ(add(m, n))) := Equal.refl[1](nat, nat.succ(add(m, n)))` |
| test/wap/test_theory_numbers_wanted.wap:18 | e | `law three: 3 == 3 := refl` | `law three: Equal[1](nat, 3, nat.succ(2)) := Equal.refl[1](nat, 3)` |
| test/wap/test_theory_numbers_wanted.wap:19 | e | `law sum: 2 + 1000000000 == 1000000002 := refl` | `law sum: Equal[1](nat, add(2, 1000000000), 1000000002) := Equal.refl[1](nat, 1000000002)` |
| test/wap/test_theory_numbers_wanted.wap:21 | e | `law add_zero(m: nat): m + 0 == m := refl` | `law add_zero(m: nat): Equal[1](nat, add(m, 0), m) := Equal.refl[1](nat, m)` |
| test/wap/test_theory_prelude_effects.wap:19 | ef | `law hidden: pure(pure_effects, bool, yes) == never(pure_effects, bool) := refl` | `law hidden: Equal[1](${PURE_BOOLS}, pure[1](pure_effects, bool, bool.yes), never[1](pure_effects, bool)) := Equal.refl[1](${PURE_BOOLS}, never[1](pure_effects, bool))` |
| test/wap/test_theory_prelude_effects.wap:20 | ef | `law recovered: Fallible.recursor(bool, (f: Fallible(bool)) => bool, (v: bool) => v, (e: Error) => bool.no, Fallible.value(bool, yes)) == yes := refl` | `law recovered: Equal[1](bool, Fallible.recursor[1, 1](bool, (f: Fallible[1](bool)) => bool, (v: bool) => v, (e: Error) => bool.no, Fallible.value[1](bool, bool.yes)), bool.yes) := Equal.refl[1](bool, bool.yes)` |
| test/wap/test_theory_quotients_wanted.wap:16 | ef | `law lifted: quotient.lift(bool, ${SAME}, bool, negated, ${RESPECTS}, quotient.of(bool, ${SAME}, no)) == yes := refl` | `law lifted: Equal[1](bool, quotient.lift[1, 1](bool, ${SAME}, bool, negated, ${RESPECTS}, quotient.of[1](bool, ${SAME}, bool.no)), bool.yes) := Equal.refl[1](bool, bool.yes)` |
| test/wap/test_theory_recursors_wanted.wap:16 | e | `law four: 2 + 2 == 4 := refl` | `law four: Equal[1](nat, add(nat.succ(nat.succ(nat.zero)), nat.succ(nat.succ(nat.zero))), nat.succ(nat.succ(nat.succ(nat.succ(nat.zero))))) := Equal.refl[1](nat, nat.succ(nat.succ(nat.succ(nat.succ(nat.zero)))))` |
| test/wap/test_theory_second.wap:21 | e | `law four: 2 + 2 == 4 := refl` | `law four: Equal[1](nat, add(2, 2), 4) := Equal.refl[1](nat, 4)` |
| test/wap/test_theory_second.wap:23 | e | `law divided: 1000001 % (1000 ÷ 7) == 37 := refl` | `law divided: Equal[1](nat, remainder(1000001, divide(1000, 7)), 37) := Equal.refl[1](nat, 37)` |
| test/wap/test_theory_second.wap:36 | e | `law four: 2 + 2 == 4 := refl` | `law four: Equal[1](nat, add(2, 2), 4) := Equal.refl[1](nat, 4)` |
| test/wap/test_theory_statements.wap:20 | e | `law r: sum_to(3) == 6 := refl` | `law r: Equal[1](nat, sum_to(3), 6) := Equal.refl[1](nat, 6)` |
| test/wap/test_theory_statements.wap:21 | e | `law r: sum_to(0) == 0 := refl` | `law r: Equal[1](nat, sum_to(0), 0) := Equal.refl[1](nat, 0)` |
| test/wap/test_theory_statements.wap:25 | e | `law r: sum_before(5, 3) == 3 := refl` | `law r: Equal[1](nat, sum_before(5, 3), 3) := Equal.refl[1](nat, 3)` |
| test/wap/test_theory_statements.wap:26 | e | `law r: sum_skipping(4, 2) == 8 := refl` | `law r: Equal[1](nat, sum_skipping(4, 2), 8) := Equal.refl[1](nat, 8)` |
| test/wap/test_theory_subtypes.wap:38 | a | `law one_is: (1 is one_only) == yes := refl` | `law one_is: Equal(bool, 1 is one_only, bool.yes) := Equal.refl(bool, bool.yes)` |
| test/wap/test_theory_verify.wap:12 | c | `law double_even(n: nat): Even(double(n)) := match n { zero => Even.zero; successor(k) => Even.step(double_even(k)) }` | `law double_even(n: nat): Even(double(n)) := match n { zero => Even.zero; successor(k) => Even.step(double_even(k)) }` |
| test/wap/test_theory_verify.wap:13 | c | `law hard(n: nat): Even(n) := assume` | `law hard(n: nat): Even(n) := assume` |
| test/wap/test_theory_verify.wap:17 | c | `law uses_hard(n: nat): Even(n + 2) := Even.step(hard(n))` | `law uses_hard(n: nat): Even(nat.successor(nat.successor(n))) := Even.step(hard(n))` |
| test/wap/test_theory_verify.wap:20 | c | `law wrong(n: nat): Even(double(n)) := Even.zero` | `law wrong(n: nat): Even(double(n)) := Even.zero` |
| test/wap/test_theory_verify.wap:24 | a | `law add_zero(n: nat): n + 0 == n` | `law add_zero(n: nat): Equal(add(n, nat.zero), n)` |
| test/wap/test_theory_verify.wap:25 | a | `law wrong_add(n: nat): n + n == n` | `law wrong_add(n: nat): Equal(add(n, n), n)` |
| test/wap/test_theory_verify.wap:26 | c | `law any_even(n: nat): Even(n)` | `law any_even(n: nat): Even(n)` |
| test/wap/test_theory_verify.wap:29 | a | `law four: 2 + 2 == 4` | `law four: Equal(nat, add(2, 2), 4)` |
| test/wap/test_theory_verify.wap:30 | a | `law add_zero_right(n: nat): n + 0 == n` | `law add_zero_right(n: nat): Equal(nat, add(n, 0), n)` |
| test/wap/test_theory_verify.wap:31 | a | `law add_zero_right(n: nat): n + 0 == n` | `law add_zero_right(n: nat): Equal(nat, add(n, 0), n)` |
| test/wap/test_theory_verify.wap:32 | b | `law same_as_given(a: nat, b: nat, h: a == b): a == b` | `law same_as_given(a: nat, b: nat, h: Equal(nat, a, b)): Equal(nat, a, b)` |
| test/wap/test_theory_verify.wap:33 | b | `law flipped(a: nat, b: nat, h: a + b == b): b == a + b` | `law flipped(a: nat, b: nat, h: Equal(nat, add(a, b), b)): Equal(nat, b, add(a, b))` |
| test/wap/test_theory_verify.wap:34 | b | `law multiply_one_left(n: nat): 1 * n == n := match n { zero => refl; successor(k) => equal_congruent(nat, nat, nat.successor, multiply(1, k), k, multiply_one_left(k)) }` | `law multiply_one_left(n: nat): Equal(nat, multiply(1, n), n) := match n { zero => Equal.refl(nat, 0); successor(k) => equal_congruent(nat, nat, nat.successor, multiply(1, k), k, multiply_one_left(k)) }` |
| test/wap/test_theory_verify.wap:36 | a | `theorem turned(a: nat, b: nat): a + b == b + a := by add_commutative` | `theorem turned(a: nat, b: nat): Equal(nat, add(a, b), add(b, a)) := by add_commutative` |
| test/wap/test_theory_verify.wap:37 | a | `theorem swap(a: nat, b: nat): a + b + 0 == b + a := by add_zero, add_commutative` | `theorem swap(a: nat, b: nat): Equal(nat, add(add(a, b), 0), add(b, a)) := by add_zero, add_commutative` |
| test/wap/test_theory_verify.wap:40 | a | `theorem swap(a: nat, b: nat): a + b + 0 == b + a := by(add_zero, add_commutative)` | `theorem swap(a: nat, b: nat): Equal(nat, add(add(a, b), 0), add(b, a)) := by(add_zero, add_commutative)` |

## What the prelude gives the kernel, to become wap/types words

The binding statements of extensions/theory/prelude, each telling the kernel which declared word plays a part it
computes with; and the words they bind. Each becomes a wap/types declaration with the binding made by core, as
type_notation.wap `literals_declared` binds the truths today.

| statement (prelude file) | what the kernel gets | the wap/types word | note |
|---|---|---|---|
| `numbers(nat, bool.yes, Equal)` (numbers.wap) | the type of the numerals, its two cases, the truth `yes`, equality: numerals become literals of that type | `int`, exact (types/numbers.wap) | user 2026-11-27: numerals are int in both worlds; the kernel's natural numbers stay its literal mechanism (kernel/numbers.wap), so this binding names int, and `nat` is `int where it >= 0` |
| `shortcut(add, …)`, `subtract`, `multiply`, `equal`, `at_most`, `divide`/`remainder` (numbers.wap) | the functions computed at once on two literals, each fixed by the theorems named | int's `+`, `-`, `*`, `==`, `<=`, `÷`, `%` (types/numbers.wap), with their defining theorems | the theorems move as laws with proofs (add_zero, add_successor, …) |
| `texts(text_of, list.empty, list.item)` (data.wap) | text literals as a function of their code points' list | `text` and `list` (types/texts.wap, types/lists.wap) | needs list as a filled enum (T5b2) with today's layout |
| `products(Pair, Unit)` (logic.wap) | the pair and unit types the course of a recursion rides | none: core declares them (coc-t5c.md T5c2, decided) | |
| `quotients(Equal)` (quotient.wap) | the quotient's four constants, over this equality | `quotient`, `.of`, `.lift` (types/quotient.wap) | needs Equal as a wap/types word, (b) and (c) |
| `runs(…)` (logic.wap 4, numbers.wap 14, data.wap 10, effects.wap 3) | how a prelude type and its cases run: the host layout, `when:` the case test, the fields read | a declared layout per enum (coc-t5b.md T6 table: bool done by core's word, int and nat by T1's rows, list by the library's code) | erasure's input, never the kernel's |
| enums `False`, `True`, `And`, `Or`, `Equal`, `Exists`, `Decidable`, `bool`, `Pair`, `Sum`, `Unit` (logic.wap) | the logic | types/logic.wap; bool by T5b3; Pair, Sum, Unit are tuples, `A or B` and `()` | (b), (c), (d) |
| axiom `proposition_extensionality` (logic.wap), `quotient_sound`, `function_extensionality` (quotient.wap) | the three axioms | types/logic.wap, types/quotient.wap | `axioms of` names them |
| `Effects`, `Eff`, `Fallible`, `Inhabited`, `never`, `pure`, `diverging`, `io` (effects.wap) | the computation types | types/effects.wap (T6e) | (f) |
| `list(T)`, `count`, `item_at`, `drop`, `joined`, `mapped`, `optional`, `text_of` (data.wap) | lists and texts as terms | types/lists.wap, types/texts.wap | `#xs`, `xs#i`, `xs + ys`, `xs.map(f)` |
| `fraction`, `rational`, `set`, `map` keys, `char`, i64's wrap (checked.wap) | quotients and subtypes of the data | types/numbers.wap, maps.wap, characters.wap | char is T4c's, i64 an int refinement |
| `implies`, `not` (operators.wap) | the operators of propositions | rows of types/operators.wap | (d) |
| `any`, `convert` (any.wap, conversions.wap) | the boxed value, the conversions | none: T5u's unions and core's conversions | |

## Appendix: the statements in wap spelling, with what they need beyond (a)

| file:line | class | statement |
|---|---|---|
| test/test_keyword_wanted.wap:64 | a | `law square(-x) == square(x)` |
| test/test_laws_page.wap:8 | a | `law doubled(n: int): n + n == 2 * n` |
| test/test_laws_wanted.wap:5 | a | `law twice_doubles:` |
| test/test_laws_wanted.wap:10 | a | `law fact(n) > 0` |
| test/test_proof_wanted.wap:6 | a | `law double(n) == n + n` |
| test/test_proof_wanted.wap:11 | a | `law double_three: double(3) == 6 := refl` |
| test/test_proof_wanted.wap:12 | a | `law add_zero(a: int): a + 0 == a` |
| test/test_proof_wanted.wap:13 | a | `law add_commutes(a: int, b: int): a + b == b + a` |
| test/test_proof_wanted.wap:14 | a | `law swap(a: int, b: int): a + b + 0 == b + a := by add_zero, add_commutes` |
| test/test_proof_wanted.wap:15 | a | `law swap_steps(a: int, b: int): a + b + 0 == b + a := chain` |
| test/test_proof_wanted.wap:20 | a nat | `law hard(n: nat): n * n >= n := assume` |
| test/test_proposition_wanted.wap:6 | a | `law four: 2 + 2 == 4 := refl` |
| test/test_proposition_wanted.wap:7 | a | `law both: 1 < 2 and 2 < 3` |
| test/test_proposition_wanted.wap:8 | d nat | `law some_sum: exists n: nat where n + n == 4` |
| test/test_proposition_wanted.wap:9 | a | `law doubled:` |
| test/test_proposition_wanted.wap:12 | a nat | `law doubled_again(n: nat): n + n == 2 * n` |
| test/test_quotient_wanted.wap:12 | a | `law lift_of(a: fraction): quotient.of(a).lift(f => sign(f.top * f.bottom)) == sign(a.top * a.bottom) := refl` |
| test/test_quotient_wanted.wap:17 | a | `law add_commutes(a: int, b: int): a + b == b + a` |
| test/test_quotient_wanted.wap:18 | a | `law same: add_one == one_more := function_extensionality(n => add_commutes(n, 1))` |
| test/wap/test_law_runs.wap:10 | a | `law positive(x: int): x > 0` |
| test/wap/test_law_runs.wap:11 | a | `law both: 1 < 2 and 2 < 3` |
| test/wap/test_law_runs.wap:12 | a | `law two: 2 + 2 == 5` |
| test/wap/test_law_runs.wap:15 | a float trials | `law tested(x: float): x * 1.0 == x` |
| test/wap/test_proof_wanted.wap:9 | a float trials | `law tested(x: float): x * 1.0 == x` |
| test/wap/test_proof_wanted.wap:10 | a nat | `law broken(n: nat): n * n > n` |
| test/wap/test_proof_wanted.wap:11 | a nat | `law hard(n: nat): n * n >= n := assume` |
| test/wap/test_proof_wanted.wap:16 | a float trials | `law guess(x: float): x * 1.0 == x` |
| test/wap/test_proposition_wanted.wap:6 | a | `law four: 2 + 2 == 4 := refl` |
| test/wap/test_proposition_wanted.wap:7 | a | `law five: 2 + 2 == 5 := refl` |
| test/wap/test_theory_arithmetic.wap:11 | a nat | `law regrouped(a: nat, b: nat): a + 1 + b == b + a + 1` |
| test/wap/test_theory_arithmetic.wap:12 | b nat | `law widened(a: nat, b: nat, h: a <= b): a <= b + 1` |
| test/wap/test_theory_arithmetic.wap:13 | b nat | `law chained(a: nat, b: nat, c: nat, h: a <= b, k: b <= c): a <= c` |
| test/wap/test_theory_arithmetic.wap:14 | b nat | `law part(a: nat, b: nat, c: nat, h: a + b <= c): a <= c` |
| test/wap/test_theory_arithmetic.wap:15 | b nat | `law from_equation(c: nat, b: nat, k: nat, h: c == b + (k + 1)): b + 1 <= c` |
| test/wap/test_theory_arithmetic.wap:16 | b nat | `law predecessor(i: nat, n: nat, h: 1 <= i and i <= n): i - 1 <= n` |
| test/wap/test_theory_arithmetic.wap:25 | a nat | `law unbounded(a: nat, b: nat): a <= b` |
| test/wap/test_theory_connectives.wap:14 | a | `law both: 1 < 2 and 2 < 3` |
| test/wap/test_theory_connectives.wap:15 | a | `law either: 1 < 0 or 2 < 3` |
| test/wap/test_theory_connectives.wap:16 | d nat | `law implied(a: nat): a < 3 implies a < 3` |
| test/wap/test_theory_connectives.wap:17 | a | `law neither: not (2 < 1)` |
| test/wap/test_theory_connectives.wap:20 | d nat | `law smaller(a: nat): a < 3 implies a < 4 := assume` |
| test/wap/test_theory_connectives_wanted.wap:11 | d nat | `law positive_product(x: nat, y: nat): x > 0 and y > 0 implies x * y > 0` |
| test/wap/test_theory_induction.wap:12 | b nat | `law positive_product(x: nat, y: nat, a: x > 0, b: y > 0): x * y > 0 := assume` |
| test/wap/test_theory_induction.wap:13 | a nat | `law fact_positive(n: nat): fact(n) > 0` |
| test/wap/test_theory_subtypes_wanted.wap:13 | a | `law dot_is: dot([1, 2, 3], [4, 5, 6]) == 32 := refl` |
| test/wap/test_theory_untyped.wap:15 | a | `law doubled:` |

## Rewritten on branch unify-laws, and kept

Of the 40 of class (a) and level-only (e), 21 lines (22 laws, `two_is_not` beside `one_is` on one line) are
rewritten in wap spelling, one commit per test file. The checks and their expected outputs are unchanged.
- test/wap/test_theory_elaborate.wap: 96 `divided`, 121 `nine`, 150 `counted`, 165 `b`
- test/wap/test_theory_induction.wap: 15 `zero_add`
- test/wap/test_theory_measures.wap: 11, 12 `r`
- test/wap/test_theory_second.wap: 21 and 36 `four`, 23 `divided`
- test/wap/test_theory_statements.wap: 20, 21, 25, 26 `r`
- test/wap/test_theory_subtypes.wap: 38 `one_is`, `two_is_not`
- test/wap/test_theory_verify.wap: 29 `four`, 30 and 31 `add_zero_right`, 31 `twice_zero`, 36 `turned`, 37 and 40 `swap`

19 stay as written: their words are the test program's own declarations, not the prelude's, or the theory's
spelling is what the check is about, so the mechanical wap spelling would test something else.
- Their own nat, add, bool or Equal (`+` would name the prelude's int, not the program's word):
  test_theory.wap:29 (STRUCTURES' own bool), test_theory_verify.wap:24 and 25 (`sums`, its own nat and add; 25's
  expected counterexample prints `nat.successor(nat.zero)`), test_theory_nested.wap:15, test_theory_numbers_wanted.wap
  11, 12, 18, 19, 21 (its own nat and a `shortcut` binding naming the laws), test_theory_recursors_wanted.wap:16.
- A program's declaration hiding the prelude's `add` (SECOND): test_theory_elaborate.wap 97, 98, 100.
- The written level is the subject: test_theory_elaborate.wap:105 ("a declaration at the levels written after its
  name").
- The recursor of the logic prelude read as a program, `negated` against wap's `not`: test_theory_logic.wap:15.
- Propositions joined, not bools: test_theory_connectives.wap 18, 19 (`And`, `Or`) and 22, 23 (`and`/`or` of two
  Equal propositions "nothing decides"). In wap spelling they become `1 == 1 and 2 == 2`, a bool law that lines 14 and
  15 already state, so they belong to class (b).
