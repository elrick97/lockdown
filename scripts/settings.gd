extends Node
## Player settings (ui-theme spec, add-pause-settings), persisted in
## user://settings.cfg. Presentation only: none of these change scoring, Heat or
## window timing. Autoload "Settings".

signal changed

const PATH := "user://settings.cfg"
const SHAKE_STEPS: Array[float] = [1.0, 0.5, 0.0]
## Cascade speed: tween speed scale; 0 = instant (the cascade auto-skips).
const SPEED_STEPS: Array[float] = [1.0, 2.0, 0.0]

var shake: float = 1.0
var cascade_speed: float = 1.0
var reduced_motion: bool = false
var haptics: bool = true
## Tests set this so they never touch the player's real settings file.
var persist := true


func _ready() -> void:
	load_settings()


## Effective shake multiplier: reduced motion turns every shake off.
func shake_scale() -> float:
	return 0.0 if reduced_motion else shake


func cycle_shake() -> void:
	shake = SHAKE_STEPS[(SHAKE_STEPS.find(shake) + 1) % SHAKE_STEPS.size()]
	_commit()


func cycle_speed() -> void:
	cascade_speed = SPEED_STEPS[(SPEED_STEPS.find(cascade_speed) + 1) % SPEED_STEPS.size()]
	_commit()


func toggle_reduced_motion() -> void:
	reduced_motion = not reduced_motion
	_commit()


func toggle_haptics() -> void:
	haptics = not haptics
	_commit()


func shake_label() -> String:
	return "Screen shake: %d%%" % roundi(shake * 100.0)


func speed_label() -> String:
	return "Score speed: " + ("Instant" if cascade_speed == 0.0 else "%d×" % roundi(cascade_speed))


func motion_label() -> String:
	return "Reduced motion: " + ("On" if reduced_motion else "Off")


func haptics_label() -> String:
	return "Haptics: " + ("On" if haptics else "Off")


func reset_defaults() -> void:
	shake = 1.0
	cascade_speed = 1.0
	reduced_motion = false
	haptics = true
	changed.emit()


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	var s := float(cf.get_value("feel", "shake", 1.0))
	shake = s if SHAKE_STEPS.has(s) else 1.0
	var c := float(cf.get_value("feel", "cascade_speed", 1.0))
	cascade_speed = c if SPEED_STEPS.has(c) else 1.0
	reduced_motion = bool(cf.get_value("feel", "reduced_motion", false))
	haptics = bool(cf.get_value("feel", "haptics", true))
	changed.emit()


func _commit() -> void:
	changed.emit()
	if not persist:
		return
	var cf := ConfigFile.new()
	cf.set_value("feel", "shake", shake)
	cf.set_value("feel", "cascade_speed", cascade_speed)
	cf.set_value("feel", "reduced_motion", reduced_motion)
	cf.set_value("feel", "haptics", haptics)
	cf.save(PATH)
