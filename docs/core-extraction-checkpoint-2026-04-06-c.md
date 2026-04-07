# Core extraction checkpoint C — 2026-04-06

This note records the first more intentional/heavier shared-core slice after the earlier low-risk header/model harvesting checkpoints.

Reference earlier checkpoints:
- `docs/core-extraction-checkpoint-2026-04-06.md`
- `docs/core-extraction-checkpoint-2026-04-06-b.md`

---

# What changed in this checkpoint

## 1. Shared browser action semantics were expanded beyond the browser app path

Earlier work introduced:
- `core/include/browser/browser_action.h`

That first slice established a shared `BrowserAction` model, but only started consuming it from the browser app path.

This checkpoint extends that idea into the CEF runtime-host path.

---

## 2. `engine-cef` now consumes shared browser action semantics from `core/`

### Build-system change
`engine-cef` now includes:
- `../core/include`

through its CMake include path setup.

That makes `engine-cef` able to consume shared browser-level contracts/models from `core/` rather than re-declaring action semantics locally.

---

## 3. CEF runtime-host shortcut handling now uses shared `BrowserAction`

`CefOsrHostGtk` was updated to recognize and execute shared browser-level actions through a local execution helper rather than hardcoding all shortcut behavior ad hoc in the key-handling path.

### Shared actions now explicitly used in the CEF runtime-host path
- reload
- new tab
- close tab
- reopen closed tab
- focus address bar
- next tab
- previous tab

### Concrete shortcut examples now routed through shared action semantics
- `F5` → `reload`
- `Ctrl+R` → `reload`
- `Ctrl+T` → `new_tab`
- `Ctrl+W` → `close_tab`
- `Ctrl+Shift+T` → `reopen_closed_tab`
- `Ctrl+L` → `focus_address_bar`
- `Ctrl+Tab` → `next_tab`
- `Ctrl+Shift+Tab` → `previous_tab`

This does **not** yet mean the entire command execution stack is shared.
The execution still happens locally in the runtime-host implementation.

But it **does** mean that the action identity layer is now shared between:
- the browser app path
- the CEF runtime-host path

That is a meaningful architectural step forward.

---

# Why this checkpoint matters

The earlier checkpoints mostly harvested:
- shared assets
- shared contracts
- shared utility headers
- shared pure models

This checkpoint is different because it starts to move a real piece of browser behavior definition into shared core semantics.

That matters for future multi-target work because it reduces the chance that:
- Linux browser/runtime path
- Windows browser/runtime path
- CEF runtime-host path

all drift into slightly different interpretations of the same user-facing actions.

---

# Build verification at this checkpoint

After the CEF runtime-host action-semantics expansion, the real browser/CEF lane was rebuilt successfully, including:

- `browser`
- `browser_cef_runtime_probe`
- `browser_cef_runtime_browser`

That confirms the heavier action-semantics slice did not break the active runtime-host/browser path.

---

# Current `core/` shared surface after this checkpoint

At this point `core/` owns at least:

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

In other words, `core/` now contains not only shared headers/assets, but also the beginning of a real shared action-semantics layer.

---

# What remains true

Even after this checkpoint:
- action execution is still local to each runtime path
- implementation-heavy backend-factory and adapter code is still browser-owned
- GTK/X11/CEF host-specific behavior is still host-specific
- the project has not yet created a fully shared command execution layer

That is okay.
This checkpoint should be seen as:

- a shared action identity and wiring milestone
not
- the completion of command unification

---

# Recommended next directions after this checkpoint

The next heavier slices could reasonably go in one of these directions:

## Option A — continue shared action/command work
Examples:
- extend shared action semantics into additional runtime/browser paths
- introduce a slightly more explicit shared command-dispatch layer
- reduce more ad hoc key-handler duplication over time

## Option B — inspect backend-factory implementation boundaries
Examples:
- identify where thin contracts stop and browser-owned implementation begins
- separate interface vs adapter/implementation more intentionally

## Option C — inspect another medium-weight shared browser/runtime semantic area
Examples:
- shared startup/navigation semantics
- shared browser state/config models

---

# Bottom line

Checkpoint C marks the point where `core/` stopped being only a contract/model extraction target and started participating in real shared browser behavior semantics.

That is a larger and more meaningful architectural milestone than the earlier thin-header moves, while still keeping the active runtime-host/browser lane buildable.
