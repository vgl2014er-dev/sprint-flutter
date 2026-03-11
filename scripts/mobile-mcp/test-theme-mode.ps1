[CmdletBinding()]
param(
    [string]$Device = 'DMIFHU7HUG9PKVVK',
    [string]$PackageName = 'elo.flutter',
    [int]$ThemeToggleX = 828,
    [int]$ThemeToggleY = 210,
    [int]$PauseMillisecondsBetweenToggles = 500,
    [ValidateSet('text', 'markdown', 'json', 'raw')]
    [string]$Output = 'json',
    [switch]$DryRun
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'common.ps1')
. (Join-Path $scriptDir 'mode-helpers.ps1')

Start-SprintApp -Device $Device -PackageName $PackageName -Output $Output -DryRun:$DryRun

Invoke-MobileTapByLabel -Device $Device -LabelContains 'Leaderboard' -Occurrence 2 -Output $Output -DryRun:$DryRun
Assert-MobileLabelVisible -Device $Device -LabelContains 'RANK' -DryRun:$DryRun

Invoke-MobileMcpCommand `
    -Label 'Tap theme toggle (to dark/light)' `
    -Arguments @(
        'mobile-click-on-screen-at-coordinates',
        '--device', $Device,
        '--x', "$ThemeToggleX",
        '--y', "$ThemeToggleY",
        '-o', $Output
    ) `
    -DryRun:$DryRun

if (-not $DryRun -and $PauseMillisecondsBetweenToggles -gt 0) {
    Start-Sleep -Milliseconds $PauseMillisecondsBetweenToggles
}

Assert-MobileLabelVisible -Device $Device -LabelContains 'RANK' -DryRun:$DryRun

Invoke-MobileMcpCommand `
    -Label 'Tap theme toggle (restore original mode)' `
    -Arguments @(
        'mobile-click-on-screen-at-coordinates',
        '--device', $Device,
        '--x', "$ThemeToggleX",
        '--y', "$ThemeToggleY",
        '-o', $Output
    ) `
    -DryRun:$DryRun

if (-not $DryRun -and $PauseMillisecondsBetweenToggles -gt 0) {
    Start-Sleep -Milliseconds $PauseMillisecondsBetweenToggles
}

Assert-MobileLabelVisible -Device $Device -LabelContains 'RANK' -DryRun:$DryRun

Write-Host ''
if ($DryRun) {
    Write-Host 'Theme mode test dry-run complete.'
} else {
    Write-Host 'Theme mode test passed.'
}
