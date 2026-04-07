#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BROWSER_DIR="$ROOT_DIR/browser"
BUILD_DIR="${BRIDGE_CEF_BUILD_DIR:-$BROWSER_DIR/build/cef-hybrid-real}"
CEF_ROOT_DEFAULT="${BRIDGE_CEF_ROOT:-${CEF_ROOT:-}}"
URL="${1:-data:text/html,<html><body>cef runtime smoke</body></html>}"

usage() {
  cat <<EOF
Usage: ./scripts/cef-runtime-smoke.sh [url]

Runs the current real-CEF browser smoke lane from the workspace root.

Environment:
  BRIDGE_CEF_ROOT / CEF_ROOT   path to cef_binary_... (required)
  BRIDGE_CEF_BUILD_DIR         build dir override (default: $BUILD_DIR)

What this does:
  1. configures the real-CEF browser build
  2. builds cef_runtime_host_smoke_test and browser_cef_runtime_probe
  3. runs the smoke test
  4. runs the browser-owned runtime probe against the provided URL
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -z "$CEF_ROOT_DEFAULT" ]]; then
  echo "CEF_ROOT is required. Set BRIDGE_CEF_ROOT or CEF_ROOT to your cef_binary_... path." >&2
  exit 1
fi

cmake -S "$BROWSER_DIR" -B "$BUILD_DIR" \
  -DBRIDGE_ENABLED_ENGINES='custom;chromium;cef' \
  -DBRIDGE_ENGINE_CEF_ENABLE_CEF=ON \
  -DBRIDGE_CEF_ROOT="$CEF_ROOT_DEFAULT"

cmake --build "$BUILD_DIR" -j "${JOBS:-$(nproc 2>/dev/null || echo 4)}" \
  --target cef_runtime_host_smoke_test browser_cef_runtime_probe

ctest --test-dir "$BUILD_DIR" --output-on-failure -R '^cef_runtime_host_smoke_test$'

PROBE_BIN="$BUILD_DIR/_deps/engine-cef/Release/browser_cef_runtime_probe"
if [[ ! -x "$PROBE_BIN" ]]; then
  echo "Browser CEF runtime probe not found: $PROBE_BIN" >&2
  exit 1
fi

exec "$PROBE_BIN" "--url=$URL"
