# ============================================================
# Lv01 · 本机离线启动脚本（java 版，等价于 mvn spring-boot:run）
#
# 用法：
#   powershell -File tools\run.ps1
#   powershell -File tools\run.ps1 --server.port=9090     # 命令行参数优先于 yml
# ============================================================
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$repo = Join-Path $env:USERPROFILE '.m2\repository'

$deps = Get-Content (Join-Path $PSScriptRoot 'deps.txt') |
          Where-Object { $_ -and -not $_.StartsWith('#') } |
          ForEach-Object { Join-Path $repo ($_.Trim() -replace '/', '\') }

$classes = Join-Path $root 'target\classes'
if (-not (Test-Path (Join-Path $classes 'com\campus\CampusApplication.class'))) {
    throw "尚未构建，请先执行 tools\build.ps1"
}

$env:CLASSPATH = ((@($classes) + $deps) -join ';')

& java com.campus.CampusApplication @args
