# ============================================================
# Lv01 · 停止由 tools\start.ps1 启动的应用
# 用法： powershell -File tools\stop.ps1 [-Name startup]
# ============================================================
param([string]$Name = 'startup')

$root = Split-Path -Parent $PSScriptRoot
$pidf = Join-Path $root "target\$Name.pid"

if (-not (Test-Path $pidf)) { Write-Host "[stop] 未找到 $Name.pid，可能未启动"; exit 0 }

$appPid = (Get-Content $pidf -Raw).Trim()
$proc = Get-Process -Id $appPid -ErrorAction SilentlyContinue
if ($proc) {
    Stop-Process -Id $appPid -Force
    Write-Host ("[stop] 已停止 PID = " + $appPid)
} else {
    Write-Host ("[stop] PID " + $appPid + " 已不在运行")
}
Remove-Item $pidf -Force -ErrorAction SilentlyContinue
