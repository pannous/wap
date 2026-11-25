# scripts/lib/wap-host.sh: what runs wap's modules (sourced by scripts/refresh-seed.sh and wap/extensions/native/build.sh):
# the native wap on PATH, else (the first build on a new machine) wasmtime's own command with the proposals wap's
# modules use, calling their main with the module's path as its program's
WASMTIME_PROPOSALS=gc=y,function-references=y,exceptions=y
# wap_ran <module.wasm> [<arguments>…]: the module run with the arguments, its status the run's
wap_ran() {
	if command -v wap >/dev/null; then wap "$@"; else MSYS_NO_PATHCONV=1 wasmtime run -W "$WASMTIME_PROPOSALS" --dir . --dir "$(root_folder)" --invoke main --argv0 "$1" "$@"; fi
}
# the folder the module sees as /, so it reads the paths bash gives as they are: Windows's drive as /<drive>, which Git
# Bash writes its paths in (and leaves them so, MSYS_NO_PATHCONV, for the module to read)
root_folder() {
	case $(uname -s) in
		MINGW* | MSYS*) local drive=$(pwd | cut -d/ -f2); echo "${drive^^}:\\::/$drive" ;;
		*) echo / ;;
	esac
}
