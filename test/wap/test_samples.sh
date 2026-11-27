#!/usr/bin/env bash
# Every headless sample program compiles (card samples-compile): the samples repository's .wap files outside the
# folders that paint, play or serve, compiled by the tree's compiler; the ones that fail are named with their first error.
# bash test/wap/test_samples.sh [--samples <folder>]   the folder defaults to the checkout's samples link
source "$(dirname "$0")/compile.sh"
# the folders whose programs need a window, a speaker, a device or a server
NOT_HEADLESS="gpu graphics sound events servers native"
samples="$tree/samples"
[ "${1:-}" = --samples ] && samples=$2
[ -d "$samples" ] || { echo "✗ no samples folder at $samples: link the samples repository there or pass --samples <folder>"; exit 1; }
skipped=$(printf '%s|' $NOT_HEADLESS)
failed=""
for program in $(cd "$samples" && find . -name '*.wap' | grep -v -E "^\./(${skipped%|})/" | sort); do
	said=$($wap "$compiler" "$samples/$program" "$stage/sample.wasm" 2>&1 >/dev/null) || failed+="$(echo "$said" | grep -v '^hint' | head -1 | sed "s|$samples/\./||")"$'\n'
done
check "every headless sample compiles" "$failed" ""
exit $((failures > 0))
