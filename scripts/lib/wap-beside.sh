# scripts/lib/wap-beside.sh: what a compiled wap compiler reads beside itself, from wap/: the types module, the Node it
# includes, the kernel, the extensions' rule files; and from the tree's root the standard library, where `use name` finds a module (sourced by
# test/wap/compile.sh and scripts/refresh-seed.sh, which copy and publish them)
# the warm state a built compiler embeds (wap/compiler.wap WARM_STATE), written from the sources before each build
WAP_WARM=wap/warm.packed
# the library compiled once a built compiler holds (wap/compiler.wap LIBRARY), written before each build
WAP_LIBRARY_MODULE=wap/types.wasm
# everything in wap/ but what the compiled compiler holds, its own source and its warm state, and the modules compiled
# there (its library, and the copy a compiler run from source writes beside itself): a new folder there goes along
WAP_COMPILED=(core compiler.wap "${WAP_WARM##*/}")
WAP_BESIDE=($(cd "$(dirname "${BASH_SOURCE[0]}")/../../wap" && ls | grep -vxF "${WAP_COMPILED[@]/#/-e}" | grep -v '\.wasm$'))
WAP_LIBRARY=lib
# wap_beside_copied <tree> <folder>: all of it copied from the tree into the folder
wap_beside_copied() {
	(cd "$1/wap" && cp -R "${WAP_BESIDE[@]}" "$2/") && cp -R "$1/$WAP_LIBRARY" "$2/"
}
# wap_beside_mirrored <tree> <folder>: the folder holds exactly that beside its compiler, wap.wasm and the machine code
# *.cwasm (refresh-seed's to remove): copied, whatever the tree no longer has removed, one line naming it
wap_beside_mirrored() {
	local kept=" wap.wasm ${WAP_BESIDE[*]} $WAP_LIBRARY " entry removed="" synced
	for entry in "$2"/*; do
		case "$kept" in *" ${entry##*/} "*) continue ;; esac
		case "${entry##*/}" in *.cwasm) continue ;; esac
		rm -rf "$entry" && removed="$removed ${entry##*/}"
	done
	synced=$(cd "$1/wap" && rsync -a --delete -i "${WAP_BESIDE[@]}" "$2/" && cd .. && rsync -a --delete -i "$WAP_LIBRARY" "$2/") || return 1
	removed="$removed $(echo "$synced" | sed -n 's/^\*deleting *//p' | tr '\n' ' ')"
	[ -z "${removed// /}" ] || echo "wap-beside: removed from $2:${removed% }"
}
