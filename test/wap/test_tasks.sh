#!/usr/bin/env bash
# Tasks as wiki/async.md and wiki/task.md show them where a program's output is the outcome: a task of a call, a task
# nobody awaits finishing at the program's end, after what the program printed meanwhile.
# Run it with bash test/wap/test_tasks.sh
source "$(dirname "$0")/compile.sh"

check "go of a call is a task of it" "$(ran go_call 'use tasks
f(ms: int): int := ms * 2
a = go f(200)
print(await a)' 2>&1)" "400"
check "a task runs while the program goes on, finishing before it ends" "$(ran go_block 'use tasks
hi() := { sleep(1000ms); print("hi") }
go {
  hi()
}
print("faster")' 2>&1)" "faster
hi"
exit $((failures > 0))
