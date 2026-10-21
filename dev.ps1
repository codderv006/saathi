# Dev setup for testing voice on a USB-connected phone. Run from saathi_poc:
#   powershell -ExecutionPolicy Bypass -File dev.ps1
# Re-run after replugging the phone (the port forward resets).

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
& $adb reverse tcp:8787 tcp:8787 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host 'Phone not found: plug it in and allow USB debugging.'; exit 1 }
Write-Host 'Phone port forward ready (phone localhost:8787 -> this PC).'

$listening = Get-NetTCPConnection -LocalPort 8787 -State Listen -ErrorAction SilentlyContinue
if ($listening) {
  Write-Host 'Session server already running on 8787.'
} else {
  Write-Host 'Starting session server (Ctrl+C to stop)...'
  node server/session_server.mjs
}
