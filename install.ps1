# zago Installer for Windows
# Usage: irm https://raw.githubusercontent.com/zonble/zago/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'

$repo = "zonble/zago"
$installDir = "$env:LOCALAPPDATA\Programs\zago"
$exeName = "zago.exe"
$targetExe = Join-Path $installDir $exeName

Write-Host "Installing zago for Windows..." -ForegroundColor Cyan

# Ensure installation directory exists
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
}

# Fetch latest release info from GitHub API
$apiUrl = "https://api.github.com/repos/$repo/releases/latest"
Write-Host "Fetching latest release information from GitHub..." -ForegroundColor Gray

try {
    $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "zago-installer" }
    $asset = $release.assets | Where-Object { $_.name -like "*windows*.zip" -or $_.name -like "*win*.zip" } | Select-Object -First 1

    if (-not $asset) {
        # Fallback to direct zago.exe asset if zip is not found
        $asset = $release.assets | Where-Object { $_.name -eq "zago.exe" } | Select-Object -First 1
    }

    if (-not $asset) {
        throw "Could not find a Windows release asset (.zip or .exe) in $apiUrl"
    }

    $downloadUrl = $asset.browser_download_url
    $fileName = $asset.name
    $tempFile = Join-Path $env:TEMP $fileName

    Write-Host "Downloading $fileName ($($release.tag_name))..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing

    if ($fileName.EndsWith(".zip")) {
        $tempExtractDir = Join-Path $env:TEMP "zago_extract_$([Guid]::NewGuid().Guid)"
        Expand-Archive -Path $tempFile -DestinationPath $tempExtractDir -Force
        
        $extractedExe = Get-ChildItem -Path $tempExtractDir -Filter "zago*.exe" -Recurse |
            Sort-Object @{ Expression = { if ($_.Name -eq $exeName) { 0 } else { 1 } } }, Name |
            Select-Object -First 1
        if (-not $extractedExe) {
            throw "No zago*.exe executable was found inside the downloaded zip package."
        }

        Copy-Item -Path $extractedExe.FullName -Destination $targetExe -Force
        Remove-Item -Path $tempExtractDir -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Copy-Item -Path $tempFile -Destination $targetExe -Force
    }

    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Error "Failed to download zago: $_"
    exit 1
}

# Update User PATH environment variable
$userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
if (-not $userPath) { $userPath = "" }

$pathArray = $userPath -split ';' | Where-Object { $_ -ne "" }
if ($pathArray -notcontains $installDir) {
    Write-Host "Adding $installDir to User PATH..." -ForegroundColor Gray
    $newPath = ($pathArray + $installDir) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)
}

# Update current PowerShell session PATH
if (($env:PATH -split ';') -notcontains $installDir) {
    $env:PATH = "$env:PATH;$installDir"
}

Write-Host ""
Write-Host "zago installed successfully!" -ForegroundColor Green
Write-Host "Location: $targetExe" -ForegroundColor Gray
Write-Host "Try running: zago --version" -ForegroundColor Cyan
