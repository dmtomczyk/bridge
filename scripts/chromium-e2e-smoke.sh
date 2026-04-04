#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CLIENT_DIR="$ROOT_DIR/client"
BUILD_DIR="${BRIDGE_BUILD_DIR:-$CLIENT_DIR/build/v8-off}"
BROWSER_BIN="$BUILD_DIR/browser"
URL="${1:-https://example.com}"
RENDERER="${BRIDGE_RENDERER:-chromium}"
WAIT_WINDOW_SECS="${WAIT_WINDOW_SECS:-15}"
WAIT_AFTER_F10_SECS="${WAIT_AFTER_F10_SECS:-4}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

require_cmd xvfb-run
require_cmd xdotool
require_cmd file
require_cmd cmake
require_cmd python3

mkdir -p "$BUILD_DIR"
cmake --build "$BUILD_DIR" -j "${JOBS:-4}" --target browser >/dev/null

if [[ ! -x "$BROWSER_BIN" ]]; then
  echo "browser binary not found after build: $BROWSER_BIN" >&2
  exit 1
fi

cd "$CLIENT_DIR"
mkdir -p artifacts/sessions
before_file="$(mktemp)"
after_file="$(mktemp)"
find artifacts/sessions -maxdepth 1 -mindepth 1 -type d | sort > "$before_file" 2>/dev/null || true

xvfb-run -a bash -lc '
  set -euo pipefail
  cd "'"$CLIENT_DIR"'"
  ./startbrowser.sh --off --renderer "'"$RENDERER"'" "'"$URL"'" > /tmp/bridge-chromium-e2e.out 2> /tmp/bridge-chromium-e2e.err &
  pid=$!
  win=""
  tries=$(( ('"$WAIT_WINDOW_SECS"' * 4) ))
  for _ in $(seq 1 "$tries"); do
    win=$(xdotool search --name "BROWZ MVP" 2>/dev/null | head -n 1 || true)
    if [[ -n "$win" ]]; then
      break
    fi
    sleep 0.25
  done
  if [[ -z "$win" ]]; then
    echo "no-window-found" >> /tmp/bridge-chromium-e2e.err
    sleep 2
  else
    xdotool key --window "$win" F10 || true
    sleep '"$WAIT_AFTER_F10_SECS"'
  fi
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
' || true

find artifacts/sessions -maxdepth 1 -mindepth 1 -type d | sort > "$after_file" 2>/dev/null || true
latest="$(comm -13 "$before_file" "$after_file" | tail -n 1)"
if [[ -z "$latest" ]]; then
  latest="$(tail -n 1 "$after_file")"
fi

if [[ -z "$latest" || ! -d "$latest" ]]; then
  echo "failed to locate new session artifact directory" >&2
  exit 1
fi

shot="$(find "$latest" -maxdepth 1 -type f \( -name 'manual-shot-*' -o -name 'manual-shot-*.png' -o -name 'manual-shot-*.bmp' \) | sort | tail -n 1)"

echo "session: $latest"
echo "renderer: $RENDERER"
echo "url: $URL"
echo "browser_bin: $BROWSER_BIN"
echo '--- browser.log tail ---'
tail -n 80 "$latest/browser.log" || true
echo '--- stderr ---'
sed -n '1,120p' /tmp/bridge-chromium-e2e.err || true

if [[ -z "$shot" ]]; then
  echo "no manual screenshot artifact found" >&2
  exit 1
fi

echo "screenshot: $shot"
file_output="$(file "$shot")"
echo "$file_output"

if ! grep -q 'renderer_backend=chromium' "$latest/browser.log"; then
  echo "browser log does not show chromium renderer backend" >&2
  exit 1
fi
if ! grep -q 'screenshot saved ' "$latest/browser.log"; then
  echo "browser log does not show screenshot capture" >&2
  exit 1
fi
if [[ "$file_output" != *'PNG image data'* ]]; then
  echo "screenshot is not a real PNG artifact" >&2
  exit 1
fi

python3 - <<PY
import json, pathlib, sys
session = pathlib.Path(${latest@Q}) / 'session.json'
data = json.loads(session.read_text())
title = (data.get('current_title') or '').strip()
url = (data.get('current_url') or '').strip()
if not url:
    print('session.json did not capture current_url', file=sys.stderr)
    sys.exit(1)
if not title:
    print('session.json did not capture current_title', file=sys.stderr)
    sys.exit(1)
if title == 'Blink runtime session':
    print('session.json title is still the placeholder title', file=sys.stderr)
    sys.exit(1)
print(f"session title: {title}")
print(f"session url: {url}")
PY

exit 0
