#!/usr/bin/env bash
# Every job slot's command runs guarded (scripts/guarded.sh): its output and status its own, a runaway past the memory
# or time cap killed with its largest process named. Source: warp-supervisor 2026-11-22, after one runaway wap took
# 90 GB and the terminal with it. Run it with bash test/wap/test_guarded.sh
source "$(dirname "$0")/../native/checks.sh"
guarded="$(dirname "$0")/../../scripts/guarded.sh"

# what a guarded run says on stderr, if it was killed (the cap, a process past the time cap), and its status
guarded_run() { "$guarded" "$@" 2>&1 >/dev/null | grep -o 'past the cap of [0-9]* [GBs]*\(: .*\)*\|runaway-input'; echo "status ${PIPESTATUS[0]}"; }

check "a guarded command's output and status are its own" "$("$guarded" bash -c 'echo said; exit 3'; echo "status $?")" "said
status 3"
check "a command past the memory cap is killed and its input named" \
	"$(guarded_run --memory-gb 1 python3 -c 'block = bytearray(2 << 30); import time; time.sleep(30)  # runaway-input')" \
	"past the cap of 1 GB
runaway-input
status 137"
check "a command past the time cap is killed, its children too" \
	"$(guarded_run --seconds 1 bash -c 'sleep 30 & sleep 30')" \
	"past the cap of 1 s: sleep 30
status 137"
exit $((failures > 0))
