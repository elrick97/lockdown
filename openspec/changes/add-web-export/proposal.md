## Why

The owner wants a playable MVP on the web, hosted on GitHub Pages (directive 2026-10-06; making the repo public is approved). There's no web build today; the only export pipeline is the M0 Android debug APK. A public link is also how strangers will play the slice for the M1 gate and how the devlog shares it. PRD trace: §7 (distribution) and the M4 item "Web demo build". That item is pulled forward by owner directive; it adds a distribution channel, not new gameplay, so it doesn't jump the M1 gate.

**Pillars served:** *One thumb, one screen*: the same portrait game in any phone or desktop browser, nothing to install. *Collect & unlock*: a shareable link that brings players back.

## What Changes

- **Web export preset** (Godot 4.6, GL Compatibility → WebGL 2): **single-threaded**, so it runs on static hosts without the COOP/COEP headers that GitHub Pages can't send. Textures are packed for both desktop (S3TC/BPTC) and mobile (ETC2/ASTC) browsers. The canvas fills the window and the game letterboxes to portrait. Dev-only content stays out of the build: tests, GUT, the style-frame archive and tools.
- **One-command local build:** `tools/build_web.ps1` exports to `build/web/` (gitignored), the same way `tools/build_apk.ps1` builds the APK.
- **Automatic deploy:** a GitHub Actions workflow builds the web export on every push to `main` with the official Godot 4.6.3 release and its export templates, downloaded from godotengine's GitHub releases, and publishes it to GitHub Pages. It uses only GitHub's own actions (`checkout` with LFS, `upload-pages-artifact`, `deploy-pages`) and no third-party actions.
- **Repo goes public** so free GitHub Pages can serve it (owner-approved). Checked first: no keystores, credentials or `.env` files in history.

## Capabilities

### New Capabilities
- `web-export`: the web build (preset, single-threaded, texture formats, exclusions), the local build script, and the Pages deployment.

### Modified Capabilities
- None. Gameplay, presentation and the Android pipeline are unchanged.

## Impact

- `export_presets.cfg` gains a `Web` preset; `tools/build_web.ps1`; `.github/workflows/pages.yml`.
- GitHub: repo visibility → public; Pages source → GitHub Actions.
- Verification is local: the exported build is served from `build/web/` on localhost and played in a browser at desktop and phone viewport sizes (the built-in browser), plus the existing GUT suite.

## Non-goals

- PWA/offline install, custom domain, analytics (PRD: no data collected).
- Audio (owner deferred).
- itch.io upload (the M4 item stays open for that).
- Any gameplay or art change.
