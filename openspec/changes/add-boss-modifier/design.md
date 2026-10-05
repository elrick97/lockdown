# Design: add-boss-modifier

## Round types for the M1 slice

The 3-ante structure maps directly to Open / Risk / Boss:
- Ante 1 → Open (standard)
- Ante 2 → Risk (standard for now; skip mechanic is a separate change)
- Ante 3 → Boss (halved lock windows)

## AnteConfig changes

Add two fields to `AnteConfig` (`.tres` resource):
- `round_names: Array[String] = ["Open", "Risk", "Boss"]` — parallel to `targets`, drives UI label
- `boss_window_scale: float = 0.5` — applied to lock window duration on boss antes
- `boss_antes: Array[int] = [3]` — 1-based ante indices that receive the boss modifier

## ThrowScene changes

On ante load, compute the effective window duration:
```gdscript
var _effective_window_s: float  # set per-ante in _start_ante()
```

For boss antes: `_effective_window_s = _config.lock_window_duration_s * _ante_config.boss_window_scale`
For non-boss: `_effective_window_s = _config.lock_window_duration_s`

Pass an `_effective_config` (a `duplicate()` of `_config` with `lock_window_duration_s` overridden) to `ThrowController._init()`. This requires no change to ThrowController.

Show round type label: `"ANTE %d — %s ROUND"` format, using `_ante_config.round_names`.

## ThrowController: no changes needed

The controller uses `_config.lock_window_duration_s`; passing a duplicated config with a modified value is sufficient.

## ThrowScene: effective duration tracking

`ThrowScene` also reads `_config.lock_window_duration_s` for:
1. Timer bar fraction: `_controller.time_remaining() / _config.lock_window_duration_s`
2. Score call: `_scoring.score(result, ..., _config.lock_window_duration_s, ...)`

Both must use `_effective_window_s` instead of `_config.lock_window_duration_s`.
