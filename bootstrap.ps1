param(
    [switch]$Update,
    [string]$RepoRoot = (Resolve-Path $PSScriptRoot).Path
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$Text) {
    Write-Host "==> $Text" -ForegroundColor Cyan
}

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found in PATH: $Name"
    }
}

Require-Command git

$RepoRoot = (Resolve-Path $RepoRoot).Path

Write-Step 'Initializing Bridge workspace submodules'
& git -C $RepoRoot submodule update --init --recursive

if ($Update) {
    Write-Step 'Updating submodules to tracked remote refs'
    & git -C $RepoRoot submodule update --remote --recursive
}

foreach ($repo in @('core', 'browser', 'engine-custom', 'engine-chromium', 'engine-cef')) {
    $cmakePath = Join-Path (Join-Path $RepoRoot $repo) 'CMakeLists.txt'
    if (-not (Test-Path $cmakePath)) {
        throw "Missing expected repo or CMakeLists.txt: $cmakePath"
    }
    Write-Host "ok: $repo"
}

Write-Host ''
Write-Host 'Bootstrap complete.' -ForegroundColor Green
Write-Host 'Next steps:' -ForegroundColor Yellow
Write-Host '  Linux/macOS scaffold build: ./compile.sh --engine chromium --js off'
Write-Host '  Windows scaffold build: .\build.ps1 -Engine chromium -Js off'
Write-Host '  Windows CEF smoke bootstrap: .\scripts\windows-smoke-bootstrap.ps1 -CefRoot C:\path\to\cef_binary_...'
