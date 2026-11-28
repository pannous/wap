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
# to write is known; wap1.wasm the source compiled by wap0 beside the folder's types module, each next one by the one
# before. The folder is built whole beside it, from its own copy of the source, and then put in its place, so scripts
# sharing it never read half a module, and two building it at once never embed each other's library or warm state
# the warm state a compiler embeds (wap/compiler.wap WARM_STATE) and the library it holds, copied into the tree after a
# build, for a compiler run from the tree's source
warm_state="$tree/$WAP_WARM"
library_module="$tree/$WAP_LIBRARY_MODULE"
# the compiler's own source files, listed from the tree's root, which test_self and the census walk: the theory
# (wap/extensions/verify, wap/extensions/theory) and its provers (wap/extensions/prove) stay outside the build until the switch (S3);
# test_theory and test_theory_verify cover them
compiler_sources() { git ls-files 'wap/*.wap' ':!wap/extensions/verify' ':!wap/extensions/theory' ':!wap/extensions/prove'; }
compiler_built() {
	local folder=$1 last=$2 said
	# (what the build says is printed only when it fails: a notice of a build that went on is no part of the path)
	[ -f "$folder/wap$last.wasm" ] || said=$(folder_built "$folder" "$last") || { echo "$said"; return 1; }
	echo "$folder/wap$last.wasm"
}
folder_built() {
	local building=$1.$$
	# each step run in the folder on relative paths, as a module names the files it was compiled from: two builds of one
	# source are the same bytes wherever they ran; a failed build takes its own folder away
	mkdir -p "$building" && wap_beside_copied "$tree" "$building" && (cd "$tree/wap" && cp -R "${WAP_SOURCE[@]}" "$building/") && (cd "$building" && steps_built "$2") || { rm -rf "$building"; return 1; }
	# another script may have put the same folder in place meanwhile: the first one stays
	[ -f "$1/wap$2.wasm" ] && { rm -rf "$building"; return; }
	rm -rf "$1" && mv "$building" "$1" || return 1
	tree_copied "$1/${WAP_LIBRARY_MODULE##*/}" "$library_module" && tree_copied "$1/${WAP_WARM##*/}" "$warm_state"
}
# the compilers of folder_built, in the folder: wap0 is the seed's, holding no library and no warm state; each next one
# is the one before's, holding the library and warm state that one writes beside the source (scripts/lib/wap-beside.sh)
steps_built() {
	local n seeded compiler
	seeded=$(wap_seed_linked "$seed" .) && compiler=$seeded || return 1
	for ((n = 0; n <= $1; n++)); do
		{ wap_stage_prepared "$compiler" "$seeded" . && wap_stage_compiled "$compiler" "$seeded" . "wap$n.wasm"; } 2>&1 || return 1
		compiler=wap$n.wasm
	done
}
# a built file put in the tree whole, so a reader never sees half of it
tree_copied() { cp "$1" "$2.$$" && mv "$2.$$" "$2"; }
# the compiler under test: the module a test script is given as its first arguments, --compiler <module>
# (test/wap/run.sh --stage passes one wap built of itself), else wap1, this tree's source compiled by the seed, built
# once for each state of wap/, lib/ and the build steps (this file and scripts/lib/wap-beside.sh), and shared by every
# script
if [ "$1" = --compiler ]; then compiler="$2"; shift 2
else
	sources=$(cd "$tree" && { cat "$seed" test/wap/compile.sh scripts/lib/wap-beside.sh; find wap "$WAP_LIBRARY" \( -name '*.wap' -o -name '*.warp' -o -name '*.c' -o -name '*.h' -o -name '*.sh' -o -name '*.awk' \) | sort | xargs cat; } | shasum | cut -c1-16)
	compiler=$(compiler_built "$data/wap1-$sources" 1) || { echo "wap1: $compiler" >&2; exit 1; }
fi
# native_wap_built <folder> [--standalone]: the tree's native wap (wap/extensions/native/driver.wap) built into the
# folder, bin/wap with the compiler under test beside it as its seed and wasmtime's library, the seed built into it too
# with --standalone (build.sh); prints its path or the build's error
native_wap_built() {
	wap_linked "$1"
	mkdir -p "$1/wap-seed" "$1/lib" && (cd "$(dirname "$compiler")" && cp -R "${WAP_BESIDE[@]}" "$WAP_LIBRARY" "$1/wap-seed/") && cp "$compiler" "$1/wap-seed/wap.wasm" && wap_tools_built "$tree" "$1/wap-seed/wap.wasm" \
		&& cp "$(cd -P "$(dirname "$wap")/lib" && pwd -P)"/libwarp_wasmtime.* "$1/lib/" \
		&& "$tree/wap/extensions/native/build.sh" ${2-} "$1/wap-seed/wap.wasm" "$tree/wap/extensions/native/driver.wap" "$1/wap" "${WAP_LINKED[@]}" >"$1/build.log" 2>&1 \
		|| { echo "the tree's native wap did not build: $(tail -3 "$1/build.log")" >&2; return 1; }
	echo "$1/wap"
}
# the modules of a test run on this tree's native wap, built once for each compiler beside it, so a program's C imports
# and the driver's other host words are this tree's; with no wasm2c the installed wap runs them, said once
tree_wap_built() {
	local folder="$(dirname "$compiler")/bin"
	[ -x "$folder/wap" ] || { native_wap_built "$folder.$$" >/dev/null || { rm -rf "$folder.$$"; return 1; }; [ -x "$folder/wap" ] && rm -rf "$folder.$$" || mv "$folder.$$" "$folder"; }
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
