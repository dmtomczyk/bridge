# Core extraction checkpoint — 2026-04-06

This note records the first successful extraction slices after the `client/` → `browser/` rename and the introduction of the new `core/` repo/directory.

---

# What changed before the extraction

## Browser rename / namespace cleanup

The former `client/` repo/directory was renamed to:

- `browser/`

A follow-up cleanup pass updated the most important path/build/target naming so the workspace no longer remained half-`client`, half-`browser` in the places that matter most for current development.

Examples:

- browser repo project identity updated to `bridge_browser`
- browser-side CMake targets renamed from `bridge_client_*` to `bridge_browser_*`
- runtime helper binaries renamed from `client_cef_*` to `browser_cef_*`
- obvious script/docs/path references updated from `client/...` to `browser/...`

This rename/namespace cleanup was verified by rebuilding the real CEF runtime-host lane from the new `browser/` path.

---

# Extraction slice 1

## Moved into `core/`

### Shared product asset
- `core/assets/bridge-home.html`

This moved BRIDGE Home out of the browser repo and into the new shared core area.

### Shared backend contract headers
- `core/include/engine_api/display_list.h`
- `core/include/engine_api/document_snapshot.h`
- `core/include/engine_api/engine_backend.h`
- `core/include/engine_api/engine_types.h`
- `core/include/engine_api/render_target.h`

These were previously under:
- `browser/src/engine_api/`

The browser and engine repos were then updated to consume the shared interface from:
- `core/include`

instead of treating the browser repo as the owner of those contracts.

## Outcome
This made `core/` a real owner of:
- a shared product asset
- the current shared engine/backend API seam

That was the first meaningful extraction milestone.

---

# Extraction slice 2

## Moved into `core/`

### Shared debug utility header
- `core/include/debug/session_logger.h`

This header had still been browser-owned even though it was also used by engine code (`engine-custom`).

Moving it into `core/include/debug/` removed another real cross-layer leak.

Browser-side runtime/helper targets were updated to include:
- `core/include`

so existing includes like:
- `#include "debug/session_logger.h"`

continue to work from the new shared location.

## Outcome
This expanded `core/` from “assets + API headers” into a slightly more real shared utility layer.

---

# Transitional leak still visible after these slices

A useful result of the work is that one important transitional dependency is still now explicit and visible:

- `engine-custom` still needs access to some browser-owned headers/source include paths in addition to `core/include`

For the moment, that leak was intentionally tolerated to keep the build green while moving obviously shared pieces first.

That is acceptable at this checkpoint.
The purpose of the first slices was not to solve every architecture problem at once.
The purpose was to start moving real ownership into `core/` without destabilizing the runtime-host/browser path.

---

# Build verification at this checkpoint

After the extraction slices, the following real browser/CEF lane was rebuilt successfully:

- `browser`
- `browser_cef_runtime_probe`
- `browser_cef_runtime_browser`

using the renamed browser build path.

That confirms that:
- the first two extraction slices did not break the active runtime-host/browser lane
- `core/` is now already participating in real builds

---

# What `core/` owns at this checkpoint

At this checkpoint, `core/` owns at least:

- `assets/bridge-home.html`
- `include/engine_api/*`
- `include/debug/session_logger.h`

That is enough to say that `core/` is now a real shared layer, not just an empty placeholder.

---

# Recommended next extraction candidates

The next likely candidates should continue to prioritize:

- clearly shared ownership
- low-to-moderate build risk
- real reduction in browser/engine coupling

Most likely next categories:

1. more shared utility/config/model headers
2. shared browser action / navigation semantics where they are not deeply tied to the app runtime
3. additional product-level shared assets/docs/benchmarks if desired

The next slice should still be incremental, not a giant rewrite.

---

# Bottom line

This checkpoint represents a successful start to the new `bridge-browser` + `bridge-core` direction.

The first extraction slices were intentionally modest, but they were real:
- shared asset ownership moved into `core/`
- shared backend contracts moved into `core/`
- at least one shared utility header moved into `core/`
- the active runtime-host/browser lane still builds successfully afterward

That is the right kind of progress.
