#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$ROOT_DIR/client"
ENGINE_CUSTOM_DIR="$ROOT_DIR/engine-custom"
ENGINE_CHROMIUM_DIR="$ROOT_DIR/engine-chromium"

ENGINE="all"
JS_MODE="both"
RUN_TESTS=1
CONFIGURE_ONLY=0
TARGETS=()
TEST_REGEX=""
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"
BUILD_ROOT="${BRIDGE_BUILD_ROOT:-$CLIENT_DIR/build}"
CMAKE_GENERATOR="${CMAKE_GENERATOR:-}"

if [[ -z "${BRIDGE_V8_INCLUDE_DIR:-}" && -d "$ENGINE_CUSTOM_DIR/third_party/v8/include" ]]; then
  export BRIDGE_V8_INCLUDE_DIR="$ENGINE_CUSTOM_DIR/third_party/v8/include"
elif [[ -z "${BRIDGE_V8_INCLUDE_DIR:-}" && -d "$ROOT_DIR/third_party/v8/include" ]]; then
  export BRIDGE_V8_INCLUDE_DIR="$ROOT_DIR/third_party/v8/include"
fi

if [[ -z "${BRIDGE_V8_LIBRARY_DIR:-}" && -d "$ENGINE_CUSTOM_DIR/third_party/v8/out.gn/x64.release/obj" ]]; then
  export BRIDGE_V8_LIBRARY_DIR="$ENGINE_CUSTOM_DIR/third_party/v8/out.gn/x64.release/obj"
elif [[ -z "${BRIDGE_V8_LIBRARY_DIR:-}" && -d "$ROOT_DIR/third_party/v8/out.gn/x64.release/obj" ]]; then
  export BRIDGE_V8_LIBRARY_DIR="$ROOT_DIR/third_party/v8/out.gn/x64.release/obj"
fi

if [[ -z "${BRIDGE_V8_INCLUDE_DIR:-}" && -n "${BROWZ_V8_INCLUDE_DIR:-}" ]]; then
  export BRIDGE_V8_INCLUDE_DIR="$BROWZ_V8_INCLUDE_DIR"
fi
if [[ -z "${BRIDGE_V8_LIBRARY_DIR:-}" && -n "${BROWZ_V8_LIBRARY_DIR:-}" ]]; then
  export BRIDGE_V8_LIBRARY_DIR="$BROWZ_V8_LIBRARY_DIR"
fi

V8_INCLUDE_DIR="${BRIDGE_V8_INCLUDE_DIR:-${V8_INCLUDE_DIR:-}}"
V8_LIBRARY_DIR="${BRIDGE_V8_LIBRARY_DIR:-${V8_LIB_DIR:-}}"

usage() {
  cat <<'EOF'
Usage: ./compile.sh [options]

Examples:
  ./compile.sh --engine chromium --js off
  ./compile.sh --engine custom --js v8
  ./compile.sh --engine custom --js off --target browser --target custom_backend_bridge_test
  ./compile.sh --engine chromium --js off --tests -R blink_backend_stub_test
  ./compile.sh --engine all --js both

  # Real CEF builds currently use the dedicated client CMake flags directly:
  cmake -S ./client -B ./client/build/cef-hybrid-real \
    -DBRIDGE_ENABLED_ENGINES='custom;chromium;cef' \
    -DBRIDGE_ENGINE_CEF_ENABLE_CEF=ON \
    -DBRIDGE_CEF_ROOT=/path/to/cef_binary_...

Options:
  --engine <custom|chromium|all>
      Select the backend focus for this wrapper build.
      custom   -> build custom-engine targets/tests only
      chromium -> build Chromium reference seam targets/tests only
      all      -> build the full client graph (default)

      Note: real CEF-enabled builds are not owned by this wrapper yet; use the
      dedicated client CMake flags shown in the examples section.

  --js <off|v8|both>
      Select JS/V8 mode.
      off  -> BRIDGE_ENABLE_V8=OFF
      v8   -> BRIDGE_ENABLE_V8=ON
      both -> build both variants in separate build dirs (default)

  --target <name>
      Build only the specified CMake target(s). Repeatable.
      If omitted, a sensible engine-specific default target set is used.

  --tests / --no-tests
      Run or skip tests after build. Default: --tests

  -R, --test-regex <regex>
      Restrict ctest to matching tests.

  --configure-only
      Configure CMake but do not build or test.

  --v8-include <path>
  --v8-lib <path>
      Override V8 include/library directories for --js v8.

  -j, --jobs <n>
      Parallel build jobs. Default: autodetect.

  -h, --help
      Show this help.

Build directories:
  client/build/<engine>-v8-off
  client/build/<engine>-v8-on
  client/build/all-v8-off
  client/build/all-v8-on

Notes:
  - This is a workspace-level wrapper around the client CMake graph.
  - It improves selection of targets/tests, but the current CMake graph still
    configures both engine repos because client links both backends today.
  - `engine-cef` is the active long-term Chromium backend target, but real
    CEF-enabled builds still go through the dedicated client CMake flags rather
    than this wrapper.
EOF
}

