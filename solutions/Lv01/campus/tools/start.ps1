# ============================================================
# Lv01 · 后台启动应用并记录日志（等价于 mvn spring-boot:run）
#
# 用法：
#   powershell -File tools\start.ps1                       # 用 application.yml 的 8080
#   powershell -File tools\start.ps1 -Name port9090 -Port 9090
#   powershell -File tools\start.ps1 -Name e01             # 实验用，日志名区分
#
# 产出：
#   target\<Name>.log      启动日志（stdout）
#   target\<Name>.err.log  错误输出（stderr）
#   target\<Name>.pid      进程号，供 tools\stop.ps1 使用
# ============================================================
param(
    [string]$Name = 'startup',
    [int]$Port = 0
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$repo = Join-Path $env:USERPROFILE '.m2\repository'

$deps = Get-Content (Join-Path $PSScriptRoot 'deps.txt') |
          Where-Object { $_ -and -not $_.StartsWith('#') } |
          ForEach-Object { Join-Path $repo ($_.Trim() -replace '/', '\') }

$classes = Join-Path $root 'target\classes'
$target  = Join-Path $root 'target'

$log  = Join-Path $target "$Name.log"
$elog = Join-Path $target "$Name.err.log"
$pidf = Join-Path $target "$Name.pid"
Remove-Item $log, $elog, $pidf -Force -ErrorAction SilentlyContinue

# 子进程继承当前进程的环境变量，所以在这里设置即可
$env:CLASSPATH = ((@($classes) + $deps) -join ';')

$jvmArgs = @('com.campus.CampusApplication')
if ($Port -gt 0) { $jvmArgs += "--server.port=$Port" }

$p = Start-Process -FilePath 'java' -ArgumentList $jvmArgs `
        -RedirectStandardOutput $log -RedirectStandardError $elog `
        -PassThru -WindowStyle Hidden
$p.Id | Set-Content $pidf

Write-Host ("[start] PID = {0}   日志 = target\{1}.log" -f $p.Id, $Name)
