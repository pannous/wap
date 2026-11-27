#!/bin/bash
# Refresh wap's seed: wap-seed/wap.wasm beside the native wap, the compiler wap's tests and census start from
# (test/wap/compile.sh), with the types module and kernel it reads beside it. Stage A is the seed compiling
# wap/compiler.wap beside the seed's own types module, so a rule form the tree's types module is the first to write is
# known; B is A compiling it beside the tree's types module, C is B compiling it again. The last stage built is the new
# seed once it compiles and runs hello: no identical bytes asked (user 2026-11-20), a fixpoint is only reported. A
# compiler source word new in the tree's types module reaches the source a seed later: such a change lands after a
# refresh. The native wap is rebuilt from the tree's driver by the new seed. The new seed is
# published as the pre-release wap-seed-<date>-<sha8> on pannous/wap, built from the tree's HEAD, and wap-seed.lock
# names it, committed in the tree.
# usage: scripts/refresh-seed.sh [--check] [<tree>, default this checkout]   (--check: run the stages, replace nothing)
# The modules run on the native wap on PATH (scripts/lib/wap-host.sh). A stage takes about half a minute.
set -u -o pipefail
STAGES="A B C"
REPOSITORY=pannous/wap
LOCK=wap-seed.lock
# how much more the new compiler may cost than the seed compiling wap's source, in percent, before the new seed is
# refused as slower; each is timed this many times in turns and counted by its best, so a busy machine, which slows a
# run by up to twice as much an hour later, slows both alike
SLOWER_PERCENT=150
TIMING_ROUNDS=2
check=
[ "${1-}" = --check ] && { check=1; shift; }
tree=$(cd "${1:-$(git rev-parse --show-toplevel)}" && pwd) || exit 2
installed=$(command -v wap) || { echo "refresh-seed: no native wap on PATH: install the wap and wap-seed/ of the release wap-seed.lock names" >&2; exit 2; }
seed=$(dirname "$(readlink -f "$installed")")/wap-seed/wap.wasm
[ -f "$seed" ] || { echo "refresh-seed: no seed at $seed" >&2; exit 2; }
# the scratch folder by its real path: a module's WASI follows no link, and data/ is often one (test/wap/compile.sh)
mkdir -p "$tree/data" && scratch=$(cd -P "$(mktemp -d "$tree/data/refresh-seed.XXXXXX")" && pwd -P) || exit 2
trap 'rm -rf "$scratch"' EXIT
source "$(dirname "$0")/lib/wap-beside.sh"
# every stage after A reads the tree's types module and kernel beside itself
wap_beside_copied "$tree" "$scratch" || exit 2
# the seed runs from the scratch folder, reading the tree's library there (scripts/lib/wap-beside.sh wap_seed_linked)
seed_run=$(wap_seed_linked "$seed" "$scratch") || exit 2

echo 'print "Hello"' >"$scratch/hello.wap"
# prepared <compiler>: what the compiler built from the tree holds, written beside the tree's source first
# (scripts/lib/wap-beside.sh wap_stage_prepared)
prepared() { wap_stage_prepared "$1" "$seed_run" "$tree/wap" >"$scratch/stage.log" 2>&1 || { echo "refresh-seed: $(basename "$1" .wasm) wrote no library or warm state: $(tail -3 "$scratch/stage.log")" >&2; exit 1; }; }
# timed <compiler> <output> <seed>: the prepared compiler compiling wap's source, as a program where it is the seed,
# else as sources (none: every compiler reads it as sources); its cost in user + system CPU seconds in
# $cost, timed warm: a first hello lets the host compile a new module's machine code before the clock starts, else a
# new compiler pays for it
timed() {
	wap_ran "$1" "$scratch/hello.wap" "$scratch/warm.wasm" >/dev/null 2>&1
	cost=$( { TIMEFORMAT="%U %S"; time wap_stage_compiled "$1" "$3" "$tree/wap" "$2" >"$scratch/stage.log" 2>&1; } 2>&1 | awk '{ printf "%.1f", $1 + $2 }')
	[ -f "$2" ] || { echo "refresh-seed: $(basename "$2" .wasm) FAILED: $(tail -3 "$scratch/stage.log")" >&2; exit 1; }
}
# stage <compiler> <output>: the compiler compiling wap's source, prepared and timed
stage() {
	local start=$SECONDS
	prepared "$1"
	timed "$1" "$2" "$seed_run"
	echo "refresh-seed: $(basename "$2" .wasm) $(wc -c <"$2" | tr -d ' ') B in $((SECONDS - start)) s, $cost s CPU, sha256 $(shasum -a 256 "$2" | cut -c1-16)"
}
# the lesser of two costs, the first when the second is empty
least() { awk -v a="$1" -v b="${2:-$1}" 'BEGIN { printf "%.1f", (a < b ? a : b) }'; }
runner=$seed_run
previous=$seed_run
for name in $STAGES; do
	stage "$previous" "$scratch/$name.wasm"
	if [ "$previous" != "$seed_run" ] && cmp -s "$previous" "$scratch/$name.wasm"; then echo "refresh-seed: $name is the same bytes as the stage before: a fixpoint"; fi
	runner=$previous
	previous=$scratch/$name.wasm
