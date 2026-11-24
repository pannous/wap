# Supervisor handover

Role: notes/agents/supervisor.md (plus lead.md, wap-owner.md). Read those first; this file only holds the live state.

## Who works on what
- wap-binding: one form at a time, in this order:
  1. loop-capture (Now, high, user OK);
  2. lazy-arguments + named-events (one argument-mode mechanism; measure before adding core lines);
  3. single-overload-value;
  4. resultless-lambda (one card now, in wap-architecture).
  Separately, inline-block-free is costing only: core lines on the card, no build until approved.
- wap-lead: routes wiki-worker needs to the one owner. It knows the queue above. When named-events' mechanism lands, the `once`/`emit` lib part and async.md go to wap-wiki.
- wap-wiki: page by page from notes/wiki_pages.md. charged.md and list.md are done, lambda.md is in progress. The not-yet sweep is done; meant-but-missing forms sit in red test/test_<page>_wanted.wap files.
- wap-wiki-lib: every library page is done except library-uuid.md (waits on card host-random). Now on the samples roadmap: make the 304 samples run under wap, one at a time, rewriting into idiomatic wap where nicer (its own commit), lib/ for missing functions, core needs to wap-lead. Its branches with the integrator: types-bits-pipe, wiki-reference, wiki-hash.
- wap-integrator: lands; holds own-type-overloads-b until the OK for +30 core lines is on its card.
- wap-reader: `{1 2 3}` (list in braces); format-keeps-comments.
- wap-fixer: tooling. Wiki worktrees come from the donor /Volumes/Worktrees/wap-wiki (handbook line).
- wap-board: works card after card until the board is clean.
- wap-interviewer: all user questions.
- Idle by default: wap-emitter, wap-native, wap-reviewer, wap-simplifier.
- wap-taste: retired, session closed; data/reviewer-taste kept.

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
