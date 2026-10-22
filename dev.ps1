# One-step dev setup for testing Saathi on a USB-connected phone. From saathi_poc:
#   powershell -ExecutionPolicy Bypass -File dev.ps1
# 1. phone port forward  2. session/tool server  3. free Cloudflare tunnel
# 4. points the Bolna agent's saathi_guide tool at the new tunnel URL.
# Re-run after replugging the phone or restarting the PC.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$logs = Join-Path $root 'server\logs'
New-Item -ItemType Directory -Force $logs | Out-Null

# 1. Phone
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
& $adb reverse tcp:8787 tcp:8787 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host 'Phone not found: plug it in and allow USB debugging.'; exit 1 }
Write-Host 'Phone forward ready (phone localhost:8787 -> this PC).'

# 2. Server
if (-not (Get-NetTCPConnection -LocalPort 8787 -State Listen -ErrorAction SilentlyContinue)) {
  Start-Process node -ArgumentList 'server/session_server.mjs' -WorkingDirectory $root `
    -RedirectStandardOutput (Join-Path $logs 'server.log') -RedirectStandardError (Join-Path $logs 'server.err.log') -WindowStyle Hidden
  Start-Sleep -Seconds 2
}
Write-Host 'Session + tool server running.'

# 3. Tunnel (quick tunnels get a new URL each start)
$tunnelLog = Join-Path $logs 'tunnel.log'
Get-CimInstance Win32_Process -Filter "Name='cloudflared.exe'" |
  Where-Object { $_.CommandLine -like '*127.0.0.1:8788*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Remove-Item $tunnelLog -ErrorAction SilentlyContinue
Start-Process cloudflared -ArgumentList 'tunnel', '--no-autoupdate', '--url', 'http://127.0.0.1:8788' `
  -RedirectStandardError $tunnelLog -RedirectStandardOutput (Join-Path $logs 'tunnel.out.log') -WindowStyle Hidden
$url = $null
for ($i = 0; $i -lt 60 -and -not $url; $i++) {
  Start-Sleep -Seconds 1
  if (Test-Path $tunnelLog) {
    $m = Select-String -Path $tunnelLog -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' | Select-Object -First 1
    if ($m) { $url = $m.Matches[0].Value }
  }
}
if (-not $url) { Write-Host 'Tunnel did not start. See server\logs\tunnel.log'; exit 1 }
Write-Host "Tunnel: $url"

# 4. Agent
node tools/update_agent.mjs $url --apply
Write-Host 'Ready. Open Saathi on the phone and tap the mic.'
