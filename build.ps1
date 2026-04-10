param(
    [ValidateSet('custom', 'chromium', 'all')]
    [string]$Engine = 'all',

    [ValidateSet('off', 'v8', 'both')]
    [string]$Js = 'both',

    [switch]$Bootstrap,
    [switch]$ConfigureOnly,
    [switch]$NoTests,
    [string[]]$Target,
    [string]$TestRegex,
    [string]$Generator,
    [int]$Jobs = 0,
    [string]$V8Include,
    [string]$V8Lib,
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
Require-Command cmake

function Test-RepoPopulated([string]$RepoPath) {
    if (-not (Test-Path $RepoPath -PathType Container)) {
        return $false
    }
    return $null -ne (Get-ChildItem -Force -ErrorAction SilentlyContinue $RepoPath | Select-Object -First 1)
}

$RepoRoot = (Resolve-Path $RepoRoot).Path
$BrowserDir = Join-Path $RepoRoot 'browser'
$CoreDir = Join-Path $RepoRoot 'core'
$EngineCustomDir = Join-Path $RepoRoot 'engine-custom'
$EngineChromiumDir = Join-Path $RepoRoot 'engine-chromium'
$EngineCefDir = Join-Path $RepoRoot 'engine-cef'
$BuildRoot = Join-Path $BrowserDir 'build'

foreach ($path in @(
    (Join-Path $BrowserDir 'CMakeLists.txt'),
    (Join-Path $EngineCustomDir 'CMakeLists.txt'),
    (Join-Path $EngineChromiumDir 'CMakeLists.txt'),
    (Join-Path $EngineCefDir 'CMakeLists.txt')
)) {
    if (-not (Test-Path $path)) {
        throw "Missing expected workspace path: $path`nRun .\\bootstrap.ps1 first or initialize submodules."
    }
}

if (-not (Test-RepoPopulated $CoreDir)) {
    throw "Missing expected populated workspace repo: $CoreDir`nRun .\\bootstrap.ps1 first or initialize submodules."
}

if ($Bootstrap) {
    Write-Step 'Initializing submodules'
    & git -C $RepoRoot submodule update --init --recursive
}

if ($Jobs -le 0) {
    $Jobs = [Math]::Max(1, [Environment]::ProcessorCount)
}

if ($Generator) {
    $env:CMAKE_GENERATOR = $Generator
}
if ($V8Include) {
    $env:BRIDGE_V8_INCLUDE_DIR = $V8Include
}
if ($V8Lib) {
    $env:BRIDGE_V8_LIBRARY_DIR = $V8Lib
}

function Get-BuildTargets([string]$SelectedEngine, [string[]]$ExplicitTargets) {
    if ($ExplicitTargets -and $ExplicitTargets.Count -gt 0) {
        return $ExplicitTargets
    }

    switch ($SelectedEngine) {
        'custom' {
            return @(
                'browser',
                'navigation_test',
                'url_loader_test',
                'load_error_page_test',
                'application_external_script_test',
                'application_external_image_test',
                'application_navigation_cleanup_test',
                'compatibility_smoke_test',
                'url_loader_http_integration_test',
                'url_loader_https_integration_test',
                'html_parser_test',
                'style_engine_test',
                'style_engine_external_css_test',
                'layout_engine_test',
                'render_quality_layout_test',
                'render_quality_paint_test',
                'render_snapshot_hash_test',
                'hit_regions_test',
                'custom_backend_bridge_test',
                'js_runtime_test',
                'js_runtime_smoke_test'
            )
        }
        'chromium' {
            return @('browser', 'blink_backend_stub_test')
        }
        default {
            return @()
        }
    }
}

function Get-TestRegex([string]$SelectedEngine, [string]$ExplicitRegex) {
    if ($ExplicitRegex) {
        return $ExplicitRegex
    }

    switch ($SelectedEngine) {
        'custom' {
            return 'custom_backend_bridge_test|js_runtime_test|js_runtime_smoke_test|url_loader_test|html_parser_test|style_engine_test|style_engine_external_css_test|layout_engine_test|render_quality_layout_test|render_quality_paint_test|render_snapshot_hash_test|hit_regions_test|url_loader_http_integration_test|url_loader_https_integration_test|load_error_page_test|application_external_script_test|application_external_image_test|application_navigation_cleanup_test|compatibility_smoke_test|navigation_test'
        }
        'chromium' {
            return 'blink_backend_stub_test'
        }
        default {
            return ''
        }
    }
}

function Invoke-BuildVariant([string]$SelectedEngine, [string]$VariantName, [string]$V8Enabled) {
    $buildDir = Join-Path $BuildRoot ("{0}-{1}" -f $SelectedEngine, $VariantName)
    $enabledEngines = 'custom;chromium'

    Write-Step "Configuring $buildDir"
    $configureArgs = @(
        '-S', $BrowserDir,
        '-B', $buildDir,
        "-DBRIDGE_ENABLE_V8=$V8Enabled",
        "-DBRIDGE_ENABLED_ENGINES=$enabledEngines",
        "-DBRIDGE_CORE_DIR=$CoreDir",
        "-DBRIDGE_ENGINE_CUSTOM_DIR=$EngineCustomDir",
        "-DBRIDGE_ENGINE_CHROMIUM_DIR=$EngineChromiumDir",
        "-DBRIDGE_ENGINE_CEF_DIR=$EngineCefDir"
    )
    if ($env:CMAKE_GENERATOR) {
        $configureArgs += @('-G', $env:CMAKE_GENERATOR)
    }
    if ($V8Enabled -eq 'ON') {
        if (-not $env:BRIDGE_V8_INCLUDE_DIR -or -not $env:BRIDGE_V8_LIBRARY_DIR) {
            throw 'V8-enabled build requested but BRIDGE_V8_INCLUDE_DIR / BRIDGE_V8_LIBRARY_DIR are not set. Pass -V8Include and -V8Lib.'
        }
        $configureArgs += @(
            "-DBRIDGE_V8_INCLUDE_DIR=$($env:BRIDGE_V8_INCLUDE_DIR)",
            "-DBRIDGE_V8_LIBRARY_DIR=$($env:BRIDGE_V8_LIBRARY_DIR)"
        )
    }
    & cmake @configureArgs

    if ($ConfigureOnly) {
        return
    }

    $targets = Get-BuildTargets -SelectedEngine $SelectedEngine -ExplicitTargets $Target
    if ($targets.Count -gt 0) {
        Write-Step "Building targets: $($targets -join ', ')"
        & cmake --build $buildDir --parallel $Jobs --target @targets
    }
    else {
        Write-Step 'Building default target set'
        & cmake --build $buildDir --parallel $Jobs
    }

    if (-not $NoTests) {
        $regex = Get-TestRegex -SelectedEngine $SelectedEngine -ExplicitRegex $TestRegex
        Write-Step 'Running tests'
        if ($regex) {
            & ctest --test-dir $buildDir --output-on-failure -R $regex
        }
        else {
            & ctest --test-dir $buildDir --output-on-failure
        }
    }
}

switch ($Js) {
    'off'  { Invoke-BuildVariant -SelectedEngine $Engine -VariantName 'v8-off' -V8Enabled 'OFF' }
    'v8'   { Invoke-BuildVariant -SelectedEngine $Engine -VariantName 'v8-on' -V8Enabled 'ON' }
    'both' {
        Invoke-BuildVariant -SelectedEngine $Engine -VariantName 'v8-off' -V8Enabled 'OFF'
        Invoke-BuildVariant -SelectedEngine $Engine -VariantName 'v8-on' -V8Enabled 'ON'
    }
}

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
