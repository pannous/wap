#!/usr/bin/env bash
# the forms wiki/warning.md shows that wap does not build yet: each red line is a to-do, fixed by building the form
source "$(dirname "$0")/cli.sh"

careful="$(written careful 'warn "careful"; 1')"
check "warn prints a warning and the program runs on" "$(wap "$careful" 2>&1)" "$(printf 'warning: careful\n1')"
check "--warnings=severe shows only severe warnings" "$(wap --warnings=severe "$careful" 2>&1)" "1"
check "--no-hints shows warnings from weak up" "$(wap --no-hints "$(written hinted 'one plus two')" 2>&1)" "3"
exit $((failures > 0))
