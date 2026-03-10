[CmdletBinding()]
param(
    [ValidateSet('debug', 'profile', 'release')]
    [string]$BuildMode = 'debug',
    [switch]$Release,
    [string]$Flavor,
    [string]$AndroidAppId,
    [switch]$SkipPermissionGrant,
    [switch]$IncludeAllSupportedTargets,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host "Detecting Flutter devices..."
$rawDevices = (flutter devices --machine | Out-String).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "Failed to list Flutter devices."
}

$parsedDevices = $rawDevices | ConvertFrom-Json
$devices = if ($parsedDevices -is [System.Array]) {
    $parsedDevices
} else {
    @($parsedDevices)
}

if ($IncludeAllSupportedTargets) {
    $targets = @($devices | Where-Object { $_.isSupported })
} else {
    $targets = @(
        $devices | Where-Object {
            $_.isSupported -and (
                $_.targetPlatform -like 'android*' -or
                $_.targetPlatform -like 'ios*'
            )
        }
    )
}

if ($targets.Count -eq 0) {
    throw "No matching connected devices found."
}

Write-Host "Targets:"
foreach ($device in $targets) {
    Write-Host ("- {0} [{1}] ({2})" -f $device.name, $device.id, $device.targetPlatform)
}

$effectiveBuildMode = if ($Release) { 'release' } else { $BuildMode }

$modeFlag = switch ($effectiveBuildMode) {
    'debug' { '--debug' }
    'profile' { '--profile' }
    default { '--release' }
}

$hasAndroidTarget = @(
    $targets | Where-Object { $_.targetPlatform -like 'android*' }
).Count -gt 0

if ($hasAndroidTarget -and -not $AndroidAppId) {
    $gradlePath = Join-Path $projectRoot 'android/app/build.gradle.kts'
    if (Test-Path $gradlePath) {
        $gradleContent = Get-Content $gradlePath -Raw
        $appIdMatch = [regex]::Match($gradleContent, 'applicationId\s*=\s*"([^"]+)"')
        if ($appIdMatch.Success) {
            $AndroidAppId = $appIdMatch.Groups[1].Value
        }
    }
}

if ($hasAndroidTarget -and -not $AndroidAppId) {
    throw "Could not determine Android applicationId. Pass -AndroidAppId explicitly."
}

$androidRuntimePermissions = @(
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.NEARBY_WIFI_DEVICES',
    'android.permission.BLUETOOTH_ADVERTISE',
    'android.permission.BLUETOOTH_CONNECT',
    'android.permission.BLUETOOTH_SCAN'
)

$failed = @()
$launchFailed = @()

foreach ($device in $targets) {
    Write-Host ""
    Write-Host ("Installing on {0} [{1}]..." -f $device.name, $device.id)

    $installArgs = @('install', '-d', $device.id, $modeFlag)
    if ($Flavor) {
        $installArgs += @('--flavor', $Flavor)
    }

    if ($DryRun) {
        Write-Host ("[dry-run] flutter {0}" -f ($installArgs -join ' '))
        if ($device.targetPlatform -like 'android*') {
            if (-not $SkipPermissionGrant) {
                foreach ($permission in $androidRuntimePermissions) {
                    Write-Host ("[dry-run] adb -s {0} shell pm grant {1} {2}" -f $device.id, $AndroidAppId, $permission)
                }
            }
            Write-Host ("[dry-run] adb -s {0} shell monkey -p {1} -c android.intent.category.LAUNCHER 1" -f $device.id, $AndroidAppId)
        } else {
            Write-Host "[dry-run] no launch command for non-Android target"
        }
        continue
    }

    & flutter @installArgs
    if ($LASTEXITCODE -ne 0) {
        $failed += $device
        continue
    }

    if ($device.targetPlatform -like 'android*') {
        if (-not $SkipPermissionGrant) {
            foreach ($permission in $androidRuntimePermissions) {
                $grantCommand = "adb -s ""$($device.id)"" shell pm grant ""$AndroidAppId"" ""$permission"" 2>&1"
                $grantOutput = cmd /c $grantCommand
                $grantExitCode = $LASTEXITCODE
                if ($grantExitCode -ne 0) {
                    $message = ($grantOutput | Out-String).Trim()
                    if (-not $message) {
                        $message = 'unknown error'
                    }
                    Write-Warning ("Could not grant {0} on {1} [{2}]: {3}" -f $permission, $device.name, $device.id, $message)
                }
            }
        }

        $launchCommand = "adb -s ""$($device.id)"" shell monkey -p ""$AndroidAppId"" -c android.intent.category.LAUNCHER 1"
        cmd /c $launchCommand | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $launchFailed += $device
        }
        continue
    }

    Write-Warning ("Install succeeded on {0} [{1}], but auto-launch is currently only implemented for Android targets." -f $device.name, $device.id)
    if ($DryRun) {
        Write-Host "[dry-run] no launch command for non-Android target"
    }
}

if ($failed.Count -gt 0) {
    Write-Error "Install failed on one or more devices:"
    foreach ($device in $failed) {
        Write-Host ("- {0} [{1}]" -f $device.name, $device.id)
    }
    exit 1
}

if ($DryRun) {
    Write-Host ""
    if ($hasAndroidTarget) {
        Write-Host ("Dry-run complete. Android app id: {0}" -f $AndroidAppId)
    } else {
        Write-Host "Dry-run complete."
    }
} else {
    if ($launchFailed.Count -gt 0) {
        Write-Error "Install succeeded but launch failed on one or more devices:"
        foreach ($device in $launchFailed) {
            Write-Host ("- {0} [{1}]" -f $device.name, $device.id)
        }
        exit 1
    }
    Write-Host ""
    if ($hasAndroidTarget) {
        Write-Host ("Install and launch completed successfully on all target devices. Android app id: {0}" -f $AndroidAppId)
    } else {
        Write-Host "Install completed successfully on all target devices."
    }
}
