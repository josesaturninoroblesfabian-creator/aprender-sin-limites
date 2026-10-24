param(
    [string]$VoiceName = 'Raul',
    [switch]$Overwrite
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$catalogPath = Join-Path $projectRoot 'data/audio/voice_lines.json'
$catalog = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
$voice = New-Object -ComObject SAPI.SpVoice
$selectedToken = $null
foreach ($registryPath in @('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices', 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech\Voices')) {
    $category = New-Object -ComObject SAPI.SpObjectTokenCategory
    $category.SetId($registryPath, $false)
    $tokens = $category.EnumerateTokens()
    for ($index = 0; $index -lt $tokens.Count; $index++) {
        $token = $tokens.Item($index)
        $language = $token.GetAttribute('Language')
        $isSpanish = @($language -split ';' | Where-Object { (([Convert]::ToInt32($_, 16)) -band 0x3ff) -eq 10 }).Count -gt 0
        if ($isSpanish -and $token.GetAttribute('Gender') -eq 'Male' -and $token.GetDescription() -like "*$VoiceName*") {
            $selectedToken = $token
            break
        }
    }
    if ($selectedToken) { break }
}
if (-not $selectedToken) { throw "No installed male Spanish voice matches '$VoiceName'. No voice pack was generated." }
$voice.Voice = $selectedToken
$voice.Rate = -1
$voice.Volume = 100
$generated = 0
foreach ($entry in $catalog.clips.PSObject.Properties) {
    $relativePath = $entry.Value.path -replace '^res://', ''
    $outputPath = [IO.Path]::GetFullPath((Join-Path $projectRoot $relativePath))
    $allowedFolder = [IO.Path]::GetFullPath((Join-Path $projectRoot 'assets/audio/voice_pack')) + [IO.Path]::DirectorySeparatorChar
    if (-not $outputPath.StartsWith($allowedFolder, [StringComparison]::OrdinalIgnoreCase)) { throw 'Voice output must stay inside assets/audio/voice_pack.' }
    if ((Test-Path -LiteralPath $outputPath) -and -not $Overwrite) { continue }
    New-Item -ItemType Directory -Path (Split-Path -Parent $outputPath) -Force | Out-Null
    $temporaryPath = $outputPath + '.tmp'
    $stream = New-Object -ComObject SAPI.SpFileStream
    try {
        $stream.Open($temporaryPath, 3, $false)
        $voice.AudioOutputStream = $stream
        $null = $voice.Speak([string]$entry.Value.text, 0)
    }
    finally { $stream.Close() }
    Move-Item -LiteralPath $temporaryPath -Destination $outputPath -Force
    $generated++
}
@{
    provider = 'Microsoft Windows Speech (installed OneCore/SAPI voice)'
    voice = $selectedToken.GetDescription()
    language = $selectedToken.GetAttribute('Language')
    gender = $selectedToken.GetAttribute('Gender')
    rate = -1
    generation = 'Local speech synthesis; no external service or recording of a person'
    catalog = 'data/audio/voice_lines.json'
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $projectRoot 'data/audio/voice_pack_provenance.json') -Encoding UTF8
Write-Host "Generated $generated clips using $($selectedToken.GetDescription()). Import the project in Godot afterwards."
