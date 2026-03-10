[CmdletBinding()]
param(
    [string]$HostDevice = 'DMIFHU7HUG9PKVVK',
    [string]$ClientDevice = '31071FDH2008FK',
    [int]$HostButtonX = 231,
    [int]$HostButtonY = 1607,
    [int]$ClientConnectButtonX = 505,
    [int]$ClientConnectButtonY = 1380,
    [int]$HostAllowLocationX = 540,
    [int]$HostAllowLocationY = 1464,
    [int]$ClientAllowLocationX = 540,
    [int]$ClientAllowLocationY = 1533,
    [int]$HostAllowNearbyX = 540,
    [int]$HostAllowNearbyY = 1293,
    [int]$ClientAllowNearbyX = 540,
    [int]$ClientAllowNearbyY = 1495,
    [int]$NearbyConnectX = 824,
    [int]$NearbyConnectY = 1824,
    [int]$HostAcceptX = 250,
    [int]$HostAcceptY = 2066,
    [int]$ClientAcceptX = 218,
    [int]$ClientAcceptY = 1782,
    [ValidateSet('text', 'markdown', 'json', 'raw')]
    [string]$Output = 'json',
    [int]$PauseSecondsBetweenSteps = 1,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Invoke-StepScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters
    )

    $stepPath = Join-Path $scriptDir $ScriptName
    if (-not (Test-Path $stepPath)) {
        throw "Missing step script: $stepPath"
    }

    & $stepPath @Parameters
}

if (-not $DryRun -and $PauseSecondsBetweenSteps -gt 0) {
    Invoke-StepScript -ScriptName 'step-00-list-devices.ps1' -Parameters @{
        Output = $Output
        DryRun = $DryRun
    }
    Start-Sleep -Seconds $PauseSecondsBetweenSteps
} else {
    Invoke-StepScript -ScriptName 'step-00-list-devices.ps1' -Parameters @{
        Output = $Output
        DryRun = $DryRun
    }
}

Invoke-StepScript -ScriptName 'step-01-host-connect.ps1' -Parameters @{
    HostDevice = $HostDevice
    ClientDevice = $ClientDevice
    HostX = $HostButtonX
    HostY = $HostButtonY
    ClientX = $ClientConnectButtonX
    ClientY = $ClientConnectButtonY
    Output = $Output
    DryRun = $DryRun
}
if (-not $DryRun -and $PauseSecondsBetweenSteps -gt 0) { Start-Sleep -Seconds $PauseSecondsBetweenSteps }

Invoke-StepScript -ScriptName 'step-02-list-elements-both.ps1' -Parameters @{
    HostDevice = $HostDevice
    ClientDevice = $ClientDevice
    Output = $Output
    DryRun = $DryRun
}
if (-not $DryRun -and $PauseSecondsBetweenSteps -gt 0) { Start-Sleep -Seconds $PauseSecondsBetweenSteps }

Invoke-StepScript -ScriptName 'step-03-allow-location.ps1' -Parameters @{
    HostDevice = $HostDevice
    ClientDevice = $ClientDevice
    HostX = $HostAllowLocationX
    HostY = $HostAllowLocationY
    ClientX = $ClientAllowLocationX
    ClientY = $ClientAllowLocationY
    Output = $Output
    DryRun = $DryRun
}
if (-not $DryRun -and $PauseSecondsBetweenSteps -gt 0) { Start-Sleep -Seconds $PauseSecondsBetweenSteps }

Invoke-StepScript -ScriptName 'step-04-allow-nearby.ps1' -Parameters @{
    HostDevice = $HostDevice
    ClientDevice = $ClientDevice
    HostX = $HostAllowNearbyX
    HostY = $HostAllowNearbyY
    ClientX = $ClientAllowNearbyX
    ClientY = $ClientAllowNearbyY
    Output = $Output
    DryRun = $DryRun
}
if (-not $DryRun -and $PauseSecondsBetweenSteps -gt 0) { Start-Sleep -Seconds $PauseSecondsBetweenSteps }

Invoke-StepScript -ScriptName 'step-05-list-client-elements.ps1' -Parameters @{
    ClientDevice = $ClientDevice
    Output = $Output
    DryRun = $DryRun
}
if (-not $DryRun -and $PauseSecondsBetweenSteps -gt 0) { Start-Sleep -Seconds $PauseSecondsBetweenSteps }

Invoke-StepScript -ScriptName 'step-06-nearby-connect-and-dual-accept.ps1' -Parameters @{
    HostDevice = $HostDevice
    ClientDevice = $ClientDevice
    NearbyConnectX = $NearbyConnectX
    NearbyConnectY = $NearbyConnectY
    HostAcceptX = $HostAcceptX
    HostAcceptY = $HostAcceptY
    ClientAcceptX = $ClientAcceptX
    ClientAcceptY = $ClientAcceptY
    Output = $Output
    DryRun = $DryRun
}
if (-not $DryRun -and $PauseSecondsBetweenSteps -gt 0) { Start-Sleep -Seconds $PauseSecondsBetweenSteps }

Invoke-StepScript -ScriptName 'step-02-list-elements-both.ps1' -Parameters @{
    HostDevice = $HostDevice
    ClientDevice = $ClientDevice
    Output = $Output
    DryRun = $DryRun
}

Write-Host ""
if ($DryRun) {
    Write-Host 'Dry-run complete.'
} else {
    Write-Host 'End-to-end mobile-mcp flow complete.'
}
