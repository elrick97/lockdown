# Headless GUT test run. Exits non-zero on any failure (CI gate).
$projectRoot = Split-Path $PSScriptRoot -Parent

$godot = Get-Command godot_console.exe -ErrorAction SilentlyContinue
if ($godot) { $godot = $godot.Source } else { $godot = "C:\Tools\Godot\godot_console.exe" }
if (-not (Test-Path $godot)) { Write-Error "godot_console.exe not found on PATH or at C:\Tools\Godot"; exit 1 }

# Always refresh the import cache: new class_name scripts aren't visible to
# tests until the global class cache is rebuilt.
& $godot --headless --path $projectRoot --import | Out-Null

& $godot --headless --path $projectRoot -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
exit $LASTEXITCODE
