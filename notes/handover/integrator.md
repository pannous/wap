# Integrator handover (2026-11-23, ~01:45)

## State
- wap main 3d04e23 (+ the cloud suite commit b5e9cdb). Installed ~/dev/bin/wap: seed wap-seed-2026-11-23-09acdec9,
  built from d78439a (library-embedded layout), lock d00b034. Checked by hand: version, hello from another folder,
  console ↑/← in a pty, `xs: any = [5, 6, 7]; print xs`.
- Size ceiling (test/wap/ratchet_census.sh) 123154; Mac full suite on 1b09da9: 871 ✓, 1 ✗.
- The one known red: test_dynamic's last line, two anys holding "a" compared with == trap (card any-char-equality,
  pinned by map-print).

## Open: new reds in the cloud full suite at 3d04e23
- b5e9cdb: 829 ✓, 4 ✗; failed test_dynamic (known), test_c.sh, test_modules.sh. The Mac suite on 1b09da9 had
  test_c and test_modules green, so the likely suspect is library-embedded (4d19514, merged 1b09da9) or
  seed-library-path on Linux: a module links the library by its compiler's folder path. First job: read the cloud
  failures and send them to the library-embedded owner (warp-wap-arch's successor); revert-first if it is the
  install layout.

## Held / waiting
- dispatch-rounds (warp-wap-lang, +10 nodes, card any-values): waits for the user's morning discussion.
- compile-library-programs remote branch: kept, its owner still works on it.
- No land/ queue, nothing merged-but-unpushed.

## Rules learned tonight
- wap has no after-push: only scripts/refresh-seed.sh <tree> installs ~/dev/bin/wap; run one after every landing
  the user should see, then push the lock commit it makes.
- wap core/extension landings need a "discussed with the user" card note (user rule 11-22); pure shrinks need a
  warp-reviewer OK note. The census also guards "functions typed alone ≤ 0": any-values first broke it.
- Remote branch deletes are hook-blocked for the integrator: send merged names to the supervisor.

## Leftovers in /Volumes/Worktrees/wap-land
- Local branches held/batch-with-any-values, held/one-memory-batch: superseded test merges, safe to delete.
