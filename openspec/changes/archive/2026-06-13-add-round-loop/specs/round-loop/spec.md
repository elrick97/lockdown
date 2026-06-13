# Spec: round-loop

Named tunables on `AnteConfig` (current M0 values): `throws_per_round` = **3**.

## ADDED Requirements

### Requirement: Round accumulates score across throws
A round SHALL accumulate the `final_score` of each resolved throw into a running total. The round is won the moment that total meets or exceeds the target score, regardless of how many throws remain.

#### Scenario: Win on first throw
- **WHEN** throw 1 resolves and its score alone meets or exceeds the round target
- **THEN** the round is won immediately and throw 2 is not taken

#### Scenario: Win after accumulation
- **WHEN** throw 1 and throw 2 resolve with scores that together meet or exceed the round target
- **THEN** the round is won after throw 2 and throw 3 is not taken

#### Scenario: Lose on final throw
- **WHEN** all three throws are resolved and the running total is still below the target
- **THEN** the round is lost

### Requirement: Throw budget is fixed at 3 per round
A round SHALL allow exactly `throws_per_round` throws. The throw counter increments by one each time a throw resolves. Once the budget is exhausted without reaching the target, the round is lost.

#### Scenario: Budget exhausted
- **WHEN** throw 3 resolves and total < target
- **THEN** the round-lost signal fires and no further throws are permitted for this round

#### Scenario: Budget not exhausted on win
- **WHEN** the target is met on throw 1 or throw 2
- **THEN** the remaining throw budget is discarded (not carried over)

### Requirement: RoundState is headless-safe
`RoundState` SHALL be a `RefCounted` driven by `add_score(score: int) -> void`. It SHALL NOT reference any scene node, autoload, or global. The throw scene owns the instance and passes scores in.

#### Scenario: Headless round sequence
- **WHEN** a test creates `RoundState` with a target and calls `add_score` three times
- **THEN** the correct signal fires (round_won or round_lost) with no scene tree present

### Requirement: RoundState signals
`RoundState` SHALL emit:
- `round_won` when the running total first meets or exceeds target
- `round_lost` when the final throw is scored without reaching target

#### Scenario: Signal fires once
- **WHEN** the winning score is added
- **THEN** `round_won` fires exactly once; subsequent `add_score` calls are ignored

### Requirement: Round is reset between antes
When a new ante begins, `RoundState` SHALL be replaced with a fresh instance (or `reset()` called) so that the running total and throw counter start from zero against the new ante's target.

#### Scenario: Fresh round for each ante
- **WHEN** ante 2 begins after ante 1 is cleared
- **THEN** the throw counter is 1 and the running total is 0
