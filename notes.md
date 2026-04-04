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
