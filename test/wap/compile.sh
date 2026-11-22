# the helper of wap's shell tests (source it): ran <name> <program> is what the program printed, compiled by wap, the
# new compiler, and run, or the compiler's error. Its modules run on the native wap on PATH (wap/extensions/native)
source "$(dirname "${BASH_SOURCE[0]}")/../native/checks.sh"
wap=$(command -v wap) || { echo "no native wap on PATH: scripts/refresh-seed.sh installs it" >&2; exit 2; }
tree="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
source_compiler="$tree/wap/compiler.wap"
source "$tree/scripts/lib/wap-beside.sh"
# the folder builds and runs go in, by its real path: a module's WASI follows no link to an absolute path (data/ is often
# one, to a scratch volume)
data="$(mkdir -p "$tree/data/wap-tests" && cd -P "$tree/data/wap-tests" && pwd -P)"
# wap's seed, wap built by itself, beside the native wap with its types module and kernel (scripts/refresh-seed.sh)
seed="$(dirname "$(readlink -f "$wap")")/wap-seed/wap.wasm"
[ -f "$seed" ] || { echo "no wap seed at $seed: scripts/refresh-seed.sh --wap installs it" >&2; exit 2; }
# wap's compiler built by itself <n> times into <folder>, a folder holding it already kept; prints the module, or the
# failed step's error. A module reads its types module beside itself (the host reads no link out of a folder): wap0.wasm
# is the source compiled by the seed beside the seed's types module, so a rule form the tree's types module is the first
# to write is known; wap1.wasm the source compiled by wap0 beside a copy of the tree's types module, each next one by
# the one before. The folder is built whole beside it and then put in its place, so scripts sharing it never read half a
# module or a types being copied
# the warm state a compiler embeds (wap/compiler.wap WARM_STATE): written from the sources by the compiler before it,
# beside each build's own copy first, so a script sharing the tree never embeds half of one
warm_state="$tree/$WAP_WARM"
warm_written() {
	$wap "$1" --sources warm "$warm_state.$$" 2>&1 && mv "$warm_state.$$" "$warm_state"
}
compiler_built() {
	local folder=$1 last=$2
	[ -f "$folder/wap$last.wasm" ] || folder_built "$folder" "$last" || return 1
	echo "$folder/wap$last.wasm"
}
folder_built() {
	local building=$1.$$ built=$1.$$/wap0.wasm n
	mkdir -p "$building" && wap_beside_copied "$tree" "$building" || return 1
	[ -f "$warm_state" ] || : >"$warm_state"
	$wap "$seed" "$source_compiler" "$built" 2>&1 || return 1
	for ((n = 1; n <= $2; n++)); do
		warm_written "$built" || return 1
		$wap "$built" --sources "$source_compiler" "$building/wap$n.wasm" 2>&1 || return 1
		built="$building/wap$n.wasm"
	done
	# another script may have put the same folder in place meanwhile: the first one stays
	[ -f "$1/wap$2.wasm" ] && { rm -rf "$building"; return; }
	rm -rf "$1" && mv "$building" "$1"
}
# the compiler under test: the module a test script is given as its first arguments, --compiler <module>
# (test/wap/run.sh --stage passes one wap built of itself), else wap1, this tree's source compiled by the seed, built
# once for each state of wap/ and lib/ and shared by every script
if [ "$1" = --compiler ]; then compiler="$2"; shift 2
else
	sources=$(cd "$tree" && { cat "$seed"; find wap "$WAP_LIBRARY" \( -name '*.wap' -o -name '*.warp' \) | sort | xargs cat; } | shasum | cut -c1-16)
	compiler=$(compiler_built "$data/wap1-$sources" 1) || { echo "wap1: $compiler" >&2; exit 1; }
fi
# each test script its own folder in the tree's data/ (never the system's temporary folder)
stage="$data/$$"
mkdir -p "$stage" || exit 1
trap 'rm -rf "$stage"' EXIT

ran() {
	printf '%s\n' "$2" >"$stage/$1.wap"
	$wap "$compiler" "$stage/$1.wap" "$stage/$1.wasm" 2>&1 && $wap "$stage/$1.wasm" 2>&1
}
