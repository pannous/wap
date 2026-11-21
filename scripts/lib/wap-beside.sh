# scripts/lib/wap-beside.sh: what a compiled wap compiler reads around itself, laid out as the tree lays it out: the
# compiler in a folder wap/ with what it reads from wap/ (the types module, the Node it includes, the kernel, the
# extensions' rule files), the standard library lib/ beside that folder, where `use name` finds a module, so every
# relative path holds in both places (sourced by test/wap/compile.sh and scripts/refresh-seed.sh, which copy and publish them)
# everything in wap/ but the compiler's own source, which the compiled compiler holds: a new folder there goes along
WAP_COMPILED=(core compiler.wap)
WAP_BESIDE=($(cd "$(dirname "${BASH_SOURCE[0]}")/../../wap" && ls | grep -vxF "${WAP_COMPILED[@]/#/-e}"))
WAP_FOLDER=wap
WAP_LIBRARY=lib
# wap_beside_copied <tree> <folder>: all of it copied from the tree into the folder, the compiler's place <folder>/wap/
wap_beside_copied() {
	mkdir -p "$2/$WAP_FOLDER" && (cd "$1/$WAP_FOLDER" && cp -R "${WAP_BESIDE[@]}" "$2/$WAP_FOLDER/") && cp -R "$1/$WAP_LIBRARY" "$2/"
}
# wap_beside_mirrored <tree> <folder>: the folder holds exactly that around its compiler, wap/wap.wasm and its machine
# code wap/wap-*.cwasm: copied, whatever the tree no longer has removed, one line naming it
wap_beside_mirrored() {
	local removed synced
	removed="$(unlisted "$2" " $WAP_FOLDER $WAP_LIBRARY ")$(unlisted "$2/$WAP_FOLDER" " wap.wasm ${WAP_BESIDE[*]} ")"
	synced=$(cd "$1/$WAP_FOLDER" && rsync -a --delete -i "${WAP_BESIDE[@]}" "$2/$WAP_FOLDER/" && cd .. && rsync -a --delete -i "$WAP_LIBRARY" "$2/") || return 1
	removed="$removed $(echo "$synced" | sed -n 's/^\*deleting *//p' | tr '\n' ' ')"
	[ -z "${removed// /}" ] || echo "wap-beside: removed from $2:${removed% }"
}
# unlisted <folder> <kept names>: each entry of the folder neither kept nor the compiler's machine code removed, its name printed
unlisted() {
	local entry
	for entry in "$1"/*; do
		[ -e "$entry" ] || continue
		case "$2" in *" ${entry##*/} "*) continue ;; esac
		case "${entry##*/}" in wap-*.cwasm) continue ;; esac
		rm -rf "$entry" && printf ' %s' "${entry##*/}"
	done
}
