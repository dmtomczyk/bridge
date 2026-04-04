#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BRIDGE_BUILD_DIR:-$ROOT_DIR/client/build/v8-off}"
ctest --test-dir "$BUILD_DIR" --output-on-failure -R 'blink_backend_stub_test|custom_backend_bridge_test'
