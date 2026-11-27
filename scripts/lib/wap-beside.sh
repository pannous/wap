# scripts/lib/wap-beside.sh: what a compiled wap compiler reads beside itself, from wap/: the types module, the Node it
# includes, the kernel, the extensions' rule files; and from the tree's root the standard library, where `use name` finds a module (sourced by
# test/wap/compile.sh and scripts/refresh-seed.sh, which copy and publish them)
source "$(dirname "${BASH_SOURCE[0]}")/wap-host.sh"
# the warm state a built compiler embeds (wap/compiler.wap WARM_STATE), written from the sources before each build
WAP_WARM=wap/warm.packed
# the library compiled once a built compiler holds (wap/compiler.wap LIBRARY), written before each build
WAP_LIBRARY_MODULE=wap/types.wasm
# everything in wap/ but what the compiled compiler holds, its own source and its warm state, and the modules compiled
# there (its library, and the copy a compiler run from source writes beside itself): a new folder there goes along
# the compiler's own source in wap/, which a build copies into the folder it builds in (test/wap/compile.sh)
WAP_SOURCE=(core compiler.wap)
WAP_COMPILED=("${WAP_SOURCE[@]}" "${WAP_WARM##*/}")
WAP_BESIDE=($(cd "$(dirname "${BASH_SOURCE[0]}")/../../wap" && ls | grep -vxF "${WAP_COMPILED[@]/#/-e}" | grep -v '\.wasm$'))
WAP_LIBRARY=lib
# the tools the native wap runs beside its compiler, each a program of wap/ compiled once wherever a seed folder is made:
# its module's name there, then its source (`wap verify`, wap/extensions/native/driver.wap)
WAP_TOOLS=(verify.wasm:wap/extensions/proof/verify/verify.wap)
# the library module a compiler writes beside itself, named by its hash, which the tools link (extensions/wasm/library.wap)
WAP_LIBRARY_LINKED='types-*.wasm'
# a seed folder's parts, by name: the compiler, what it reads beside itself, the tools (its machine code *.cwasm is none)
WAP_PARTS=(wap.wasm "${WAP_BESIDE[@]}" "$WAP_LIBRARY" "${WAP_TOOLS[@]%%:*}")
# wap_linked <folder>: the C compiler's arguments that link the native wap with wasmtime's library in <folder>/lib, which
# it finds beside itself wherever it moves (macOS names the executable's folder @executable_path, Linux $ORIGIN;
# Windows has no such path: it finds the DLL beside the executable or on the PATH, and loads it only for the functions
# imported from it, so all are, as the native wap finds each by name)
wap_linked() {
	case $(uname -s) in
		Darwin) WAP_LINKED=(-L"$1/lib" -lwarp_wasmtime -Wl,-rpath,@executable_path/lib) ;;
		MINGW* | MSYS*) WAP_LINKED=(-L"$1/lib" -Wl,--whole-archive -lwarp_wasmtime -Wl,--no-whole-archive) ;;
		*) WAP_LINKED=(-L"$1/lib" -lwarp_wasmtime -Wl,-rpath,'$ORIGIN/lib') ;;
	esac
}
# wap_tools_built <tree> <compiler>: each tool compiled by that compiler, by the native wap on PATH, in its folder, so
# the tool links the library module by its name beside it and the folder can move
wap_tools_built() {
	local tool tree
	tree=$(cd "$1" && pwd -P) || return 1
	for tool in "${WAP_TOOLS[@]}"; do
		(cd "$(dirname "$2")" && wap "${2##*/}" "$tree/${tool#*:}" "${tool%%:*}" >&2) || { echo "wap-beside: ${tool#*:} did not compile" >&2; return 1; }
	done
}
# wap_seed_linked <seed> <folder>: the seed linked into the folder as its wap.wasm, its machine code beside it, so run
# from there it reads the library and anything its warm state lacks in that folder, the tree's copy, never the seed
# folder, which holds no source; prints the link's path
wap_seed_linked() {
	local code
	ln -sf "$1" "$2/wap.wasm" || return 1
	for code in "$(dirname "$1")"/wap-*.cwasm; do [ ! -e "$code" ] || ln -sf "$code" "$2/"; done
	echo "$(cd "$2" && pwd)/wap.wasm"
}
# wap_library_compiled <compiler>: each module of the library beside the compiler compiled once by it, by its full path,
# beside its source (`use name` finds name.wasm, core/analyze/declarations.wap MODULE_ENDINGS). An example (examples/)
# is no module; lib's unported warp files compile in no wap. A module that does not compile is named and refused
wap_library_compiled() {
	local folder module failed=""
	folder=$(cd "$(dirname "$1")" && pwd -P)
	for module in $(cd "$folder" && find "$WAP_LIBRARY" -name '*.wap' -not -path '*/examples/*'); do
		(cd "$folder" && wap "${1##*/}" "$folder/$module" "$folder/${module%.wap}.wasm" >/dev/null 2>&1) || failed="$failed $module"
	done
	[ -z "$failed" ] || { echo "wap-beside: these library modules do not compile alone:$failed" >&2; return 1; }
}
# wap_beside_copied <tree> <folder>: all of it copied from the tree into the folder
wap_beside_copied() {
	(cd "$1/wap" && cp -R "${WAP_BESIDE[@]}" "$2/") && cp -R "$1/$WAP_LIBRARY" "$2/"
}
# wap_beside_mirrored <tree> <folder>: the folder holds exactly that beside its compiler, wap.wasm and the machine code
# *.cwasm (refresh-seed's to remove): copied, whatever the tree no longer has removed, one line naming it
wap_beside_mirrored() {
	local kept=" ${WAP_PARTS[*]} " entry removed="" synced
	for entry in "$2"/*; do
		case "$kept" in *" ${entry##*/} "*) continue ;; esac
		case "${entry##*/}" in *.cwasm) continue ;; esac
		rm -rf "$entry" && removed="$removed ${entry##*/}"
	done
	synced=$(cd "$1/wap" && rsync -a --delete -i "${WAP_BESIDE[@]}" "$2/" && cd .. && rsync -a --delete -i "$WAP_LIBRARY" "$2/") || return 1
	removed="$removed $(echo "$synced" | sed -n 's/^\*deleting *//p' | tr '\n' ' ')"
	[ -z "${removed// /}" ] || echo "wap-beside: removed from $2:${removed% }"
}

