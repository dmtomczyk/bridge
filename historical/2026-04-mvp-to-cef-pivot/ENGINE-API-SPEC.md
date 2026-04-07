# ENGINE-API-SPEC.md

## Purpose

This document defines the intended meaning of the shared engine contract owned by the client repo under:

- `client/src/engine_api/`

It exists to answer a simple question:

**What should an engine implement, what is still transitional, and what should be removed or split later?**

The goal is not to invent a perfect end-state browser architecture in one pass.
The goal is to make the current migration intentional and honest.

---

## Ownership model

### Client owns
- the engine contract (`engine_api/`)
- engine selection / backend factory
- shell lifecycle and UX
- transitional shell-local DOM/layout/runtime while migration continues

### Engines own
- engine-specific implementation
- engine-specific dependencies
- engine-specific internal document/layout/runtime representation

### Engines must not own
- another engine's types
- another engine's headers
- another engine's build graph

### Contract rule
Only browser-owned types under `engine_api/` should cross the shell/engine boundary.

---

## Current contract surface

Primary header:
- `client/src/engine_api/engine_backend.h`

Related shared types:
- `engine_types.h`
- `document_snapshot.h`
- `display_list.h`
- `render_target.h`

---

## Classification system

Each method is classified as one of:

- **Core** — valid long-term engine responsibility
- **Transitional** — acceptable for now during migration, but not ideal long-term
- **Problematic** — known bad seam that should be replaced or removed
- **Candidate split** — likely belongs in a narrower sub-interface later

---

## Contract areas

# 1. Lifecycle

## `initialize(const RendererInitParams& params)`
**Classification:** Core

### Purpose
Initialize engine state for a session/runtime instance.

### Why it belongs
Every engine needs explicit startup.

### Notes
- `RendererInitParams` is currently small and acceptable.
- May later grow cautiously, but should avoid leaking shell-specific internals.

## `shutdown()`
**Classification:** Core

### Purpose
Release engine resources and end the session cleanly.

## `identity() const`
**Classification:** Core

### Purpose
Return engine identity/version information.

## `capabilities() const`
**Classification:** Core

### Purpose
Advertise what this engine currently supports.

### Notes
Important during migration because engines are intentionally uneven.

---

# 2. Navigation and resource loading

## `navigate(const std::string& url)`
**Classification:** Core

## `reload()`
**Classification:** Core

## `go_back()`
**Classification:** Core

## `go_forward()`
**Classification:** Core

## `resolve_url(const std::string& base_url, const std::string& href) const`
**Classification:** Core

### Why it belongs
URL resolution is a real engine concern and should not depend on sibling engines.

---

## `fetch_navigation_resource(...)`
**Classification:** Transitional

### Why transitional
This exists because the shell still owns much of the page/document pipeline.
In a more mature engine contract, navigation/resource loading likely becomes more internal to the engine.

### Keep for now?
Yes.
Useful while shell-owned document preparation still exists.

## `fetch_resource(...)`
**Classification:** Transitional

### Why transitional
Currently supports shell-owned loading of external CSS/scripts/images and runtime fetch bridging.
May remain useful for debugging or explicit shell-assisted loading, but should not be assumed as a permanent primary engine API.

## `prepare_navigation_document(...)`
**Classification:** Transitional

### Why transitional
Very tied to current shell-owned parse/load/install workflow.

### Target direction
Eventually this may become:
- a more explicit navigation preparation/export API, or
- disappear if engines own navigation more fully.

---

# 3. Document handoff / document export

## `install_navigation_document(const RendererPreparedDocument& prepared)`
**Classification:** Transitional

### Why transitional
This is part of the current shell-owned page/document install path.
It is acceptable during migration but reflects unfinished ownership boundaries.

---

## `snapshot_document_snapshot(EngineDocumentSnapshot* out) const`
**Classification:** Core

### Why core
This is the correct direction for engine-neutral document export:
- browser-owned snapshot type
- no engine-internal DOM types in the shared contract

### Notes
This is the preferred document export path going forward.

---

## `snapshot_document(dom::Document* out) const`
**Classification:** Problematic

### Why problematic
This leaks custom-engine DOM types into the shared engine contract.

### Current status
Still needed during transition because the shell still performs direct DOM-based operations.

### Target direction
Deprecate and remove after shell mutation paths stop depending on full DOM round-trip.

---

## `sync_shell_document(const dom::Document& document)`
**Classification:** Problematic

### Why problematic
This is the inverse of the same leak:
- shell sends engine a custom-engine DOM tree
- ownership and mutation boundaries become unclear

### Target direction
Replace with explicit operations and/or narrower sync APIs.

---

# 4. Runtime and editable interactions

## `runtime_reset_document()`
**Classification:** Transitional

## `runtime_load_document(const std::string& page_url)`
**Classification:** Transitional

## `runtime_evaluate(...)`
**Classification:** Transitional

## `runtime_has_click_handler(int node_id) const`
**Classification:** Transitional

## `runtime_dispatch_click(int node_id, RendererClickDispatchResult* out)`
**Classification:** Transitional

### Why transitional
These reflect the shell still owning substantial runtime/document flow while using engine-side JS/runtime assistance.

### Notes
These may eventually stay, but likely under a narrower runtime-oriented sub-interface.

---

## `focus_editable(int node_id)`
**Classification:** Core

## `blur_editable()`
**Classification:** Core

## `snapshot_editable_state(RendererEditableState* out) const`
**Classification:** Core

## `editable_insert_text(std::string_view text)`
**Classification:** Core

## `editable_backspace()`
**Classification:** Core

## `editable_delete_forward()`
**Classification:** Core

## `editable_move_cursor_left()`
**Classification:** Core

## `editable_move_cursor_right()`
**Classification:** Core

