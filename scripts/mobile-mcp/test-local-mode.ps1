[CmdletBinding()]
param(
    [string]$HostDevice = 'DMIFHU7HUG9PKVVK',
    [string]$ClientDevice = '31071FDH2008FK',
    [ValidateSet('text', 'markdown', 'json', 'raw')]
    [string]$Output = 'json',
    [switch]$DryRun
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'common.ps1')
. (Join-Path $scriptDir 'mode-helpers.ps1')

& (Join-Path $scriptDir 'run-end-to-end.ps1') `
    -HostDevice $HostDevice `
    -ClientDevice $ClientDevice `
    -Output $Output `
    -DryRun:$DryRun

Assert-MobileLabelVisible -Device $HostDevice -LabelContains 'Offline Mirror' -TimeoutSeconds 20 -DryRun:$DryRun
Assert-MobileLabelVisible -Device $ClientDevice -LabelContains 'RANK' -TimeoutSeconds 20 -DryRun:$DryRun
Assert-MobileLabelVisible -Device $ClientDevice -LabelContains 'PLAYER' -TimeoutSeconds 20 -DryRun:$DryRun

Write-Host ''
if ($DryRun) {
    Write-Host 'Local mode test dry-run complete.'
} else {
    Write-Host 'Local mode test passed.'
}
