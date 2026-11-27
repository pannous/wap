# V2: `wap check`

coc-plan.md's V2 row covers three things:
- `wap check` lists the obligations left to the run;
- `--strict` refuses each one that is not proved;
- the laws' verdicts are printed beside them, through one door with verify.

Read on unify-typers 2b0e87be. V2 lands after T4d1, which already moves the obligations list into the TypingState
(notes/coc-t4d.md).

## The wiki passages

- type.md "Proved or checked" (:177-189): the five ways an obligation is met. "`wap check` lists the obligations
  left to the run … A proof, and `wap check --strict` for a whole program, refuse every obligation that is not proved."
- cli.md:108-109: "`wap check file.wap` lists the conditions left to be checked when the program runs;
  `wap check --strict` refuses each one not proved."
- strict.md and warning.md: `wap --strict` turns warnings into errors, and `--strict=<level>` picks the level.

No page has `wap check` print law verdicts. That is `wap verify`'s job (law.md, proof.md).

## What unify-typers holds

- `check <program>` is a compiler command (compiler.wap:136). It types the program, then prints dispatch.wap's
  global `obligations`, one line each: `obliged` (dispatch.wap:290-295) writes `line 2:1: it > 0 is checked when the
  program runs`.
- test/wap/test_check.wap pins that form (green): the place with its column, the condition, the words.
- Nothing reads `--strict`, neither `wap --strict` nor `wap check --strict`.

## Two red lines that disagree with a green one

wap/test_type_wanted:10 wants `line 2: line as char: #line == 1 is checked when the program runs`. That is the place
without a column, the code, then the condition. test_check.wap's green lines pin the place with its column and the
condition, without the code.

The general message form is errors.wap's `warning_of`: the place, the why, then `: ` and the code quoted. An
obligation left to the run is a warning in that form:
`line 2:5: #line == 1 is checked when the program runs: line as char`. test_check's lines match it as they are,
since they test with `lines_with`.

Recommended: obligations print as warnings in `warning_of`'s form, and wap/test_type_wanted:10 is rewritten to that
form in its own commit. This went to warp-interviewer as a question.

## The plan

1. **An obligation is a warning.** `obliged` writes `warning_of(at, "<condition> is checked when the program runs")`
   into T4d1's list in the TypingState. core +1 (the form), −3 (the line built by hand).
2. **`--strict` is the general switch.** In strict.md, `--strict` makes warnings from level normal up fail.
   - An obligation left to the run is a warning of level normal.
   - `wap check --strict` refuses the first one: `refused by unproved condition: #line == 1 …`.
   - The same switch serves `wap --strict` on a build once warnings carry levels (warning.md). V2 reads the option
     for check only.
   - core +6 (compiler.wap's check command reads the option and refuses), native +2 (the driver passes it on).
3. **Verdicts in `wap check`: cut.** No wiki page shows it, and `wap verify` prints them. The row's door shared with
   verify comes with V3, where check needs the provers.

## The red lines it turns green

| line | form | part |
|---|---|---|
| wap/test_type_wanted:10 | `wap check` lists `line as char`'s obligation | 1, once the line is in the decided form |
| wap/test_type_wanted:11 | `wap check --strict` is refused by unproved condition | 2 |

test_check.wap stays green.

## Estimate

Core about +4 (+7 −3), native +2, kernel 0. The row had core −5 and check +40: the −5 is T4d1's, and the +40 door is
V3's. Normal path: test_check, test_type_wanted, test_cli.
