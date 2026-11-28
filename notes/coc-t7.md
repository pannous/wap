# T7: the theory extension retires

coc-plan.md's T7 row: what is left of wap/extensions/theory goes, and the proof code (provers, the second opinion,
the export, the arithmetic proofs, the `wap check` door) lives in wap/extensions/proof, which only `wap check` and
proofs load. Read on unify-typers 2b0e87be.

## What is left on unify-typers

- unify-typers already deleted most of what the row lists: the theory's reader, its run door and its prelude.
- wap/extensions/theory holds eight files:
  - export.wap (the export of a declaration for an outside checker);
  - second/, seven files, the second opinion (K7): bindings, blocks, check, expressions, judge, nested, read.
- The proof code is spread over three folders:
  - extensions/prove/ (9 files: goals, computing, apart, facts, rewriting, introduction, induction, linear, prove);
  - extensions/verify/ (verify.wap, laws.wap, options.wap);
  - extensions/theory/.
- The kernel's arithmetic is in wap/kernel/. counting.wap (count and int with their definitions and shortcut
  licences) is declared at every compile by core_environment, so it stays in kernel/. integer_laws.wap is declared only
  before a prover's first goal (integer_laws_ready), and no compiler file uses it, so it moves to
  extensions/proof/prove/ with its two users, goals.wap and linear.wap. Its proofs are still checked by the kernel
  when they are declared; only the census and the compiler's sources lose it (unify-cost's N1).

## The plan

1. **One folder, wap/extensions/proof/**, with three subfolders:
   - prove/ (the provers);
   - verify/ (`wap verify`'s door and laws.wap; V3's `wap check` door beside it);
   - second/ (the second opinion and export.wap).

   This is moves only. Each `use` path and the native driver's part names (`VERIFY_PART`, the seed's file list in
   scripts/refresh-seed.sh) follow. extensions/theory/ is gone. Core 0, lines 0 net.
2. **Who loads it.** `wap verify`, `wap check` (V3), and a plain compile of a program with a proof obligation, such
   as a `lift` (Q1) or a written proof checked by the kernel.
   - A plain compile without one never loads the folder. That holds today, and stays so by the pipeline's
     `standard_brought`.
   - The test: a plain `print "Hello"` compiles with extensions/proof absent from the seed folder. That is a gap line
     for test_native.sh, the run with a seed folder that lacks extensions/proof.
3. **The trust base listed.** `wap trust`, a new native command, prints the files the kernel's checks rest on:
   - kernel/*.wap;
   - the second opinion's checker, if run;
   - and, for a program, the axioms its laws rest on (V1's `axioms of` over every law).

   The row asks for it ("the trust base listed by a command"). No wiki page shows it. cli.md has no such command, so
   it is a wiki passage first (cli.md "Proofs"), through warp-interviewer. native +12.

## The red lines

None of its own: T7 moves files, and every test stays as it was. The row's lines are:
- test_native's seedless hello (a gap line, (2));
- the second opinion's tests (parked/theory-second/test_theory_second.wap) run from the new folder;
- `wap trust`'s line, once cli.md shows it.

## Estimate

Core 0, kernel 0, moves only, plus native +12 for `wap trust`. Careful path, since it changes the seed's file list:
test_self, a seed refresh (scripts/refresh-seed.sh), and test_hello from a fresh seed. T7 lands after V3 (the check
door moves with it) and after T6 closes (the row's wait), so that no T6 step lands into the old folders.
