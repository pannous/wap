#!/usr/bin/env bash
# A wap program built to a native executable: compiled by wap to a module, which wasm2c writes as C, which cc
# builds with wasm2c's runtime, lib/native/wasi.c and the C glue of its imports (main.c, glue.awk beside this
# script). The program uses no GC value: no list or raise; a text is in the module's memory, as the compiler writes one
# that reads text_bytes.wap (beside this script) in the place of types/text_bytes.wap.
#   wap/extensions/native/build.sh <compiler.wasm> <program.wap> <executable> [<C compiler arguments>…]
# the arguments after the executable are the C compiler's, the libraries the program's C functions are in:
# `-Llib -lwarp_wasmtime -Wl,-rpath,@executable_path/lib` for the native wap (driver.wap)
# The warp that runs the compiler is WARP (default the warp on PATH). The build's files go in <executable>.build/
set -euo pipefail
WARP=${WARP:-warp}
C_COMPILER=cc
C_FLAGS="-O2"
MODULE_NAME=program
WASM2C_RUNTIME=share/wabt/wasm2c
WABT_HEADERS=include

[ $# -ge 3 ] || { echo "usage: $0 <compiler.wasm> <program.wap> <executable> [<C compiler arguments>…]" >&2; exit 2; }
compiler=$1 program=$2 executable=$3
shift 3
here="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
library="$(cd -P "$here/../../../lib" && pwd -P)"
wasm2c=$(command -v wasm2c) || { echo "no wasm2c on the PATH (brew install wabt)" >&2; exit 1; }
wabt="$(cd -P "$(dirname "$(readlink -f "$wasm2c")")/.." && pwd -P)"
building="$executable.build"
mkdir -p "$building" && building="$(cd -P "$building" && pwd -P)"
# the compiler beside what it reads (scripts/lib/wap-beside.sh), a text's layout the native one
source "$here/../../../scripts/lib/wap-beside.sh"
mkdir -p "$building/compiler"
(cd "$(dirname "$compiler")" && cp -R "${WAP_BESIDE[@]}" "$WAP_LIBRARY" "$building/compiler/") && cp "$compiler" "$building/compiler/wap.wasm"
# (a library the compiler compiled once, types/types.wasm, is the GC one: a native build's library is read anew)
cp "$here/text_bytes.wap" "$building/compiler/types/text_bytes.wap" && rm -f "$building/compiler/types/types.wasm"
"$WARP" --no-window "$building/compiler/wap.wasm" native "$program" "$building/$MODULE_NAME.wasm"
"$wasm2c" "$building/$MODULE_NAME.wasm" -n "$MODULE_NAME" -o "$building/$MODULE_NAME.c"
awk -f "$here/glue.awk" "$building/$MODULE_NAME.h" >"$building/glue.c"
"$C_COMPILER" $C_FLAGS -I"$building" -I"$wabt/$WASM2C_RUNTIME" -I"$wabt/$WABT_HEADERS" -I"$library" -o "$executable" \
	"$building/$MODULE_NAME.c" "$here/main.c" "$wabt/$WASM2C_RUNTIME/wasm-rt-impl.c" "$wabt/$WASM2C_RUNTIME/wasm-rt-mem-impl.c" -lm "$@"
rm -rf "$building"
