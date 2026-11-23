# symbols

In wasp, [[data]] and [[code]] have the same [[syntax]].

The main difference is that in data everything is a symbol and nearly nothing is [[evaluated]].

# explicit symbols

As in other languages :symbols can be made explicit with a preceding colon. [[significant-whitespace]] differentiates
this syntax from [[map]] notation a:b !

The colon symbol syntax is useful to uncharge operators without separating them via comma:
` a :plus b == a, plus, b `

There is an interesting intermediary in un[[charged]] code, where symbols can be [[dangling]]:

# difference between [[assignment]] and [[declaration]] ( = / := )

# assignment

All words on the left hand side of [[assignment]]s are treated as [[symbol]]s:
`x y z = y*y+u`

* x is a function declaration symbol
* y is a bound argument symbol
* z is an unused argument symbol (compiler error or warning)
* u is an external symbol, evaluated immediately on construction, or [[deferred]] in the [[shell]]

⚠️ on assignment the compiler immediately emits an error if a symbol was not defined before

# explicit declaration

`x y z := y*y+u`

* u is an unbound external symbol, evaluated on calling x(y=1)
* ok if u is available only on invocation, as parameter `x(y=1,u=2)`
* ok if u is available only on invocation, in the context `u=2; x(y=1)`
* => error if u is still undefined or `y*y+u()`

⚠️ the above context consumption of `u` may be enforced with [[global]] keyword if using [[strict]] mode.

⚠️ on declaration the compiler emits an error if a symbol is not defined in invocations `x()`

What is the point of providing arguments, when unbound external symbols are resolved

<!-- dropped: parameters fed from same-named locals
```text
x y z := y*y+u
x(y=2,u=3) # 7
y=2,u=3;x() # 7
```
-->

arguments are more robust and allow [[pure]] functions. arguments are more more efficient, since unbound external
symbols require function calls to query the current [[context]] on [[evaluation]]

# ⚠️ when to allow unknown symbols

The declaration `x y z = y*y+u` is problematic for two reasons:

1. `u` neccessarily refers to an external symbol (variable …), making x stricty un[[pure]].
2. `u` might not even be declared or inteded to be declared.

# Example usages of symbols

internal keywords can have aliases too, similar to c's `#define`, but they need to be quoted as symbol:

`alias typedef => :alias`
