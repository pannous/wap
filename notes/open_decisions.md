# Open decisions for the user

Shapes waiting for the user's discussion, each with its core lines, the case against, and why no hook or library
does it. Line counts are estimates from reading the code, marked as such; the measured size comes with the branch.
An entry goes once decided (its decision then lives in the wiki or notes/debts.md).

## The top debts still open (notes/debts.md); the "5" + 3 warning is parked (card digit-text-compile-warning)

## Pending questions (ask at 10:00; core growth waits for the morning, notes/agents/night.md)

Built and held by wap-integrator; wap-reviewer sound per integrator; recommendation: OK each. Per entry still to
show the user: the case against and why no library or hook does it (ask the branch owner before 10:00).

- foreign-globals-first 88f7063c, +8 core (core/emit/host.wap): every library global is imported before the
  program's own, so a global imported late no longer renumbers the program's globals (test_modules kept_global).
- valueless-argument 3e46a738, about +5 core: an argument, name or result that gives no value gives ø; a function
  giving nothing, used as a C callback, answers 0.
- is-equal 3b44e172, +3 core (analyze/names.wap): `x is y` with two variables compares their values (wiki/equality.md).
