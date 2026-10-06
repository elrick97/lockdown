# Headless web (WebGL 2, single-threaded) release build into build/web/. Exits
# non-zero on failure. Prerequisite: 4.6.3.stable export templates installed via the
# Godot editor (Editor -> Manage Export Templates -> Download and Install).
$projectRoot = Split-Path $PSScriptRoot -Parent
$preset = "Web"
$outDir = Join-Path $projectRoot "build/web"
$outAbs = Join-Path $outDir "index.html"

$godot = Get-Command godot_console.exe -ErrorAction SilentlyContinue
if ($godot) { $godot = $godot.Source } else { $godot = "C:\Tools\Godot\godot_console.exe" }
if (-not (Test-Path $godot)) { Write-Error "godot_console.exe not found on PATH or at C:\Tools\Godot"; exit 1 }

# Fail early and clearly if the single-threaded web template is missing.
$tmpl = Join-Path $env:APPDATA "Godot\export_templates\4.6.3.stable\web_nothreads_release.zip"
if (-not (Test-Path $tmpl)) {
    Write-Error @"
Web export template not found:
  $tmpl
Install it in the Godot editor:
  Editor -> Manage Export Templates -> Download and Install (4.6.3.stable)
"@
    exit 1
}

# Start clean so stale files from an earlier build never ship.
if (Test-Path $outDir) { Remove-Item -Recurse -Force $outDir }
New-Item -ItemType Directory -Path $outDir | Out-Null

# Refresh the import cache first (same reason as the test runner).
& $godot --headless --path $projectRoot --import | Out-Null

& $godot --headless --path $projectRoot --export-release $preset $outAbs
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $outAbs)) {
    Write-Error "Web export failed (exit $LASTEXITCODE). If the message is a blank configuration error, open Project -> Export in the editor to read it."
    exit 1
}
foreach ($f in Get-ChildItem $outDir) { Write-Host ("{0,12:N0}  {1}" -f $f.Length, $f.Name) }
exit 0
