#!/usr/bin/env bash
# scripts/compiler-growth.sh [<tree>] [<base>] [<tip>]: the three-uses rule (AGENTS.md Layers), checked on a change against
# <base> (origin/main) up to <tip> (HEAD). A change that widens the language, a new rewrite rule anywhere (sugar/, extensions/, the types
# module, a library file) or a new file in wap/core, wap/kernel, wap/sugar or wap/extensions, passes only when the
# change's commit messages say why with one line:
#   uses: <a>, <b>, <c>      three different libraries (or programs) that use the mechanism, the asking one included
#   spec: wiki/<page>.md     a form of the language that wiki page specifies (sugar for the language itself)
# Exit 1 names each new rule or file and the missing line; rules and files already on <base> never block.
set -uo pipefail
GUARDED_FILES=(wap/core wap/kernel wap/sugar wap/extensions)
RULE_SOURCES=(wap lib)
REQUIRED_USES=3

tree=${1:-.}
base=${2:-origin/main}
tip=${3:-HEAD}
cd "$tree" || exit 2
range="$base...$tip"

# a rule is new when its head (the pattern before =>) is added and no removed rule had that head: a rewritten
# template, a moved or reworded rule is no growth. A rule is a declaration, `rule <pattern> => <template>` at the line's
# start; a variable named rule, `rule = Rule(…)`, is none
new_rules=$(git diff --unified=0 "$range" -- "${RULE_SOURCES[@]}" | awk '
	/^\+\+\+ / { file = substr($0, 7); next }
	/^[+-]rule[[:space:]]+[^=:[:space:]].*=>/ {
		sign = substr($0, 1, 1); line = substr($0, 2)
		head = line; sub(/[[:space:]]*=>.*/, "", head)
		if (sign == "-") removed[head] = 1; else { added[head] = file ": " line; order[++count] = head }
	}
	END { for (i = 1; i <= count; i++) if (!(order[i] in removed)) print added[order[i]] }')
new_files=$(git diff --name-only --diff-filter=A "$range" -- "${GUARDED_FILES[@]}")
[ -z "$new_rules$new_files" ] && exit 0

messages=$(git log --format=%B "$base..$tip")
spec=$(grep -m1 -E '^spec: wiki/[^ ]+\.md' <<<"$messages" | sed 's/^spec: //')
uses=$(grep -m1 -E '^uses: ' <<<"$messages" | sed 's/^uses: //' | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' | sort -u)
used_by=$(grep -c . <<<"$uses")

[ -n "$spec" ] && [ -f "$spec" ] && exit 0
[ "$used_by" -ge "$REQUIRED_USES" ] && exit 0

echo "FAIL this change widens the language without saying who needs it (AGENTS.md Layers, the three-uses rule):"
[ -n "$new_rules" ] && sed 's/^/  new rule  /' <<<"$new_rules"
[ -n "$new_files" ] && sed 's/^/  new file  /' <<<"$new_files"
[ -n "$spec" ] && echo "  spec: $spec is no page of wiki/ (its own clone, pannous/wap.wiki)"
[ -n "$uses" ] && echo "  uses: names $used_by, $REQUIRED_USES needed"
echo "  add to a commit message 'uses: <a>, <b>, <c>' ($REQUIRED_USES different libraries using it, the asking one included)"
echo "  or 'spec: wiki/<page>.md' (a language form that page specifies); else write it as plain wap in the library"
exit 1
