#!/usr/bin/env bash
# packages (wiki/use.md "packages" and "versions"): a `use name` no file beside the program nor the library holds is
# fetched from the registry, once, into packages/<name>, then the program runs; a pin in packages.wap picks a version
# or another repository; a manifest makes a registry folder a proxy for a repository. Offline: the registry and the
# repositories are git folders in the test's own folder, named by --registry. Run it with bash test/wap/test_packages.sh
source "$(dirname "$0")/compile.sh"
command -v wasm2c >/dev/null || { echo "⊘ no wasm2c: skipped"; exit 0; }
native_wap=$(tree_wap_built) || exit 1

# a git folder of these files, `name=content` each, committed and tagged by the third argument where one is given
committed() {
	local folder=$1 tag=$2
	shift 2
	mkdir -p "$folder"
	for file in "$@"; do mkdir -p "$folder/$(dirname "${file%%=*}")" && printf '%s\n' "${file#*=}" >"$folder/${file%%=*}"; done
	git -C "$folder" init -q 2>/dev/null; git -C "$folder" add -A && git -C "$folder" -c user.name=test -c user.email=test@localhost commit -q -m "${tag:-newer}" && [ -z "$tag" ] || git -C "$folder" tag "$tag"
}
registry="$stage/registry"
# the registry: colors at its tag colors@1.0.0, then newer; shout a proxy for a repository at its tag v1.0.0
committed "$registry" "colors@1.0.0" 'colors/colors.wap=shade(): text := "old red"'
committed "$stage/shout" "v1.0.0" 'shout.wap=shout(t: text): text := t + "!"'
committed "$stage/shout" "" 'shout.wap=shout(t: text): text := t + "!!!"'
committed "$registry" "" 'colors/colors.wap=shade(): text := "red"' "shout/package.wap=repository: \"$stage/shout\"
version: 1.0.0"
packaged() {
	local folder="$stage/$1"
	mkdir -p "$folder" && printf '%s\n' "$2" >"$folder/main.wap"
	[ -z "${3-}" ] || printf '%s\n' "$3" >"$folder/packages.wap"
	(cd "$folder" && "$native_wap" --registry "$registry" main.wap 2>&1)
}

check "use colors fetches the registry's colors into packages/colors and runs" "$(packaged newest 'use colors
print shade()')$([ -L "$stage/newest/packages/colors" ] && echo ' linked')" "red linked"
check "a pin in packages.wap takes the registry's tag of that version" "$(packaged pinned 'use colors
print shade()' 'colors: 1.0.0')" "old red"
check "a registry folder whose manifest names a repository fetches it at the manifest's version" "$(packaged proxied 'use shout
print shout("hey")')" "hey!"
check "a pin names a repository and its version" "$(packaged redirected 'use shout
print shout("hey")' "shout: \"$stage/shout@1.0.0\"")" "hey!"
check "a pin names a repository's default branch" "$(packaged branch 'use shout
print shout("hey")' "shout: \"$stage/shout\"")" "hey!!!"
check "a package the registry has not is refused, said" "$(packaged missing 'use nowhere
print 1' | grep -c 'nowhere')" "1"
check "wap fetch fetches the packages named, running nothing" "$(cd "$stage" && mkdir -p fetching && cd fetching && "$native_wap" --registry "$registry" fetch colors 2>&1; [ -f "$stage/fetching/packages/colors/colors.wap" ] && echo fetched)" "fetched"
check "wap use runs the program using the package, fetched first" "$(mkdir -p "$stage/using" && cd "$stage/using" && "$native_wap" --registry "$registry" use colors 2>&1; [ -L "$stage/using/packages/colors" ] && echo ran)" "ran"
# the versions a use asks for in its own line (wiki/use.md "versions"), red until a use reads them
check "use colors version 1.0.0 takes that version" "$(packaged exact 'use colors version 1.0.0
print shade()')" "old red"
check "use colors from 1.0 takes that version or later" "$(packaged later 'use colors from 1.0
print shade()')" "red"
exit $((failures > 0))
