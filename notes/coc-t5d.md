# T5d, statements and loops: the plan's starting points (parked)

Parked while the two typers are unified (card unify-typers); the table in the shape of coc-t5b.md is still to be
written. What it builds on, read on main ccf63462:

- **What a write means is decided** (coc-plan.md 9.5, test/test_sharing.wap, user 2026-11-27 write-meaning): lists,
  maps and instances are shared; a write to a value the function made and gave no second name is a new binding; a
  write through a parameter, a capture, a global or a second name is State, and a name ending in `!` claims it. T5d
  needs the analysis that tells the two apart, "no second name": the plan's largest part.
- **Bindings along paths exist in core:** core/analyze/flow.wap gives each assignment of another type a binding of
  its own (REBOUND) and joins unlike bindings where paths meet; core/analyze/terms.wap already reads REBOUND for a
  name. A block's lets are terms since T5a (`lets_term`); T5d adds the assignment as a new let, the join of a choice,
  and the loops.
- **What T5d builds in core:** a choice before the rest of a block joins again (the rest read once as a function of
  the names the parts give), a counted loop is a walk down its count, with `break` and `continue` as calls of the join
  and of the next round, and `return` giving the block's value at once.
- **Loops:** `For(at, n, body)` (kernel/forms.wap) always ends and is a recursion over the count. `While` is a
  recursion over its state: the T5c1 ending test applied to it would make a `while i < n { …; i += 1 }` no Div, but
  wiki/effects.md says "a `while` that may run" is Div. That is a spec question for wap-interviewer: the general rule
  (a loop is a recursion, with one ending test for both) against the wiki's present wording (0 lines: every while is
  Div).
- **`T or Error` and try:** the failable type landed (`int??` holds an int, ø or an Error; `int or Error` its
  precise form). A function with Fail enters the kernel with the result `T or Error`, `raise` its Error part and
  `try` its match (coc-plan.md 9.1). The Fail fact itself comes from T5b1.
