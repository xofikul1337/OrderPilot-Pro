$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    throw "Flutter Windows release build failed."
}

$isccCandidates = @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
)

$iscc = $isccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) {
    throw "Inno Setup 6 was not found. Install it with: winget install JRSoftware.InnoSetup"
}

& $iscc "windows\installer\orderpilot-pro.iss"
if ($LASTEXITCODE -ne 0) {
    throw "Windows installer compilation failed."
}

Write-Host ""
Write-Host "Installer ready:"
Write-Host "$projectRoot\build\windows\installer\OrderPilot-Pro-Setup.exe"
