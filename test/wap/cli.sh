# the helper of the wap command's tests (source it): written <name> <code> writes a program and prints its path
source "$(dirname "${BASH_SOURCE[0]}")/../native/checks.sh"
command -v wap >/dev/null || { echo "no wap on PATH: scripts/refresh-seed.sh installs it" >&2; exit 2; }
programs="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)/data/wap-tests/cli"
mkdir -p "$programs"
written() {
	printf '%s\n' "$2" >"$programs/$1.wap" && echo "$programs/$1.wap"
}
