# Core extraction checkpoint B — 2026-04-06

This note records the next successful set of low-risk shared-core extractions after the first `core/` slices landed.

Reference earlier checkpoint:
- `docs/core-extraction-checkpoint-2026-04-06.md`

---

# What changed in this checkpoint

## 1. Shared browser action semantics started in `core/`

Added:
- `core/include/browser/browser_action.h`

This introduced a shared `BrowserAction` enum and action-name helper for browser-level actions such as:

- reload
- navigate_back
- navigate_forward
- new_tab
- close_tab
- reopen_closed_tab
- focus_address_bar
- next_tab
- previous_tab

The initial consumer wiring started in the browser app path, where the shared action enum is now used for at least:

- reload
- navigate back
- navigate forward

This was intentionally a small first step:
- shared action identity moved into `core/`
- execution remained local to the browser/runtime path for now

---

## 2. Navigation controller fully extracted into `core/`

Moved into:
- `core/include/browser/navigation_controller.h`

Removed from browser repo:
- `browser/src/browser/navigation_controller.h`
- `browser/src/browser/navigation_controller.cpp`

The inspection showed that `NavigationController` was:
- tiny
- pure
- self-contained
- not meaningfully entangled with app/runtime/platform code

That made it a better candidate than expected.
It was converted into a small header-only shared utility in `core/` rather than being partially extracted.

Browser build updates:
- `bridge_browser_core` no longer compiles `src/browser/navigation_controller.cpp`
- `navigation_test` now consumes the shared header from `core/include`

Result:
- the full controller semantics now live in shared core
- browser/runtime code consumes them from there

---

## 3. Backend-factory shared contract surface expanded in `core/`

Additional thin backend-factory headers were moved into:
- `core/include/backend_factory/`

Specifically:
- `cef_runtime_attach.h`
- `cef_attach.h`
- `cef_renderer_name.h`
- `renderer_catalog.h`
- `create_backend.h`

This expands `core/` as the owner of thin browser/runtime-facing backend selection and attach semantics.

Important note:
- the implementation-heavy pieces remain in `browser/`
- examples include:
  - `create_backend.cpp`
  - `cef_backend_adapter.*`
  - `cef_runtime_attach.cpp`

That was an intentional low-chaos boundary choice.

---

## 4. Shared browser UI state header moved into `core/`

Moved into:
- `core/include/ui/chrome.h`

Why this was safe:
- it is a small pure state/model header
- it is not inherently browser-runtime-only
- it is the kind of shared browser shell state that belongs in shared core if multiple targets are expected

---

# Build verification at this checkpoint

After these moves, the real browser/CEF lane was rebuilt successfully, including:

- `browser`
- `browser_cef_runtime_probe`
- `browser_cef_runtime_browser`
- `navigation_test`
- `cef_backend_runtime_attach_metadata_test`

That means the low-risk header/model/contract extraction pattern remained valid through this checkpoint.

---

# What `core/` owns now

At this checkpoint, `core/` owns at least:

## Assets
- `assets/bridge-home.html`

## Shared engine/backend API
- `include/engine_api/*`

## Shared debug/logging utility
- `include/debug/session_logger.h`

## Shared browser-level semantics
- `include/browser/browser_action.h`
- `include/browser/navigation_controller.h`

## Shared backend-factory contracts/seams
- `include/backend_factory/create_backend.h`
- `include/backend_factory/renderer_catalog.h`
- `include/backend_factory/cef_renderer_name.h`
- `include/backend_factory/cef_attach.h`
- `include/backend_factory/cef_runtime_attach.h`

## Shared browser UI state
- `include/ui/chrome.h`

This is now a substantial enough shared-core footprint that `core/` is clearly becoming a real architectural layer rather than a placeholder folder/repo.

---

# Where the easy wins stop

By the end of this checkpoint, the obvious low-risk thin-header extractions are becoming less plentiful.

What remains in `browser/src` includes heavier items such as:

- `app/application.h`
- `backend_factory/cef_backend_adapter.h`

These are more implementation-adjacent and no longer obviously safe “just move the header” candidates.

That means the project is now approaching the boundary between:

- low-chaos shared contract/model extraction
and
- heavier interface/implementation refactoring

That is a good point to stop and reassess before the next phase.

---

# Recommended next phase after this checkpoint

The next likely phase should be a deliberate heavier slice, not another random header move.

Likely directions:

1. expand shared browser action semantics further into the CEF runtime-host path
2. inspect backend-factory / adapter boundaries for a real interface-vs-implementation split
3. identify whether a small shared runtime/browser command layer should sit in `core/` and be consumed by both browser app code and CEF runtime-host code

In other words:

- the thin extractions have gone well
- now it is time to pick a more deliberate structural slice

---

# Bottom line

Checkpoint B confirms that the new `bridge-browser` + `core/` direction is still working as intended.

The project successfully extracted another meaningful set of thin shared contracts/models into `core/` while keeping the active browser/CEF lane buildable and testable.

The next step should now be a more intentional, heavier slice rather than more opportunistic header harvesting.
