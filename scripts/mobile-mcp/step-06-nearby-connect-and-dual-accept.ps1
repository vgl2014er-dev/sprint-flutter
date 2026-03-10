[CmdletBinding()]
param(
    [string]$HostDevice = 'DMIFHU7HUG9PKVVK',
    [string]$ClientDevice = '31071FDH2008FK',
    [int]$NearbyConnectX = 824,
    [int]$NearbyConnectY = 1824,
    [int]$HostAcceptX = 250,
    [int]$HostAcceptY = 2066,
    [int]$ClientAcceptX = 218,
    [int]$ClientAcceptY = 1782,
    [ValidateSet('text', 'markdown', 'json', 'raw')]
    [string]$Output = 'json',
    [switch]$DryRun
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'common.ps1')

Invoke-MobileMcpCommand `
    -Label 'Tap Nearby -> Connect on client device' `
    -Arguments @(
        'mobile-click-on-screen-at-coordinates',
        '--device', $ClientDevice,
        '--x', "$NearbyConnectX",
        '--y', "$NearbyConnectY",
        '-o', $Output
    ) `
    -DryRun:$DryRun

Invoke-MobileMcpCommand `
    -Label 'Tap Accept on host approval prompt' `
    -Arguments @(
        'mobile-click-on-screen-at-coordinates',
        '--device', $HostDevice,
        '--x', "$HostAcceptX",
        '--y', "$HostAcceptY",
        '-o', $Output
    ) `
    -DryRun:$DryRun

Invoke-MobileMcpCommand `
    -Label 'Tap Accept on client approval prompt' `
    -Arguments @(
        'mobile-click-on-screen-at-coordinates',
        '--device', $ClientDevice,
        '--x', "$ClientAcceptX",
        '--y', "$ClientAcceptY",
        '-o', $Output
    ) `
    -DryRun:$DryRun
