# Lean's library in wap: importing checked kernel terms

The layer after track T, beside notes/metaprogramming.md. Lean's surface syntax is not taken: every Lean file may
declare its own notation and run code to read it, so reading a Lean file means running Lean's whole front end
(notation, elaborator, instances, tactics), which a rule set cannot do beyond toy files. What travels is what Lean's
kernel checked: its declarations as terms, written by lean4export. wap's kernel has Lean 4's kernel rules
(notes/coc-plan.md section 6), so those terms mean the same in both, and wap's kernel checks each one again:
nothing is believed on Lean's word.

The format is already wap's: the second opinion (parked/theory-second/export.wap, coc-plan K7) writes every accepted
declaration in lean4export's shape. The importer is that writer read backwards.

## What it gives

`use lean "Mathlib.Data.Nat.Prime"` (spelling open, decided with step 3) brings in that module's declarations and
everything they need, each checked by wap's kernel, under wap names: a library of theorems that wap does not write
itself, and the largest test the kernel will ever see, since a Lean declaration wap refuses is a difference between
the two kernels.

## Steps

1. **Reader.** lean4export's records (names, levels, terms, axioms, definitions, theorems, inductive blocks,
   quotients) read into kernel declarations, the reverse of export.wap; a record the kernel refuses is refused with its
   Lean name. A round trip test: what export writes, the reader gives back. About 150-250 library lines.
2. **The gaps to wap's kernel**, each refused by name until it is closed:
   - number literals: Lean's are any size, wap's stop below 2^63. Like a text literal, which opens into a library
     function of its code points, a larger number opens into a library function of its 63-bit digits: no new kernel
     rule. About 30 kernel lines, the user's OK first.
   - projections out of a structure that holds itself, which wap's kernel refuses (coc-plan section 6): measured on
     Mathlib before anything is changed.
   - Lean's axioms (propext, Classical.choice, Quot.sound): each bound to wap's own statement or brought in as an
     axiom that `axioms of` lists.
3. **Names.** Lean's names (`Nat.add_comm`) shown as wap's (`nat.add_commutes` or a generated canonical form), by a
   name table that is library, never core; the same table serves the second opinion's export. About 100-200 lines.
4. **Closure and speed.** Only the declarations a program reaches are checked, in dependency order, and the checked
   environment is carried as a compiled module (card compile-checks), so a module is checked once, not per compile.
   Checking all of Mathlib takes Lean hours; wap's kernel is slower, so whole-library checks are a nightly job.
5. **The dumps.** lean4export needs a Lean install where the dump is made. Either the dumps are made once and shipped as
   data (a Lean install on one machine, never in the build), or wap reads `.olean` files directly (a binary format that
   changes with Lean versions: rejected unless the dumps prove impractical).

Steps 1-4: about 400-700 lines, at most 30 of them kernel.

## Rules

- wap's kernel is the only judge; the importer is untrusted, a wrong import is refused, not believed.
- No Lean syntax in wap, no Lean front end, no Lean tactic run.
- Takes over much of notes/metaprogramming.md step 6: proofs Lean's automation found come in as terms.
- Starts after T5 (kernel declarations in a compile) and, for speed, compile-checks.

## The decision it needs

coc-plan.md section 1 says "Lean's practices are adopted, Lean is not: no Lean install, no proof found by Lean, no
library taken from it" (user 2026-11-24). This plan takes Lean's library and its proofs as terms, checked by wap's
kernel, with a Lean install only where dumps are made. The user decides before step 1; until then the plan is a
proposal and section 1 stands.
