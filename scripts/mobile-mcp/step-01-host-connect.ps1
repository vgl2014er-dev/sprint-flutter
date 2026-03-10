[CmdletBinding()]
param(
    [string]$HostDevice = 'DMIFHU7HUG9PKVVK',
    [string]$ClientDevice = '31071FDH2008FK',
    [int]$HostX = 231,
    [int]$HostY = 1607,
    [int]$ClientX = 505,
    [int]$ClientY = 1380,
    [ValidateSet('text', 'markdown', 'json', 'raw')]
    [string]$Output = 'json',
    [switch]$DryRun
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'common.ps1')

Invoke-MobileMcpCommand `
    -Label 'Tap Host on host device' `
    -Arguments @(
        'mobile-click-on-screen-at-coordinates',
        '--device', $HostDevice,
        '--x', "$HostX",
        '--y', "$HostY",
        '-o', $Output
    ) `
    -DryRun:$DryRun

Invoke-MobileMcpCommand `
    -Label 'Tap Connect on client device' `
    -Arguments @(
        'mobile-click-on-screen-at-coordinates',
        '--device', $ClientDevice,
        '--x', "$ClientX",
        '--y', "$ClientY",
        '-o', $Output
    ) `
    -DryRun:$DryRun
