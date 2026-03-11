[CmdletBinding()]
param(
    [string]$Device = 'DMIFHU7HUG9PKVVK',
    [string]$PackageName = 'elo.flutter',
    [ValidateSet('p1', 'p2', 'draw')]
    [string]$Result = 'draw',
    [ValidateSet('text', 'markdown', 'json', 'raw')]
    [string]$Output = 'json',
    [switch]$DryRun
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'common.ps1')
. (Join-Path $scriptDir 'mode-helpers.ps1')

Start-SprintApp -Device $Device -PackageName $PackageName -Output $Output -DryRun:$DryRun

Invoke-MobileTapByLabel -Device $Device -LabelContains 'Home' -Output $Output -DryRun:$DryRun
Invoke-MobileTapByLabel -Device $Device -LabelContains 'Random Matches' -Output $Output -DryRun:$DryRun
Assert-MobileLabelVisible -Device $Device -LabelContains 'Generate Matches' -DryRun:$DryRun

Invoke-MobileTapByLabel -Device $Device -LabelContains 'Generate Matches' -Output $Output -DryRun:$DryRun

& (Join-Path $scriptDir 'step-08-start-and-record-match.ps1') `
    -Device $Device `
    -Result $Result `
    -Output $Output `
    -DryRun:$DryRun

Invoke-MobileTapByLabelWithFallback `
    -Device $Device `
    -PrimaryLabel 'Go Home' `
    -FallbackLabel 'Go Back' `
    -Output $Output `
    -DryRun:$DryRun
Assert-MobileLabelVisible -Device $Device -LabelContains 'RANK' -DryRun:$DryRun
Assert-MobileLabelVisible -Device $Device -LabelContains 'PLAYER' -DryRun:$DryRun
Assert-MobileLabelVisible -Device $Device -LabelContains 'ELO' -DryRun:$DryRun
Assert-MobileLabelVisible -Device $Device -LabelContains 'WIN %' -DryRun:$DryRun

Write-Host ''
if ($DryRun) {
    Write-Host 'Random mode test dry-run complete.'
} else {
    Write-Host 'Random mode test passed.'
}
