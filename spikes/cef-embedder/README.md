# CEF / Alloy embedder spike

## Goal

Prove a more native Chromium integration path than the current `headless_shell` + DevTools + screenshot reference backend.

This spike exists to answer a narrow question:

> Can we host Chromium in a more normal embedded-browser shape, with a healthier responsiveness/build-feedback story than the current screenshot-driven backend?

## Status

Phase 1 scaffold.

No production migration is happening here yet.

## Chosen bootstrap path

For the first spike, use:

- **CEF binary distribution** on Linux x64
- **CMake-based host app** inside this directory
- **windowed rendering first**
- **Alloy-style runtime preferred** for the browser window
- **no off-screen rendering in the first spike**
- **no Chromium source build / patching** as part of first bring-up

### Why this bootstrap path

- avoids the worst feedback loop from rebuilding Chromium internals
- is much closer to a normal embedded browser architecture
- keeps the spike focused on proving the integration boundary, not custom frame transport
- aligns with the project goal of moving toward a real long-term Chromium integration instead of polishing the screenshot backend

## Non-goals

- replacing the current backend yet
- full browser chrome
- tabs/history/session persistence parity
- accessibility completeness
- production packaging
- cross-platform support
- off-screen rendering

## First success criteria

The spike is considered alive once it can:

1. build against a CEF binary distribution
2. open a native window
3. load `https://example.com`
4. show real content
5. accept basic click/input

## Directory layout

- `docs/` — decisions, setup notes, and checklists
- `src/` — spike source code

## Current reference backend

The current tagged reference baseline remains:

- `chromium-mvp-reference-2026-04-04`

That backend is for reference/demo/regression comparison only. This spike should not mutate it.

## Immediate next tasks

See:

- `docs/bootstrap-decision.md`
- `docs/cef-distribution-bootstrap.md`
- `docs/linux-prereqs.md`
- `docs/phase-1-checklist.md`
