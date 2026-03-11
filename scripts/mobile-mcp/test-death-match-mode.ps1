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
Invoke-MobileTapByLabel -Device $Device -LabelContains 'Death Match' -Output $Output -DryRun:$DryRun
Assert-MobileLabelVisible -Device $Device -LabelContains 'Start Death Match' -DryRun:$DryRun

Invoke-MobileTapByLabel -Device $Device -LabelContains 'Start Death Match' -Output $Output -DryRun:$DryRun
Assert-MobileLabelVisible -Device $Device -LabelContains 'Death Match' -DryRun:$DryRun
Assert-MobileLabelVisible -Device $Device -LabelContains 'START' -DryRun:$DryRun

& (Join-Path $scriptDir 'step-08-start-and-record-match.ps1') `
    -Device $Device `
    -Result $Result `
    -Output $Output `
    -DryRun:$DryRun

Assert-MobileLabelVisibleWithFallback `
    -Device $Device `
    -PrimaryLabel 'Go Home' `
    -FallbackLabel 'Go Back' `
    -DryRun:$DryRun

Write-Host ''
if ($DryRun) {
    Write-Host 'Death Match mode test dry-run complete.'
} else {
    Write-Host 'Death Match mode test passed.'
}
