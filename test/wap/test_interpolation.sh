#!/usr/bin/env bash
# wap's texts with holes (wiki/string.md "templates interpolation"), as `wap format` prints them; their values are
# test/test_interpolation.wap. Run it with bash test/wap/test_interpolation.sh
source "$(dirname "$0")/compile.sh"
source "$(dirname "$0")/format_checks.sh"

# wap format prints a text with holes as it was written
format_check 'print "n is ${n + 1}, \(m)"' 'print "n is ${n + 1}, \(m)"'
exit $((failures > 0))