# One stage of wap's bootstrap (test/wap/compile.sh and scripts/refresh-seed.sh): a compiler building wap's compiler
# from the source in a wap folder, which holds compiler.wap, core/ and types/, and beside them what the compiler built
# holds. A file in the wap folder, named as written there, relative where the folder is the current one ("."), so two
# builds of one source are the same bytes wherever they ran
wap_file() { if [ "$1" = . ]; then echo "$2"; else echo "$1/$2"; fi; }
# wap_stage_prepared <compiler> <seed> <wap folder>: what the compiler built holds, written beside its source first:
# the warm state, written by its full path so the state's paths are marked as the wap folder's (extensions/warm.wap
# marked), and once, by the first compiler built from the tree, the library: compiled by it beside itself from the types
# module there, on the paths its build reads. A later compiler holds that library already and keeps it, as its own
# words would be declared twice; the seed writes neither (it may write older ones) and its compiler holds none
wap_stage_prepared() {
	local folder library own warm
	folder=$(dirname "$1") library=$(wap_file "$3" "${WAP_LIBRARY_MODULE##*/}") warm=$(wap_file "$3" "${WAP_WARM##*/}")
	own=$(wap_file "$folder" "${WAP_LIBRARY_MODULE##*/}")
	[ "$1" != "$2" ] || { : >"$library" && : >"$warm"; return; }
	if [ ! -s "$library" ]; then wap_ran "$1" --sources "$(wap_file "$folder" types/types.wap)" "$own" && { [ "$own" -ef "$library" ] || cp "$own" "$library"; } || return 1; fi
	wap_ran "$(cd "$folder" && pwd -P)/${1##*/}" --sources warm "$warm"
}
# wap_stage_compiled <compiler> <seed> <wap folder> <output>: wap's compiler compiled from the folder's source, which a
# compiler built from the tree reads as sources and the seed as a program
wap_stage_compiled() {
	local sources=(--sources)
	[ "$1" != "$2" ] || sources=()
	wap_ran "$1" ${sources[@]+"${sources[@]}"} "$(wap_file "$3" compiler.wap)" "$4"
}
