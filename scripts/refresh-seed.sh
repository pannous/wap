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
# the scratch folder by its real path: a module's WASI follows no link, and data/ is often one (test/wap/compile.sh)
mkdir -p "$tree/data" && scratch=$(cd -P "$(mktemp -d "$tree/data/refresh-seed.XXXXXX")" && pwd -P) || exit 2
trap 'rm -rf "$scratch"' EXIT
source "$(dirname "$0")/lib/wap-beside.sh"
# every stage after A reads the tree's types module and kernel beside itself
wap_beside_copied "$tree" "$scratch" || exit 2

echo 'print "Hello"' >"$scratch/hello.wap"
# stage <compiler> <output>: the compiler compiling wap's source; its cost in user + system CPU seconds, timed warm: a
# first hello lets warp compile a new module's machine code before the clock starts, else a new stage pays for it
stage() {
	local start=$SECONDS cost
	"$warp" --no-window "$1" "$scratch/hello.wap" "$scratch/warm.wasm" >/dev/null 2>&1
	cost=$( { TIMEFORMAT="%U %S"; time "$warp" --no-window "$1" "$tree/wap/compiler.wap" "$2" >"$scratch/stage.log" 2>&1; } 2>&1 | awk '{ printf "%.1f", $1 + $2 }')
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

hello=$("$warp" --no-window "$chosen" "$scratch/hello.wap" "$scratch/hello.wasm" 2>&1 && "$warp" --no-window "$scratch/hello.wasm" 2>&1)
echo "$hello" | grep -q Hello || { echo "refresh-seed: $(basename "$chosen" .wasm) runs no hello ($(echo "$hello" | tail -1 | cut -c1-200)); the seed stays" >&2; exit 1; }
echo "refresh-seed: wap's source took $stage_cost s CPU with the new compiler, $old_cost s with the seed it replaces"
awk -v new="$stage_cost" -v old="$old_cost" -v most="$SLOWER_PERCENT" 'BEGIN { exit !(new * 100 <= old * most) }' || { echo "refresh-seed: the new compiler is over ${SLOWER_PERCENT}% of the seed's time; the seed stays" >&2; exit 1; }
if [ -n "$check" ]; then
	cmp -s "$chosen" "$seed" && echo "refresh-seed: the seed is that stage" || echo "refresh-seed: the seed differs from that stage (--check: kept)"
	exit 0
fi

# the seed and what it reads beside it, installed and published
cp "$chosen" "$seed" && wap_beside_mirrored "$tree" "$(dirname "$seed")" && echo "refresh-seed: replaced $seed"
# (the old compiler's machine code goes with it, and every program's it compiled: the native wap writes the new
# compiler's at its first run, below)
rm -f "$(dirname "$seed")"/*.cwasm
# the native wap beside the warp binary, the command that runs the seed (wap/extensions/native/driver.wap), built by it
native=$(dirname "$(dirname "$seed")")
WARP=$warp "$tree/wap/extensions/native/build.sh" "$seed" "$tree/wap/extensions/native/driver.wap" "$native/wap" \
	-L"$native/lib" -lwarp_wasmtime -Wl,-rpath,@executable_path/lib && echo "refresh-seed: installed $native/wap" ||
	echo "refresh-seed: the native wap was not built; $native/wap stays" >&2
# its first run, so the first one anyone makes finds the compiler's machine code written
"$native/wap" '1+1' >/dev/null || echo "refresh-seed: the installed $native/wap fails to run 1+1" >&2
beside=$scratch/wap-seed-beside.tar.gz
tar -czf "$beside" -C "$tree/wap" "${WAP_BESIDE[@]}" -C "$tree" "$WAP_LIBRARY" || { echo "refresh-seed: the types module and kernel were not packed" >&2; exit 1; }
release=wap-seed-$(date +%Y-%m-%d)-$(shasum -a 256 "$seed" | cut -c1-8)
source_commit=$(git -C "$tree" rev-parse HEAD)
gh release create "$release" "$seed" "$beside" --repo "$REPOSITORY" --prerelease --title "$release" --target "$source_commit" \
	--notes "wap's seed compiler: wap/compiler.wap of ${source_commit:0:10}, compiled by the stages A B C." &&
	echo "refresh-seed: published $release"
echo "$release $(shasum -a 256 "$seed" | cut -d' ' -f1)" >"$tree/$LOCK"
git -C "$tree" add "$LOCK" && git -C "$tree" commit -q -m "chore: $LOCK names $release, built from ${source_commit:0:10}" -- "$LOCK" &&
	echo "refresh-seed: $LOCK committed in $tree: push it with the tree"
