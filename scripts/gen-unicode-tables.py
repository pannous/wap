#!/usr/bin/env python3
"""Write lib/unicode_data.wap (the tables of lib/unicode.wap) and test/test_unicode_normalization.wap (a sample of
NormalizationTest.txt).

Rerun: download UnicodeData.txt, CompositionExclusions.txt, CaseFolding.txt, SpecialCasing.txt and NormalizationTest.txt of the pinned
version from https://www.unicode.org/Public/<VERSION>/ucd/ into a directory (data/ucd-<VERSION>/ is ignored), then
    python3 scripts/gen-unicode-tables.py <that directory>
The raw UCD files are not committed."""
import sys, os
VERSION = "15.1.0"
if len(sys.argv) != 2: sys.exit("usage: scripts/gen-unicode-tables.py <directory of the UCD files>")
ucd = sys.argv[1]
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
def lines(name):
    for l in open(os.path.join(ucd, name), encoding="utf-8"):
        l = l.split("#")[0].strip()
        if l: yield l
first = open(os.path.join(ucd, "NormalizationTest.txt"), encoding="utf-8").readline()
assert VERSION in first, first
ccc = {}; decomp = {}; upper = {}; lower = {}
for l in lines("UnicodeData.txt"):
    f = l.split(";"); cp = int(f[0], 16)
    if f[1].endswith("First>") or f[1].endswith("Last>"): continue  # ranges (Hangul, CJK) have no ccc or mapping
    if int(f[3]): ccc[cp] = int(f[3])
    if f[12]: upper[cp] = [int(f[12], 16)]
    if f[13]: lower[cp] = [int(f[13], 16)]
    if f[5]:
        d = f[5].split(); compat = d[0].startswith("<")
        if compat: d = d[1:]
        decomp[cp] = (compat, [int(x, 16) for x in d])
# ccc as runs: gap from the previous run's end, length, class
runs = []; prev = None
for cp in sorted(ccc):
    if runs and cp == runs[-1][0] + runs[-1][1] and ccc[cp] == runs[-1][2]: runs[-1][1] += 1
    else: runs.append([cp, 1, ccc[cp]])
out = []; end = 0
for s, n, c in runs: out.append("%d %d %d" % (s - end, n, c)); end = s + n
ccc_text = " ".join(out)
# decompositions: gap from the previous key, 0 canonical or 1 compatibility, then the code points; a run of
# consecutive keys each to one code point at the same distance is "gap flag *count delta"
out = []; last = 0; keys = sorted(decomp); i = 0
while i < len(keys):
    cp = keys[i]; compat, d = decomp[cp]; j = i + 1
    if len(d) == 1:
        while j < len(keys) and keys[j] == cp + (j - i) and decomp[keys[j]][0] == compat and len(decomp[keys[j]][1]) == 1 and decomp[keys[j]][1][0] - keys[j] == d[0] - cp: j += 1
    if j - i >= 3:
        out.append("%d %d *%d %d" % (cp - last, 1 if compat else 0, j - i, d[0] - cp)); last = keys[j - 1]; i = j
    else:
        out.append("%d %d %s" % (cp - last, 1 if compat else 0, " ".join(str(x) for x in d))); last = cp; i += 1
decomp_text = ";".join(out)
excl = sorted(int(l.split()[0], 16) for l in lines("CompositionExclusions.txt"))
excl_text = " ".join(str(x) for x in excl)
# a case mapping as runs of its one-to-one mappings (gap from the last run's last code point, count, stride, delta),
# then its mappings to several code points (code point, those)
def mapping_texts(mapping):
    runs = []
    for cp in sorted(c for c in mapping if len(mapping[c]) == 1):
        d = mapping[cp][0] - cp
        if runs:
            s, n, stride, delta = runs[-1]
            if delta == d and (n == 1 and cp - s <= 2 or n > 1 and cp == s + n * stride):
                if n == 1: runs[-1][2] = cp - s
                runs[-1][1] += 1; continue
        runs.append([cp, 1, 1, d])
    out = []; end = 0
    for s, n, stride, d in runs: out.append("%d %d %d %d" % (s - end, n, stride, d)); end = s + (n - 1) * stride
    multi = ";".join("%d %s" % (cp, " ".join(str(x) for x in t)) for cp, t in sorted(mapping.items()) if len(t) > 1)
    return " ".join(out), multi
# case folding: CaseFolding.txt's statuses C and F
folding = {}
for l in lines("CaseFolding.txt"):
    f = [x.strip() for x in l.split(";")]
    if f[1] in ("C", "F"): folding[int(f[0], 16)] = [int(x, 16) for x in f[2].split()]
