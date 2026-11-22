# Library coverage under wap

Each lib/ module run as `use <module>` plus a print, by the installed wap (`--seconds 60`), main 3818e62, 2026-11-22.
16 of 121 modules pass: bits case_table case_tables csv exact_values host_io html_entities ini integers intervals
letter_ranges ordering ui uncertain unicode_data events.

A module fails at the first module it uses that fails, so one root cause blocks many. Root causes, most modules
blocked first; **lib** marks a module's own fault (fixed in lib/), **compiler** a form wap does not take yet.

## Compiler: forms wap does not take yet

| Modules blocked | Where | Root cause |
|---|---|---|
| 17: clustering color compress geometry hash image jpeg math matrix money numeric pga png random scene shaders splats | math.warp:94 | `circumfix operator ‖ ‖ := abs`: wap declares no circumfix operators |
| 7: earthquakes feeds json json_tools net polymarket wikipedia | json.warp:237 | `x not in xs` is not lowered |
| 5: file forest meshlets script shell | file.warp:31 | a path literal, `?? /tmp` |
| 6: collections disjoint graphs ring slugs sorted | collections.warp:22 … | `alias ArrayDeque => Deque` declarations |
| 5: cron idna markdown powershell tables | tables.warp:110 … | an if-expression as a call's argument, `parts.add(if … then … else …)` |
| 6: agent audio markup music sound tasks | tasks.warp:12, agent.warp:23, markup.warp:53 | a rule's `where $x = …` binding a template hole |
| 4: channels signals storage timers | timers.warp:20 | a rule template `() => $body` with `where $day is symbol` |
| 9: draw gpu_passes keys pga_draw router uniscript wagi web webview | C bindings | C types node, int, owned_text do not cross yet |
| 11: crypto diff encoding html semver symbolic template text url uuid version xml | text.warp:17, diff.warp:109 … | a comprehension over a text's characters, `[c for c in t]`, lowers to `map(text, f)`, which the types module does not define (a loop `for c in t` works); one `map(t: text, f: (char) -> U)` in wap/types/texts.wap would take it |
| 3: os repl wasm | os.warp:16 | no host word std_io |
| 2: display units | units.warp:276 | the `format Angle a as text := …` declaration |
| 2: hyperreal reals | reals.warp:264 | no `denominator(number)` |
| 2: R extrema | R.warp:6, extrema.warp:32 | rest parameters, `c(xs...)` |
| 1 each | interpret.warp:6 | a labelled parameter, `with names: map` |
| | complex.warp:46 | a type alias, `type complex = Complex` |
| | english.warp:12 | a rule phrase with a keyword hole, `increase $x by: $n` |
| | frames.warp:17 | `data exit` |
| | memory.warp:8 | a range written `start until end` |
| | laws.warp:24 | no `op_of(Key)` |
| | shown_frames.warp:6 | no host word window_open |
| | c.warp | no C function field_u8 in the executable |
| found running modules | any program | `text(m)` of a map<text, int> traps (out of bounds) |
| | lib/list.warp | an operator a used module declares, `[1] ∪ [2]`, is not lowered in the program |
| | list.warp (fixed around) | an if-expression as a call's argument (above) |

## Lib: the module's own fault

| Modules blocked | Where | Root cause | State |
|---|---|---|---|
| 10: crypto encoding html list template text url uuid version xml | list.warp | parameters typed `any` where a list is meant: count(any) is a float, so `0 to count(xs) - n` is no range | fixed (batch 1): list passes; the other nine now stop at text.warp:17 (compiler, below) |
| 2: fast_math machine_math | machine_math.warp:30 | `rest % 2` with a float rest: floor gives a float | open |
| 6: cli i18n map PHP toml yaml | each module | state kept in maps of any, `st["at"] - 1`, `keys(a)` on an any | open |
| 1: callbacks | callbacks.warp:14 | `+=` on a global without `global`: reads as a new local | open |
| 1: functions | functions.warp:36 | assigning a closure's outer local without `let`/`global` | open |
| 1: unit_names | unit_names.warp:101 | a function giving values of two types | open |
| 1: unicode | unicode.warp:42 | a table filled as a map but read with `#` | open |
| 1: path | path.warp:100 | `ord` of a one-letter text, not a char | open |
| 1: fractions | fractions.warp:26 | `is rational` names no type | open |
| 1: time | time.warp:24 | clock_time_get without `use` of the host module | open |
| 1: regex | lib/regex.warp, lib/crates/regex.warp | two modules named regex | open |
