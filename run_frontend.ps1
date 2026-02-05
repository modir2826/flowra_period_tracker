#!/usr/bin/env pwsh
# run_frontend.ps1
param(
    [string]$device = "chrome"
)

Set-StrictMode -Version Latest
Set-Location -Path $PSScriptRoot

Write-Host "Fetching Flutter packages..."
flutter pub get

if ($device -eq 'chrome') {
    Write-Host "Running Flutter web on Chrome"
    flutter run -d chrome
} elseif ($device -eq 'windows') {
    Write-Host "Running Flutter on Windows desktop"
    flutter run -d windows
} else {
    Write-Host "Listing devices and attempting to run on device id: $device"
    flutter devices
    flutter run -d $device
}
