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

function Test-RepoPopulated([string]$RepoPath) {
    if (-not (Test-Path -Path $RepoPath -PathType Container)) {
        return $false
    }
    return $null -ne (Get-ChildItem -Path $RepoPath -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
}

$RepoRoot = (Resolve-Path $RepoRoot).Path

Write-Step 'Initializing Bridge workspace submodules'
& git -C $RepoRoot submodule update --init --recursive

if ($Update) {
    Write-Step 'Updating submodules to tracked remote refs'
    & git -C $RepoRoot submodule update --remote --recursive
}

$repoChecks = @(
    @{ Name = 'core'; Type = 'populated-dir'; Path = (Join-Path $RepoRoot 'core') },
    @{ Name = 'browser'; Type = 'cmake'; Path = (Join-Path $RepoRoot 'browser\CMakeLists.txt') },
    @{ Name = 'engine-custom'; Type = 'cmake'; Path = (Join-Path $RepoRoot 'engine-custom\CMakeLists.txt') },
    @{ Name = 'engine-chromium'; Type = 'cmake'; Path = (Join-Path $RepoRoot 'engine-chromium\CMakeLists.txt') },
    @{ Name = 'engine-cef'; Type = 'cmake'; Path = (Join-Path $RepoRoot 'engine-cef\CMakeLists.txt') }
)

foreach ($check in $repoChecks) {
    if ($check.Type -eq 'populated-dir') {
        if (-not (Test-RepoPopulated $check.Path)) {
            throw "Missing expected populated repo directory: $($check.Path)"
        }
    }
    elseif (-not (Test-Path $check.Path)) {
        throw "Missing expected repo file: $($check.Path)"
    }
    Write-Host "ok: $($check.Name)"
}

Write-Host ''
Write-Host 'Bootstrap complete.' -ForegroundColor Green
Write-Host 'Next steps:' -ForegroundColor Yellow
Write-Host '  Linux/macOS scaffold build: ./compile.sh --engine chromium --js off'
Write-Host '  Windows scaffold build: .\build.ps1 -Engine chromium -Js off'
Write-Host '  Windows CEF smoke bootstrap: .\scripts\windows-smoke-bootstrap.ps1 -CefRoot C:\path\to\cef_binary_...'
