param(
    [string]$SdkRoot = (Join-Path $env:LOCALAPPDATA 'Android\Sdk'),
    [string]$JdkRoot = (Join-Path $env:LOCALAPPDATA 'Android\jdk-17'),
    [string]$CmdlineToolsVersion = '13114758',
    [string]$BuildTools = '35.0.1',
    [string]$Platform = 'android-35'
)

# Instala en la carpeta del usuario (sin permisos de administrador) lo que Godot
# necesita para exportar a Android: OpenJDK 17 y Android SDK (platform-tools,
# build-tools y la plataforma). Al ejecutarlo se aceptan las licencias del Android SDK.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$downloads = Join-Path $env:TEMP 'aprende-android-setup'
New-Item -ItemType Directory -Force -Path $downloads, $SdkRoot | Out-Null

if (-not (Test-Path (Join-Path $JdkRoot 'bin\java.exe'))) {
    Write-Host 'Descargando Microsoft Build of OpenJDK 17...'
    $jdkZip = Join-Path $downloads 'jdk17.zip'
    & curl.exe -L --fail -o $jdkZip 'https://aka.ms/download-jdk/microsoft-jdk-17-windows-x64.zip'
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo descargar OpenJDK 17.' }
    $jdkExtract = Join-Path $downloads 'jdk17'
    Remove-Item -Recurse -Force $jdkExtract -ErrorAction SilentlyContinue
    Expand-Archive -LiteralPath $jdkZip -DestinationPath $jdkExtract
    $inner = Get-ChildItem $jdkExtract -Directory | Select-Object -First 1
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $JdkRoot) | Out-Null
    Move-Item -LiteralPath $inner.FullName -Destination $JdkRoot
}
Write-Host "JDK 17: $JdkRoot"

$sdkManager = Join-Path $SdkRoot 'cmdline-tools\latest\bin\sdkmanager.bat'
if (-not (Test-Path $sdkManager)) {
    Write-Host 'Descargando Android SDK Command-line Tools...'
    $toolsZip = Join-Path $downloads 'cmdline-tools.zip'
    & curl.exe -L --fail -o $toolsZip "https://dl.google.com/android/repository/commandlinetools-win-$($CmdlineToolsVersion)_latest.zip"
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron descargar las Command-line Tools.' }
    $toolsExtract = Join-Path $downloads 'cmdline-tools'
    Remove-Item -Recurse -Force $toolsExtract -ErrorAction SilentlyContinue
    Expand-Archive -LiteralPath $toolsZip -DestinationPath $toolsExtract
    New-Item -ItemType Directory -Force -Path (Join-Path $SdkRoot 'cmdline-tools') | Out-Null
    Move-Item -LiteralPath (Join-Path $toolsExtract 'cmdline-tools') -Destination (Join-Path $SdkRoot 'cmdline-tools\latest')
}

$env:JAVA_HOME = $JdkRoot
$env:Path = (Join-Path $JdkRoot 'bin') + ';' + $env:Path
Write-Host 'Aceptando licencias e instalando paquetes del SDK...'
$yes = (1..30 | ForEach-Object { 'y' }) -join "`n"
$yes | & $sdkManager --sdk_root=$SdkRoot --licenses | Out-Null
# cmd.exe separa los argumentos por ';', así que cada paquete va entre comillas.
cmd /c "`"$sdkManager`" --sdk_root=`"$SdkRoot`" `"platform-tools`" `"build-tools;$BuildTools`" `"platforms;$Platform`""
if ($LASTEXITCODE -ne 0) { throw 'sdkmanager no pudo instalar los paquetes.' }

$apksigner = Join-Path $SdkRoot "build-tools\$BuildTools\apksigner.bat"
if (-not (Test-Path $apksigner)) { throw "Falta apksigner en $apksigner" }
Write-Host "Android SDK listo en: $SdkRoot"
