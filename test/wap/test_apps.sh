#!/usr/bin/env bash
# The dogfood programs of samples/apps (wiki/library-dogfood-apps.md) run as plain programs and print what
# test/apps/expected/<name>.txt holds.
# Run it with bash test/wap/test_apps.sh
source "$(dirname "$0")/compile.sh"

for expected in "$tree"/test/apps/expected/*.txt; do
	name=$(basename "$expected" .txt)
	check "samples/apps/$name.wap prints what test/apps/expected/$name.txt holds" "$(ran "$name" "$(cat "$tree/samples/apps/$name.wap")" 2>&1)" "$(cat "$expected")"
done
exit $((failures > 0))