normalize_js_mode() {
  case "$1" in
    off) echo "off" ;;
    on|v8) echo "v8" ;;
    both) echo "both" ;;
    *)
      echo "Invalid --js value: $1" >&2
      exit 1
      ;;
  esac
}

validate_engine() {
  case "$1" in
    custom|chromium|all) ;;
    *)
      echo "Invalid --engine value: $1" >&2
      exit 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --engine)
      ENGINE="${2:-}"
      validate_engine "$ENGINE"
      shift 2
      ;;
    --js)
      JS_MODE="$(normalize_js_mode "${2:-}")"
      shift 2
      ;;
    off|on|both)
      JS_MODE="$(normalize_js_mode "$1")"
      shift
      ;;
    --target)
      TARGETS+=("${2:-}")
      shift 2
      ;;
    --tests)
      RUN_TESTS=1
      shift
      ;;
    --no-tests)
      RUN_TESTS=0
      shift
      ;;
    -R|--test-regex)
      TEST_REGEX="${2:-}"
      shift 2
      ;;
    --configure-only)
      CONFIGURE_ONLY=1
      shift
      ;;
    --v8-include)
      V8_INCLUDE_DIR="${2:-}"
      shift 2
      ;;
    --v8-lib)
      V8_LIBRARY_DIR="${2:-}"
      shift 2
      ;;
    -j|--jobs)
      JOBS="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

build_targets_for_engine() {
  local engine="$1"
  if ((${#TARGETS[@]} > 0)); then
    printf '%s\n' "${TARGETS[@]}"
    return
  fi

  case "$engine" in
    custom)
      printf '%s\n' \
        browser \
        navigation_test \
        url_loader_test \
        load_error_page_test \
        application_external_script_test \
        application_external_image_test \
        application_navigation_cleanup_test \
        compatibility_smoke_test \
        url_loader_http_integration_test \
        url_loader_https_integration_test \
        html_parser_test \
        style_engine_test \
        style_engine_external_css_test \
        layout_engine_test \
        render_quality_layout_test \
        render_quality_paint_test \
        render_snapshot_hash_test \
        hit_regions_test \
        custom_backend_bridge_test \
        js_runtime_test \
        js_runtime_smoke_test
      ;;
    chromium)
      printf '%s\n' \
        browser \
        blink_backend_stub_test
      ;;
    all)
      printf '%s\n'
      ;;
  esac
}

test_regex_for_engine() {
  local engine="$1"
  if [[ -n "$TEST_REGEX" ]]; then
    printf '%s\n' "$TEST_REGEX"
    return
  fi

  case "$engine" in
    custom)
      printf '%s\n' 'custom_backend_bridge_test|js_runtime_test|js_runtime_smoke_test|url_loader_test|html_parser_test|style_engine_test|style_engine_external_css_test|layout_engine_test|render_quality_layout_test|render_quality_paint_test|render_snapshot_hash_test|hit_regions_test|url_loader_http_integration_test|url_loader_https_integration_test|load_error_page_test|application_external_script_test|application_external_image_test|application_navigation_cleanup_test|compatibility_smoke_test|navigation_test'
      ;;
    chromium)
      printf '%s\n' 'blink_backend_stub_test'
      ;;
    all)
      printf '%s\n' ''
      ;;
  esac
}

