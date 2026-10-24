param([switch]$Overwrite)

# Backwards-compatible entry point; all llama voices now use the neural generator.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$pythonPath = Join-Path $projectRoot '.godot/voice-tools/Scripts/python.exe'
if (-not (Test-Path -LiteralPath $pythonPath)) {
    throw 'Prepare the voice environment first. See docs/MENUS_MATEMATICOS.md. Running the game does not require Python.'
}
$voiceArguments = @((Join-Path $PSScriptRoot 'generate_llama_voice.py'), '--sections', 'numbers')
if ($Overwrite) { $voiceArguments += '--overwrite' }
& $pythonPath @voiceArguments
if ($LASTEXITCODE -ne 0) { throw 'Neural voice generation failed.' }
