param(
    [Parameter(Mandatory)]
    [string]$Source,
    [switch]$Write
)

$ErrorActionPreference = 'Stop'
$destination = Join-Path (Split-Path -Parent $PSScriptRoot) 'data/dictionary'
$alphabet = 'abcdefghijklmnñopqrstuvwxyz'
$accented = 'áéíóúü'
$plain = 'aeiouu'

foreach ($letter in $alphabet.ToCharArray()) {
    $file = @(Get-ChildItem -LiteralPath $Source -File -Filter '*.json' |
        Where-Object { $_.BaseName -match "letra $letter$" })
    if ($file.Count -ne 1) { throw "Se esperaba un archivo para la letra $letter." }
    $raw = (Get-Content -Raw -LiteralPath $file[0].FullName).Trim()
    # A–I contain comma-separated objects without an enclosing array.
    if ($raw -match '^\{\s*"palabra"') { $raw = '[' + $raw + ']' }
    $parsed = ConvertFrom-Json -InputObject $raw
    $rows = if ($parsed -is [pscustomobject] -and $null -ne $parsed.entradas) { $parsed.entradas } else { $parsed }
    $filePath = Join-Path $destination "dictionary_$letter.json"
    $entries = [System.Collections.Generic.List[object]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    if (Test-Path -LiteralPath $filePath) {
        foreach ($entry in (Get-Content -Raw -LiteralPath $filePath | ConvertFrom-Json)) {
            $entries.Add($entry)
            [void]$seen.Add($entry.palabra.Trim().Normalize())
        }
    }
    $before = $entries.Count
    $repeated = @{}
    foreach ($group in ($rows | Group-Object significado | Where-Object Count -ge 4)) {
        $repeated[$group.Name.Trim()] = $true
    }
    foreach ($row in $rows) {
        $word = ([string]$row.palabra).Trim().Normalize()
        $kind = ([string]$row.tipo).Trim()
        $meaning = ([string]$row.significado).Trim()
        if (!$word -or !$kind -or !$meaning) { continue }
        $initial = $word.Substring(0, 1).ToLowerInvariant()
        $index = $accented.IndexOf($initial)
        if ($index -ge 0) { $initial = $plain[$index] }
        if ($initial -ne $letter -or $repeated.ContainsKey($meaning)) { continue }
        if ($meaning -match '^Forma (plural|femenina|masculina) de «|^(Palabra|Expresión|Término|Nombre|Persona) .{0,90}(relacionad[oa]|vinculad[oa]|conocid[oa]) (con|por) (la|el|los|las|su) (música|informática|historia|ciencia|arte|trabajo|literatura|cultura|deporte|medidas|tecnología|lugares)') { continue }
        if ($seen.Add($word)) {
            $entries.Add([ordered]@{ palabra = $word; tipo = $kind; significado = $meaning })
        }
    }
    if ($entries.Count -eq 0) { Write-Warning "No quedaron entradas utilizables para $letter." }
    if ($Write -and $entries.Count -ne $before) {
        $lines = $entries | ForEach-Object { '  ' + (ConvertTo-Json -InputObject $_ -Compress) }
        Set-Content -LiteralPath $filePath -Encoding utf8NoBOM -Value ('[' + "`n" + ($lines -join ",`n") + "`n]")
    }
    '{0}: {1} existentes + {2} nuevas ({3} filas de origen)' -f $letter, $before, ($entries.Count - $before), @($rows).Count
}
