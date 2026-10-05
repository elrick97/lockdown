# Design: add-juice-pass

## 1. Lock haptics

In `throw_scene.gd._on_die_locked()`, after the tumbler call:
```gdscript
func _on_die_locked(die_index: int, _window_index: int) -> void:
    _tumbler.lock_die(die_index, _controller.faces[die_index])
    Input.vibrate_handheld(30)  # 30 ms, perceptible but not overbearing
```

Android-only; no-ops silently on other platforms. No guard needed.

## 2. Screen shake

ThrowScene adds a `_shake_offset: Vector2` property and applies it in `_process` to a dedicated `_shake_pivot: Control` that wraps the scene content. Because our layout is Control-anchor-driven (not position-driven), the cleanest approach is to tween the `_result.position` modulation directly — not the root — since the result label is the focal point of the shake.

Actually simpler: use Godot's `get_viewport().get_camera_2d()` — but there's no Camera2D in the scene. Use a plain Tween on `position.x` of the ThrowScene root (Control nodes support position). Except `_apply_layout()` uses anchors+offsets and resets on viewport resize, so tweeening `position` won't conflict (anchors define the rect, `position` is the rect's own offset within its parent).

**Implementation**: add `_shake_offset: Vector2` and a helper:
```gdscript
var _shake_offset: Vector2 = Vector2.ZERO

func _screen_shake(amplitude: float, duration: float) -> void:
    var tween := create_tween()
    var steps := 6
    for i in steps:
        var t := duration / steps
        var sign := 1.0 if i % 2 == 0 else -1.0
        var decay := 1.0 - float(i) / steps
        tween.tween_property(self, "position",
            Vector2(sign * amplitude * decay, 0.0), t / 2.0)
        tween.tween_property(self, "position", Vector2.ZERO, t / 2.0)
```

Call in `_on_resolved()` when `breakdown.combos.size() > 0`, AFTER building the cascade:
```gdscript
if not breakdown.combos.is_empty():
    _screen_shake(8.0, 0.25)
```

## 3. Audio stubs

```gdscript
@onready var _sfx_lock: AudioStreamPlayer = $SfxLock
@onready var _sfx_combo: AudioStreamPlayer = $SfxCombo
```

Added to `throw_scene.tscn` as children with `stream = null`. Play calls:
- `_on_die_locked()`: `if _sfx_lock and _sfx_lock.stream: _sfx_lock.play()`
- In `_on_resolved()` when combos found: `if _sfx_combo and _sfx_combo.stream: _sfx_combo.play()`

Without audio files assigned in the .tscn, these are no-ops. Audio designer drops in a file, assigns in editor, and it works.

## 4. File changes

| File | Change |
|------|--------|
| `scenes/throw/throw_scene.gd` | Add `_screen_shake()`, `_sfx_lock`/`_sfx_combo` @onready, haptic in `_on_die_locked`, shake + sfx in `_on_resolved` |
| `scenes/throw/throw_scene.tscn` | Add SfxLock and SfxCombo AudioStreamPlayer children |
