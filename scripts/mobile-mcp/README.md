# Mobile MCP Flow Scripts

Reusable scripts for the repeated host/connect/permission flow used during local display verification.

## Default devices
- Host device (OnePlus): `DMIFHU7HUG9PKVVK`
- Client device (Pixel): `31071FDH2008FK`

Override with `-HostDevice` and `-ClientDevice` in any step script.

## Step scripts
- `step-00-list-devices.ps1`
- `step-01-host-connect.ps1`
- `step-02-list-elements-both.ps1`
- `step-03-allow-location.ps1`
- `step-04-allow-nearby.ps1`
- `step-05-list-client-elements.ps1`
- `step-06-nearby-connect-and-dual-accept.ps1`
- `step-07-open-random-matches.ps1`
- `step-08-start-and-record-match.ps1`

## Recurring random-match flow
Start a random-match run (landing -> random card -> generate -> START -> result):
```powershell
powershell -ExecutionPolicy Bypass -File scripts/mobile-mcp/run-random-match-cycles.ps1 `
  -OpenRandomMatches `
  -TapHomeFirst `
  -Cycles 1 `
  -Result draw
```

Run multiple match cycles using the same result (`p1`, `p2`, or `draw`):
```powershell
powershell -ExecutionPolicy Bypass -File scripts/mobile-mcp/run-random-match-cycles.ps1 `
  -Cycles 5 `
  -Result p1
```

## End-to-end
```powershell
powershell -ExecutionPolicy Bypass -File scripts/mobile-mcp/run-end-to-end.ps1
```

Dry run:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/mobile-mcp/run-end-to-end.ps1 -DryRun
```

With custom device ids:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/mobile-mcp/run-end-to-end.ps1 `
  -HostDevice "<ONEPLUS_ID>" `
  -ClientDevice "<PIXEL_ID>"
```

## Reverse flow example (Pixel hosts, OnePlus connects)
```powershell
powershell -ExecutionPolicy Bypass -File scripts/mobile-mcp/run-end-to-end.ps1 `
  -HostDevice "31071FDH2008FK" `
  -ClientDevice "DMIFHU7HUG9PKVVK" `
  -HostButtonX 203 `
  -HostButtonY 1380 `
  -ClientConnectButtonX 577 `
  -ClientConnectButtonY 1607 `
  -HostAllowLocationX 540 `
  -HostAllowLocationY 1533 `
  -ClientAllowLocationX 540 `
  -ClientAllowLocationY 1464 `
  -HostAllowNearbyX 540 `
  -HostAllowNearbyY 1495 `
  -ClientAllowNearbyX 540 `
  -ClientAllowNearbyY 1293 `
  -NearbyConnectX 787 `
  -NearbyConnectY 2114 `
  -HostAcceptX 218 `
  -HostAcceptY 1737 `
  -ClientAcceptX 250 `
  -ClientAcceptY 2117
```
