extends GutTest
## Verifies charm on_score hook dispatch in ScoringEngine (charm-effect spec,
## combo-scoring spec). All tests are headless; no scene tree required.

const WINDOW := 2.5

var _config: ScoringConfig
var _engine: ScoringEngine


func before_each() -> void:
	_config = ScoringConfig.new()
	_engine = ScoringEngine.new()


func _result(faces: Array) -> ThrowResult:
	var r := ThrowResult.new()
	for f in faces:
		r.faces.append(int(f))
	for i in faces.size():
		r.locked_order.append(i)
		r.lock_windows.append(1)  # default: all locked in window 1
	return r


# --- stub charms -----------------------------------------------------------

## Adds a fixed amount to charm_chips.
class ChipsCharm extends CharmEffect:
	var amount: int = 0
	func on_score(bd: ScoreBreakdown, _ctx: CharmContext) -> void:
		bd.charm_chips += amount


## Adds a fixed amount to charm_mult.
class MultCharm extends CharmEffect:
	var amount: float = 0.0
	func on_score(bd: ScoreBreakdown, _ctx: CharmContext) -> void:
		bd.charm_mult += amount


## Reads charm_chips written by a prior charm and records whether it saw the value.
class ObserverCharm extends CharmEffect:
	var saw_chips: int = -1
	func on_score(bd: ScoreBreakdown, _ctx: CharmContext) -> void:
		saw_chips = bd.charm_chips


# --- tests -----------------------------------------------------------------

func test_no_charm_baseline_unchanged() -> void:
	var bd := _engine.score(_result([4, 4]), _config, WINDOW, false)
	assert_eq(bd.final_score, 18, "no charm: (8 + 10) x 1 x 1.0 = 18")
	assert_eq(bd.charm_chips, 0)
	assert_almost_eq(bd.charm_mult, 0.0, 0.001)


func test_single_charm_adds_chips() -> void:
	var charm := ChipsCharm.new()
	charm.amount = 20
	var inv := CharmInventory.new()
	inv.add_charm(charm)
	var bd := _engine.score(_result([4, 4]), _config, WINDOW, false, inv)
	assert_eq(bd.charm_chips, 20)
	assert_eq(bd.final_score, 38, "(8 + 10 + 20) x 1 x 1.0 = 38")


func test_single_charm_adds_mult() -> void:
	var charm := MultCharm.new()
	charm.amount = 2.0
	var inv := CharmInventory.new()
	inv.add_charm(charm)
	var bd := _engine.score(_result([4, 4]), _config, WINDOW, false, inv)
	assert_almost_eq(bd.charm_mult, 2.0, 0.001)
	assert_eq(bd.final_score, 54, "(8 + 10) x (1 + 2.0) x 1.0 = 54")


func test_two_charms_stack_additively() -> void:
	var c1 := MultCharm.new(); c1.amount = 1.0
	var c2 := MultCharm.new(); c2.amount = 1.0
	var inv := CharmInventory.new()
	inv.add_charm(c1)
	inv.add_charm(c2)
	var bd := _engine.score(_result([4, 4]), _config, WINDOW, false, inv)
	assert_almost_eq(bd.charm_mult, 2.0, 0.001)
	assert_eq(bd.final_score, 54, "(8 + 10) x (1 + 1.0 + 1.0) x 1.0 = 54")


func test_hooks_fire_in_slot_order() -> void:
	var writer := ChipsCharm.new(); writer.amount = 10
	var observer := ObserverCharm.new()
	var inv := CharmInventory.new()
	inv.add_charm(writer)    # slot 0
	inv.add_charm(observer)  # slot 1 sees slot 0's write
	_engine.score(_result([4, 4]), _config, WINDOW, false, inv)
	assert_eq(observer.saw_chips, 10, "slot 1 sees charm_chips written by slot 0")