done
chosen=$previous

# the seed and the compiler that built the last stage, timed in turns, each by its best round, both reading wap's
# source as sources, so both do the same work
round_timed() { prepared "$1" && timed "$1" "$scratch/timed.wasm" ""; }
old_cost=
new_cost=
for round in $(seq "$TIMING_ROUNDS"); do
	round_timed "$seed_run"
	old_cost=$(least "$cost" "$old_cost")
	round_timed "$runner"
	new_cost=$(least "$cost" "$new_cost")
	echo "refresh-seed: timing round $round: the seed $old_cost s CPU at best, the new compiler $new_cost s"
done

hello=$(wap_ran "$chosen" "$scratch/hello.wap" "$scratch/hello.wasm" 2>&1 && wap_ran "$scratch/hello.wasm" 2>&1)
echo "$hello" | grep -q Hello || { echo "refresh-seed: $(basename "$chosen" .wasm) runs no hello ($(echo "$hello" | tail -1 | cut -c1-200)); the seed stays" >&2; exit 1; }
echo "refresh-seed: wap's source took $new_cost s CPU with the new compiler, $old_cost s with the seed it replaces"
awk -v new="$new_cost" -v old="$old_cost" -v most="$SLOWER_PERCENT" 'BEGIN { exit !(new * 100 <= old * most) }' || { echo "refresh-seed: the new compiler is over ${SLOWER_PERCENT}% of the seed's time; the seed stays" >&2; exit 1; }
if [ -n "$check" ]; then
	cmp -s "$chosen" "$seed" && echo "refresh-seed: the seed is that stage" || echo "refresh-seed: the seed differs from that stage (--check: kept)"
	exit 0
fi

# the build stamp appended to a compiler, the custom section wap.build of lines: the tree's commit, when it was built
# (`wap version` shows it, wap/extensions/native/commands.wap; as warp's stamp, core/native/warp.warp stamped)
stamped() {
	python3 - "$1" "$2" "$(date '+%Y-%m-%d %H:%M')" <<'PY'
import sys
path, commit, built = sys.argv[1:]
name = b"wap.build"
payload = bytes([len(name)]) + name + f"{commit}\n{built}".encode()
size, leb = len(payload), bytearray()
while True:
    byte, size = size & 127, size >> 7
    leb.append(byte | (128 if size else 0))
    if not size:
        break
open(path, "ab").write(b"\0" + bytes(leb) + payload)
PY
}
source_commit=$(git -C "$tree" rev-parse HEAD)
# the seed and what it reads beside it, installed and published
cp "$chosen" "$seed" && stamped "$seed" "$source_commit" && wap_beside_mirrored "$tree" "$(dirname "$seed")" && wap_tools_built "$tree" "$seed" && wap_library_compiled "$seed" && echo "refresh-seed: replaced $seed, its folder holding no source"
# (the old compiler's machine code goes with it, and every program's it compiled: the native wap writes the new
# compiler's at its first run, below)
rm -f "$(dirname "$seed")"/*.cwasm
# the native wap, the command that runs the seed (wap/extensions/native/driver.wap), built by it
native=$(dirname "$(dirname "$seed")")
wap_linked "$native"
"$tree/wap/extensions/native/build.sh" "$seed" "$tree/wap/extensions/native/driver.wap" "$native/wap" "${WAP_LINKED[@]}" && echo "refresh-seed: installed $native/wap" ||
	echo "refresh-seed: the native wap was not built; $native/wap stays" >&2
# its first run, so the first one anyone makes finds the compiler's machine code written
"$native/wap" '1+1' >/dev/null || echo "refresh-seed: the installed $native/wap fails to run 1+1" >&2
beside=$scratch/wap-seed-beside.tar.gz
COPYFILE_DISABLE=1 tar -czf "$beside" -C "$(dirname "$seed")" "${WAP_BESIDE[@]}" "$WAP_LIBRARY" "${WAP_TOOLS[@]%%:*}" || { echo "refresh-seed: what the seed reads beside itself was not packed" >&2; exit 1; }
release=wap-seed-$(date +%Y-%m-%d)-$(shasum -a 256 "$seed" | cut -c1-8)
gh release create "$release" "$seed" "$beside" --repo "$REPOSITORY" --prerelease --title "$release" --target "$source_commit" \
	--notes "wap's seed compiler: wap/compiler.wap of ${source_commit:0:10}, compiled by the stages A B C." &&
	echo "refresh-seed: published $release"
echo "$release $(shasum -a 256 "$seed" | cut -d' ' -f1)" >"$tree/$LOCK"
git -C "$tree" add "$LOCK" && git -C "$tree" commit -q -m "chore: $LOCK names $release, built from ${source_commit:0:10}" -- "$LOCK" &&
	echo "refresh-seed: $LOCK committed in $tree: push it with the tree"
