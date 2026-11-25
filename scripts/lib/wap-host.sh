# scripts/lib/wap-host.sh: what runs wap's modules (sourced by scripts/refresh-seed.sh and wap/extensions/native/build.sh):
# the native wap on PATH, else (the first build on a new machine) wasmtime's own command with the proposals wap's
# modules use, calling their main with the module's path as its program's
WASMTIME_PROPOSALS=gc=y,function-references=y,exceptions=y
# wap_ran <module.wasm> [<arguments>…]: the module run with the arguments, its status the run's
wap_ran() {
	if command -v wap >/dev/null; then wap "$@"; else MSYS_NO_PATHCONV=1 wasmtime run -W "$WASMTIME_PROPOSALS" --dir . --dir "$(root_folder)" --invoke main --argv0 "$1" "$(host_path "$1")" "${@:2}"; fi
}
# the module's file as wasmtime opens it, on the host: on Windows by its drive
host_path() { if command -v cygpath >/dev/null; then cygpath -w "$1"; else echo "$1"; fi; }
# the folder the module sees as /, so it reads the paths bash gives as they are (wap opens an absolute path below /,
# types/host.wap ROOT_FOLDER): on Windows, where Git Bash writes a drive as /<drive>, the drive, holding itself by
# that name (a junction, which wasmtime follows as it stays inside), the paths left so for the module (MSYS_NO_PATHCONV); the module's own file wasmtime opens
# as the host names it (host_path)
root_folder() {
	case $(uname -s) in
		MINGW* | MSYS*)
			local drive=$(pwd | cut -d/ -f2)
			[ -e "/$drive/$drive" ] || cmd //c mklink //J "${drive^^}:\\$drive" "${drive^^}:\\" >/dev/null
			echo "${drive^^}:\\::/" ;;
		*) echo / ;;
	esac
}
