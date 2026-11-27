#!/usr/bin/env bash
# A wap program built to a native executable: compiled by wap to a module, which wasm2c writes as C, which cc
# builds with wasm2c's runtime, lib/native/wasi.c and the C glue of its imports (main.c, glue.awk beside this
# script). wasm2c takes no GC type, so its texts, lists, enums and class instances are in the module's memory
# (memory.wap beside this script), as the compiler writes them for `native`, which reads types/memory_texts.wap and
# types/memory_lists.wap in the place of types/text_bytes.wap and types/list_items.wap; an uncaught raise is written to
# stderr. Maps, `any`, enums whose cases have fields and try/catch stay GC values it cannot use.
#   wap/extensions/native/build.sh [--standalone] <compiler.wasm> <program.wap> <executable> [<C compiler arguments>…]
# --standalone: the parts of the compiler's seed folder (scripts/lib/wap-beside.sh WAP_PARTS) built into the executable,
# which the native wap unpacks once into its cache folder (main.c wap_seed, linking.wap seed_folder_found) in place of
# a wap-seed/ folder beside it; and each library -l<name> whose static library lib<name>.a is in a -L folder linked
# whole into it (its functions are found by name, so no reference pulls them in): one file, needing only the system's
# the arguments after the executable are the C compiler's, the libraries the program's C functions are in:
# scripts/lib/wap-beside.sh wap_linked's for the native wap (driver.wap)
# The compiler runs on the native wap on PATH, else on wasmtime (scripts/lib/wap-host.sh). The build's files go in
# <executable>.build/
set -euo pipefail
C_COMPILER=cc
# -std=gnu23: wasm2c writes C23 (static asserts without a message), and glibc shows POSIX (sigaction, sigaltstack) only
# to a GNU dialect
C_FLAGS="-O2 -std=gnu23"
MODULE_NAME=program
WASM2C_RUNTIME=share/wabt/wasm2c
WABT_HEADERS=include
STANDALONE_OPTION=--standalone
# the seed's name: the first digits of its parts' contents hashed, so a seed built again unchanged finds its unpacked folder
SEED_NAME_DIGITS=12

standalone=""
[ "${1-}" = "$STANDALONE_OPTION" ] && standalone=1 && shift
[ $# -ge 3 ] || { echo "usage: $0 [$STANDALONE_OPTION] <compiler.wasm> <program.wap> <executable> [<C compiler arguments>…]" >&2; exit 2; }
compiler=$1 program=$2 executable=$3
shift 3
# whole_archive <static library>: the linker's arguments that link all of it
whole_archive() {
	case $(uname -s) in
		Darwin) echo "-Wl,-force_load,$1" ;;
		*) echo "-Wl,--whole-archive,$1,--no-whole-archive" ;;
	esac
}
# the linker's arguments each system spells its own way: the executable's own C functions (main.c native_call,
# wap_host_callback) exported, found by name as libc's are; on Windows its threads (winpthreads, linked in, so no
# DLL of the compiler's goes with it) and a main thread's stack as deep as the others give it (Windows gives 1 MB)
system_linked() {
	case $(uname -s) in
		MINGW* | MSYS*) echo "-Wl,--export-all-symbols -Wl,-Bstatic -lpthread -Wl,-Bdynamic -Wl,--stack,0x10000000" ;;
		*) echo "-rdynamic" ;;
	esac
}
# the C compiler's arguments of a standalone build: each -l<name> with a lib<name>.a in a -L folder replaced by it whole
statically_linked() {
	local argument folder folders=() static
	for argument in "$@"; do case $argument in -L*) folders+=("${argument#-L}") ;; esac; done
	for argument in "$@"; do
		static=""
		case $argument in -l*) for folder in ${folders[@]+"${folders[@]}"}; do [ -f "$folder/lib${argument#-l}.a" ] && static=$folder/lib${argument#-l}.a && break; done ;; esac
		if [ -n "$static" ]; then whole_archive "$static"; else echo "$argument"; fi
	done
}
if [ -n "$standalone" ] && [ $# -gt 0 ]; then
	linked=()
	while IFS= read -r argument; do linked+=("$argument"); done < <(statically_linked "$@")
	set -- "${linked[@]}"
fi
here="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$here/../../../scripts/lib/wap-host.sh"
library="$(cd -P "$here/../../../lib" && pwd -P)"
# a call in last place is wasm's return_call, which wasm2c writes correctly only after 1.0.42: the Homebrew keg
# wabt-head (a local tap) stands in for wabt until then
# TODO (card tail-call-slowdown) at wabt 1.0.43: brew unpin wabt-head && brew uninstall wabt-head && brew upgrade wabt && brew link wabt
wasm2c=$(command -v wasm2c) || { echo "no wasm2c on the PATH (brew install wabt)" >&2; exit 1; }
wabt="$(cd -P "$(dirname "$(readlink -f "$wasm2c")")/.." && pwd -P)"
building="$executable.build"
mkdir -p "$building" && building="$(cd -P "$building" && pwd -P)"
source "$here/../../../scripts/lib/wap-beside.sh"
# (the library the compiler compiled once, types.wasm, is the GC one: a native build compiles the types module's files
# anew, from their code in the warm state, its own files for texts and lists among them)
wap_ran "$compiler" native "$program" "$building/$MODULE_NAME.wasm"
"$wasm2c" "$building/$MODULE_NAME.wasm" -n "$MODULE_NAME" -o "$building/$MODULE_NAME.c"
seed=()
if [ -n "$standalone" ]; then
	seeded="$(dirname "$compiler")"
	parts=("${WAP_PARTS[@]}" $(cd "$seeded" && echo $WAP_LIBRARY_LINKED))
	(cd "$seeded" && COPYFILE_DISABLE=1 tar -cf "$building/seed.tar" "${parts[@]}")
	seed_name=seed-$(cd "$seeded" && find "${parts[@]}" -type f | sort | xargs shasum | shasum | cut -c1-$SEED_NAME_DIGITS)
	seed=(-DWAP_SEED="\"$building/seed.tar\"" -DWAP_SEED_NAME="\"$seed_name\"")
fi
awk -f "$here/glue.awk" "$building/$MODULE_NAME.h" >"$building/glue.c"
"$C_COMPILER" $C_FLAGS $(system_linked) ${seed[@]+"${seed[@]}"} -I"$building" -I"$wabt/$WASM2C_RUNTIME" -I"$wabt/$WABT_HEADERS" -I"$library" -o "$executable" \
	"$building/$MODULE_NAME.c" "$here/main.c" "$wabt/$WASM2C_RUNTIME/wasm-rt-impl.c" "$wabt/$WASM2C_RUNTIME/wasm-rt-mem-impl.c" -lm "$@"
rm -rf "$building"
