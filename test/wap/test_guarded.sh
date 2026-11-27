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
check "a script of short runs may take longer than the time cap" "$("$guarded" --seconds 2 bash -c 'for run in 1 2 3 4; do sleep 1; done; echo done'; echo "status $?")" "done
status 0"
# a test cut short, its runner killed with it, as a guard kills a runaway's whole tree, is red, never green by the
# checks it printed before (test/wap/run.sh ended; card test-killed)
runner="$(dirname "$0")/run.sh"
cut_short="$(cd "$(dirname "$0")/../.." && pwd)/data/wap-tests/cut-short/test_cut_short.sh"
mkdir -p "$(dirname "$cut_short")" && printf '%s\n' 'echo "✓ a check before the cut"' 'kill -9 $PPID "$(ps -o ppid= -p $PPID)" $$' 'echo "✓ a check never reached"' >"$cut_short"
check "a test killed partway with its runner is red: it did not run to its end" "$(bash "$runner" all_run "" no no "$cut_short" | grep -c 'test_cut_short.sh: test_cut_short.sh ran to its end')" "1"
exit $((failures > 0))
