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
library_module="$tree/$WAP_LIBRARY_MODULE"
warm_written() {
	$wap "$1" --sources warm "$warm_state.$$" 2>&1 && mv "$warm_state.$$" "$warm_state"
}
compiler_built() {
	local folder=$1 last=$2 said
	# (what the build says is printed only when it fails: a notice of a build that went on is no part of the path)
	[ -f "$folder/wap$last.wasm" ] || said=$(folder_built "$folder" "$last") || { echo "$said"; return 1; }
	echo "$folder/wap$last.wasm"
}
folder_built() {
	local building=$1.$$ built=$1.$$/wap0.wasm n
	mkdir -p "$building" && wap_beside_copied "$tree" "$building" || return 1
	[ -f "$warm_state" ] || : >"$warm_state"
	[ -f "$library_module" ] || : >"$library_module"
	$wap "$seed" "$source_compiler" "$built" 2>&1 || return 1
	# the library compiled once, which each compiler built next holds (extensions/wasm/library.wap), by wap0, which is
	# this tree's source as each next one is, from the sources (wap0 holds whatever library and warm state the tree had):
	# beside the compiler, where the warm states read it, and in the tree, where each build takes it
	$wap "$built" --sources "$building/types/types.wap" "$building/types.wasm" 2>&1 || return 1
	cp "$building/types.wasm" "$library_module.$$" && mv "$library_module.$$" "$library_module" || return 1
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
# native_wap_built <folder>: the tree's native wap (wap/extensions/native/driver.wap) built into the folder, bin/wap with
# the compiler under test beside it as its seed and wasmtime's library; prints its path or the build's error
native_wap_built() {
	mkdir -p "$1/wap-seed" "$1/lib" && (cd "$(dirname "$compiler")" && cp -R "${WAP_BESIDE[@]}" "$WAP_LIBRARY" "$1/wap-seed/") && cp "$compiler" "$1/wap-seed/wap.wasm" \
		&& cp "$(cd -P "$(dirname "$wap")/lib" && pwd -P)"/libwarp_wasmtime.* "$1/lib/" \
		&& "$tree/wap/extensions/native/build.sh" "$compiler" "$tree/wap/extensions/native/driver.wap" "$1/wap" -L"$1/lib" -lwarp_wasmtime -Wl,-rpath,@executable_path/lib >"$1/build.log" 2>&1 \
		|| { echo "the tree's native wap did not build: $(tail -3 "$1/build.log")" >&2; return 1; }
	echo "$1/wap"
}
# the modules of a test run on this tree's native wap, built once for each compiler beside it, so a program's C imports
# and the driver's other host words are this tree's; with no wasm2c the installed wap runs them, said once
tree_wap_built() {
	local folder="$(dirname "$compiler")/bin"
	[ -x "$folder/wap" ] || { native_wap_built "$folder.$$" >/dev/null || return 1; [ -x "$folder/wap" ] && rm -rf "$folder.$$" || mv "$folder.$$" "$folder"; }
	echo "$folder/wap"
}
# and the programs are compiled by the copy of the compiler beside it, as a user's are, so the library it writes goes
# beside that copy, never into the tree
if command -v wasm2c >/dev/null; then wap=$(tree_wap_built) && compiler="$(dirname "$wap")/wap-seed/wap.wasm" || exit 1; else echo "no wasm2c: the installed wap runs the modules, not this tree's" >&2; fi
# each test script its own folder in the tree's data/ (never the system's temporary folder)
stage="$data/$$"
mkdir -p "$stage" || exit 1
trap 'rm -rf "$stage"' EXIT

ran() {
	printf '%s\n' "$2" >"$stage/$1.wap"
	$wap "$compiler" "$stage/$1.wap" "$stage/$1.wasm" 2>&1 && $wap "$stage/$1.wasm" 2>&1
}
