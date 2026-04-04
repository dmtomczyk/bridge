#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
for repo in client engine-custom engine-chromium engine-cef; do
  echo "=== $repo ==="
  if [[ -e "$ROOT_DIR/$repo/.git" ]]; then
    git -C "$ROOT_DIR/$repo" status --short --branch
  else
    echo "missing repo: $repo"
  fi
  echo
 done
