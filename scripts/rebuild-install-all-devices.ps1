[CmdletBinding()]
param(
    [switch]$Release,
    [string]$Flavor,
    [string]$AndroidAppId,
    [switch]$SkipPermissionGrant,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string[]]$Command
    )

    Write-Host ""
    Write-Host "==> $Label"
    Write-Host ($Command -join ' ')

    if ($DryRun) {
        return
    }

    & $Command[0] @($Command[1..($Command.Length - 1)])
    if ($LASTEXITCODE -ne 0) {
        throw "Step failed: $Label"
    }
}

$buildArgs = @('flutter', 'build', 'apk')
if ($Release) {
    $buildArgs += '--release'
} else {
    $buildArgs += '--debug'
}

if ($Flavor) {
    $buildArgs += @('--flavor', $Flavor)
}

$installScriptPath = Join-Path $PSScriptRoot 'install-all-devices.ps1'
$installArgs = @(
    'powershell',
    '-ExecutionPolicy',
    'Bypass',
    '-File',
    $installScriptPath
)

if ($Release) {
    $installArgs += '-Release'
}
if ($Flavor) {
    $installArgs += @('-Flavor', $Flavor)
}
if ($AndroidAppId) {
    $installArgs += @('-AndroidAppId', $AndroidAppId)
}
if ($SkipPermissionGrant) {
    $installArgs += '-SkipPermissionGrant'
}
if ($DryRun) {
    $installArgs += '-DryRun'
}

Invoke-Step -Label 'flutter clean' -Command @('flutter', 'clean')
Invoke-Step -Label 'flutter pub get' -Command @('flutter', 'pub', 'get')
Invoke-Step -Label 'flutter build apk' -Command $buildArgs
Invoke-Step -Label 'install on all connected devices' -Command $installArgs

Write-Host ""
if ($DryRun) {
    Write-Host 'Dry-run complete.'
} else {
    Write-Host 'Rebuild + install flow completed.'
}
