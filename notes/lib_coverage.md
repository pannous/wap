# Library coverage under wap

Each lib/ module run as `use <module>` plus a print, by the installed wap (`--seconds 60`), main 3818e62, 2026-11-22.
scripts/coverage.sh measures it hourly (cron), with the samples, into data/wap-tests/coverage.txt and the wap Vitals page.
16 of 121 modules pass: bits case_table case_tables csv exact_values host_io html_entities ini integers intervals
letter_ranges ordering ui uncertain unicode_data events.

Ported to plain wap since that measurement, each lib/<module>.wap shadowing the .warp a row below names (the counts
still include them until the next one): collections complex csv diff geometry graphs html intervals math matrix money
numeric path random slugs tasks template text xml callbacks native/sqlite3.

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
| | english.warp:12 | a rule phrase with a keyword hole, `increase $x by: $n` |
| | frames.warp:17 | `data exit` |
| | laws.warp:24 | no `op_of(Key)` |
| | shown_frames.warp:6 | no host word window_open |
| | c.warp | no C function field_u8 in the executable |
| found running modules | any program | `text(m)` of a map<text, int> traps (out of bounds) |
| | callbacks.warp | reading an item of a `list<function?>` / `list<function>`: the types module's list_item "gives no value" |
| | unicode.warp:149 | no `upper(text)` in the types module |
| | unicode.warp:18 … | an empty map takes text keys, so int-keyed tables write their types: `m = {}; m[3] = 4` is refused (lists take their element type from first use already); card empty-map, one token in core/analyze/data.wap:140 |
| | test/test_dynamic.wap:30 | `letter: any = "z"; letter is text` gives no (red on main) |
| 5: cli i18n map toml yaml | map.warp deep_merge … | no cast from an any back to a container, `a as map<text, any>` (refused in binding) |

## Lib: the module's own fault

| Modules blocked | Where | Root cause | State |
|---|---|---|---|
| 5: cli i18n map toml yaml | each module | trees of mixed maps and lists read back out of an any, `st["kinds"][k]`, `keys(messages)`: needs the cast below | compiler |
| 1: functions | functions.warp:36 | throttle's closure reassigns a name it captured, `last = [at, f(x)]` | compiler: a closure can't assign a captured local |
| 1: unit_names | unit_names.warp:101 | units as mixed `[amount, dimension]` lists of exact fractions (10^-3) | open: wants a class and exact numbers |
| 1: fractions | fractions.warp:26 | `is rational`: wap has no exact rational type | compiler |
| 1: time | time.warp:24 | clock_time_get lives in wap/types/host.wap, which a library module can't `use` by name | compiler/layout |
