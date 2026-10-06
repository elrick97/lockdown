## 1. Build

- [x] 1.1 `Web` preset in `export_presets.cfg` (single-threaded, desktop + mobile textures, exclusions, adaptive canvas)
- [x] 1.2 `tools/build_web.ps1` (headless import + export to `build/web/`, non-zero exit on failure)

## 2. Local verification

- [x] 2.1 Serve `build/web/` on localhost without isolation headers; game loads in the built-in browser
- [x] 2.2 Desktop and 375×812 viewport: THROW, lock a die, a full throw resolves; blur/focus pause and resume. Found and fixed: on the web a tab/canvas blur arrives only as a window focus notification, which the throw scene ignored (no pause); it now handles both, and the resume countdown step is capped so a hidden tab's long first frame can't skip the 3-2-1
- [x] 2.3 `.pck` file table holds none of the excluded folders (also excludes `build/` and `.gutconfig.json`); clean-clone CI rehearsal pack: 223 files, 1.27 MB; GUT suite green (179)

## 3. Deploy

- [x] 3.1 `.github/workflows/pages.yml` (official Godot download, cached; dice-only LFS pull so the excluded art archive never costs LFS bandwidth; export; Pages deploy)
- [x] 3.2 Repo public; Pages source = GitHub Actions; first deploy green in 1m12s; https://elrick97.github.io/lockdown/ loads and plays (throw, lock, score) on desktop and phone viewports
