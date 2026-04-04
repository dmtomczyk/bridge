# Document Boundary Plan

## Why this exists

The workspace is now meaningfully improved at the build-graph level:

- `engine-custom` and `engine-chromium` can build separately
- Chromium no longer imports or links custom-engine code
- the client-owned renderer API now owns the display-list contract

However, the backend contract is still **not cleanly engine-neutral** because it still exposes custom-DOM-shaped APIs:

- `snapshot_document(dom::Document* out)`
- `sync_shell_document(const dom::Document& document)`

Those methods leak custom-engine implementation details into the renderer contract and make the shell/backend seam much less honest than the build graph now suggests.

This document defines the target document-boundary architecture before the next code refactor.

---

## Problem statement

Today the shell (`client`) still keeps a live mutable `dom::Document` and also asks backends to:

1. export their current document as a custom-engine DOM tree
2. accept a shell-mutated custom-engine DOM tree back in

That creates several bad properties:

### 1. The renderer API is not engine-neutral
The contract depends on custom-engine DOM types.

### 2. Chromium is forced to pretend to speak custom DOM
Even though Chromium should be its own backend, its interface is shaped around custom-engine data structures.

### 3. Mutation ownership is unclear
The shell and the backend can both mutate what is conceptually the same document state, but the synchronization protocol is implicit and fragile.

### 4. Refactoring pressure stays high
As long as the shell/backend seam passes a full custom DOM tree around, it is hard to make either engine independent.

---

## Design goals

The next document-boundary refactor should satisfy these goals:

### A. Zero engine-to-engine coupling
- `engine-custom` must not know about `engine-chromium`
- `engine-chromium` must not know about `engine-custom`
- neither engine should depend on the other engine's internal document or layout types

### B. Client-owned contract
The only shared types across shell/backends should live under client-owned renderer API headers.

### C. Explicit mutation protocol
Do not round-trip a large mutable DOM tree through the backend interface unless there is a very strong reason.

### D. Preserve pragmatic iteration
The shell can continue to own a transitional local DOM/layout pipeline while the engine contract is cleaned up, but that transitional ownership must not leak engine-specific internals across backend boundaries.

---

## Recommended target architecture

## Short version

Replace the current backend document round-trip with:

1. **client-owned document snapshot types** for read/export
2. **explicit backend mutation/edit APIs** for write/update
3. **shell-local working DOM** as an internal implementation detail, not a backend contract type

---

## The new boundary in one sentence

Backends should expose **snapshots and explicit operations**, not a shared mutable custom-engine DOM object.

---

## Proposed contract split

### 1. Read-only export types in `client/src/engine_api/`

Introduce client-owned document snapshot types, for example:

- `RendererNodeSnapshot`
- `RendererDocumentSnapshot`
- `RendererAttribute`
- `RendererComputedStyleSnapshot` (only if needed)

These are **API types**, not engine-internal types.

They should be:
- simple value types
- serializable/thin if possible
- sufficient for inspection/debugging/shell sync needs
- not responsible for owning engine logic

Example direction:

```cpp
struct RendererNodeSnapshot {
    int node_id = -1;
    std::string node_type;
    std::string tag_name;
    std::string text;
    std::string element_id;
    std::vector<std::string> classes;
    std::vector<std::pair<std::string, std::string>> attributes;
    std::vector<RendererNodeSnapshot> children;
};

struct RendererDocumentSnapshot {
    std::string title;
    std::string body_text;
    std::string raw_html;
    bool has_root = false;
    RendererNodeSnapshot root;
};
```

This exact shape can evolve, but the ownership principle should not.

---

### 2. Remove full-DOM round-trip from `IRendererBackend`

Retire these methods from the long-term contract:

- `snapshot_document(dom::Document* out)`
- `sync_shell_document(const dom::Document& document)`

Replace them with something like:

- `snapshot_document(RendererDocumentSnapshot* out)`
- or, if that is still too much, narrower export methods for specific state the shell actually needs

---