## `editable_move_cursor_home()`
**Classification:** Core

## `editable_move_cursor_end()`
**Classification:** Core

### Why core
These are explicit mutation operations. They are exactly the kind of focused API that should replace generic DOM round-tripping.

### Notes
This area is one of the healthiest parts of the current contract.

---

# 5. Presentation and layout export

## `rebuild_presentation(...)`
**Classification:** Transitional

### Why transitional
This exists because the shell still owns significant layout/presentation flow.
It is useful now, but the long-term ownership may move.

## `snapshot_display_list(DisplayList* out, int* document_content_height_out) const`
**Classification:** Core

### Why core
This now uses a browser-owned contract type and is a legitimate engine export seam.

### Notes
Even if the exact display-list shape evolves, the concept is valid.

---

## `resize(int width, int height)`
**Classification:** Core

## `tick()`
**Classification:** Core

## `render(RenderTarget& target)`
**Classification:** Core

### Why core
These are fundamental engine presentation lifecycle methods.

---

# 6. Input forwarding

## `handle_mouse_move(const MouseMoveEvent& event)`
**Classification:** Core

## `handle_mouse_button(const MouseButtonEvent& event)`
**Classification:** Core

## `handle_mouse_wheel(const MouseWheelEvent& event)`
**Classification:** Core

## `handle_key(const KeyEvent& event)`
**Classification:** Core

## `handle_text_input(const TextInputEvent& event)`
**Classification:** Core

### Why core
Engines need a standard input surface even if support differs by capability.

---

# 7. State export

## `page_state() const`
**Classification:** Core

## `load_state() const`
**Classification:** Core

### Why core
These expose lightweight state the shell/UI needs regardless of engine maturity.

---

# 8. Shell bridge hooks

## `sync_shell_bridge_state(const ShellBridgeState& state)`
**Classification:** Transitional

## `sync_shell_frame(const RenderTarget& target)`
**Classification:** Transitional

### Why transitional
These explicitly acknowledge that the shell still owns part of the active render/debug flow.
They are acceptable during migration but not ideal as the final engine contract shape.

### Notes
These may later become:
- narrower debug bridge hooks, or
- disappear as engine ownership becomes more complete.

---

# 9. Diagnostics and tooling

## `capture_screenshot(const std::string& path)`
**Classification:** Core

## `debug_snapshot() const`
**Classification:** Core

## `inspect_at(int x, int y, InspectResult* out) const`
**Classification:** Core

### Why core
These are useful, engine-appropriate debug/tooling surfaces and do not inherently leak engine internals when backed by shared API types.

---

## Shared type review

# `engine_types.h`

### Good / stable enough
- input event structs
- editable state
- identity/capabilities
- page/load state
- inspect/debug types
- init params

### Transitional / review later
- `RendererNavigationResource`
- `RendererPreparedDocument`

These are tightly coupled to the current shell-owned navigation/document-prep flow.

They are acceptable for v1 migration but should be revisited after document ownership becomes cleaner.

---

# `document_snapshot.h`

### Role
This is the new preferred read/export document contract.

### Status
Early but directionally correct.

### Notes
The exact fields may evolve, but this is the right ownership model:
- browser-owned snapshot type
- no custom-engine DOM headers in the contract

---

# `display_list.h`

### Role
Client-owned presentation export contract.

### Status
Good migration milestone.

### Notes
This should continue to evolve here, not inside either engine repo.

---

# `render_target.h`

### Role
Shared rendering target for shell/engine presentation integration.

### Status
Reasonable for now.

---

## v1 engine_api recommendation

For practical purposes, treat the following as the **v1 contract**.

### Stable v1 core
- initialize / shutdown
- identity / capabilities
- navigate / reload / back / forward / resolve_url
- snapshot_document_snapshot
- snapshot_display_list
- resize / tick / render
- input handlers
- page_state / load_state
- explicit editable APIs
- capture_screenshot / debug_snapshot / inspect_at

### Transitional v1 allowed
- fetch_navigation_resource
- fetch_resource
- prepare_navigation_document
- install_navigation_document
- runtime_* methods
- rebuild_presentation
- sync_shell_bridge_state
- sync_shell_frame

### Explicit deprecation target
- `snapshot_document(dom::Document* out)`
- `sync_shell_document(const dom::Document& document)`

---

## Engine implementation expectations

## `engine-custom`
Expected near-term status:
- implements essentially all current methods
- acts as the richer reference implementation during migration
- should progressively move away from exporting/importing custom DOM through the shared contract

## `engine-chromium`
Expected near-term status:
- implements lifecycle/state/debug/presentation scaffold honestly
- returns partial/minimal document snapshot until deeper integration exists
- should not pretend to implement custom-engine behavior it does not own

---

## Recommended next steps

### 1. Begin using `snapshot_document_snapshot(...)` preferentially in read-only shell paths
Already started; continue.

### 2. Mark old DOM round-trip methods as deprecated in comments
Not necessarily compiler deprecation attributes yet, but clearly labeled in code/docs.

### 3. Create a follow-up plan for mutation-path replacement
Especially for:
- shell document sync
- runtime document load/reset assumptions
- form/edit synchronization

### 4. Consider future interface split
Once migration stabilizes, `IRendererBackend` may want to split conceptually into narrower areas such as:
- lifecycle/navigation
- document export
- runtime/editable
- presentation
- diagnostics

Do not do this split yet unless it clearly reduces churn.

---

## Bottom line

The right mental model is:

- `engine_api` is real now
- some parts are already healthy and should be treated as durable
- some parts are explicitly transitional and acceptable for now
- two methods are known-bad seams and should be removed later:
  - `snapshot_document(dom::Document* out)`
  - `sync_shell_document(const dom::Document& document)`

This spec should be the reference for future engine and shell migration work.
