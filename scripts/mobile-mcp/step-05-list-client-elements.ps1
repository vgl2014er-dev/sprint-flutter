[CmdletBinding()]
param(
    [string]$ClientDevice = '31071FDH2008FK',
    [ValidateSet('text', 'markdown', 'json', 'raw')]
    [string]$Output = 'json',
    [switch]$DryRun
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'common.ps1')

Invoke-MobileMcpCommand `
    -Label 'List elements on client device (post-flow check)' `
    -Arguments @(
        'mobile-list-elements-on-screen',
        '--device', $ClientDevice,
        '-o', $Output
    ) `
    -DryRun:$DryRun
