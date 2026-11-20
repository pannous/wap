#!/bin/bash
# Refresh wap's seed: wap-seed/wap.wasm beside the warp binary, the compiler wap's tests and census start from
# (test/wap/compile.sh), with the types module and kernel it reads beside it. Stage A is the seed compiling
# wap/compiler.wap beside the seed's own types module, so a rule form the tree's types module is the first to write is
# known; B is A compiling it beside the tree's types module, C is B compiling it again. The last stage built is the new
# seed once it compiles and runs hello: no identical bytes asked (user 2026-11-20), a fixpoint is only reported. A
# compiler source word new in the tree's types module reaches the source a seed later: such a change lands after a
# refresh. The native wap beside the warp binary is rebuilt from the tree's driver by the new seed. The new seed is
# published as the pre-release wap-seed-<date>-<sha8> on pannous/wap, built from the tree's HEAD, and wap-seed.lock
# names it, committed in the tree.
# usage: scripts/refresh-seed.sh [--check] [<tree>, default this checkout]   (--check: run the stages, replace nothing)
# WARP_BINARY: the warp host that runs the modules (default `warp` on PATH). A stage takes about half a minute.
set -u -o pipefail
STAGES="A B C"
REPOSITORY=pannous/wap
LOCK=wap-seed.lock
# how much more a stage may cost than the seed's own stage A, in percent, before the new seed is refused as slower
SLOWER_PERCENT=150
check=
[ "${1-}" = --check ] && { check=1; shift; }
tree=$(cd "${1:-$(git rev-parse --show-toplevel)}" && pwd) || exit 2
warp=${WARP_BINARY:-warp}
seed=$(dirname "$(command -v "$warp")")/wap-seed/wap.wasm
[ -f "$seed" ] || { echo "refresh-seed: no seed at $seed" >&2; exit 2; }
mkdir -p "$tree/data" && scratch=$(mktemp -d "$tree/data/refresh-seed.XXXXXX") || exit 2
trap 'rm -rf "$scratch"' EXIT
# every stage after A reads the tree's types module and kernel beside itself
cp -R "$tree/wap/types" "$tree/wap/kernel" "$scratch/" || exit 2

# stage <compiler> <output>: the compiler compiling wap's source; its cost in user + system CPU seconds
stage() {
	local start=$SECONDS cost
	cost=$( { TIMEFORMAT="%U %S"; time "$warp" --no-window "$1" "$tree/wap/compiler.wap" "$2" >"$scratch/stage.log" 2>&1; } 2>&1 | awk '{ printf "%d", $1 + $2 }')
	[ -f "$2" ] || { echo "refresh-seed: $(basename "$2" .wasm) FAILED: $(tail -3 "$scratch/stage.log")" >&2; exit 1; }
	stage_cost=$cost
	echo "refresh-seed: $(basename "$2" .wasm) $(wc -c <"$2" | tr -d ' ') B in $((SECONDS - start)) s, $cost s CPU, sha256 $(shasum -a 256 "$2" | cut -c1-16)"
}
previous=$seed
old_cost=
for name in $STAGES; do
	stage "$previous" "$scratch/$name.wasm"
	[ -n "$old_cost" ] || old_cost=$stage_cost
	if [ "$previous" != "$seed" ] && cmp -s "$previous" "$scratch/$name.wasm"; then echo "refresh-seed: $name is the same bytes as the stage before: a fixpoint"; fi
	previous=$scratch/$name.wasm
done
chosen=$previous

echo 'print "Hello"' >"$scratch/hello.wap"
hello=$("$warp" --no-window "$chosen" "$scratch/hello.wap" "$scratch/hello.wasm" 2>&1 && "$warp" --no-window "$scratch/hello.wasm" 2>&1)
echo "$hello" | grep -q Hello || { echo "refresh-seed: $(basename "$chosen" .wasm) runs no hello ($(echo "$hello" | tail -1 | cut -c1-200)); the seed stays" >&2; exit 1; }
echo "refresh-seed: wap's source took $stage_cost s CPU with the new compiler, $old_cost s with the seed it replaces"
[ $((stage_cost * 100)) -le $((old_cost * SLOWER_PERCENT)) ] || { echo "refresh-seed: the new compiler is over ${SLOWER_PERCENT}% of the seed's time; the seed stays" >&2; exit 1; }
if [ -n "$check" ]; then
	cmp -s "$chosen" "$seed" && echo "refresh-seed: the seed is that stage" || echo "refresh-seed: the seed differs from that stage (--check: kept)"
	exit 0
fi

# the seed and what it reads beside it, installed and published
cp "$chosen" "$seed" && cp -R "$tree/wap/types" "$tree/wap/kernel" "$(dirname "$seed")/" && echo "refresh-seed: replaced $seed"
# (the old compiler's machine code goes with it: the native wap writes the new one's at its first run)
rm -f "$(dirname "$seed")"/wap-*.cwasm
# the native wap beside the warp binary, the command that runs the seed (wap/extensions/native/driver.wap), built by it
native=$(dirname "$(dirname "$seed")")
WARP=$warp "$tree/wap/extensions/native/build.sh" "$seed" "$tree/wap/extensions/native/driver.wap" "$native/wap" \
	-L"$native/lib" -lwarp_wasmtime -Wl,-rpath,@executable_path/lib && echo "refresh-seed: installed $native/wap" ||
	echo "refresh-seed: the native wap was not built; $native/wap stays" >&2
beside=$scratch/wap-seed-beside.tar.gz
tar -czf "$beside" -C "$tree/wap" types kernel || { echo "refresh-seed: the types module and kernel were not packed" >&2; exit 1; }
release=wap-seed-$(date +%Y-%m-%d)-$(shasum -a 256 "$seed" | cut -c1-8)
source_commit=$(git -C "$tree" rev-parse HEAD)
gh release create "$release" "$seed" "$beside" --repo "$REPOSITORY" --prerelease --title "$release" --target "$source_commit" \
	--notes "wap's seed compiler: wap/compiler.wap of ${source_commit:0:10}, compiled by the stages A B C." &&
	echo "refresh-seed: published $release"
echo "$release $(shasum -a 256 "$seed" | cut -d' ' -f1)" >"$tree/$LOCK"
git -C "$tree" add "$LOCK" && git -C "$tree" commit -q -m "chore: $LOCK names $release, built from ${source_commit:0:10}" -- "$LOCK" &&
	echo "refresh-seed: $LOCK committed in $tree: push it with the tree"
