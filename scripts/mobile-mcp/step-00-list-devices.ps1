[CmdletBinding()]
param(
    [ValidateSet('text', 'markdown', 'json', 'raw')]
    [string]$Output = 'json',
    [switch]$DryRun
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'common.ps1')

Invoke-MobileMcpCommand `
    -Label 'List available mobile devices' `
    -Arguments @('mobile-list-available-devices', '-o', $Output) `
    -DryRun:$DryRun
