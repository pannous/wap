# Tool renames for the user

Each shell tool that gets a wap port is then called as `wap <path>.wap`, with the same arguments and output. The user
applies these lines (CLAUDE.md and the crontab are theirs); each block says when.

## test_hello: apply when test/wap/test_hello.wap lands
CLAUDE.md, Build and test:
    wap test/wap/test_hello.wap                    # smoke: the tree's compiler, built from the seed, says hello
CLAUDE.md prose (Testing "Tiers", Done "express"): `test_hello.sh` → `test_hello.wap`.

## run: apply when test/wap/run.wap lands
CLAUDE.md, Build and test:
    wap test/wap/run.wap --wait <area>...          # the tests of what a change touches: test/test_<area>.wap, test/wap/test_<area>.wap (wap test <area> too)
    wap test/wap/run.wap --wait [--stage <n>]      # all scripts (the integrator), --stage: wap built of itself n times
CLAUDE.md prose (Testing "Tiers"): `run.sh` → `run.wap`, `test/wap/test_<area>.sh` → `test/wap/test_<area>.wap`.

## ratchet_census: apply when test/wap/ratchet_census.wap lands
    wap test/wap/ratchet_census.wap                # the census: every function of wap's source typed (the integrator)

## refresh-seed: apply when scripts/refresh-seed.wap lands
    wap scripts/refresh-seed.wap [--check]         # wap's seed refreshed and published
CLAUDE.md prose (Project Overview, the seed): `scripts/refresh-seed.sh` → `scripts/refresh-seed.wap`.

## compile: apply when test/wap/compile.wap lands
CLAUDE.md prose (Project Overview, the seed): `test/wap/compile.sh` → `test/wap/compile.wap`.

## compiler-growth: apply when scripts/compiler-growth.wap lands
CLAUDE.md prose (Layers, Done "express"): `scripts/compiler-growth.sh <tree>` → `wap scripts/compiler-growth.wap <tree>`.

## repeated-code: apply when scripts/repeated-code.wap lands
CLAUDE.md prose (Principles, never repeat code): `scripts/repeated-code.sh <tree>` → `wap scripts/repeated-code.wap <tree>`.

## job-slot: apply when scripts/job-slot.wap lands
CLAUDE.md prose (Testing, one heavy job): `scripts/job-slot.sh` → `scripts/job-slot.wap`.

## test_self: apply when test/wap/test_self.wap lands
CLAUDE.md prose (Done "careful"): `test_self.sh` → `test_self.wap`.

## coverage: apply when scripts/coverage.wap lands
crontab line 103, only the command changes:
    20 * * * * cd /Users/me/dev/angles/wap && PATH=/Users/me/dev/bin:/opt/homebrew/bin:/usr/bin:/bin /usr/bin/lockf -t 0 data/coverage.lock nice -n 19 wap scripts/coverage.wap >> /Users/me/Library/Logs/warp/cron/wap-coverage.log 2>&1
and its comment on line 102: `scripts/coverage.sh` → `scripts/coverage.wap`.

## start: apply when notes/agents/start.wap lands
    wap notes/agents/start.wap [<role> | owner <stage> | worker <branch> "<task>"]
replaces `notes/agents/start.sh` with the same arguments, in the user's own habit and in notes/agents/README.md "Start".
