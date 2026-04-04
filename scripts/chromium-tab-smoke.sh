#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CLIENT_DIR="$ROOT_DIR/client"
BUILD_DIR="${BRIDGE_BUILD_DIR:-$CLIENT_DIR/build/v8-off}"
BROWSER_BIN="$BUILD_DIR/browser"
WAIT_WINDOW_SECS="${WAIT_WINDOW_SECS:-15}"
WAIT_AFTER_TAB_SECS="${WAIT_AFTER_TAB_SECS:-5}"
EXPECTED_TITLE="${EXPECTED_TITLE:-b}"
URL='data:text/html,%3Chtml%3E%3Cbody%20style%3D%22margin%3A0%3Bpadding%3A24px%22%3E%3Cinput%20id%3D%22a%22%20autofocus%20onfocus%3D%22document.title%3D%27a%27%22%20style%3D%22display%3Ablock%3Bmargin-bottom%3A16px%3Bpadding%3A12px%22%3E%3Cinput%20id%3D%22b%22%20onfocus%3D%22document.title%3D%27b%27%22%20style%3D%22display%3Ablock%3Bpadding%3A12px%22%3E%3C%2Fbody%3E%3C%2Fhtml%3E'

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
  ./startbrowser.sh --off --renderer chromium "'"$URL"'" > /tmp/bridge-chromium-tab.out 2> /tmp/bridge-chromium-tab.err &
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
    echo "no-window-found" >> /tmp/bridge-chromium-tab.err
    sleep 2
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    exit 0
  fi
  sleep 1
  xdotool key --window "$win" Tab || true
  sleep '"$WAIT_AFTER_TAB_SECS"'
  xdotool key --window "$win" F10 || true
  sleep 2
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

shot="$(find "$latest" -maxdepth 1 -type f -name 'manual-shot-*' | sort | tail -n 1)"

echo "session: $latest"
echo "browser_bin: $BROWSER_BIN"
echo "expected_title: $EXPECTED_TITLE"
echo 'expected_log: backend-key Tab'
echo 'expected_log: backend page-title b'
echo '--- browser.log tail ---'
tail -n 120 "$latest/browser.log" || true
echo '--- stderr ---'
sed -n '1,120p' /tmp/bridge-chromium-tab.err || true

if [[ -z "$shot" ]]; then
  echo "no manual screenshot artifact found" >&2
  exit 1
fi

echo "screenshot: $shot"
file_output="$(file "$shot")"
echo "$file_output"
if [[ "$file_output" != *'PNG image data'* ]]; then
  echo "screenshot is not a real PNG artifact" >&2
  exit 1
fi
if ! grep -q 'backend-key Tab' "$latest/browser.log"; then
  echo "browser log does not show forwarded Tab key reaching backend path" >&2
  exit 1
fi
if ! grep -q 'backend] page-title b' "$latest/browser.log"; then
  echo "browser log does not show page reaction to Tab focus change" >&2
  exit 1
fi

SESSION_DIR="$latest" EXPECTED_TITLE="$EXPECTED_TITLE" python3 - <<'PY'
import json, os, pathlib, sys
session = pathlib.Path(os.environ['SESSION_DIR']) / 'session.json'
data = json.loads(session.read_text())
title = (data.get('current_title') or '').strip()
url = (data.get('current_url') or '').strip()
expected = os.environ['EXPECTED_TITLE']
if title != expected:
    print(f'unexpected title: {title!r} != {expected!r}', file=sys.stderr)
    sys.exit(1)
if not url.startswith('data:text/html'):
    print(f'unexpected url: {url!r}', file=sys.stderr)
    sys.exit(1)
print(f'session title: {title}')
print(f'session url: {url[:80]}...')
print('backend Tab forwarding + page reaction confirmed in browser.log')
PY

exit 0
