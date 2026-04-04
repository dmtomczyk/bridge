# ENGINE-API-MIGRATION-MAP.md

## Purpose

This file maps the remaining uses of the old DOM round-trip path:

- `snapshot_document(dom::Document* out)`
- `sync_shell_document(const dom::Document& document)`

The goal is to separate:
- low-risk cleanup
- mutation-critical behavior
- places that need new engine_api methods before the old DOM contract can be removed

---

## Current remaining `snapshot_document(&current_document_)` call sites

File:
- `client/src/app/application.cpp`

### 1. Backend install handoff
Line area:
- around `install_backend_navigation_document(...)`

Current behavior:
- after backend install, shell refreshes neutral snapshot
- then still pulls full `dom::Document`

Classification:
- **transitional but expected**

Reason:
- shell still needs a live DOM for many downstream operations

Removal difficulty:
- **high**, unless the shell stops depending on full DOM after backend install

---

### 2. Editable/focus lifecycle
Call sites around:
- `blur_page_form_focus()`
- `focus_form_control()`
- `set_focused_form_control_value()`
- `insert_into_focused_form_control()`
- `backspace_focused_form_control()`
- `delete_from_focused_form_control()`

Classification:
- **mutation-critical**

Reason:
- shell still reads/mutates node state via live DOM
- focus/edit state currently round-trips through backend DOM snapshot
- event dispatch and cursor/value synchronization still assume `current_document_`

What this implies:
- these are not good “quick cleanup” targets
- removing old DOM snapshot usage here requires a deliberate replacement plan

Likely replacement direction:
- extend explicit editable/field APIs further
- stop depending on shell-side DOM refresh for text-entry state
- treat focused editable state as engine-owned with explicit query/update operations

---

### 3. Runtime document load + lifecycle refresh
Call sites around:
- post `runtime_load_document(...)`
- post lifecycle dispatch (`__browzDispatchLifecycle`)

Classification:
- **mutation-critical but structurally separable**

Reason:
- backend JS/runtime may mutate document state
- shell currently re-pulls full DOM afterward

Why this matters:
- this is probably the next major seam after editable handling

Likely replacement direction:
- either document snapshot becomes rich enough for read-only shell needs
- or shell stops requiring a generic live DOM refresh after backend runtime events
- may need explicit engine-side change notifications / state exports

---

### 4. Click dispatch / JS click side effects
Call site around:
- `runtime_dispatch_click_via_backend_or_runtime(...)`

Classification:
- **mutation-critical**

Reason:
- click handlers can mutate DOM
- shell currently re-pulls full DOM immediately after handled clicks

Likely replacement direction:
- same family as runtime lifecycle seam
- likely needs explicit state export or narrower post-click update contract

---

### 5. Presentation rebuild path
Call site around:
- `render_frame()` after `rebuild_presentation(...)`

Classification:
- **transitional, moderate complexity**

Reason:
- shell currently refreshes display list
- then also refreshes neutral document snapshot
- then still re-pulls full DOM

Interpretation:
- this path is closer to removable later than editable paths
- once shell rendering/debug/summary consumers stop needing full DOM after rebuild, this may become a good removal candidate

Likely replacement direction:
- rely on:
  - `snapshot_display_list(...)`
  - `snapshot_document_snapshot(...)`
  - page/load/debug state
- avoid requiring full DOM after rebuild unless mutation-specific behavior truly needs it

---

## Categories

## A. Low-risk / mostly already addressed
These now have at least partial neutral snapshot coverage:
- shell title/body/UI summary consumption
- page context reporting
- backend install refresh sequencing
- backend runtime/lifecycle refresh sequencing
- rebuild path snapshot refresh sequencing

These are worth continuing, but remaining gains here are incremental.

---

## B. Mutation-critical blockers
These are the true blockers to removing old DOM round-trip usage:

### Editable/focus/form synchronization
- focus
- blur
- value setting
- text insertion
- delete/backspace
- input event follow-up

### Runtime-driven DOM mutation refresh
- runtime document load
- lifecycle dispatch
- click handler side effects

These need explicit design work, not search/replace cleanup.

---

## C. Best candidates for the next major interface cut
If choosing one major seam to tackle next, these are the strongest candidates:

### Candidate 1 — Editable state contract expansion
Why first:
- already partially explicit today
- fits the existing API design direction
- replaces the most obviously bad DOM round-trip behavior

Potential additions might include concepts like:
- explicit editable value replace/set
- explicit editable commit/input event semantics
- explicit focused node metadata export
- optional focused element snapshot independent of full DOM snapshot

### Candidate 2 — Runtime mutation/export contract
Why second:
- affects click handlers and lifecycle-driven DOM changes
- likely bigger/more invasive than editable work

Potential additions might include:
- post-runtime document snapshot export requirements
- explicit mutation/change summary
- richer document snapshot for read-only shell sync

### Candidate 3 — Render rebuild cleanup
Why later:
- useful, but not the root blocker
- likely becomes easier after editable/runtime seams are cleaner

---

## Recommendation

### Short version
Do **not** spend much more time shaving tiny read-only cases.
The remaining real work is now concentrated in two major problem areas:

1. **editable/form synchronization**
2. **runtime-driven DOM mutation refresh**

### Recommended order
1. tackle editable/form synchronization first
2. tackle runtime/click/lifecycle DOM refresh second
3. then remove leftover rebuild/install DOM snapshot dependencies

---

## Practical conclusion

The old DOM round-trip path is no longer a broad vague problem.
It is now mostly concentrated in:
- editable mutation handling
- backend runtime/click/lifecycle mutation handling
- a smaller transitional rebuild/install residue

That means the next steps can be deliberate instead of exploratory.
