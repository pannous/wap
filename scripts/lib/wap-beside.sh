# scripts/lib/wap-beside.sh: what a compiled wap compiler reads beside itself, from wap/: the types module, the Node it
# includes, the kernel, the extensions' rule files; and from the tree's root the standard library, where `use name` finds a module (sourced by
# test/wap/compile.sh and scripts/refresh-seed.sh, which copy and publish them)
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
WAP_TOOLS=(verify.wasm:wap/extensions/theory/elaborate/verify.wap)
# the library module a compiler writes beside itself, named by its hash, which the tools link (extensions/wasm/library.wap)
WAP_LIBRARY_LINKED='types-*.wasm'
# a seed folder's parts, by name: the compiler, what it reads beside itself, the tools (its machine code *.cwasm is none)
WAP_PARTS=(wap.wasm "${WAP_BESIDE[@]}" "$WAP_LIBRARY" "${WAP_TOOLS[@]%%:*}")
# wap_linked <folder>: the C compiler's arguments that link the native wap with wasmtime's library in <folder>/lib, which
# it finds beside itself wherever it moves (macOS names the executable's folder @executable_path, Linux $ORIGIN)
wap_linked() {
	local executable_folder='$ORIGIN'
	[ "$(uname -s)" = Darwin ] && executable_folder=@executable_path
	WAP_LINKED=(-L"$1/lib" -lwarp_wasmtime -Wl,-rpath,"$executable_folder/lib")
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
