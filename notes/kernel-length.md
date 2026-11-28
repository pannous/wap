# kernel-length: the shrinks, read on int-takes

Card kernel-length takes the counts route (decided; the case route was measured at +85 and rejected). It is built
after unify-typers and int-takes land. These shrinks were read on int-takes 22c1211b. Code lines, comments and blanks
left out: integer_laws.wap 360, counting.wap 202, equality.wap 89, logic.wap 68, extensions/prove/linear.wap 320.
The estimates are code lines.

int-takes has already removed what the two cases made removable: the zero and positive arms went in fdb551e0. One
leftover is listed under counting.wap below. `unshifted` (counting.wap:241-245) stays. A negative's downs is a
successor and `·add` recurses on its second count, so `add(zero, successor(n))` stays stuck and needs `zero_added`
in either order of the crossed counts.

## Copies

| where | what | lines |
|---|---|---|
| extensions/prove/integer_laws.wap and counting.wap, seven sites | Seven single inductions of one shape, `theorem_declared(b.e, NAME, [], binders, motive(v), induced(b, motive, base, step, v))`, each with its motive on a line of its own. They become `inducted(b, name, binders, motive, base, step)` on the last binder, done in 7b6f901f: `inducted` takes its major from the last binder and each user writes the motive inline, as equation_inducted does (unbuilt) | −5 |
| integer_laws.wap:181-192 (at_most_split), :195-202 (at_most_beyond); counting.wap:224-232 (count_equals_sound) | Three paired inductions under a hypothesis. Each writes `X_at = (i, j) => pis([h: premise(i, j)], conclusion(i, j))`, the hypothesis local, `every = paired(…)`, `apply(apply(every, n), h)`, and arms that each open with `assuming(b, premise(…), h => …)`. They become one `paired_law(b, name, m, n, premise, conclusion, at_zero, at_first, at_both)` whose arms take h (−2 if count_equals_sound's uneven zero arm reads worse) | 0: tried, not applied. `paired_law` and `assumed` take 7 lines and the three users lose 9, and count_equals_sound's zero arm needs an `apply(induced(…), h)` of its own |
| extensions/prove/integer_laws.wap `applied`, extensions/prove/linear.wap `law_equated` (both now `instance_of`) | Each law's two sides are written twice: once in its declaration, again at every use. Instead, `instance_of(e, name, given): Identity` instantiates the declared statement with the arguments and reads its type and sides. That is kernel +5. The one-line wrappers it replaces go: successor_added, at_most_shifted, parts, differences_equal, the `shift` lambda, added_zero, associated, minus_cancelled. A use can then never restate a law differently from its declaration. Two fewer wrappers are left after main's merge, and law_equated stays one line over it | −7: done in this branch. `instance_of(b, name, given)` is in extensions/prove/integer_laws.wap (`equation_of` of the proof's type, so kernel +0); linear.wap's `law_equated` and the Sums wrappers stay, as they reach a Sums checker |
| integer_laws.wap:304-305 `complete`, `sound`; linear.wap:380-381 | The same two functions, over a Building and over Sums. One pair reads `e.integers`' equals_sound and equals_complete (open) | −2 |
| integer_laws.wap:134-137 `count_sums`; linear.wap:370 `int_sums` | Two Monoids built the same way from three law names. They become one `monoid_of(c, type, zero, addition, zero_law, grouping_law, order_law)` with `instance_of` (open) | −1 |
| equality.wap:79-83, :91-95 | symmetric and transitive open with the same five lines. One `equal_binders(e)` (open; no hit on the last scan: check whether it still exists before counting it) | −3 |
| counting.wap `zero_subtract_proof`, `successors_subtract_proof` | The two recursor proofs have one shape, now `by_predecessors(b, left, right, base, n)`; `fixing_proof` keeps its name test, a list of (statement, proof) would not be shorter | -2 |

`fixing_proof` keeps its name test: it picks the proof by the statement's name, and a list of (statement, proof) pairs
would spell every statement a second time.

Every refusal in bindings.wap names the statement it refused: `bound` wraps `binding_made` and puts the statement before the message.

## A helper used once, or nothing using it

| where | what | lines |
|---|---|---|
| integer_laws.wap:23, :347 `·add_swapped` | No caller (the card's note). linear.wap's regrouper does without it | −2 |
| logic.wap:18, :29, :54-61 `·yes_is_not_no`; :19, :30, :62-75 `·bool_cases` | No caller on int-takes, t6a3a or unify-linear. unify-provers.md:80-81 and :100 plan them only for the divide laws, which are not built. Both go. `·bool_cases` comes back in the commit of its first caller, a proof by cases over a comparison (Q1's sign_product or T6a4's case proofs); `·yes_is_not_no` with divide | −16 |
| integer_laws.wap:232 `parts_zero` | An induction inside paired's zero arm. paired's at_zero takes a step (the card's note) | −2 |

## Parameters always passed the same

- `theorem_declared(b.e, …, [], …)`: every call in integer_laws.wap and counting.wap passes `b.e` and no levels.
  A `theorem(b, name, binders, statement, proof)` on the Building makes the lines shorter, not fewer (0).
- `b.e.literals!.truth` is spelled at integer_laws.wap:70, :165, :167, :172, :259, :318, :396, :407, :430. A
  `truth(b)` makes the lines shorter (0).
- `int_numeral(s.c.environment, v)` appears 7 times in linear.wap; a `number(s, v)` does the same (0).

## Speed, no lines

`count_sums(b)` is rebuilt at 13 calls and `int_sums(s)` at 3. Building each once, as a field of Building and Sums,
saves the rebuild in every regrouping. This counts toward a "standing OK speed" only if measured at ≥ 1%.

## Dead code across wap/ (wap-tree-wap's caller scan, on the card)

wap-tree-wap scanned origin/int-takes for names with no caller; the scan is a todo note on card kernel-length. 12
names, about 37 lines, are dead and go in the same card: seen_ids, declared_named, REFUSED_DECLARATION,
RUNNING, is_sort, written_parts_of, language_loaded, library_path,
instantiate_all.

These stay:
- CALL_REF, an opcode row.
- Names called from outside wap/: declared_code and enums_shown (scripts/wap-census.warp); host_word,
  host_word_answered and caller_memory (main.c).
- axioms_shown, which V1 calls for `axioms of` (notes/coc-v1.md).
- Gaps waiting on a caller: courses.wap (T5c3), texts_declared (T4d3's text rows), the quotients (Q1) and
  condition_proof (T4d1's to check).

## Total

About −45 code lines in the five files, against the card's measured −12, plus the dead code's about 37 elsewhere:
- integer_laws.wap about −17;
- counting.wap about −8;
- logic.wap −16;
- equality.wap −3;
- linear.wap about −5;
- kernel +0: `instance_of` sits in extensions/prove.

integer_laws.wap ends near 336 code lines. One builder, normal path. The census and the provers' test lines
(test_theory_arithmetic, test_induction, test_verify, wap/test_law_runs) stay as they were.
