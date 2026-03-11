[CmdletBinding()]
param(
    [string]$Device = 'DMIFHU7HUG9PKVVK',
    [string]$HostDevice = 'DMIFHU7HUG9PKVVK',
    [string]$ClientDevice = '31071FDH2008FK',
    [ValidateSet('p1', 'p2', 'draw')]
    [string]$Result = 'draw',
    [switch]$IncludeLocalMode,
    [int]$PauseSecondsBetweenTests = 1,
    [ValidateSet('text', 'markdown', 'json', 'raw')]
    [string]$Output = 'json',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters
    )

    $scriptPath = Join-Path $scriptDir $ScriptName
    if (-not (Test-Path $scriptPath)) {
        throw "Missing test script: $scriptPath"
    }

    Write-Host ''
    Write-Host ("==> Running {0}" -f $ScriptName)
    & $scriptPath @Parameters
}

Invoke-TestScript -ScriptName 'test-theme-mode.ps1' -Parameters @{
    Device = $Device
    Output = $Output
    DryRun = $DryRun
}
if (-not $DryRun -and $PauseSecondsBetweenTests -gt 0) { Start-Sleep -Seconds $PauseSecondsBetweenTests }

Invoke-TestScript -ScriptName 'test-random-mode.ps1' -Parameters @{
    Device = $Device
    Result = $Result
    Output = $Output
    DryRun = $DryRun
}
if (-not $DryRun -and $PauseSecondsBetweenTests -gt 0) { Start-Sleep -Seconds $PauseSecondsBetweenTests }

Invoke-TestScript -ScriptName 'test-elo-mode.ps1' -Parameters @{
    Device = $Device
    Result = $Result
    Output = $Output
    DryRun = $DryRun
}
if (-not $DryRun -and $PauseSecondsBetweenTests -gt 0) { Start-Sleep -Seconds $PauseSecondsBetweenTests }

Invoke-TestScript -ScriptName 'test-death-match-mode.ps1' -Parameters @{
    Device = $Device
    Result = $Result
    Output = $Output
    DryRun = $DryRun
}

if ($IncludeLocalMode) {
    if (-not $DryRun -and $PauseSecondsBetweenTests -gt 0) { Start-Sleep -Seconds $PauseSecondsBetweenTests }

    Invoke-TestScript -ScriptName 'test-local-mode.ps1' -Parameters @{
        HostDevice = $HostDevice
        ClientDevice = $ClientDevice
        Output = $Output
        DryRun = $DryRun
    }
}

Write-Host ''
if ($DryRun) {
    Write-Host 'Mode test suite dry-run complete.'
} else {
    Write-Host 'Mode test suite completed successfully.'
}