configure_variant() {
  local engine="$1"
  local js_mode="$2"
  local v8_enabled="$3"
  local build_dir="$BUILD_ROOT/${engine}-${js_mode}"

  mkdir -p "$BUILD_ROOT"

  # Transitional reality: the client graph still needs both engine repos present at
  # configure/build time even when the caller only wants to focus builds/tests on
  # one engine. The engine selector below narrows targets/tests, not the configured
  # repo set.
  local enabled_engines="custom;chromium"

  local cmake_args=(
    -S "$CLIENT_DIR"
    -B "$build_dir"
    -DBRIDGE_ENABLE_V8="$v8_enabled"
    -DBRIDGE_ENABLED_ENGINES="$enabled_engines"
    -DBRIDGE_ENGINE_CUSTOM_DIR="$ENGINE_CUSTOM_DIR"
    -DBRIDGE_ENGINE_CHROMIUM_DIR="$ENGINE_CHROMIUM_DIR"
  )

  if [[ -n "$CMAKE_GENERATOR" ]]; then
    cmake_args+=(-G "$CMAKE_GENERATOR")
  fi

  if [[ "$v8_enabled" == "ON" ]]; then
    if [[ -z "$V8_INCLUDE_DIR" || -z "$V8_LIBRARY_DIR" ]]; then
      echo "V8-enabled build requested but V8 paths are missing." >&2
      echo "Provide --v8-include and --v8-lib, or make sure engine-custom/third_party/v8 exists." >&2
      exit 1
    fi
    cmake_args+=(
      -DBRIDGE_V8_INCLUDE_DIR="$V8_INCLUDE_DIR"
      -DBRIDGE_V8_LIBRARY_DIR="$V8_LIBRARY_DIR"
    )
  fi

  echo "==> Configuring $build_dir" >&2
  cmake "${cmake_args[@]}" >&2

  printf '%s\n' "$build_dir"
}

build_and_test_variant() {
  local engine="$1"
  local js_mode="$2"
  local v8_enabled="$3"
  local build_dir
  build_dir="$(configure_variant "$engine" "$js_mode" "$v8_enabled")"

  if [[ "$CONFIGURE_ONLY" -eq 1 ]]; then
    return
  fi

  mapfile -t resolved_targets < <(build_targets_for_engine "$engine")
  if ((${#resolved_targets[@]} > 0)); then
    echo "==> Building targets for engine=$engine js=$js_mode: ${resolved_targets[*]}"
    cmake --build "$build_dir" -j "$JOBS" --target "${resolved_targets[@]}"
  else
    echo "==> Building default target set for engine=$engine js=$js_mode"
    cmake --build "$build_dir" -j "$JOBS"
  fi

  if [[ "$RUN_TESTS" -eq 1 ]]; then
    local regex
    regex="$(test_regex_for_engine "$engine")"
    echo "==> Running tests for engine=$engine js=$js_mode"
    if [[ -n "$regex" ]]; then
      ctest --test-dir "$build_dir" --output-on-failure -R "$regex"
    else
      ctest --test-dir "$build_dir" --output-on-failure
    fi
  fi
}

case "$JS_MODE" in
  off)
    build_and_test_variant "$ENGINE" "v8-off" "OFF"
    ;;
  v8)
    build_and_test_variant "$ENGINE" "v8-on" "ON"
    ;;
  both)
    build_and_test_variant "$ENGINE" "v8-off" "OFF"
    build_and_test_variant "$ENGINE" "v8-on" "ON"
    ;;
esac

echo
echo "Done. Build directories:"
case "$JS_MODE" in
  off)
    echo "  $BUILD_ROOT/${ENGINE}-v8-off"
    ;;
  v8)
    echo "  $BUILD_ROOT/${ENGINE}-v8-on"
    ;;
  both)
    echo "  $BUILD_ROOT/${ENGINE}-v8-off"
    echo "  $BUILD_ROOT/${ENGINE}-v8-on"
    ;;
esac
