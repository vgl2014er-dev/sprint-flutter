[CmdletBinding()]
param(
    [string]$Device = 'DMIFHU7HUG9PKVVK',
    [ValidateSet('p1', 'p2', 'draw')]
    [string]$Result = 'draw',
    [string]$StartLabel = 'START',
    [string]$WinsLabelFragment = ' WINS',
    [string]$DrawLabel = 'DRAW',
    [int]$PauseMillisecondsAfterStart = 400,
    [ValidateSet('text', 'markdown', 'json', 'raw')]
    [string]$Output = 'json',
    [switch]$DryRun
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'common.ps1')

Invoke-MobileTapByLabel `
    -Device $Device `
    -LabelContains $StartLabel `
    -Output $Output `
    -DryRun:$DryRun

if (-not $DryRun -and $PauseMillisecondsAfterStart -gt 0) {
    Start-Sleep -Milliseconds $PauseMillisecondsAfterStart
}

if ($Result -eq 'draw') {
    Invoke-MobileTapByLabel `
        -Device $Device `
        -LabelContains $DrawLabel `
        -Output $Output `
        -DryRun:$DryRun
    return
}

if ($DryRun) {
    Write-Host ""
    Write-Host ("==> Tap result '{0}' by selecting the {1} '{2}' button" -f $Result, ($(if ($Result -eq 'p1') { 'first' } else { 'second' })), $WinsLabelFragment.Trim())
    Write-Host "[dry-run] mobile-mcp mobile-list-elements-on-screen --device $Device -o raw"
    Write-Host "[dry-run] mobile-mcp mobile-click-on-screen-at-coordinates --device $Device --x <resolved> --y <resolved> -o $Output"
    return
}

$elements = Get-MobileElements -Device $Device
$winsButtons = Find-MobileElementsByLabel -Elements $elements -LabelContains $WinsLabelFragment
if ($winsButtons.Count -lt 2) {
    throw ("Could not find two result buttons containing '{0}'. Found {1}." -f $WinsLabelFragment, $winsButtons.Count)
}

$winsIndex = if ($Result -eq 'p1') { 0 } else { 1 }
Invoke-MobileTapElement -Device $Device -Element $winsButtons[$winsIndex] -Output $Output
