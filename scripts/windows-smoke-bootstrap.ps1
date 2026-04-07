param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [Parameter(Mandatory = $true)]
    [string]$CefRoot,
    [string]$BuildDir = "browser\build\cef-hybrid-real-browser-win",
    [switch]$SkipSubmodules,
    [switch]$SkipBuild,
    [switch]$OpenBuildDir
)

$ErrorActionPreference = "Stop"

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found in PATH: $Name"
    }
}

function Write-Step([string]$Text) {
    Write-Host "==> $Text" -ForegroundColor Cyan
}

Require-Command git
Require-Command cmake
Require-Command ninja

$RepoRoot = (Resolve-Path $RepoRoot).Path
$BrowserDir = Join-Path $RepoRoot "browser"
if (-not (Test-Path (Join-Path $BrowserDir "CMakeLists.txt"))) {
    throw "Browser CMakeLists.txt not found at expected path: $BrowserDir"
}

$CefRoot = (Resolve-Path $CefRoot).Path
if (-not (Test-Path (Join-Path $CefRoot "cmake"))) {
    throw "CEF root does not look valid (missing cmake dir): $CefRoot"
}

$BuildPath = Join-Path $RepoRoot $BuildDir

Write-Step "Repository root: $RepoRoot"
Write-Step "CEF root: $CefRoot"
Write-Step "Build dir: $BuildPath"

Push-Location $RepoRoot
try {
    if (-not $SkipSubmodules) {
        Write-Step "Updating submodules"
        git submodule update --init --recursive
    }

    Write-Step "Configuring Windows runtime-host build"
    $configureArgs = @(
        '-S', $BrowserDir,
        '-B', $BuildPath,
        '-G', 'Ninja',
        '-DBRIDGE_ENABLED_ENGINES:STRING=custom;cef',
        '-DBRIDGE_ENGINE_CEF_ENABLE_CEF=ON',
        "-DBRIDGE_CEF_ROOT=$CefRoot",
        '-DENGINE_CEF_RUNTIME_TARGET_PLATFORM=windows'
    )
    & cmake @configureArgs

    if (-not $SkipBuild) {
        Write-Step "Building key Windows smoke targets"
        $buildArgs = @(
            '--build', $BuildPath,
            '--target', 'browser_cef_runtime_probe', 'browser_cef_runtime_browser', 'browser'
        )
        & cmake @buildArgs
    }

    Write-Step "Build complete"
    Write-Host "Suggested first smoke executable:" -ForegroundColor Green
    Write-Host "  $(Join-Path $BuildPath 'browser_cef_runtime_browser.exe')"
    Write-Host "Alternative runtime-host launch:" -ForegroundColor Green
    Write-Host "  $(Join-Path $BuildPath 'browser.exe') --renderer=cef-runtime-host"
    Write-Host ""
    Write-Host "Recipe:" -ForegroundColor Yellow
    Write-Host "  engine-cef/docs/windows-runtime-host-smoke-recipe-2026-04-06.md"

    if ($OpenBuildDir) {
        Write-Step "Opening build directory"
        Start-Process explorer.exe $BuildPath
    }
}
finally {
    Pop-Location
}
