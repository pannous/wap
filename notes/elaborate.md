# Holes and unification: what a program leaves out, found

Core typing finds what a program leaves out by holes of the kernel and unification: `wap/core/analyze/holes.wap`
(the `Elaboration`, its holes and answers) and `wap/core/analyze/unify.wap` (`unified`). Typing keeps one
`Elaboration` for a compile (core/analyze/types.wap `el`): a generic letter's value at a call and an empty list's
item type are its holes (core/analyze/letters.wap). The verify door (wap/extensions/proof/verify/laws.wap) and the provers
(wap/extensions/proof/prove/) make one of their own for each goal. Nothing here is trusted: a filled term is handed to the
kernel, which judges it whole (notes/theory.md).

## Holes

A hole stands for what the program left out: a letter's value, a level, an item type. A hole for a term is a free
variable of the kernel (`hypothesis(c, name, type)`) that the elaboration may answer; so the kernel's `type_of` and
`computed` work on a term with holes as they are, a hole being a variable nothing is known of. A hole for a level is
a level parameter whose name starts with `?` (`LEVEL_HOLE`), a name no program writes.

**A hole is a function of the binders in scope.** Under the binders `x` and `y` a hole of type `T` is made as a
variable of type `(x: X) -> (y: Y) -> T`, and what the caller gets is that variable applied, `?h(x, y)`. So:
- a binder that closes binds its variable inside `?h(x, y)` like anywhere else, also when the hole has no answer
  yet; an answer found after the binder closed is still good;
- an answer names no binder at all, only its own parameters and other holes. It is a closed function, put in
  anywhere as it is. No order of making and no scope is asked when an answer is given: "names a binder"
  (`names_binder`) is the whole test, and it is what keeps a variable from escaping its binder.

`Elaboration` is the state: a `Checker`, the binders in scope (their variables, the outermost first; a binder's name
is its hypothesis's), the holes with their answers, the level holes' answers, and the problems put off.
- `scoped(el, binder, type)`: a binder gone into, in scope from here; `named(el, name)`: the innermost binder in
  scope of a name.
- `hole(el, name, type)`: a new hole over the whole scope. `hole_over(el, name, type, variables)`: one over these
  binders only. `level_hole(el)`: a new level hole.
- `filled(el, t)`: t with every answered hole replaced by its answer, levels too; an answered hole applied to its
  arguments is the answer's body with them put in. It goes under a binder by a free variable, as the kernel does,
  so what is put in is closed. A term is filled before it is computed, compared or handed on; the checker fills a
  hypothesis's type the same way (`el.c.filled_in`).
- `unified(el, a, b)`: whether a and b can be made equal, answering holes on the way; a failed try leaves no answer.
  Two terms without a hole are the kernel's `equal`, an ill-typed one being no match. With holes it follows
  equal.wap's rules on filled terms (the unfolding order, eta for functions) and adds:
  - **the pattern rule**: a hole applied to variables of binders, no two the same, against a term t is answered by
    the function of those variables that gives t, when that function names neither the hole itself nor a binder;
    the answer's type is unified with the hole's type, which is what finds a letter's level from its value. With
    a hole on both sides the left one is tried first, then the right one;
  - **waiting**: a hole applied to anything else (a value, a variable twice, another hole), and a pattern whose
    other side still holds a hole and gave no answer, is a problem put off: the unification says yes, and the
    problem is tried again whenever a hole is answered (`problems_retried`); an answer a waiting problem refuses is
    no answer;
  - a pattern that finds no answer against a term without holes is a mismatch;
  - two levels are unified by answering a level hole that stands alone on one side, or by what two successors are
    above; other level problems are put off.
- `found_so_far(el)` and `back_to(el, kept)` take a reading back: the answers, the problems and the scope;
  `taken_back(el, attempt)` gives what an attempt gives with its answers taken back.

Not in the unifier: no guess is made for a hole applied to values. `?F(?A)` against `list(int)` waits; taking it
apart as `?F` against `list` and `?A` against `int` (first-order approximation) is not done.

## Rules

- The rules of notes/theory.md hold here too: closed terms only (a binder is entered by a free variable), names
  are hints, never `==` on a term, each file names what it uses.
- Nothing here may weaken a check: a term the kernel refuses is refused, never retried another way.
