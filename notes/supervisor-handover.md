# Supervisor handover

Role: notes/agents/supervisor.md (plus lead.md, wap-owner.md). Read those first; this file only holds the live state.

## Who works on what (2026-11-24 08:00, after the fleet's idle night)
- wap-simplifier: op-spelled-once (user OK 2026-11-23), then simplify-43. template-shape (wap-enum-index-constant-time) waits on it.
- wap-fixer: any-truth-crash, then char-show; unclosed-text 62e35a5b waits for the core OK.
- wap-enum-index-constant-time: list-pattern-seed.
- wap-reader: indexing-method, then postfix-chain-brackets; three branches wait for core OKs.
- wap-emitter: c-callback-overwrite, then callback-export; wap-build e7ebfcb7 and foreign-globals-first 88f7063c wait.
- wap-binding: analyze-split-2 07d9e09d handed off if its prerequisites landed, else as-narrows; named-events stays its own.
- wap-lib-rules-audit: notes/lib-rules.md 59d55b48 to wap-integrator, then format-keeps-literals.
- wap-lead: next wap-architecture card. wap-interviewer: bringing the queued core OKs to the user now.
- The hourly watch round is a session cron: a fresh supervisor recreates it (CronCreate, the Routine's steps as prompt).

## Pending user questions (with wap-interviewer)
- Shared samples folder (warp and wap both symlink /Users/me/dev/angles/samples). I decided provisionally that samples follow wap, and pushing has started (revertible). The options went to the user.
- How `(1 2)` prints: parked by the user until the Node-in-runtime discussion. No page or test prints it either way.

## Routine
- Hourly watch round:
  - run warp/scripts/vitals.py;
  - republish data/vitals/wap-vitals.html to https://claude.ai/code/artifact/8b33d965-01c9-4a3b-9f75-d4597da4804e;
  - commit leftovers in wap and wap/wiki as "(user)";
  - give idle wiki workers their next page;
  - find idle workers (`ListAgents`; any session at an empty prompt for an hour) and send each its next card by name,
    day and night: "nothing new" is never a round's result while the board has unowned cards;
  - report only news.
- Full suite: the cloud routine trig_011CmX1HYy4erz3ugNtuYZwm, hourly. The Mac cron runs coverage only.
- Remote branch deletes are the supervisor's. Verify each branch is merged first, then `git -C <repo> push origin --delete <literal names>`; the hook refuses variables.
- Latest numbers: full suite 1433 ✓ 7 ✗ in 93 tests; coverage 21/125 lib modules, 19/304 samples.
