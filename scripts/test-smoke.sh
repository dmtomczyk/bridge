#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CLASSIC_BUILD_DIR="${BRIDGE_BUILD_DIR:-$ROOT_DIR/client/build/v8-off}"
LANE="classic"
URL="data:text/html,<html><body>cef smoke</body></html>"

usage() {
  cat <<EOF
Usage: ./scripts/test-smoke.sh [options] [url]

Options:
  --lane <classic|cef>   smoke lane to run (default: classic)
  --build-dir <path>     override classic ctest build dir
  -h, --help             show help

Lanes:
  classic  -> runs focused scaffold smoke tests from the client build dir
  cef      -> runs the real-CEF smoke helper via ./scripts/cef-runtime-smoke.sh

Examples:
  ./scripts/test-smoke.sh
  ./scripts/test-smoke.sh --lane classic --build-dir ./client/build/custom-v8-off
  CEF_ROOT=/path/to/cef_binary_... ./scripts/test-smoke.sh --lane cef
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lane)
      LANE="${2:-}"
      shift 2
      ;;
    --build-dir)
      CLASSIC_BUILD_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      URL="$1"
      shift
      ;;
  esac
done

case "$LANE" in
  classic)
    exec ctest --test-dir "$CLASSIC_BUILD_DIR" --output-on-failure \
      -R 'blink_backend_stub_test|custom_backend_bridge_test|cef_backend_hybrid_test|cef_backend_bridge_preference_test'
    ;;
  cef)
    exec "$ROOT_DIR/scripts/cef-runtime-smoke.sh" "$URL"
    ;;
  *)
    echo "Unknown --lane value: $LANE" >&2
    usage >&2
    exit 1
    ;;
esac
