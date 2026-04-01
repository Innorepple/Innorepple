Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
  # Ensure we run from project root
  $projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
  Set-Location $projectRoot

  Write-Host "Reading GEMINI_API_KEY from .env..."
  $envPath = Join-Path $projectRoot ".env"
  if (-not (Test-Path $envPath)) { throw ".env not found at $envPath" }

  $match = Select-String -Path $envPath -Pattern '^\s*(?:export\s+)?GEMINI_API_KEY\s*=\s*(.*)$' | Select-Object -First 1
  if (-not $match) { throw "GEMINI_API_KEY not set in .env" }

  $val = $match.Matches[0].Groups[1].Value.Trim()
  if ($val.StartsWith('"') -and $val.EndsWith('"')) { $val = $val.Trim('"') }
  if ($val.StartsWith("'") -and $val.EndsWith("'")) { $val = $val.Trim("'") }
  $env:GEMINI_API_KEY = $val
  Write-Host "Loaded GEMINI_API_KEY into environment for this process."

  # Locate flutter binary
  $flutter = "C:\\flutter\\bin\\flutter"
  if (-not (Test-Path $flutter)) { $flutter = "flutter" }
  Write-Host "Using flutter at: $flutter"

  # Optional Java 17 check
  try {
    $javaVersion = (& java -version) 2>&1 | Select-Object -First 1
    if ($javaVersion -notmatch 'version "17\.') {
      Write-Warning "Java 17 not detected. If build fails, set JAVA_HOME to a JDK 17 and ensure java.exe is on PATH."
    }
  } catch {
    Write-Warning "Java not found in PATH. If build fails, install JDK 17 and set JAVA_HOME."
  }

  Write-Host "Running flutter pub get..."
  & $flutter pub get

  Write-Host "Building release APK..."
  & $flutter build apk --release --dart-define="GEMINI_API_KEY=$env:GEMINI_API_KEY"

  $apkPath = Join-Path $projectRoot "build\\app\\outputs\\flutter-apk\\app-release.apk"
  if (Test-Path $apkPath) {
    Write-Host "APK built successfully: $apkPath"
  } else {
    Write-Host "Build finished. Check build\\app\\outputs\\flutter-apk for APK artifacts."
  }

  exit 0
} catch {
  Write-Error $_
  exit 1
}
