# The rewrite rules of the library files

A library speaks plain wap: functions, enums, classes, overloads, block and data parameters. A rule belongs only where
plain wap cannot say the spelling (AGENTS.md "Plain wap first"). This survey sorts every rule of lib/ into three
groups.
- **plain**: a plain wap word replaces it today, so the port writes that word.
- **copy**: it repeats another rule, so the port drops it.
- **mechanism**: plain wap lacks something, named once below the table.

## Per file

| file | rule | sort | the plain wap or the mechanism |
|---|---|---|---|
| keys.warp | `listen(data ESC…, …)` with a list of key names | plain | `enum Key {escape, enter, tab, …}`, `listen(k: Key, listener)`: the CLAUDE.md example `on Key.escape {…}` |
| keys.warp | `listen(data key, …)` | plain | the same enum's overload without a key |
| frames.warp | `listen(data frame …)`, `listen(data exit …)` | plain | `enum Moment {frame, exit}` and an overload of listen per case |
| markup.warp | `listen(data mount/cleanup …)` | plain | the same enum, the cases `mount`, `cleanup` |
| markup.warp | `$tag each $xs` over 25 tag names | mechanism: data | the tag names are vocabulary: `enum Tag {li, tr, …}`, then `each(tag: Tag, xs)` is a call |
| markup.warp | `click $who` | mechanism: data | `click(who: data)` |
| channels.warp | `channel()`, `channel $name` | plain | `channel(): Channel`, `channel(name: text): MachineChannel` |
| channels.warp | `$c.send($v)`, `$c.receive()` over `channel $name` | plain | methods of the class `MachineChannel` |
| channels.warp | `on message from $name {…}` | plain | `on(message_from: text, handler: block)`, a phrase with a block parameter |
| sound.warp | `play {…}`, `play({…})` | mechanism: data | `play(score: data)`; the bracketed call and the spaced one are the same call |
| sound.warp | `tune {…}`, `tune({…})` | copy | the word alias `tune → play` |
| uncertain.warp | `$a certainly > $b`, `certainly <` | copy | `certainly` changes nothing: `a > b` |
| uncertain.warp | `$a possibly > $b`, `possibly <` | mechanism: operator modifier | methods `possibly_greater`/`possibly_less` exist; the spelling between operands needs a word before an operator |
| english.warp | `add $x to $list` | plain | `add(x, to: list)`: a list is shared, so the call changes it |
| english.warp | `increase/decrease/multiply/divide $x by $n` | mechanism: place | the four phrases write the caller's variable |
| english.warp | each of those four again with `by:` | copy | a preposition labelling an argument is the same with or without its colon (function.md) |
| english.warp | `set $field of $object to $value` | mechanism: place | as above, a field place |
| timers.warp | `on every $period {…}`, `on every $count $unit {…}` | plain | `on(every: duration, handler: block)`; `2 minutes` is a duration already |
| timers.warp | `on every $day at $time {…}` | plain + read | `enum Weekday`, `on(every: Weekday, at: Clock, handler: block)`; the clock literal `9:00` is a reader gap |
| timers.warp | `at $hour:$minute {…}` | read | the same clock literal |
| timers.warp | each `{}` and `: $body` variant | copy | an empty block and a colon body are blocks wherever a block parameter stands |
| signals.warp | `whenever $c {…}`, `once $c {…}` | plain | `whenever(condition: block, handler: block)`: a block parameter takes its argument unevaluated |
| signals.warp | `on set $x {…}`, `on change $x {…}` | mechanism: data | the watched name, not its value: `on(change: data, handler: block)` |
| signals.warp | `on change dark mode` | copy | `dark mode` is vocabulary: a value `dark_mode` |
| signals.warp | each `: $body` variant | copy | as in timers |
| storage.warp | `$store.$name`, `$store[$key]`, `keys($store)` over `[storage, database, local]` | plain | one class `Store` with `[]`, `[]=`, keys and a dynamic field read; `database` and `local` are names of the one value `storage` |
| storage.warp | the same four over `[session]` | plain | a second `Store` value, `session`, of the same class with an in-memory backend |
| storage.warp | `delete $read($key)`, `delete $read[$key]` | plain | `delete(store: Store, key)` |
| storage.warp | `stored $name: [$kind] in $table`, `stored $name default $value` | mechanism: declaration | a declaration naming a variable a library keeps: the name as data plus a write listener |
| storage.warp | `transaction {…}` | plain | `transaction(body: block)` |
| agent.warp | `x: T = agent p`, `agent(p) as T` | mechanism: result type | the expected type as a value: a function generic in its result reads `T`'s name |

## The mechanisms
- **data**: a data parameter takes its argument as written, a name or a brace block unevaluated (dsl.md, user-approved).
  It serves 6 rules: markup ×2, sound, signals ×2, storage's declaration.
- **place**: a parameter that names the caller's variable or field, so a phrase can write it. It serves english ×5.
  A block argument already writes the caller's names, which may be the mechanism.
- **operator modifier**: a word before an infix operator (`possibly >`). It serves uncertain ×2. Recommendation:
  keep the methods and drop the spelling, as an edge case.
- **result type**: the expected type as a value, for agent ×4. Variants told apart by result type exist
  (function.md), but not one generic body reading the type.
- **read**: the clock literal `9:00`, for timers ×2 (on the reader's pick list).

Count: of about 75 rules, about 30 are plain wap today, about 25 are copies, and about 20 wait on five mechanisms. The
mechanism a rule needs is never one word per rule: data serves three libraries (markup, sound, signals), the three
uses AGENTS.md asks of a compiler change.
