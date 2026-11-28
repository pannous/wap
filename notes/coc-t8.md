# T8: exact int, re-read on unify-typers

coc-plan.md's T8 rows (T8a the reader, T8b the machine words, T8c exact int on the run), with the section's "The
compiler's own ints" and "Fast values flow" paragraphs, were written with their lines and tests. This note checks them
against unify-typers 2b0e87be and adds what the later plans changed.

## T8a: the reader keeps whole literals whole

- **Waits on exact-big-literals**, which is not in unify-typers yet (its tip df289030 merges onto it). On 2b0e87be:
  - `Large` is absent;
  - `magnitude_of_digits` lives in lib/magnitude.wap, lib/exact.wap and the second opinion's read.wap;
  - core/parse/atoms.wap still has its own `LARGEST_INT`, beside kernel/primitives.wap's `WHOLE_LARGEST`.

  The row's plan reads right once exact-big-literals lands: the atom +5, its int typing +4, the one range test +3,
  LARGEST_INT and the DEBT −3, kernel +2.
- **With T7** the second opinion's `magnitude_of_digits` copy moves to extensions/proof/second. T8a's kernel numeral
  from digits should be the one copy the second opinion also uses. That is a −8 the row did not count: the second
  opinion is an outside checker by design, but it may share the digit reader, which is no part of the judgement.
- Lines: the row's three red lines and the gap `type of 18446744073709551616` is `int`. Estimate unchanged: core +12,
  kernel +2.

## T8b: the machine words

- `i64` as int's quotient by multiples of 2^64 is Q1's `quotient(int, same_wrapped)` (notes/coc-q1.md), with
  `same_wrapped(a, b) := (a - b) % 2^64 == 0`.
  - It is the one quotient whose run layout is not its carrier's: an i64 is stored in 64 bits, an int is not.
  - So T8b declares i64 with its row operations (T1's table) and states the quotient as its laws' reading: a law over
    i64 is a law over `quotient(int, same_wrapped)`. That follows quotient.md:43-44 without making every i64 a boxed
    int.
- A literal that does not fit is refused by T4d1's decided narrowing: i64's range is a condition, and T4d1 computes it
  (`x: i64 = 2^70` refused, naming the range).
- Estimate unchanged: types +15, core 0. T8b lands after Q1 and T4d1.

## T8c: exact int on the run

- The row's mechanism stands:
  - checked operations carry into a big int (lib/magnitude.wap with a sign);
  - storage as i64 where a fact shows the value fits (T4b's findings, T4e's ranges, T6a4's nat hypothesis);
  - `wap fast` as every int a wrapping i64.
- The mixing rule of "Fast values flow" adds core +10 in fits.wap (a fast value with a plain int gives an exact int).
  The row's core +40 becomes +50.
- The compiler's own build uses `wap fast` (decision 13), so the self-compile is unchanged. The benchmarks' guardrails
  measure the loop counters.
- Estimate: core +50, kernel −10, types +60, emit +150, native +10. Careful path, value layout. It lands after T8a and
  T5f (erasure).

## Order

exact-big-literals onto unify-typers, then T8a. Q1 and T4d1, then T8b. T5f, then T8c. The fast-flow lines
(599ada57, red until T8c) are T8c's.
