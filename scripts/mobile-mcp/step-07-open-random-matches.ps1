[CmdletBinding()]
param(
    [string]$Device = 'DMIFHU7HUG9PKVVK',
    [string]$RandomMatchesLabel = 'Random Matches',
    [string]$GenerateMatchesLabel = 'Generate Matches',
    [switch]$TapHomeFirst,
    [int]$PauseMilliseconds = 500,
    [ValidateSet('text', 'markdown', 'json', 'raw')]
    [string]$Output = 'json',
    [switch]$DryRun
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'common.ps1')

if ($TapHomeFirst) {
    Invoke-MobileTapByLabel `
        -Device $Device `
        -LabelContains 'Home' `
        -Output $Output `
        -DryRun:$DryRun

    if (-not $DryRun -and $PauseMilliseconds -gt 0) {
        Start-Sleep -Milliseconds $PauseMilliseconds
    }
}

Invoke-MobileTapByLabel `
    -Device $Device `
    -LabelContains $RandomMatchesLabel `
    -Output $Output `
    -DryRun:$DryRun

if (-not $DryRun -and $PauseMilliseconds -gt 0) {
    Start-Sleep -Milliseconds $PauseMilliseconds
}

Invoke-MobileTapByLabel `
    -Device $Device `
    -LabelContains $GenerateMatchesLabel `
    -Output $Output `
    -DryRun:$DryRun
