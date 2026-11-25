# Compound assignment

`a ⊕= b`, for every infix operator ⊕ of the table, is the assignment `a = a ⊕ b`. The reader
(core/parse/keys.wap infix_call) writes it that way and marks both the assignment and its inner call with the written
spelling (the COMPOUND fact): `wap format` prints `a ⊕= b` again from the assignment's mark.

A type may declare its own `⊕=`. When typing reaches the inner call (core/analyze/calls.wap call_typed), the
definitions named `⊕=` are the innermost scope. One of them that takes the arguments wins; otherwise `⊕` is chosen as
usual. The declared one gives back the place's new value, which the assignment stores.

A list's `+=` (types/lists.wap) grows the list itself and gives it back, so `xs += [5, 6]` appends in place and a
name sharing xs sees the items (wiki/list.md). `+` still makes a new list. So code that keeps a list to go back to
holds a copy, `before = xs.copy()`, or builds the new list with `+`, `f.present = before + known`.
