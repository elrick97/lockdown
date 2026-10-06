## 1. Assets

- [x] 1.1 `export_production_table()`: felt + backdrop to `res://assets/table/`; lossy import; `check_assets.py` covers them

## 2. Integration

- [x] 2.1 `SmokeOverlay` (grain + vignette shader, ignores input)
- [x] 2.2 Backdrop + felt + overlay on throw, shop and start screens
- [x] 2.3 Tests: overlay ignores input; felt fills the tray; backdrop fills the screen

## 3. Verification

- [x] 3.1 GUT suite green (191); playthrough green with screenshots (boss timing check made frame-independent: it measured from the frame after the window opened); `perf_dice.gd` with table + overlay: 0.67 ms avg, 1.39 ms p95, 2.69 ms worst (desktop stand-in). Web pack 1.3 MB
