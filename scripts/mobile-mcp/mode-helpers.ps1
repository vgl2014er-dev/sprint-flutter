Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Start-SprintApp {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Device,
        [string]$PackageName = 'elo.flutter',
        [ValidateSet('text', 'markdown', 'json', 'raw')]
        [string]$Output = 'json',
        [int]$LaunchPauseMilliseconds = 800,
        [switch]$DryRun
    )

    Invoke-MobileMcpCommand `
        -Label ("Launch app '{0}' on {1}" -f $PackageName, $Device) `
        -Arguments @(
            'mobile-launch-app',
            '--device', $Device,
            '--package-name', $PackageName,
            '-o', $Output
        ) `
        -DryRun:$DryRun

    if (-not $DryRun -and $LaunchPauseMilliseconds -gt 0) {
        Start-Sleep -Milliseconds $LaunchPauseMilliseconds
    }
}

function Assert-MobileLabelVisible {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Device,
        [Parameter(Mandatory = $true)]
        [string]$LabelContains,
        [int]$Occurrence = 1,
        [int]$TimeoutSeconds = 15,
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-Host ("[dry-run] Assert label containing '{0}' exists on {1}" -f $LabelContains, $Device)
        return
    }

    [void](Wait-MobileElementByLabel `
        -Device $Device `
        -LabelContains $LabelContains `
        -Occurrence $Occurrence `
        -TimeoutSeconds $TimeoutSeconds)
}

function Invoke-MobileTapIfVisible {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Device,
        [Parameter(Mandatory = $true)]
        [string]$LabelContains,
        [int]$Occurrence = 1,
        [ValidateSet('text', 'markdown', 'json', 'raw')]
        [string]$Output = 'json',
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-Host ("[dry-run] Tap label containing '{0}' on {1} if visible" -f $LabelContains, $Device)
        return
    }

    $elements = Get-MobileElements -Device $Device
    $matches = @(Find-MobileElementsByLabel -Elements $elements -LabelContains $LabelContains)
    if ($matches.Count -lt $Occurrence) {
        return
    }

    Invoke-MobileTapElement -Device $Device -Element $matches[$Occurrence - 1] -Output $Output
}

function Invoke-MobileTapByLabelWithFallback {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Device,
        [Parameter(Mandatory = $true)]
        [string]$PrimaryLabel,
        [Parameter(Mandatory = $true)]
        [string]$FallbackLabel,
        [int]$Occurrence = 1,
        [ValidateSet('text', 'markdown', 'json', 'raw')]
        [string]$Output = 'json',
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-Host ("[dry-run] Tap '{0}' on {1}, fallback to '{2}' if missing" -f $PrimaryLabel, $Device, $FallbackLabel)
        return
    }

    $elements = Get-MobileElements -Device $Device
    $primaryMatches = @(Find-MobileElementsByLabel -Elements $elements -LabelContains $PrimaryLabel)
    if ($primaryMatches.Count -ge $Occurrence) {
        Invoke-MobileTapElement -Device $Device -Element $primaryMatches[$Occurrence - 1] -Output $Output
        return
    }

    Invoke-MobileTapByLabel `
        -Device $Device `
        -LabelContains $FallbackLabel `
        -Occurrence $Occurrence `
        -Output $Output
}

function Assert-MobileLabelVisibleWithFallback {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Device,
        [Parameter(Mandatory = $true)]
        [string]$PrimaryLabel,
        [Parameter(Mandatory = $true)]
        [string]$FallbackLabel,
        [int]$Occurrence = 1,
        [int]$TimeoutSeconds = 15,
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-Host ("[dry-run] Assert '{0}' exists on {1}, fallback to '{2}'" -f $PrimaryLabel, $Device, $FallbackLabel)
        return
    }

    try {
        Assert-MobileLabelVisible `
            -Device $Device `
            -LabelContains $PrimaryLabel `
            -Occurrence $Occurrence `
            -TimeoutSeconds 2
        return
    } catch {
        Assert-MobileLabelVisible `
            -Device $Device `
            -LabelContains $FallbackLabel `
            -Occurrence $Occurrence `
            -TimeoutSeconds $TimeoutSeconds
    }
}
