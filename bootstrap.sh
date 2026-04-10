#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [options]

Initializes the Bridge workspace and checks for the expected child repos.

Options:
  --update         run submodule update --remote after init (optional)
  -h, --help       show this help

What it does:
  1. initializes and updates git submodules recursively
  2. verifies browser/core/engine-* repos are present
  3. prints next-step build examples for Linux/macOS and Windows
EOF
}

UPDATE_REMOTE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --update)
      UPDATE_REMOTE=1
      shift
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

echo "==> Initializing Bridge workspace submodules"
git -C "$ROOT_DIR" submodule update --init --recursive

if [[ "$UPDATE_REMOTE" -eq 1 ]]; then
  echo "==> Updating submodules to tracked remote refs"
  git -C "$ROOT_DIR" submodule update --remote --recursive
fi

for repo in core browser engine-custom engine-chromium engine-cef; do
  if [[ ! -e "$ROOT_DIR/$repo/CMakeLists.txt" ]]; then
    echo "Missing expected repo or CMakeLists.txt: $repo" >&2
    exit 1
  fi
  echo "ok: $repo"
done

echo
echo "Bootstrap complete."
echo
echo "Next steps:"
echo "  Linux/macOS scaffold build: ./compile.sh --engine chromium --js off"
echo "  Windows CEF smoke bootstrap: pwsh -File ./scripts/windows-smoke-bootstrap.ps1 -CefRoot C:\\path\\to\\cef_binary_..."
