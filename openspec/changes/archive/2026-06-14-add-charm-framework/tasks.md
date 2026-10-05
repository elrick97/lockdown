## 1. Headless data layer

- [x] 1.1 Create `scripts/charm_effect.gd` (`Resource`) — `@export var display_name: String`, `@export var description: String`, `@export var cost: int`; four no-op hook methods: `on_throw(ctx)`, `on_window(window_index, ctx)`, `on_lock(die_index, face, window_index, ctx)`, `on_score(breakdown, ctx)`
- [x] 1.2 Create `scripts/charm_context.gd` (`RefCounted`) — fields: `locked_faces: Array[int]`, `locked_windows: Array[int]`, `window_times: Array[float]`, `current_window: int`, `die_index: int`, `round_total: int`, `throw_number: int`; static factory `make(...)` that copies arrays defensively
- [x] 1.3 Create `scripts/charm_inventory.gd` (`RefCounted`) — `MAX_SLOTS = 5`, `add_charm(c: CharmEffect) -> bool`, `iter_charms() -> Array[CharmEffect]`, `is_full() -> bool`
- [x] 1.4 Add `charm_chips: int = 0` and `charm_mult: float = 0.0` to `scripts/score_breakdown.gd`

## 2. RngService shop stream

- [x] 2.1 Add `get_shop() -> RandomNumberGenerator` to `scripts/rng_service.gd` — seeded from `run_seed + SHOP_OFFSET` (a fixed constant, e.g. `0xCAFE`), initialised in `start_run()` alongside the existing streams

## 3. ScoringEngine charm hooks

- [x] 3.1 Extend `ScoringEngine.score()` to accept an optional `inventory: CharmInventory = null` parameter; after best-partition is chosen but before final multiply, build a `CharmContext` and call each charm's `on_score(breakdown, ctx)` in slot order
- [x] 3.2 GUT tests: `test_charm_hooks.gd` — headless tests: no-charm baseline unchanged, single charm adds chips, single charm adds mult, two charms stack additively, hooks fire in slot order (slot 0 value visible to slot 1)

## 4. ThrowController charm hooks

- [x] 4.1 Extend `ThrowController.__init__()` to accept `inventory: CharmInventory = null`; store as `_inventory`
- [x] 4.2 Fire `on_throw` hooks: after RNG determines faces in `start_throw()`, build `CharmContext` (`current_window = 0`, `die_index = -1`) and call each charm's `on_throw`
- [x] 4.3 Fire `on_window` hooks: when a window opens in the state machine, build `CharmContext` (`current_window = window_index`) and call each charm's `on_window`
- [x] 4.4 Fire `on_lock` hooks: in `lock_die()` and force-lock logic, build `CharmContext` (`current_window`, `die_index`, `face`) and call each charm's `on_lock`
- [x] 4.5 GUT tests: extend `test_throw_controller.gd` — verify `on_throw` fires once, `on_window` fires 3 times in a full throw, `on_lock` fires per die; verify no hooks fired when inventory is null

## 5. RunCoordinator wiring

- [x] 5.1 Add `inventory: CharmInventory` field to `scripts/run_coordinator.gd`; initialise to a fresh `CharmInventory` in `start_run()`
- [x] 5.2 Pass `RunCoordinator.inventory` into `ThrowController` constructor in `ThrowScene._ready()`
- [x] 5.3 Pass `RunCoordinator.inventory` into `ScoringEngine.score()` call in `ThrowScene._on_resolved()`

## 6. Proof charms

- [x] 6.1 Create `scripts/charms/charm_quick_draw.gd` — extends `CharmEffect`; `on_score`: if all `ctx.locked_windows` entries equal 1 (all locked in window 1), add `breakdown.charm_mult += 2.0`
- [x] 6.2 Create `scripts/charms/charm_loaded.gd` — extends `CharmEffect`; `on_score`: for each locked face equal to 6, add `breakdown.charm_chips += 6` (net 12 pips: base 6 + 6 bonus)
- [x] 6.3 Create `scripts/charms/charm_snake_charmer.gd` — extends `CharmEffect`; `on_score`: if the locked set contains exactly two 1s and the base combo is a Pair, replace `breakdown.combo_mult` with 4 and zero `breakdown.combo_chips` (overrides standard pair scoring — adds a `combo_mult` field to ScoreBreakdown so charms can override it)
- [x] 6.4 Create `.tres` resources: `resources/charms/quick_draw.tres`, `resources/charms/loaded.tres`, `resources/charms/snake_charmer.tres` — each an instance of the corresponding script with `display_name`, `description`, and `cost` filled in
- [x] 6.5 GUT tests: `test_proof_charms.gd` — headless tests: Quick Draw gives ×2 charm_mult when all window-1 locks, no bonus when not; Loaded adds +6 chips per six, zero bonus when no sixes; Snake Charmer replaces pair scoring on two 1s

## 7. ShopScene integration

- [x] 7.1 Add `_build_offer_pool() -> Array[CharmEffect]` to `scripts/shop_scene.gd` — returns array of the 3 proof charm resources (preloaded); shuffle order using `RngService.shuffle_shop()`
- [x] 7.2 Update `_refresh_offers()` to draw from the pool instead of stub `ShopOffer` objects; each card shows `charm.display_name`, `charm.description`, and `charm.cost`
- [x] 7.3 Update `_on_buy_pressed()`: call `RunCoordinator.inventory.add_charm(charm)` on successful spend; disable all BUY buttons when `RunCoordinator.inventory.is_full()`
- [x] 7.4 Update `_update_button_states()` to also disable all BUY buttons when inventory is full

## 8. Verify on device

- [x] 8.1 Build APK and install on Pixel 9 — open the shop, confirm Quick Draw / Loaded / Snake Charmer appear with correct names and costs
- [x] 8.2 Buy Quick Draw, press CONTINUE — clear an ante with all locks in window 1, confirm score is visibly higher than without the charm
- [x] 8.3 Buy Loaded, confirm 6-faces score noticeably more; buy Snake Charmer, confirm pair-of-1s scores ×4 mult
- [x] 8.4 Fill all 5 charm slots — confirm BUY buttons disable and shop shows correct state
