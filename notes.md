# notes.md

# bridge notes: client scope, engine interface, and roadmap

This document captures the current strategic direction for the split bridge architecture.

## Strategic direction

We are keeping **two engines** under one client:
- a **Chromium-backed** engine as the current practical/compatibility focus
- a **custom** engine as a strategic long-term asset, reference backend, and experimentation platform

### Near-term emphasis
- get the Chromium-backed path working first
- continue hardening the client/engine contract
- keep the custom engine on the roadmap and buildable

## Mental model

The `client` repo is not “just HTML waiting for an engine.”

The client is the:
- application layer
- browser-like chrome and UX layer
- app/window lifecycle layer
- orchestration layer for engine backends
- settings/history/debug/session/tooling layer

The engines are the things that turn web content into pixels and behavior.

## What the client should own

- windows and tabs
- navigation model
- address bar / omnibox
- history/bookmarks/downloads/settings UI
- profiles/session restore
- internal pages
- diagnostics/artifacts/tooling UI
- engine selection/fallback UX
- backend/engine capability and health reporting
- automation/agent-oriented control surfaces

## What the client should not own

- HTML parsing
- DOM model ownership
- CSS/layout semantics
- page JS runtime semantics
- page rendering semantics
- engine-specific web API internals

## Why keep both engines

### Chromium engine advantages
- strongest practical compatibility path
- best near-term route to real-world web behavior

### Custom engine advantages
- point of differentiation
- full-stack control
- lighter-weight experimentation platform
- strategic hedge against total Chromium dependence
- architectural leverage by keeping the client/engine contract honest across two implementations

## Recommended posture

- Chromium is the current practical focus
- custom remains on the roadmap and should stay buildable/documented
- do not force the custom engine to compete with Chromium at being “all of the modern web” in the near term

## Client/engine interface direction

The engine contract should remain:
- backend-neutral
- small enough to reason about
- rich enough to support a serious app/client
- stable enough to export/share later

### Broad interface areas
- lifecycle
- navigation
- presentation/frame output
- page/load state
- input/interaction
- debug/inspection
- normalized capability reporting

## What we can work on while Chromium builds/matures

### High-value client work
- harden the client/engine contract
- strengthen the client as a real product/app layer
- expand client-owned internal pages and diagnostics
- improve engine selection/fallback UX
- improve workspace/build DX

### Custom engine background track
- keep it buildable
- keep it smoke-tested
- avoid large new custom-only feature pushes unless they strengthen the contract or strategic differentiation

## Immediate work items

- [ ] define and document a formal engine capabilities model
- [ ] clarify normalized backend state surfaces
- [ ] identify and remove transitional engine leaks from client-side code
- [ ] define the set of client-owned internal pages
- [ ] define engine selection/fallback UX
- [ ] improve targeted workspace build/test wrappers
- [ ] add `engine-custom/config/v8.env`
- [ ] keep `engine-custom` buildable and documented while Chromium remains the short-term focus

## Summary

The client is a real application layer, not a placeholder.
That makes client work some of the highest-leverage work we can do while the Chromium engine path matures.

## 2026-04-04 CEF hybrid checkpoint and next seam

We now have a meaningful `renderer=cef` checkpoint in the split workspace:

- `engine-cef` publishes a real public client contract (`include/engine_cef/...`)
- `client` constructs `renderer=cef` through that public contract
- the CEF adapter now owns the shell-facing state/cache boundaries for:
  - page/load state
  - navigation/document preparation
  - install/document ownership
  - presentation/display-list cache
  - frame/screenshot cache
- focused CEF-path tests exist and pass alongside the custom/chromium regression trio

### What is still transitional

The current `renderer=cef` path is still intentionally hybrid.
The remaining delegated pieces are:

- draw internals
- runtime behavior
- input behavior

Those still flow through the custom backend.

### Why this is a natural pause point

Up to this checkpoint, the work was mostly about moving ownership boundaries outward into the adapter without over-claiming a final architecture.

The next step is different: continuing deeper means deciding whether we want to keep borrowing more custom-engine implementation or instead pivot toward a truer `engine-cef` visual/runtime path.

### Recommended path forward

Before writing the next chunk of migration code, define the next seam explicitly.

Recommended immediate design question:

> Should the next slice keep peeling custom draw internals into the adapter, or should it start shaping a real `engine-cef`-owned frame/presentation surface for the client to consume?

Current recommendation:

- keep the current hybrid path as the working migration scaffold
- avoid blindly deepening temporary custom draw/runtime borrowing
- write a short v2 seam note before the next implementation push

That note now exists at:

- `engine-cef/docs/presentation-seam-v2.md`

### Suggested next design note scope

Keep it short and concrete. It should answer:

- what the client should consume from `engine-cef` for presentation
- whether `engine-cef` should become the source of truth for pixels/frames
- what remains client-owned (chrome, HUD, diagnostics, composition)
- whether runtime/input migration should wait until after a clearer visual/frame contract exists
