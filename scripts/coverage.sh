#!/usr/bin/env bash
# scripts/coverage.sh: how much of the library and of the samples the installed native wap takes, a line per file
# (✓, or ✗ with the run's last line) and the summary line last, into data/wap-tests/coverage.txt (read by warp's
# scripts/vitals.py). A library module counts when a program of `use <module>` and a print runs; a sample when it runs to
# its end. The installed wap and its own library are what is measured, named by the commit its compiler was built of
# (`wap version`), whatever this checkout holds. Each run is capped, windowless (--no-window) and goes through a job
# slot, niced; run hourly by cron (user 2026-11-23)
set -uo pipefail
# ✓, ✗ and the runs' messages are UTF-8: counted and cut by characters, whatever locale cron gives (none)
export LC_ALL=C.UTF-8
RUN_SECONDS=60
RUN_MEMORY_GB=4
RUNS_AT_ONCE=4
COVERED_MARK=covered
# samples that bring in one of these C libraries open a window even under --no-window, so coverage leaves them out (user 2026-11-26)
WINDOW_LIBRARIES='raylib'
tree="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
wap=$(command -v wap) || { echo "coverage.sh: no native wap on PATH: scripts/refresh-seed.sh installs it" >&2; exit 2; }
out="$tree/data/wap-tests/coverage.txt"
work="$tree/data/coverage"

# a file as its line names it: from the checkout, or from the folder of the installed wap's library
shown() { local file=${1#"$tree/"}; echo "${file#"$(dirname "$library")/"}"; }
# one file run, its line printed: <kind> <file> [<program>] runs <program> (the file itself when none is given) from the
# file's folder; it counts when it exits well and, given <expected>, its last line says that
covered() {
	local kind=$1 file=$2 program=${3:-$2} expected=${4:-} said status
	said=$(cd "$(dirname "$file")" && "$tree/scripts/job-slot.sh" "$wap" --no-window --seconds "$RUN_SECONDS" --memory-gb "$RUN_MEMORY_GB" "$program" 2>&1 </dev/null)
	status=$?
	if [ $status -eq 0 ] && { [ -z "$expected" ] || [ "$(tail -n 1 <<<"$said")" = "$expected" ]; }; then
		echo "✓ $kind $(shown "$file")"
	else
		echo "✗ $kind $(shown "$file"): $(grep -v '^job-slot.sh: ' <<<"$said" | tail -n 1 | cut -c1-200)"
	fi
}
# a library module's use: a program of its own in the work folder, which prints COVERED_MARK once the module is in
module_covered() {
	local module=$1 name program
	name=$(basename "${module%.*}")
	program="$work/use_$name.wap"
	printf 'use %s\nprint "%s"\n' "$name" "$COVERED_MARK" >"$program"
	covered lib "$module" "$program" "$COVERED_MARK"
}
export -f shown covered module_covered
export tree wap work library RUN_SECONDS RUN_MEMORY_GB COVERED_MARK

mkdir -p "$work" "$(dirname "$out")" || exit 1
version=$("$wap" version)
commit=$(sed -n 's/^wap.wasm of \([0-9a-f]*\) .*/\1/p' <<<"$version")
[ -n "$commit" ] || { echo "coverage.sh: wap version names no commit the installed wap was built of" >&2; exit 2; }
# the modules a `use` finds: the library beside the installed wap's compiler, not this checkout's lib/
library="$(dirname "$(sed -n '1s/.*(\(.*\))$/\1/p' <<<"$version")")/lib"
[ -d "$library" ] || { echo "coverage.sh: no library beside the installed wap's compiler ($library)" >&2; exit 2; }
modules=$(find "$library" -maxdepth 1 \( -name '*.warp' -o -name '*.wap' \) | sort)
samples=$(find -L "$tree/samples" \( -name '*.warp' -o -name '*.wap' \) -print0 | xargs -0 grep -LE "^(use|import)\b.*\b($WINDOW_LIBRARIES)\b" | sort)
[ "${1:-}" = --runnable ] && { printf '%s\n%s\n' "$modules" "$samples"; exit 0; }
lines=$({
	xargs -P "$RUNS_AT_ONCE" -I{} bash -c 'module_covered "$1"' _ {} <<<"$modules"
	xargs -P "$RUNS_AT_ONCE" -I{} bash -c 'covered sample "$1"' _ {} <<<"$samples"
} | sort -k2,3)
# the count of ✓ lines of a kind, and of all its lines
counted() { echo "$(grep -c "^✓ $1 " <<<"$lines")/$(grep -c "^. $1 " <<<"$lines")"; }
summary="coverage: lib modules $(counted lib), samples $(counted sample) at $commit $(date '+%Y-%m-%d %H:%M')"
printf '%s\n%s\n' "$lines" "$summary" >"$out.$$" && mv "$out.$$" "$out"
echo "$summary"
