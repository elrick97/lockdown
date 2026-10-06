## Context

Godot 4.6.3 is installed locally with web export templates (`web_nothreads_release.zip` included). The project already renders with GL Compatibility, which maps to WebGL 2 in browsers. GitHub Pages serves static files only and can't set COOP/COEP headers, so a threaded build (SharedArrayBuffer) wouldn't start there. The repo uses git LFS for art.

## Decisions

### D1: Single-threaded export
`variant/thread_support=false` uses the no-threads template. The game is light (one SubViewport, ≤8 dice, Labels), so audio/thread latency trade-offs don't matter yet (no audio).

### D2: Texture formats
`vram_texture_compression/for_desktop` and `/for_mobile` both on. Godot picks the format the browser supports at load. The dice atlases are lossless anyway; the rest of the project imports with ETC2/ASTC already enabled.

### D3: Canvas and focus
`html/canvas_resize_policy=2` (adaptive: the canvas fills the page) and the project's `viewport` stretch with `keep` aspect letterbox the portrait game. `html/focus_canvas_on_start=true` so keyboard/mouse focus starts on the game; tab blur maps to Godot's focus-out notification, which the throw scene already handles.

### D4: CI downloads official Godot
The workflow downloads `Godot_v4.6.3-stable_linux.x86_64.zip` and `Godot_v4.6.3-stable_export_templates.tpz` from `github.com/godotengine/godot/releases`, installs the templates into `~/.local/share/godot/export_templates/4.6.3.stable/`, runs `--headless --import` then `--export-release "Web"`. *Alternative:* a third-party Godot CI action/container. Rejected: CLAUDE.md asks before new dependencies, and the official release zips need none. Actions used: `actions/checkout`, `actions/cache` (Godot binary + the web template, keyed on the version), `actions/configure-pages`, `actions/upload-pages-artifact`, `actions/deploy-pages`, all GitHub-owned. LFS: only `assets/dice/*` is pulled (`git lfs pull --include`), and `assets/art_direction/` gets a `.gdignore` in CI before import. A full LFS checkout would pull ~60 MB of style-frame archive per deploy and exhaust the free LFS bandwidth quota within a few weeks.

### D5: Repo visibility
Free GitHub Pages needs a public repository. The owner approved going public (2026-10-06). History was checked for keystores, credentials and `.env` files: none. Release signing stays manual (CLAUDE.md).

### D6: Local verification
`tools/build_web.ps1`, then serve `build/web/` with Python's `http.server` on localhost (no extra headers, mirroring Pages) and drive it in the built-in browser at desktop and 390×844 sizes.

## Risks / Trade-offs

- **WebGL 2 differences from desktop GL** (MSAA on SubViewports, transparency). Mitigation: the local browser check is part of the tasks.
- **First load size** (engine wasm ≈ 35 MB uncompressed, compressed by Pages). Acceptable for an MVP.
- **Public repo exposes history**, including commit author emails and playtester first names in TASKS.md. Flagged to the owner.
