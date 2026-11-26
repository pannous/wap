# scripts/lib/wap-host.sh: what runs wap's modules (sourced by scripts/refresh-seed.sh and wap/extensions/native/build.sh):
# the native wap on PATH, else (the first build on a new machine) wasmtime's own command with the proposals wap's
# modules use, calling their main with the module's path as its program's
WASMTIME_PROPOSALS=gc=y,function-references=y,exceptions=y
# wap_ran <module.wasm> [<arguments>…]: the module run with the arguments, its status the run's
wap_ran() { if command -v wap >/dev/null; then wap "$@"; else wasmtime_ran "$@"; fi; }
# wasmtime_ran <module.wasm> [<arguments>…]: the module run on wasmtime's own command, as the native wap runs it; a
# machine with no native wap yet takes a `wap` command that does only this (.github/workflows/windows.yml)
wasmtime_ran() {
	local read=() argument
	for argument in "$@"; do read+=("$(module_path "$argument")"); done
	MSYS_NO_PATHCONV=1 wasmtime run -W "$WASMTIME_PROPOSALS" --dir . --dir "$(root_folder)" $(modules_preloaded "$1") --invoke main --argv0 "${read[0]}" "$(host_path "$1")" "${read[@]:1}"
}
# the modules a module imports by their absolute path (its types module, extensions/wasm/library.wap), which the
# native wap links: each preloaded under that name, found by it in the module's bytes
modules_preloaded() {
	local name
	for name in $(grep -aoE '/[A-Za-z0-9_./-]+\.wasm' "$1" | sort -u); do
		[ -f "$(guest_file "$name")" ] && echo "--preload $name=$(host_path "$(guest_file "$name")")"
	done
}
# a path the module reads, as bash finds the file: on Windows below the drive (root_folder)
guest_file() { if on_windows; then echo "/$(drive)$1"; else echo "$1"; fi; }
# Windows: the module's / is the drive bash works on (wap opens an absolute path below /, types/host.wap ROOT_FOLDER),
# so a path Git Bash writes as /<drive>/… reaches it as /…, left so for the module (MSYS_NO_PATHCONV); the module's own
# file wasmtime opens as the host names it
on_windows() { case $(uname -s) in MINGW* | MSYS*) return 0 ;; *) return 1 ;; esac; }
# the current folder's drive, read as POSIX writes it: a sh a Windows program starts holds it as Windows does, D:/a
drive() { cygpath -u "$PWD" | cut -d/ -f2; }
root_folder() { if on_windows; then local drive=$(drive); echo "${drive^^}:\\::/"; else echo /; fi; }
module_path() { if on_windows && [[ $1 == /$(drive)/* ]]; then echo "${1#/$(drive)}"; else echo "$1"; fi; }
host_path() { if on_windows; then cygpath -w "$1"; else echo "$1"; fi; }
