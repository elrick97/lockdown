# Headless GUT test run. Exits non-zero on any failure (CI gate).
$projectRoot = Split-Path $PSScriptRoot -Parent

$godot = Get-Command godot_console.exe -ErrorAction SilentlyContinue
if ($godot) { $godot = $godot.Source } else { $godot = "C:\Tools\Godot\godot_console.exe" }
if (-not (Test-Path $godot)) { Write-Error "godot_console.exe not found on PATH or at C:\Tools\Godot"; exit 1 }

# First run after a fresh clone needs the import step to build the .godot cache.
if (-not (Test-Path "$projectRoot\.godot")) {
    & $godot --headless --path $projectRoot --import
}

& $godot --headless --path $projectRoot -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
exit $LASTEXITCODE
