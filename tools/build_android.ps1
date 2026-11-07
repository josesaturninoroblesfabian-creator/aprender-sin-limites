param(
    [string]$Godot = "C:\Users\USUARIO\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe",
    [string]$JdkRoot = (Join-Path $env:LOCALAPPDATA 'Android\jdk-17'),
    [string]$Output = "",
    # Clave de firma de la versión publicada. Se guarda FUERA del repositorio:
    # consérvala, porque Android solo instala actualizaciones firmadas con la misma clave.
    [string]$Keystore = (Join-Path $env:USERPROFILE '.android\aprende-sin-limites-release.keystore'),
    [string]$KeyAlias = 'aprende'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path -LiteralPath $Godot)) {
    throw "No se encontró Godot en '$Godot'. Pasa la ruta con -Godot."
}
if (-not (Test-Path (Join-Path $JdkRoot 'bin\keytool.exe'))) {
    throw "No se encontró el JDK 17 en '$JdkRoot'. Ejecuta antes tools\setup_android_sdk.ps1."
}
$env:JAVA_HOME = $JdkRoot
$env:Path = (Join-Path $JdkRoot 'bin') + ';' + $env:Path

# Godot exige la ruta del JDK en la Configuración del Editor (Exportar → Android).
$editorSettings = Get-ChildItem (Join-Path $env:APPDATA 'Godot') -Filter 'editor_settings-4*.tres' -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -First 1
if ($editorSettings) {
    $jdkSetting = $JdkRoot.Replace('\', '/')
    $text = Get-Content -LiteralPath $editorSettings.FullName -Raw -Encoding UTF8
    if ($text -match 'export/android/java_sdk_path = ""') {
        $text = $text.Replace('export/android/java_sdk_path = ""', "export/android/java_sdk_path = `"$jdkSetting`"")
        [System.IO.File]::WriteAllText($editorSettings.FullName, $text, (New-Object System.Text.UTF8Encoding $false))
        Write-Host "Ruta del JDK guardada en $($editorSettings.Name)"
    }
}

if ([string]::IsNullOrWhiteSpace($Output)) {
    $Output = Join-Path $projectRoot 'builds\android\AprendeSinLimites.apk'
}
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Output) | Out-Null

# Contraseña de la clave: variable de entorno o archivo local junto a la clave.
$passwordFile = "$Keystore.password.txt"
$password = $env:APRENDE_KEYSTORE_PASSWORD
if ([string]::IsNullOrWhiteSpace($password) -and (Test-Path -LiteralPath $passwordFile)) {
    $password = (Get-Content -LiteralPath $passwordFile -Raw).Trim()
}
if (-not (Test-Path -LiteralPath $Keystore)) {
    if ([string]::IsNullOrWhiteSpace($password)) {
        $bytes = New-Object byte[] 24
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        $password = [Convert]::ToBase64String($bytes) -replace '[^A-Za-z0-9]', ''
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Keystore) | Out-Null
    Write-Host "Creando clave de firma: $Keystore"
    & keytool -genkeypair -keystore $Keystore -storepass $password -keypass $password -alias $KeyAlias `
        -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Aprende sin Limites, O=Aprende sin Limites, C=PE" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la clave de firma.' }
    Set-Content -LiteralPath $passwordFile -Value $password -NoNewline
}
if ([string]::IsNullOrWhiteSpace($password)) {
    throw "Falta la contraseña de la clave. Define APRENDE_KEYSTORE_PASSWORD o crea $passwordFile."
}

# Godot lee la firma de release desde estas variables, sin guardarla en el proyecto.
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $Keystore
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $KeyAlias
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $password

Write-Host 'Importando recursos (incluye texturas ETC2/ASTC para Android)...'
& $Godot --headless --path $projectRoot --editor --quit
if ($LASTEXITCODE -ne 0) { throw "Falló la importación de recursos (código $LASTEXITCODE)." }

Write-Host "Exportando APK de Android a: $Output"
if (Test-Path -LiteralPath $Output) { Remove-Item -LiteralPath $Output -Force }
& $Godot --headless --path $projectRoot --export-release 'Android' $Output
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Output)) {
    throw 'Falló la exportación del APK de Android.'
}

$apksigner = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Android\Sdk\build-tools') -Recurse -Filter apksigner.bat |
    Sort-Object FullName -Descending | Select-Object -First 1
if ($apksigner) {
    $verifyOutput = & $apksigner.FullName verify --print-certs $Output 2>&1
    if ($LASTEXITCODE -ne 0) { $verifyOutput; throw 'El APK no pasó la verificación de firma.' }
    $verifyOutput | Select-Object -First 1
}
$sizeMb = [Math]::Round((Get-Item -LiteralPath $Output).Length / 1MB, 2)
Write-Host "¡APK generado! $Output ($sizeMb MB)"
