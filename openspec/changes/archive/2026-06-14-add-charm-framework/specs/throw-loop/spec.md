## ADDED Requirements

### Requirement: Charm hooks fire at throw-loop state transitions
`ThrowController` SHALL accept an optional `CharmInventory` at construction (default `null`). When an inventory is provided, it SHALL dispatch hook calls at the following moments:
- **`on_throw`** — immediately after RNG has determined all faces at throw start, before tumble begins
- **`on_window`** — when a lock window opens (after tumble or re-roll completes), passing the 1-based window index
- **`on_lock`** — when a die is locked (by player tap or force-lock), passing die index, face value, and window index

Hook calls SHALL pass a freshly-built `CharmContext` snapshot. Hook calls SHALL NOT affect die faces, lock state, or window timing — they are fire-and-forget in M1 (no return values are read by the engine).

#### Scenario: on_throw fires once per throw
- **WHEN** a throw starts with a charm in the inventory
- **THEN** `on_throw` is called exactly once, after all faces are determined by RNG

#### Scenario: on_window fires at each window open
- **WHEN** a 3-window throw completes with a charm in the inventory
- **THEN** `on_window` is called three times, with `window_index` 1, 2, and 3 in order

#### Scenario: on_lock fires per die locked
- **WHEN** the player locks 2 dice in window 1 and the remaining 4 are force-locked in window 3
- **THEN** `on_lock` fires 6 times total: 2 during window 1, 4 during window 3

#### Scenario: No inventory — no hooks fired
- **WHEN** `ThrowController` is constructed without a `CharmInventory`
- **THEN** no hook calls are made and throw behaviour is identical to M0
