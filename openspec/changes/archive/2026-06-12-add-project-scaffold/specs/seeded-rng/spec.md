# Spec: seeded-rng

## ADDED Requirements

### Requirement: Single source of randomness
The game SHALL provide an autoloaded `RngService` that is the only source of gameplay randomness. Gameplay code MUST NOT call `randi()`, `randf()`, `randomize()`, or create its own `RandomNumberGenerator` instances; presentation-only effects (particle jitter, animation variation) are exempt but MUST NOT feed back into gameplay state.

#### Scenario: Gameplay code requests randomness
- **WHEN** any gameplay system needs a random value (die face, shop offer, bag shuffle)
- **THEN** it obtains it through `RngService` and through no other API

### Requirement: Injectable seed
`RngService` SHALL accept an explicit seed at run start. When no seed is provided, it SHALL generate one and expose it for display/logging, so any run can be reproduced from its logged seed.

#### Scenario: Explicit seed provided
- **WHEN** a run starts with seed S
- **THEN** all subsequent draws from `RngService` are fully determined by S

#### Scenario: No seed provided
- **WHEN** a run starts without a seed
- **THEN** the service generates a seed, and that seed is retrievable as a value that reproduces the run exactly

### Requirement: Deterministic reproduction
Two runs initialized with the same seed SHALL produce identical random sequences regardless of frame rate, device, render state, or wall-clock time. Physics and rendering MUST NOT influence any value the service returns.

#### Scenario: Same seed, same sequence
- **WHEN** `RngService` is seeded with S and asked for N die faces, twice, in fresh sessions
- **THEN** both sessions return the identical sequence of N faces

#### Scenario: Headless equals editor
- **WHEN** the same seeded draw sequence runs headless and in the editor
- **THEN** the resulting values are identical

### Requirement: Named sub-streams
`RngService` SHALL expose independent named streams (at minimum: `dice`, `shop`, `bag`) derived from the run seed, so consuming randomness in one domain does not shift outcomes in another.

#### Scenario: Stream independence
- **WHEN** extra draws are taken from the `shop` stream between two `dice` stream draws
- **THEN** the `dice` stream's sequence is unchanged compared to a run with no `shop` draws
