# zago Build Script for Windows
# Usage: .\build.ps1

$ErrorActionPreference = 'Stop'

$installDir = "$env:LOCALAPPDATA\Programs\zago"
$exeName = "zago.exe"
$targetExe = Join-Path $installDir $exeName

Write-Host "Building zago..." -ForegroundColor Cyan

swift build

$binPath = swift build --show-bin-path
$builtExe = Join-Path $binPath $exeName

if (-not (Test-Path $builtExe)) {
    throw "Build completed, but $builtExe was not found."
}

if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
}

try {
    Copy-Item -Path $builtExe -Destination $targetExe -Force
}
catch {
    throw "Failed to copy $builtExe to $targetExe. Close any running zago.exe process and try again. $_"
}

Write-Host ""
Write-Host "zago build completed successfully." -ForegroundColor Green
Write-Host "Location: $targetExe" -ForegroundColor Gray
