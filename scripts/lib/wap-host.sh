# scripts/lib/wap-host.sh: what runs wap's modules (sourced by scripts/refresh-seed.sh and wap/extensions/native/build.sh):
# the native wap on PATH, else (the first build on a new machine) wasmtime's own command with the proposals wap's
# modules use, calling their main with the module's path as its program's
WASMTIME_PROPOSALS=gc=y,function-references=y,exceptions=y
# wap_ran <module.wasm> [<arguments>…]: the module run with the arguments, its status the run's
wap_ran() {
	if command -v wap >/dev/null; then wap "$@"; else wasmtime run -W "$WASMTIME_PROPOSALS" --dir . --dir / --invoke main --argv0 "$1" "$@"; fi
}
