param(
    [string]$Godot = "C:\Users\USUARIO\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe",
    [string]$Output = ""
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path -LiteralPath $Godot)) {
    $cmd = Get-Command godot* -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) {
        $Godot = $cmd.Source
    } else {
        throw "No se encontró el ejecutable de Godot en '$Godot'. Pasa la ruta con -Godot 'C:\ruta\a\Godot_console.exe'."
    }
}

if ([string]::IsNullOrWhiteSpace($Output)) {
    $Output = Join-Path $projectRoot "builds\windows\Aprende sin Limites.exe"
}

$outputDir = Split-Path -Parent $Output
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Write-Host "Importando recursos nuevos en Godot..."
& $Godot --headless --path $projectRoot --editor --quit
if ($LASTEXITCODE -ne 0) {
    throw "Falló la importación de recursos en Godot (código $LASTEXITCODE)."
}

Write-Host "Exportando aplicación de Windows (.exe) a: $Output"
& $Godot --headless --path $projectRoot --export-release "Windows Desktop" $Output
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Output)) {
    throw "Falló la exportación del ejecutable de Windows."
}

$fileInfo = Get-Item -LiteralPath $Output
$sizeMb = [Math]::Round($fileInfo.Length / 1MB, 2)
Write-Host "¡Exportación completada con éxito! Archivo: $($fileInfo.FullName) ($sizeMb MB)"
