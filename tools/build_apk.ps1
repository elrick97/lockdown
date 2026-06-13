# Headless Android debug APK build. Exits non-zero on failure.
# Prerequisite: 4.6.3.stable export templates installed via the Godot editor
# (Editor -> Manage Export Templates -> Download and Install).
$projectRoot = Split-Path $PSScriptRoot -Parent
$preset = "Android"
$outRel = "build/lockdown.apk"
$outAbs = Join-Path $projectRoot $outRel

$godot = Get-Command godot_console.exe -ErrorAction SilentlyContinue
if ($godot) { $godot = $godot.Source } else { $godot = "C:\Tools\Godot\godot_console.exe" }
if (-not (Test-Path $godot)) { Write-Error "godot_console.exe not found on PATH or at C:\Tools\Godot"; exit 1 }

# Fail early and clearly if the export templates are missing.
$tmpl = Join-Path $env:APPDATA "Godot\export_templates\4.6.3.stable\android_debug.apk"
if (-not (Test-Path $tmpl)) {
    Write-Error @"
Android export template not found:
  $tmpl
Install it in the Godot editor:
  Editor -> Manage Export Templates -> Download and Install (4.6.3.stable)
"@
    exit 1
}

# Ensure the output directory exists.
$buildDir = Join-Path $projectRoot "build"
if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }

# Refresh the import cache first (same reason as the test runner).
& $godot --headless --path $projectRoot --import | Out-Null

# Export the debug APK.
& $godot --headless --path $projectRoot --export-debug $preset $outAbs
if ($LASTEXITCODE -ne 0) { Write-Error "Godot export failed (exit $LASTEXITCODE)"; exit $LASTEXITCODE }

if (-not (Test-Path $outAbs)) { Write-Error "Export reported success but $outRel was not produced"; exit 1 }

$sizeMb = [math]::Round((Get-Item $outAbs).Length / 1MB, 1)
Write-Host "Built $outRel  ($sizeMb MB)"
if ($sizeMb -lt 5) { Write-Warning "APK is suspiciously small ($sizeMb MB) - check the export log above" }
exit 0
