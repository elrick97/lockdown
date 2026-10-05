## 1. Tests first (headless)

- [x] 1.1 Case C: one Glass shatters after W1, the two live dice are locked 0.5 s into W2 → resolves at once, window times [0, 2.0, 2.5], Heat ×1.3
- [x] 1.2 Case A/B: 1 Bone locked in W1, 5 Glass shatter at W1 expiry → resolves at the re-roll with [0, 0, 0], Heat ×1.0, `reroll_started` not emitted
- [x] 1.3 Regression: a throw without Glass still credits skipped windows at full duration (existing scenario); a throw where live dice remain after shattering still re-rolls

## 2. Implementation

- [x] 2.1 `ThrowController._all_done()`; `lock_die()` uses it (D1, D2)
- [x] 2.2 `_begin_reroll()`: when `_all_done()` after shattering, record 0 for later windows and resolve (D3)

## 3. Local verification

- [x] 3.1 Full GUT suite green (161). The throw-scene smoke test was flaky before this change (2/8 failures on HEAD too: a random hand sometimes won the round); it now uses a fixed seed.
- [x] 3.2 Desktop playthrough: add dead-slot cases (lock last live die → immediate resolve; nothing left to lock → resolves without empty windows); 0 failed checks. Found and fixed on the way: dead slots were only dimmed on re-roll, so the nothing-left path (no re-roll) drew them undimmed; the scene now marks them on resolve too.
