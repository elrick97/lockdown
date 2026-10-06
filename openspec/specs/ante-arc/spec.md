# ante-arc Specification

## Purpose
The ante climb that gives a run its arc: per-ante target scores and how clearing or failing them advances or ends the run.

Named tunables on `AnteConfig` Resource (current M0 values): `targets` = **[150, 350, 700]** (3 antes). These are the minimum cumulative scores needed to clear each ante.
## Requirements
### Requirement: Ante arc drives run progression
`AnteArc` SHALL advance through a sequence of antes. After a round is won it checks whether more antes remain: if yes it advances to the next ante; if no it emits `run_won`. If a round is lost it emits `run_lost` immediately.

#### Scenario: Advance to next ante on win
- **WHEN** ante 1's round is won and antes remain
- **THEN** `AnteArc` advances to ante 2 (current_ante = 2) and provides the ante 2 target

#### Scenario: Run won after final ante
- **WHEN** the final ante's round is won
- **THEN** `run_won` fires and no further antes are started

#### Scenario: Run lost on round loss
- **WHEN** any round is lost
- **THEN** `run_lost` fires immediately regardless of which ante

### Requirement: Targets are data-driven via AnteConfig Resource
The ante target scores SHALL live in an `AnteConfig` Resource (`resources/ante_arc.tres`) as a named `targets: Array[int]` tunable. `AnteArc` reads from this resource at construction. Rebalancing M0 targets requires only editing the `.tres`, not touching script files.

#### Scenario: Targets loaded from resource
- **WHEN** `AnteArc` is constructed with the default `ante_arc.tres`
- **THEN** `target_for(1)` returns 150, `target_for(2)` returns 350, `target_for(3)` returns 700

#### Scenario: Custom targets in tests
- **WHEN** a test constructs `AnteConfig` with `targets = [10, 20]`
- **THEN** `AnteArc` uses those targets and a two-ante run can be driven headlessly

### Requirement: AnteArc is headless-safe
`AnteArc` SHALL be a `RefCounted` with no scene tree or autoload references. It SHALL be driven by `on_round_won() -> void` and `on_round_lost() -> void` calls from the throw scene.

#### Scenario: Headless full run
- **WHEN** a test creates `AnteArc` with 3 targets and calls `on_round_won` three times
- **THEN** `run_won` fires after the third call and `current_ante` equals 3

#### Scenario: Headless loss
- **WHEN** a test calls `on_round_lost` on ante 1
- **THEN** `run_lost` fires and `current_ante` remains 1

### Requirement: AnteArc signals
`AnteArc` SHALL emit:
- `ante_advanced(new_ante: int, target: int)` when a round is won and another ante begins
- `run_won` when the final ante is cleared
- `run_lost` when any round is lost

#### Scenario: ante_advanced carries correct data
- **WHEN** ante 1 is won and ante 2 begins
- **THEN** `ante_advanced` fires with `new_ante = 2` and `target = 350` (using default config)

### Requirement: AnteArc owned by RunCoordinator
`AnteArc` SHALL be created and owned by `RunCoordinator` (autoload) rather than by `ThrowScene` directly. `ThrowScene` SHALL receive the arc instance by reference from `RunCoordinator` on scene entry. This ensures arc state survives scene transitions to and from `ShopScene`.

#### Scenario: Arc state survives shop visit
- **WHEN** ante 1 clears, `ShopScene` loads and the player presses CONTINUE
- **THEN** `AnteArc.current_ante` is 2 when `ThrowScene` re-enters, and the arc's `run_won`/`run_lost` signals are still connected

### Requirement: ThrowScene signals ante cleared to RunCoordinator
When `AnteArc` emits `ante_advanced`, `ThrowScene` SHALL emit `ante_cleared(throws_left: int)` and disable the THROW button. `RunCoordinator` SHALL handle `ante_cleared` as follows:
1. Credit the round's gold.
2. Apply interest once for the coming shop visit.
3. Emit `cashout_ready` with the itemised breakdown.

The throw screen shows the round-cleared panel, and its CONTINUE calls `RunCoordinator.go_to_shop()`, which transitions to `ShopScene`.

#### Scenario: ante_cleared leads to the shop through the cash-out
- **WHEN** `ThrowScene` emits `ante_cleared` with `throws_left = 1`
- **THEN** `RunCoordinator` credits `base_gold + 1 * gold_per_leftover`, applies interest and emits `cashout_ready`; the shop loads when the player presses CONTINUE

### Requirement: Run end is terminal
Once `run_won` or `run_lost` has fired, `AnteArc` SHALL ignore further `on_round_won` or `on_round_lost` calls without emitting additional signals.

#### Scenario: No double-fire after run end
- **WHEN** `on_round_won` is called again after `run_won` has already fired
- **THEN** no additional signal is emitted

### Requirement: AnteConfig carries round names and boss parameters
`AnteConfig` SHALL include:
- `round_names: Array[String]` — one label per ante (e.g. "Open", "Risk", "Boss"), parallel to `targets`
- `boss_antes: Array[int]` — 1-based ante indices that receive the boss modifier (default: `[3]`)
- `boss_window_scale: float` — multiplier applied to `lock_window_duration_s` on boss antes (current value: `0.5`)

#### Scenario: Round names accessible per ante
- **WHEN** `AnteConfig` is loaded with default values and `current_ante = 3`
- **THEN** `round_names[2]` returns `"Boss"`

#### Scenario: Boss antes list consulted
- **WHEN** `current_ante = 3` and `boss_antes = [3]`
- **THEN** the ante is identified as a boss ante and `boss_window_scale` is applied

### Requirement: AnteConfig carries risk-skip parameters
`AnteConfig` SHALL include:
- `risk_antes: Array[int]` — 1-based ante indices where a skip offer is shown (default: `[2]`)
- `skip_reward_gold: int` — gold earned when the player skips the risk round (current value: `3`)

#### Scenario: Skip reward configured
- **WHEN** `AnteConfig` has default values
- **THEN** `skip_reward_gold` is 3 and `risk_antes` is `[2]`

### Requirement: Risk round can be skipped for reduced gold
`AnteArc.skip_round()` SHALL behave identically to `on_round_won()`: advance the ante or emit `run_won`. `RunCoordinator.on_risk_skipped()` SHALL do the following:
1. Earn `skip_reward_gold` before calling `skip_round()`.
2. If the run continues, apply interest for the coming shop visit, like any other shop visit (gold-economy spec).
3. Emit `cashout_ready` titled "ROUND SKIPPED".

#### Scenario: Skip earns gold and advances
- **WHEN** the player presses SKIP on ante 2 holding 6 gold
- **THEN** gold becomes 6 + 3 = 9 plus interest (11), `current_ante` becomes 3, and the round-skipped cash-out shows before the shop

### Requirement: Round rules are presented before play
Each ante's special rule SHALL be stated in plain words before its first throw, through the throw screen's ante intro card:
- Boss: the halved lock window, with its duration in seconds.
- Risk: the skip reward next to the win reward.

The rules themselves are unchanged.

#### Scenario: Rules come from the tunables
- **WHEN** `boss_window_scale` or `skip_reward_gold` changes
- **THEN** the intro card text changes with it

