# ============================================================
# Lv01 · 本机离线构建脚本（javac 版）
# ------------------------------------------------------------
# 为什么不用 mvn？
#   本机无外网，~/.m2/repository 只缓存了"应用依赖"和部分插件 jar，
#   插件自身的传递依赖（plexus-utils / maven-filtering 等）不全，
#   因此 mvn 在离线模式下连 resources 阶段都过不去。
#   所以这里用 JDK 自带的 javac —— 这正好演示了 Maven 平时替你做的三件事：
#   解析依赖闭包、拼 classpath、调用编译器。
#
# 一旦有外网，应改回： mvn spring-boot:run
#   见 docs/levels/Lv01-SpringBoot启动.md 附录 A · A.2
#
# 用法： powershell -File tools\build.ps1
# ============================================================
$ErrorActionPreference = 'Stop'

$root   = Split-Path -Parent $PSScriptRoot
$repo   = Join-Path $env:USERPROFILE '.m2\repository'
$deps   = Get-Content (Join-Path $PSScriptRoot 'deps.txt') |
            Where-Object { $_ -and -not $_.StartsWith('#') } |
            ForEach-Object { Join-Path $repo ($_.Trim() -replace '/', '\') }

# 校验依赖是否齐全，缺哪个直接报出来
$missing = $deps | Where-Object { -not (Test-Path $_) }
if ($missing) { throw ("依赖缺失:`n" + ($missing -join "`n")) }

$classes = Join-Path $root 'target\classes'
Remove-Item $classes -Recurse -Force -ErrorAction SilentlyContinue
New-Item $classes -ItemType Directory -Force | Out-Null

$src = @(Get-ChildItem (Join-Path $root 'src\main\java') -Filter *.java -Recurse |
            Select-Object -ExpandProperty FullName)

# 注意：classpath 用环境变量传，不要写成 javac -cp <超长字符串>。
# Windows PowerShell 5.1 在把含分号/反斜杠的长参数交给原生 exe 时会破坏它。
$env:CLASSPATH = ((@($classes) + $deps) -join ';')

Write-Host ("[build] 依赖 jar : " + $deps.Count)
Write-Host ("[build] 源文件   : " + $src.Count)

# --release 17：用本机 JDK 编译，产出 Java 17 字节码（对应 pom 的 java.version）
& javac --release 17 -encoding UTF-8 -d $classes $src
if ($LASTEXITCODE -ne 0) { throw "javac 编译失败（退出码 $LASTEXITCODE）" }

Copy-Item (Join-Path $root 'src\main\resources\*') $classes -Recurse -Force
Write-Host "[build] OK -> $classes"
