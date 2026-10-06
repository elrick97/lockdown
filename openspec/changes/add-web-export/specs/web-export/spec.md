## ADDED Requirements

### Requirement: Repeatable single-threaded web build
The project SHALL have a `Web` export preset that builds headlessly with `tools/build_web.ps1` (Godot `--export-release "Web"`) into `build/web/index.html`. The build SHALL be single-threaded (`variant/thread_support = false`) so it runs on any static host without cross-origin-isolation headers, and SHALL include both desktop (S3TC/BPTC) and mobile (ETC2/ASTC) texture formats. Named values (current): export path `build/web/index.html`, engine `4.6.3.stable`.

#### Scenario: Local build
- **WHEN** `tools/build_web.ps1` runs on a machine with Godot 4.6.3 and its web templates
- **THEN** `build/web/` contains `index.html`, the `.wasm`, `.pck` and `.js` files, and the script exits 0

#### Scenario: Runs without isolation headers
- **WHEN** `build/web/` is served by a plain static server that sends no COOP/COEP headers
- **THEN** the game loads and plays in a desktop browser

### Requirement: Web build excludes dev-only content
The `Web` preset SHALL exclude `tests/*`, `addons/gut/*`, `assets/art_direction/*`, `tools/*`, `openspec/*`, `build/*` and `.gutconfig.json` from the exported pack, so players download only game content.

#### Scenario: Pack stays lean
- **WHEN** the web build is exported
- **THEN** the `.pck` contains no files from the excluded folders

### Requirement: The web build plays on desktop and phone browsers
The exported game SHALL keep its portrait 1080×2400 layout (letterboxed in wider windows), accept mouse and touch input (touch arrives as emulated mouse events), and apply focus-loss protection when the browser tab loses focus (throw-loop spec).

#### Scenario: Phone-sized browser
- **WHEN** the build is opened in a 390×844 viewport and the player taps THROW, then taps a die during a lock window
- **THEN** the throw starts and the die locks

#### Scenario: Tab switch
- **WHEN** the browser tab loses focus during a lock window and regains it
- **THEN** the game pauses behind the cover and resumes with the 3-2-1 countdown

### Requirement: Deployed to GitHub Pages from main
A GitHub Actions workflow SHALL, on every push to `main`, check out the repository with only the game's LFS assets (`assets/dice/*`; the excluded style-frame archive is not downloaded and is kept out of the import), download the official Godot 4.6.3 editor and export templates, export the `Web` preset, and deploy `build/web/` to GitHub Pages using only GitHub's own actions. Build output SHALL NOT be committed.

#### Scenario: Push deploys
- **WHEN** a commit is pushed to `main`
- **THEN** the workflow exports the web build and the Pages site serves it

#### Scenario: Broken export doesn't deploy
- **WHEN** the export step fails
- **THEN** the workflow fails and the previously deployed version stays live
