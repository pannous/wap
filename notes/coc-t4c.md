# T4c char: `char` as a subset of text

The row of notes/coc-t4.md, written out. `char` is `text where #it == 1` (wiki/subtype.md:4), stored as its code
point, an i32, as today (user 2026-11-27). A declared conversion takes a char up to text. Core's char conversions
go, because that one conversion does their work.

## Forms

- **The declaration**, in wap/types (numbers.wap or texts.wap, next to `char(code: int)`):
  `type char < text where #it == 1`.
  - The `<` subtype mark is there already: rules/stages.wap:95 `SUBTYPE_MARK`, used by numbers.wap:36 `type i64 < int`.
  - The storage stays the atom's i32, so emit/values.wap:47 (`Char(value) => i32_const(ord(value))`) is unchanged.
- **The up-conversion** is the declared one: prelude.wap:128 `text(c: char): text := encoded(ord(c), 1, 1)`.
  - Every text word takes a char through it: `shout(c)` and `c + "b"`.
  - It runs where a char meets a text place. Today core does that itself (char_text).
- **The down-conversion** is T4a's Narrowed with the predicate `#it == 1`:
  - `"a" is char` and `line as char` are run-time checks;
  - `c: char = "a"` is decided when compiling by T4d3's text rows (`#"a" == 1` computes).
  - Once a text is checked, it is stored as its code point by texts.wap:204 `char(t: text): char`. This is the
    Narrowed conversion's body, so a declared word does it, not core.
- **`'a'`** is a char literal as before: the reader's Char atom with the type `char`, no longer typed by its place.
  - Where a text is expected, it goes up by the declared conversion, like any char.
  - wiki/char.md:19 `'a' == "a"` holds through compare at text.
- **The Port line** (test/test_subtype_wanted.wap:20-21) is `type Port < int where …` and `(8080 as Port) as int`.
  It is the same mechanism on int and needs nothing of its own.

## What core loses

| site | today | after |
|---|---|---|
| analyze/calls.wap:207, :218 | `if n is Char and read == TEXT_TERM { return char_text(n) }`, `char_text` | gone: the declared conversion is chosen like any up-conversion |
| analyze/types.wap:291 | `Char(value) => if expected == TEXT_TERM then char_text(n) else …` | `Char(value) => with_type(n, CHAR_TYPE)` |
| type_notation.wap:332 | `READS = [[CHAR_TERM, TEXT_TERM], [RANGE_TERM, list_type(INT_TERM)]]` | the char row goes; read_of and passing_types read the declared `<` instead |
| analyze/fits.wap:215 | `is_plain`'s CHAR_TYPE | kept: a char's storage is still plain i32 |
| letters.wap:224 reads_as | reads READS | unchanged code, one row fewer |

- CHAR_TYPE and CHAR_TERM stay. The atom, emit, format.wap:36 and the matcher still name char's storage, so the
  ATOM_TYPES entry stays.
- Estimate: about −10 core, +30 types (the declaration, plus `char(t)` written as the Narrowed body with its check).
- The RANGE_TERM row is left alone: it is not char's.

## Reused landed mechanisms

- T4a: Same up and Narrowed down, with `narrowing_test` for `is` and `as`.
- T4b: a condition known inside an `if` (`if #line == 1 { e: char = line }`).
- The `<` subtype mark, which declares a Record with an extends annotation (rules/stages.wap:95).
- The `as` sugar: `x as T` is `T(x)`.
- T4d: Obligation verdicts, so a literal that computes needs no run-time check, and one that fails is refused by
  condition. T4d1 to T4d3 are not on main yet (q1's t4d-obligations stack).

## Test lines (all from wiki/subtype.md and wiki/char.md)

These stay green:
- test/test_subtype_page.wap:4-12:
  - "a" is char, "ab" is no char;
  - `c: char = "a"`;
  - shout(c) == "A!", c + "b" == "ab";
  - `line as char`.
  On main they are green through char_text; after the change they are green through the declared conversion.
- test_char_page, all 10 checks.

These turn green:
- test/test_subtype_wanted.wap:16-21: initial, the `if #line == 1` line, and the Port pair.
- test/wap/test_subtype_wanted.wap:5-7:
  - `d: char = "ab"` refused by condition (T4d);
  - `initial("")` refused (T4d);
  - the run-time check naming `#"ab" == 1`. This one is T4c's own: Narrowed's check prints its predicate.

From coc-t4.md's row: `[1, "a"]` is a `list<int or text>`. With T5u's unions it is `list<char or int>` while "a" is a
char. Check which one the wiki shows (wiki/subtype.md, wiki/list.md) before pinning it; no test pins it today.

## Path and order

- Careful path: it changes how a char converts. The speed gate is measured at this step: one Narrowed check per
  `as char`, and the up-conversion is a call where char_text was inline.
- It lands after T4d1 to T4d3. The Port line does not wait on anything: `<` is landed.

## Open, for warp-interviewer

- wiki/subtype.md:46 says "a char is stored as its text". The user's decision keeps the i32. The old and new text:
  - old: "a char is stored as its text, and every text word takes it"
  - new: "a char is stored as its code point, and every text word takes it"

  This is a wiki rewrite, so it goes to the user first.
