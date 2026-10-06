## 1. Build

- [ ] 1.1 `Web` preset in `export_presets.cfg` (single-threaded, desktop + mobile textures, exclusions, adaptive canvas)
- [ ] 1.2 `tools/build_web.ps1` (headless import + export to `build/web/`, non-zero exit on failure)

## 2. Local verification

- [ ] 2.1 Serve `build/web/` on localhost without isolation headers; game loads in the built-in browser
- [ ] 2.2 Desktop and 390×844 viewport: THROW, lock a die, a full throw resolves; tab-switch pause/resume
- [ ] 2.3 `.pck` holds none of the excluded folders; GUT suite green

## 3. Deploy

- [ ] 3.1 `.github/workflows/pages.yml` (official Godot download, LFS checkout, export, Pages deploy)
- [ ] 3.2 Repo public; Pages source = GitHub Actions; first deploy green and the site loads
