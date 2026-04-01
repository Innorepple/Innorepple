# PowerShell script to run Flutter app with environment variables
# Usage: .\run-app.ps1 [device]

param(
    [string]$device = "chrome"
)

# Load environment variables from .env file
if (Test-Path ".env") {
    Write-Host "Loading environment variables from .env file..." -ForegroundColor Green
    Get-Content ".env" | ForEach-Object {
        if ($_ -match "^([^#][^=]*?)=(.*)$") {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            if ($value -match "^`"(.*):`"$") {
                $value = $matches[1]
            }
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
            Write-Host "Set $name" -ForegroundColor Yellow
        }
    }
}

# Get the API key
$apiKey = $env:GEMINI_API_KEY
if ([string]::IsNullOrEmpty($apiKey)) {
    Write-Host "Error: GEMINI_API_KEY not found in environment variables" -ForegroundColor Red
    Write-Host "Make sure you have a .env file with GEMINI_API_KEY=your_key_here" -ForegroundColor Yellow
    exit 1
}

Write-Host "Running Flutter app on device: $device" -ForegroundColor Cyan
Write-Host "Using API key: $($apiKey.Substring(0, 8))..." -ForegroundColor Green

# Run Flutter app
flutter run -d $device --dart-define=GEMINI_API_KEY=$apiKey