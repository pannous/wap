#!/usr/bin/env bash
# scripts/compiler-growth.sh [<tree>] [<base>] [<tip>]: the three-uses rule (AGENTS.md Layers), checked on a change against
# <base> (origin/main) up to <tip> (HEAD). A change that widens the language, a new rewrite rule anywhere (sugar/, extensions/, the types
# module, a library file) or a new file in wap/core, wap/kernel, wap/sugar or wap/extensions, passes only when the
# change's commit messages say why with one line:
#   uses: <a>, <b>, <c>      three different libraries (or programs) that use the mechanism, the asking one included
#   spec: wiki/<page>.md     a form of the language that wiki page specifies (sugar for the language itself)
# Exit 1 names each new rule or file and the missing line; rules and files already on <base> never block.
# scripts/compiler-growth.sh --measures [<since>] [<tree>]: the plan's sizes (notes/coc-plan.md 5.3), never a gate: the
# compiler's lines by the plan's count against its ballpark, the census's and the self-compile's ceilings with every raise
# of them since <since> (default: 2026-11-27), and the files the plan deletes that are still there
set -uo pipefail
GUARDED_FILES=(wap/core wap/kernel wap/sugar wap/extensions)
RULE_SOURCES=(wap lib)
REQUIRED_USES=3

BALLPARK_LINES=17000
PLAN_PARTS=(wap/core wap/kernel wap/types wap/sugar wap/compiler.wap wap/nodes.wap)
# ceiling name, the file holding it, its line's start
CEILINGS=("census size nodes:test/wap/ratchet_census.sh:SIZE_NODES=" "self-compile instructions:test/wap/test_self.sh:SELF_COMPILE_INSTRUCTIONS=")
# files the plan deletes (notes/coc-plan.md, audit R5): each needs a step that removes it
PLANNED_DELETIONS=(wap/core/analyze/letters.wap wap/core/analyze/fits.wap wap/core/analyze/conditions.wap wap/core/analyze/matching.wap)
DEFAULT_SINCE="2026-11-27"

if [ "${1:-}" = "--measures" ]; then
	since=${2:-$DEFAULT_SINCE}
	cd "${3:-.}" || exit 2
	lines=$(git ls-files "${PLAN_PARTS[@]}" | grep '\.wap$' | xargs cat | wc -l | tr -d ' ')
	echo "compiler: $lines lines by the plan's count, ballpark $BALLPARK_LINES ($((lines - BALLPARK_LINES)) over)"
	for ceiling in "${CEILINGS[@]}"; do
		IFS=: read -r name file start <<<"$ceiling"
		echo "$name: $(grep -m1 "^$start" "$file" | sed "s/^$start//") now; raised since $since:"
		git log --since="$since" --reverse --format='%h %ad' --date=short -G"^$start" -- "$file" | sed 's/^/  /'
	done
	for file in "${PLANNED_DELETIONS[@]}"; do [ -f "$file" ] && echo "planned deletion without a step: $file stays ($(wc -l <"$file" | tr -d ' ') lines)"; done
	exit 0
fi

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
# a split or a move is no growth: a new file counts only when it holds a code line no file of the change gave up
# (comments, blank lines and `use` lines are a split's own)
fresh_in_new=$(git diff --unified=0 "$range" -- "${GUARDED_FILES[@]}" | awk -v new_files="$(tr '\n' ' ' <<<"$new_files")" '
	BEGIN { split(new_files, names, " "); for (i in names) is_new["b/" names[i]] = 1 }
	/^--- / { next }
	/^\+\+\+ / { file = substr($0, 5); next }
	/^-/ { removed[substr($0, 2)]++; next }
	/^\+/ { if (file in is_new) added[++count] = substr($0, 2) }
	END {
		for (i = 1; i <= count; i++) {
			line = added[i]; if (removed[line] > 0) { removed[line]--; continue }
			code = line; sub(/^[[:space:]]+/, "", code)
			if (code != "" && code !~ /^#/ && code !~ /^use /) fresh++
		}
		print fresh + 0
	}')
[ "$fresh_in_new" -eq 0 ] && new_files=""
# only the kernel's rule functions make a judgement (notes/coc-t2.md "Checked(term, type)"), so a Checked found is one
# the rules concluded
judgements_made=$(git grep -n -E '(^|[^A-Za-z_])Checked\(' "$tip" -- 'wap/*.wap' ':!wap/kernel/typing.wap' | grep -v -E '^[^:]+:[^:]+:[0-9]+:[[:space:]]*#')
[ -n "$judgements_made" ] && { echo "FAIL only wap/kernel/typing.wap's rule functions make a judgement:"; echo "$judgements_made"; exit 1; }
[ -z "$new_rules$new_files" ] && exit 0

messages=$(git log --format=%B "$base..$tip")
spec=$(grep -m1 -E '^spec: wiki/[^ ]+\.md' <<<"$messages" | sed 's/^spec: //')
uses=$(grep -m1 -E '^uses: ' <<<"$messages" | sed 's/^uses: //' | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' | sort -u)
used_by=$(grep -c . <<<"$uses")

# the wiki is its own clone in the main checkout only (a worktree has none): pages are looked up there
wiki_home=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
[ -n "$spec" ] && [ ! -d "$wiki_home/wiki" ] && { echo "FAIL no wiki clone at $wiki_home/wiki to check '$spec' against"; exit 1; }
[ -n "$spec" ] && [ -f "$wiki_home/$spec" ] && exit 0
[ "$used_by" -ge "$REQUIRED_USES" ] && exit 0

echo "FAIL this change widens the language without saying who needs it (AGENTS.md Layers, the three-uses rule):"
[ -n "$new_rules" ] && sed 's/^/  new rule  /' <<<"$new_rules"
[ -n "$new_files" ] && sed 's/^/  new file  /' <<<"$new_files"
[ -n "$spec" ] && echo "  spec: $spec is no page of $wiki_home/wiki (its own clone, pannous/wap.wiki)"
[ -n "$uses" ] && echo "  uses: names $used_by, $REQUIRED_USES needed"
echo "  add to a commit message 'uses: <a>, <b>, <c>' ($REQUIRED_USES different libraries using it, the asking one included)"
echo "  or 'spec: wiki/<page>.md' (a language form that page specifies); else write it as plain wap in the library"
exit 1
