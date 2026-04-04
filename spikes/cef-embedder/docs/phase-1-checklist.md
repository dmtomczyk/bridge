# Phase 1 checklist — CEF / Alloy embedder spike

## Outcome of Phase 1

Have a clean spike scaffold plus a concrete bootstrap path so Phase 2 can focus on getting the first embedded browser window on screen.

## Checklist

- [x] Create isolated spike directory: `spikes/cef-embedder/`
- [x] Write spike README with goals/non-goals
- [x] Record bootstrap decision
- [x] Decide exact CEF distribution/version acquisition flow
- [x] Document expected local prerequisites for Linux x64
- [x] Create initial CMake skeleton for the host app
- [x] Create initial host app skeleton (`src/main.cpp`)
- [x] Record how `CEF_ROOT` will be supplied locally
- [x] Write the smallest run target goal: open window + load `https://example.com`

## Phase 2 preview

Phase 2 starts when the project can be configured and compiled against a chosen CEF distribution.

The first visible milestone is:

- native window opens
- Chromium content is visible
- `https://example.com` loads

## Notes to future-us

- do not mutate the current reference backend during this spike
- prefer smaller, easier-to-throw-away spike code over elegant abstractions too early
- keep notes on every build/runtime pain point; those observations are part of the spike result
