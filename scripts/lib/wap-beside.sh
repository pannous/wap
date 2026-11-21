# scripts/lib/wap-beside.sh: what a compiled wap compiler reads beside itself, from wap/: the types module, the Node it
# includes, the kernel; and from the tree's root the standard library, where `use name` finds a module (sourced by
# test/wap/compile.sh and scripts/refresh-seed.sh, which copy and publish them)
WAP_BESIDE=(types sugar nodes.wap kernel)
WAP_LIBRARY=lib
# wap_beside_copied <tree> <folder>: all of it copied from the tree into the folder
wap_beside_copied() {
	(cd "$1/wap" && cp -R "${WAP_BESIDE[@]}" "$2/") && cp -R "$1/$WAP_LIBRARY" "$2/"
}
