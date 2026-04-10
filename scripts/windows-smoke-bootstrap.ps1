param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$CefRoot,
    [string]$BuildDir = "browser\build\cef-hybrid-real-browser-win",
    [switch]$SkipSubmodules,
    [switch]$SkipBuild,
    [switch]$OpenBuildDir,
    [switch]$PreflightOnly
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Step([string]$Text) {
    Write-Host "==> $Text" -ForegroundColor Cyan
}

function Write-Info([string]$Text) {
    Write-Host "    $Text" -ForegroundColor DarkGray
}

function Add-Issue($Issues, [string]$Name, [string]$Problem, [string]$Fix) {
    $Issues.Add([pscustomobject]@{
        Name = $Name
        Problem = $Problem
        Fix = $Fix
    }) | Out-Null
}

function Test-CommandAvailable([string]$Name) {
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Assert-LastExit([string]$StepName) {
    if ($LASTEXITCODE -ne 0) {
        throw "$StepName failed with exit code $LASTEXITCODE"
    }
}

function Test-FileAny([string[]]$Paths) {
    foreach ($path in $Paths) {
        if (Test-Path $path) {
            return $true
        }
    }
    return $false
}

function Test-RepoPopulated([string]$RepoPath) {
    if (-not (Test-Path $RepoPath -PathType Container)) {
        return $false
    }
    return $null -ne (Get-ChildItem -Force -ErrorAction SilentlyContinue $RepoPath | Select-Object -First 1)
}

$issues = New-Object System.Collections.Generic.List[object]

$RepoRoot = (Resolve-Path $RepoRoot).Path
$BrowserDir = Join-Path $RepoRoot "browser"
$CoreDir = Join-Path $RepoRoot "core"
$EngineCustomDir = Join-Path $RepoRoot "engine-custom"
$EngineChromiumDir = Join-Path $RepoRoot "engine-chromium"
$EngineCefDir = Join-Path $RepoRoot "engine-cef"
$BuildPath = Join-Path $RepoRoot $BuildDir

$cefRootSource = $null
if ($CefRoot) {
    $cefRootSource = 'argument'
}
elseif ($env:BRIDGE_CEF_ROOT) {
    $CefRoot = $env:BRIDGE_CEF_ROOT
    $cefRootSource = 'BRIDGE_CEF_ROOT'
}
elseif ($env:CEF_ROOT) {
    $CefRoot = $env:CEF_ROOT
    $cefRootSource = 'CEF_ROOT'
}

Write-Step "Windows smoke preflight"
Write-Info "Repository root: $RepoRoot"
if ($CefRoot) {
    Write-Info "CEF root ($cefRootSource): $CefRoot"
}
else {
    Write-Info "CEF root: <not set>"
}
Write-Info "Build dir: $BuildPath"

if (-not (Test-CommandAvailable 'git')) {
    Add-Issue $issues 'git' 'git is not available in PATH.' 'Install Git for Windows and ensure `git.exe` is available in PATH.'
}

if (-not (Test-CommandAvailable 'cmake')) {
    Add-Issue $issues 'cmake' 'cmake is not available in PATH.' 'Install CMake and ensure `cmake.exe` is available in PATH.'
}

if (-not (Test-CommandAvailable 'ninja')) {
    Add-Issue $issues 'ninja' 'ninja is not available in PATH.' 'Install Ninja (`winget install Ninja-build.Ninja`) or use a shell/environment where `ninja.exe` is already available.'
}

if (-not (Test-CommandAvailable 'cl')) {
    Add-Issue $issues 'MSVC compiler (cl.exe)' 'The Visual C++ compiler is not available in PATH for this PowerShell session.' 'Open a "Developer PowerShell for VS 2022" or import vcvars64.bat into the current session, then confirm `Get-Command cl` works before rerunning.'
}

if (-not (Test-CommandAvailable 'link')) {
    Add-Issue $issues 'MSVC linker (link.exe)' 'The Visual Studio linker is not available in PATH for this PowerShell session.' 'Open a "Developer PowerShell for VS 2022" or import vcvars64.bat into the current session, then confirm `Get-Command link` works before rerunning.'
}

if (-not (Test-Path $RepoRoot)) {
    Add-Issue $issues 'workspace root' "Repo root does not exist: $RepoRoot" 'Run the script from the Bridge workspace or pass -RepoRoot to the correct checkout path.'
}

foreach ($entry in @(
    @{ Name = 'browser repo'; Kind = 'cmake'; Path = (Join-Path $BrowserDir 'CMakeLists.txt'); Fix = 'Run .\bootstrap.ps1 (or `git submodule update --init --recursive`) from the workspace root.' },
    @{ Name = 'core repo'; Kind = 'populated-dir'; Path = $CoreDir; Fix = 'Run .\bootstrap.ps1 (or `git submodule update --init --recursive`) from the workspace root.' },
    @{ Name = 'engine-custom repo'; Kind = 'cmake'; Path = (Join-Path $EngineCustomDir 'CMakeLists.txt'); Fix = 'Run .\bootstrap.ps1 (or `git submodule update --init --recursive`) from the workspace root.' },
    @{ Name = 'engine-chromium repo'; Kind = 'cmake'; Path = (Join-Path $EngineChromiumDir 'CMakeLists.txt'); Fix = 'Run .\bootstrap.ps1 (or `git submodule update --init --recursive`) from the workspace root.' },
    @{ Name = 'engine-cef repo'; Kind = 'cmake'; Path = (Join-Path $EngineCefDir 'CMakeLists.txt'); Fix = 'Run .\bootstrap.ps1 (or `git submodule update --init --recursive`) from the workspace root.' }
)) {
    if ($entry.Kind -eq 'populated-dir') {
        if (-not (Test-RepoPopulated $entry.Path)) {
            Add-Issue $issues $entry.Name "Missing or empty repo directory: $($entry.Path)" $entry.Fix
        }
    }
    elseif (-not (Test-Path $entry.Path)) {
        Add-Issue $issues $entry.Name "Missing expected file: $($entry.Path)" $entry.Fix
    }
}

if (-not $CefRoot) {
    Add-Issue $issues 'CEF root' 'No CEF root was provided.' 'Pass -CefRoot to an extracted `cef_binary_...` directory, or set BRIDGE_CEF_ROOT / CEF_ROOT in the environment before running the script.'
}
else {
    try {
        $CefRoot = (Resolve-Path $CefRoot).Path
    }
    catch {
        Add-Issue $issues 'CEF root' "CEF root path does not exist: $CefRoot" 'Pass -CefRoot to an extracted `cef_binary_...` directory, or set BRIDGE_CEF_ROOT / CEF_ROOT to a valid path.'
    }
}

if ($CefRoot -and (Test-Path $CefRoot)) {
    if (-not (Test-Path (Join-Path $CefRoot 'cmake'))) {
        Add-Issue $issues 'CEF cmake directory' "CEF root is missing the `cmake` directory: $CefRoot" 'Point -CefRoot at the top-level extracted CEF binary distribution directory.'
    }

    if (-not (Test-Path (Join-Path $CefRoot 'cmake\FindCEF.cmake'))) {
        Add-Issue $issues 'FindCEF.cmake' "CEF root is missing `cmake\\FindCEF.cmake`: $CefRoot" 'Use a full CEF binary distribution that includes the CMake integration files.'
    }

    if (-not (Test-Path (Join-Path $CefRoot 'include\cef_version.h'))) {
        Add-Issue $issues 'CEF headers' "CEF root is missing `include\\cef_version.h`: $CefRoot" 'Use a full extracted CEF SDK/binary directory, not just runtime DLLs.'
    }

    $cefBinaryPresent = Test-FileAny @(
        (Join-Path $CefRoot 'Release\libcef.dll'),
        (Join-Path $CefRoot 'Debug\libcef.dll'),
        (Join-Path $CefRoot 'libcef.dll')
    )
    if (-not $cefBinaryPresent) {
        Add-Issue $issues 'CEF runtime binary' "Could not find libcef.dll under $CefRoot" 'Verify that -CefRoot points to an extracted Windows CEF binary distribution with Release/Debug runtime files.'
    }

    $cefLibPresent = Test-FileAny @(
        (Join-Path $CefRoot 'Release\libcef.lib'),
        (Join-Path $CefRoot 'Debug\libcef.lib'),
        (Join-Path $CefRoot 'libcef.lib')
    )
    if (-not $cefLibPresent) {
        Add-Issue $issues 'CEF import library' "Could not find libcef.lib under $CefRoot" 'Verify that -CefRoot points to a Windows CEF distribution with development libraries, not runtime-only files.'
    }
}

if ($issues.Count -gt 0) {
    Write-Host ''
    Write-Host 'Preflight failed. Missing or invalid dependencies:' -ForegroundColor Red
    Write-Host ''
    $i = 1
    foreach ($issue in $issues) {
        Write-Host ("{0}. {1}" -f $i, $issue.Name) -ForegroundColor Yellow
        Write-Host ("   Problem: {0}" -f $issue.Problem)
        Write-Host ("   Fix:     {0}" -f $issue.Fix)
        Write-Host ''
        $i++
    }
    exit 1
}

Write-Host ''
Write-Host 'Preflight passed.' -ForegroundColor Green

if ($PreflightOnly) {
    Write-Host 'Stopping after preflight because -PreflightOnly was requested.' -ForegroundColor Yellow
    exit 0
}

Push-Location $RepoRoot
try {
    if (-not $SkipSubmodules) {
        Write-Step 'Updating submodules'
        & git submodule update --init --recursive
        Assert-LastExit 'git submodule update'
    }

    Write-Step 'Configuring Windows runtime-host build'
    $configureArgs = @(
        '-S', $BrowserDir,
        '-B', $BuildPath,
        '-G', 'Ninja',
        '-DBRIDGE_ENABLED_ENGINES:STRING=custom;cef',
        '-DBRIDGE_ENGINE_CEF_ENABLE_CEF=ON',
        "-DBRIDGE_CORE_DIR=$CoreDir",
        "-DBRIDGE_ENGINE_CUSTOM_DIR=$EngineCustomDir",
        "-DBRIDGE_ENGINE_CHROMIUM_DIR=$EngineChromiumDir",
        "-DBRIDGE_ENGINE_CEF_DIR=$EngineCefDir",
        "-DBRIDGE_CEF_ROOT=$CefRoot",
        '-DENGINE_CEF_RUNTIME_TARGET_PLATFORM=windows'
    )
    & cmake @configureArgs
    Assert-LastExit 'cmake configure'

    if (-not $SkipBuild) {
        Write-Step 'Building key Windows smoke targets'
        $buildArgs = @(
            '--build', $BuildPath,
            '--target', 'browser_cef_runtime_probe', 'browser_cef_runtime_browser', 'browser'
        )
        & cmake @buildArgs
        Assert-LastExit 'cmake build'
    }

    Write-Step 'Build complete'
    Write-Host 'Suggested first smoke executable:' -ForegroundColor Green
    Write-Host "  $(Join-Path $BuildPath 'browser_cef_runtime_browser.exe')"
    Write-Host 'Alternative runtime-host launch:' -ForegroundColor Green
    Write-Host "  $(Join-Path $BuildPath 'browser.exe') --renderer=cef-runtime-host"
    Write-Host ''
    Write-Host 'Recipe:' -ForegroundColor Yellow
    Write-Host '  engine-cef/docs/windows-runtime-host-smoke-recipe-2026-04-06.md'

    if ($OpenBuildDir) {
        Write-Step 'Opening build directory'
        Start-Process explorer.exe $BuildPath
    }
}
finally {
    Pop-Location
}
