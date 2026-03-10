Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-MobileMcpCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [switch]$DryRun
    )

    Write-Host ""
    Write-Host "==> $Label"
    Write-Host ("mobile-mcp {0}" -f ($Arguments -join ' '))

    if ($DryRun) {
        return
    }

    & mobile-mcp @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ("mobile-mcp command failed: mobile-mcp {0}" -f ($Arguments -join ' '))
    }
}

function Get-MobileElements {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Device
    )

    $rawOutput = & mobile-mcp mobile-list-elements-on-screen --device $Device -o raw
    if ($LASTEXITCODE -ne 0) {
        throw ("mobile-mcp command failed: mobile-mcp mobile-list-elements-on-screen --device {0} -o raw" -f $Device)
    }

    $parsed = $rawOutput | ConvertFrom-Json
    $textPayload = @($parsed.raw.content | Where-Object { $_.type -eq 'text' } | Select-Object -First 1)
    if ($textPayload.Count -eq 0) {
        throw 'Could not parse list-elements payload (missing text content).'
    }

    $prefix = 'Found these elements on screen: '
    $text = [string]$textPayload[0].text
    if (-not $text.StartsWith($prefix)) {
        throw ('Unexpected list-elements payload format: {0}' -f $text)
    }

    $elementsJson = $text.Substring($prefix.Length)
    $elements = $elementsJson | ConvertFrom-Json
    return @($elements)
}

function Find-MobileElementsByLabel {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Elements,
        [Parameter(Mandatory = $true)]
        [string]$LabelContains
    )

    $needle = $LabelContains.Trim()
    if ([string]::IsNullOrWhiteSpace($needle)) {
        throw 'LabelContains cannot be empty.'
    }

    $results = @(
        $Elements |
            Where-Object {
                $label = ''
                if ($null -ne $_.label) {
                    $label = [string]$_.label
                }
                $label.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
            } |
            Sort-Object @{ Expression = { [int]$_.coordinates.y } }, @{ Expression = { [int]$_.coordinates.x } }
    )
    return ,$results
}

function Find-MobileElementByLabel {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Elements,
        [Parameter(Mandatory = $true)]
        [string]$LabelContains,
        [int]$Occurrence = 1
    )

    if ($Occurrence -lt 1) {
        throw 'Occurrence must be >= 1.'
    }

    $matches = @(Find-MobileElementsByLabel -Elements $Elements -LabelContains $LabelContains)
    if ($matches.Count -lt $Occurrence) {
        throw ("Could not find occurrence {0} of label containing '{1}'. Found {2} match(es)." -f $Occurrence, $LabelContains, $matches.Count)
    }

    return $matches[$Occurrence - 1]
}

function Wait-MobileElementByLabel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Device,
        [Parameter(Mandatory = $true)]
        [string]$LabelContains,
        [int]$Occurrence = 1,
        [int]$TimeoutSeconds = 12,
        [int]$PollIntervalMs = 400
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $deadline) {
        try {
            $elements = Get-MobileElements -Device $Device
            $candidate = Find-MobileElementByLabel -Elements $elements -LabelContains $LabelContains -Occurrence $Occurrence
            if ($null -ne $candidate) {
                return $candidate
            }
        } catch {
            # Keep polling until timeout in case the UI is transitioning.
        }
        Start-Sleep -Milliseconds $PollIntervalMs
    }

    throw ("Timed out waiting for label containing '{0}' (occurrence {1}) on device {2}." -f $LabelContains, $Occurrence, $Device)
}

function Invoke-MobileTapElement {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Device,
        [Parameter(Mandatory = $true)]
        [object]$Element,
        [ValidateSet('text', 'markdown', 'json', 'raw')]
        [string]$Output = 'json',
        [switch]$DryRun
    )

    $centerX = [int][Math]::Round([double]$Element.coordinates.x + ([double]$Element.coordinates.width / 2))
    $centerY = [int][Math]::Round([double]$Element.coordinates.y + ([double]$Element.coordinates.height / 2))

    Invoke-MobileMcpCommand `
        -Label ("Tap element '{0}'" -f ([string]$Element.label).Trim()) `
        -Arguments @(
            'mobile-click-on-screen-at-coordinates',
            '--device', $Device,
            '--x', "$centerX",
            '--y', "$centerY",
            '-o', $Output
        ) `
        -DryRun:$DryRun
}

function Invoke-MobileTapByLabel {
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
        Write-Host ""
        Write-Host ("==> Tap label containing '{0}' (occurrence {1}) on {2}" -f $LabelContains, $Occurrence, $Device)
        Write-Host "[dry-run] mobile-mcp mobile-list-elements-on-screen --device $Device -o raw"
        Write-Host "[dry-run] mobile-mcp mobile-click-on-screen-at-coordinates --device $Device --x <resolved> --y <resolved> -o $Output"
        return
    }

    $element = Wait-MobileElementByLabel -Device $Device -LabelContains $LabelContains -Occurrence $Occurrence
    Invoke-MobileTapElement -Device $Device -Element $element -Output $Output
}
