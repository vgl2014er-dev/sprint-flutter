[CmdletBinding()]
param(
    [string]$Device = 'DMIFHU7HUG9PKVVK',
    [int]$Cycles = 1,
    [ValidateSet('p1', 'p2', 'draw')]
    [string]$Result = 'draw',
    [switch]$OpenRandomMatches,
    [switch]$TapHomeFirst,
    [int]$PauseSecondsBetweenCycles = 1,
    [ValidateSet('text', 'markdown', 'json', 'raw')]
    [string]$Output = 'json',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if ($Cycles -lt 1) {
    throw 'Cycles must be at least 1.'
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'common.ps1')

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

if ($OpenRandomMatches) {
    Invoke-StepScript -ScriptName 'step-07-open-random-matches.ps1' -Parameters @{
        Device = $Device
        TapHomeFirst = $TapHomeFirst
        Output = $Output
        DryRun = $DryRun
    }

    if (-not $DryRun -and $PauseSecondsBetweenCycles -gt 0) {
        Start-Sleep -Seconds $PauseSecondsBetweenCycles
    }
}

for ($index = 1; $index -le $Cycles; $index += 1) {
    Write-Host ""
    Write-Host ("==> Match cycle {0}/{1} ({2})" -f $index, $Cycles, $Result)

    Invoke-StepScript -ScriptName 'step-08-start-and-record-match.ps1' -Parameters @{
        Device = $Device
        Result = $Result
        Output = $Output
        DryRun = $DryRun
    }

    if (-not $DryRun -and $index -lt $Cycles -and $PauseSecondsBetweenCycles -gt 0) {
        Start-Sleep -Seconds $PauseSecondsBetweenCycles
    }
}

Invoke-MobileMcpCommand `
    -Label 'List elements after random match cycles' `
    -Arguments @(
        'mobile-list-elements-on-screen',
        '--device', $Device,
        '-o', $Output
    ) `
    -DryRun:$DryRun

Write-Host ""
if ($DryRun) {
    Write-Host 'Dry-run complete.'
} else {
    Write-Host 'Random match cycles flow complete.'
}