# full upper and lower case: UnicodeData.txt's simple mappings, SpecialCasing.txt's unconditional ones over them
for l in lines("SpecialCasing.txt"):
    f = [x.strip() for x in l.split(";")]
    if f[4]: continue  # a condition (language or context)
    cp = int(f[0], 16)
    lower[cp] = [int(x, 16) for x in f[1].split()]
    upper[cp] = [int(x, 16) for x in f[3].split()]
for mapping in (upper, lower):
    for cp in [c for c in mapping if mapping[c] == [c]]: del mapping[cp]
fold_text, multi_text = mapping_texts(folding)
upper_text, upper_multi_text = mapping_texts(upper)
lower_text, lower_multi_text = mapping_texts(lower)
data = '''# Written by scripts/gen-unicode-tables.py (Unicode %s), do not edit: the tables of lib/unicode.wap, texts of
# decimal numbers it reads when it loads. ccc: runs (gap from the last run's end, length, class). decompositions:
# entries (gap from the last code point, 1 when compatibility, its code points) split by ;, a run of keys each one
# code point at one distance written "gap flag *count distance". exclusions: CompositionExclusions.txt. folding: runs
# (gap from the last run's last code point, count, stride, delta) of CaseFolding.txt's one-to-one C+F mappings, then
# its F mappings to several code points (code point, those). upper and lower: the full case mappings the same way,
# UnicodeData.txt's simple ones and SpecialCasing.txt's unconditional ones
unicode_version := "%s"
unicode_ccc_text(): text := "%s"
unicode_decomposition_text(): text := "%s"
unicode_exclusion_text(): text := "%s"
unicode_folding_text(): text := "%s"
unicode_folding_multi_text(): text := "%s"
unicode_upper_text(): text := "%s"
unicode_upper_multi_text(): text := "%s"
unicode_lower_text(): text := "%s"
unicode_lower_multi_text(): text := "%s"
''' % (VERSION, VERSION, ccc_text, decomp_text, excl_text, fold_text, multi_text, upper_text, upper_multi_text, lower_text, lower_multi_text)
open(os.path.join(root, "lib", "unicode_data.wap"), "w", encoding="utf-8").write(data)
print("lib/unicode_data.wap", len(data.encode()), "bytes;", len(runs), "ccc runs,", len(decomp), "decompositions,", len(folding), "foldings,", len(upper), "upper,", len(lower), "lower")

# --- the sampled test: NormalizationTest.txt's Part 0 whole, every SPARSE-th line of the other parts, the Hangul
# syllables and the composition exclusions of Part 1 sparser still; eight lines a check
SPARSE = 400
parts = {}; part = None
for l in open(os.path.join(ucd, "NormalizationTest.txt"), encoding="utf-8"):
    if l.startswith("@Part"): part = l.split()[0][1:]; continue
    body = l.split("#")[0].strip()
    if not body: continue
    parts.setdefault(part, []).append([[int(x, 16) for x in c.split()] for c in body.split(";")[:5]])
excluded = set(excl)
picked = [("Part 0", parts["Part0"]),
          ("Part 1", parts["Part1"][::SPARSE]),
          ("Part 1's Hangul syllables", [r for r in parts["Part1"] if 0xAC00 <= r[0][0] <= 0xD7A3][::10 * SPARSE]),
          ("Part 1's composition exclusions", [r for r in parts["Part1"] if len(r[0]) == 1 and r[0][0] in excluded][::10]),
          ("Part 2, canonical order of several marks", parts["Part2"][::SPARSE // 10]),
          ("Part 3, PRI #29", parts["Part3"][::SPARSE // 40])]
L = ["# nfc, nfd, nfkc and nfkd of lib/unicode.wap (wiki/library-unicode.md) on a sample of NormalizationTest-%s.txt: every" % VERSION,
     "# line's five columns hold the invariants of all four forms. Written by scripts/gen-unicode-tables.py, do not edit",
     "use unicode", 'use "check.wap"']
for title, rows in picked:
    for i in range(0, len(rows), 8):
        group = rows[i:i + 8]
        L.append('check("%s, lines %d to %d", show(%s.map(line => normalization_check(line))), "[%s]")' % (title, i + 1, i + len(group), str(group).replace(" ", ""), ", ".join("[]" for _ in group)))
open(os.path.join(root, "test", "test_unicode_normalization.wap"), "w", encoding="utf-8").write("\n".join(L) + "\n")
print("test_unicode_normalization:", len(L) - 4, "checks,", sum(len(r) for _, r in picked), "lines")