### 3. Keep edits as explicit operations

Editable/focus APIs already point in the right direction:

- `focus_editable`
- `editable_insert_text`
- `editable_backspace`
- `editable_delete_forward`
- etc.

That pattern is better than exporting/importing a giant mutable DOM tree for text-entry changes.

The next refactor should continue in that direction:

- explicit navigation/document install
- explicit editable operations
- explicit shell bridge state sync
- explicit frame sync
- explicit inspect/debug snapshot

Not: “here is my entire mutable engine DOM, please take it back.”

---

## Transitional ownership model

For now, the shell still owns a lot of custom-engine-era logic:

- local HTML parse
- local style/layout
- local runtime integration
- direct DOM mutation

That is acceptable **internally** during migration.

What must change is this:

### Allowed
- `client` internally uses `dom::Document` as a shell-local implementation detail during the transition

### Not allowed long-term
- `IRendererBackend` exposes `dom::Document` in the shared contract

That distinction is critical.

---

## Migration strategy

Do this in phases.

### Phase 1 — snapshot type introduction
Create client-owned document snapshot types under `engine_api/`.

No behavior change yet.

Goal:
- define the neutral document shape
- make it available to both engines and the shell

### Phase 2 — backend export migration
Add a new backend method:

- `snapshot_document_snapshot(RendererDocumentSnapshot* out)`
  or rename directly to the final neutral method if done in one pass

Implement adapters:
- `engine-custom`: convert `dom::Document` -> `RendererDocumentSnapshot`
- `engine-chromium`: convert its current scaffold state -> `RendererDocumentSnapshot`

Goal:
- remove backend dependence on custom DOM types for read/export

### Phase 3 — shell consumption migration
Move shell paths that only need inspection/snapshot data to the neutral snapshot type.

Examples likely include:
- debug/inspection
- backend bridge state summaries
- non-mutating shell sync paths

Goal:
- stop relying on full custom DOM tree export in read-only cases

### Phase 4 — mutation protocol cleanup
Replace remaining shell/backend DOM round-trip assumptions with explicit operations.

Examples:
- editable/form state remains explicit API
- backend navigation install remains explicit
- shell debug sync remains explicit

Goal:
- remove `sync_shell_document(...)` from the backend contract entirely

### Phase 5 — optional shell-internal cleanup
Once the backend seam is neutral, decide separately whether the shell should continue using custom DOM internally or introduce a more shell-owned document representation.

That decision should happen **after** the backend seam is fixed, not before.

---

## Non-goals

This plan does **not** require, right now:

- removing the shell's local custom-era DOM/layout/runtime implementation immediately
- making Chromium own all page lifecycle today
- designing a perfect long-term browser engine abstraction in one pass

This is about making the contract honest and the dependency directions correct.

---

## Success criteria

The document-boundary refactor is successful when all of the following are true:

1. `IRendererBackend` no longer includes or exposes `dom::Document`
2. `IRendererBackend` no longer includes or exposes engine-custom internal layout/document types
3. `engine-custom` and `engine-chromium` both build against client-owned renderer API types only
4. backend edits are represented by explicit methods, not a shared mutable DOM tree contract
5. the shell may still use internal transitional DOM/layout code, but that does not leak into the backend interface

---

## Recommended next implementation step

The next concrete code step should be:

### Implement Phase 1 + the start of Phase 2

Specifically:

1. add `RendererDocumentSnapshot` types in `client/src/engine_api/`
2. add a new backend snapshot method using those types
3. implement conversion in `engine-custom`
4. implement a minimal scaffold snapshot in `engine-chromium`
5. keep old DOM-based methods temporarily only if needed during transition

This gives a safe bridge toward removing the old methods instead of forcing an all-at-once rewrite.

---

## Final principle

The shell can be transitional.
The engines can be transitional.
The build graph can be transitional.

But the **direction** must be clean:

- client owns the contract
- engines implement the contract
- engines do not know each other
- backend boundaries use neutral API types, not one engine's internal structures
