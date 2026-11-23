#!/usr/bin/env bash
# the forms wiki/cli.md shows that wap does not build yet: each red line is a to-do, fixed by building the form
source "$(dirname "$0")/cli.sh"

check "wap eval runs a line of code" "$(wap eval '2+3' 2>&1)" "5"
check "a build mode before the program: wap release" "$(wap release "$(written app 'print "hi"')" 2>&1)" "hi"
check "wap format check lists what would change and exits 0 when nothing would" "$(wap format check "$(written formatted 'x = 1')" >/dev/null 2>&1; echo $?)" "0"
check "wap build makes an executable that runs without wap" "$(cd "$programs" && wap build app.wap >/dev/null 2>&1 && ./app 2>&1)" "hi"
check "--no-window runs a program" "$(wap --no-window "$(written app 'print "hi"')" 2>&1)" "hi"
check "exec runs a command and gives what it printed" "$(wap 'exec sh "echo hi"' 2>&1)" '"hi\n"'
check "wap --sandbox refuses a process" "$(wap --sandbox "$(written exec 'exec sh "echo hi"')" 2>&1 | grep -c 'capability denied')" "1"
check "a whole-number result is the exit status" "$(wap "$(written answer '42')" >/dev/null; echo $?)" "42"
exit $((failures > 0))
