# Genera el APK release de Great Memories y deja SOLO ese APK en build\app\outputs\flutter-apk\.
# Ver GENERAR-APK.md. Uso (desde la raiz del repo):
#   powershell -ExecutionPolicy Bypass -File mobile\build-apk.ps1              # arm64 (casi todos los celulares)
#   powershell -ExecutionPolicy Bypass -File mobile\build-apk.ps1 -Universal   # un APK para cualquier celular (mas pesado)
param([switch]$Universal)

$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
  function Invoke-Native { & $args[0] @($args | Select-Object -Skip 1); if ($LASTEXITCODE) { throw "Fallo: $args" } }

  Invoke-Native flutter pub get
  # lib/generated/ no esta versionado; sin esto no compila
  Invoke-Native dart run easy_localization:generate -S ../i18n
  Invoke-Native dart run bin/generate_keys.dart

  # flutter-apk\ acumula APKs de builds anteriores; se vacia para que solo quede el nuevo
  $out = 'build\app\outputs\flutter-apk'
  if (Test-Path $out) { Remove-Item "$out\*.apk", "$out\*.sha1" }

  if ($Universal) {
    Invoke-Native flutter build apk --release
    $apk = "$out\app-release.apk"
  } else {
    Invoke-Native flutter build apk --release --split-per-abi --target-platform android-arm64
    $apk = "$out\app-arm64-v8a-release.apk"
  }

  $version = (Select-String -Path pubspec.yaml -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value
  $mb = [math]::Round((Get-Item $apk).Length / 1MB)
  Write-Host ""
  Write-Host "APK listo (version $version, $mb MB):" -ForegroundColor Green
  Write-Host "  $((Resolve-Path $apk).Path)"
  if (-not (Test-Path 'android\key.jks')) {
    Write-Host "Aviso: sin mobile\android\key.jks el APK queda firmado con la llave debug de ESTA PC." -ForegroundColor Yellow
  }
} finally {
  Pop-Location
}
