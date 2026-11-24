# Integrator handover (2026-11-24)

Landing worktree: /Volumes/Worktrees/wap-land (detached). Merges are main-first-parent: checkout origin/main, `git merge --no-ff <tip>`.
Close cards and delete branches only after the push succeeded (`push && todo done …`); branch deletes by literal name.
Size: `seed=$(dirname "$(readlink -f "$(command -v wap)")")/wap-seed/wap.wasm; mkdir -p data/size; wap "$seed" scripts/wap-size.warp data/size/s.wasm; wap data/size/s.wasm $(git ls-files 'wap/*.wap') | sed -n 's/^total\t//p'`

## Landed this session
through 271c4f0a: op-spelled-once, c-callback-overwrite, any-layout-missing, ini-review-nits (SIZE_NODES 134830; careful green, only test_modules alias red)

## Queue (handed, not held)
- module-alias-preload 903c3c53 (user OK on card; census line conflicts: remeasure). Fixes test_modules' alias red.
- simplify-43 dc07aa2a (pure shrink, reviewer sound; census line conflicts: remeasure)
- unclosed-text ebd95ed7 (user OK + wiki line pushed; +1 WAP_SUFFIX moved to driver.wap)
- truthiness-absent 82e36688 (test variable rename, own commit)
- library-port-pga 898998c3 (lib only; check glyph operators are plain definitions, no rewrite rules)
- format-fidelity 3d477367 (types/texts.wap escaped \r + one test_reader line)
- wap-headless 9660c92, fn-type-empty-result 08b4db9e (supervisor's list; fn-type-empty-result needs wap-reviewer sound on its +1: check the card)
## Held for the user (wap-interviewer queue)
exact-numbers-literals 2310158e (core +6), prelude-modules-hint 25846492 (+4 core/extensions), any-truth-crash e64c0d15,
native-cache-folders 91ef2aba, fix-previous-line 19b558da (console extension).
## Owed
Full run.sh on main's tip after the queue, counts to wap-supervisor (13 known reds outside _wanted; test_conditions_truthiness
fixed by truthiness-absent, test_modules by module-alias-preload). Seed refresh before any try line.
