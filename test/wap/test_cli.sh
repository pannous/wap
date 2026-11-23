#!/usr/bin/env bash
# the wap command as wiki/cli.md shows it: running a file or code, the exit status. Run it with bash test/wap/test_cli.sh;
# it runs the wap on PATH
source "$(dirname "$0")/cli.sh"

check "wap runs a file" "$(wap "$(written app 'print "hi"')")" "hi"
check "wap run runs a file" "$(wap run "$(written app 'print "hi"')")" "hi"
check "wap runs code given in a file's place" "$(wap '2+3')" "5"
check "code starting with a command's name as a variable is code" "$(wap 'lower = "abc"; lower')" '"abc"'
check "wap help lists the commands" "$(wap help | grep -c 'wap run')" "1"
check "a float result exits 0" "$(wap "$(written float '2.5')" >/dev/null; echo $?)" "0"
check "a failed run exits 1" "$(wap "$(written failed 'x: int = "a"')" >/dev/null 2>&1; echo $?)" "1"
exit $((failures > 0))
