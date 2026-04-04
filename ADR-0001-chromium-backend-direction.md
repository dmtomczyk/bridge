# ADR-0001: Chromium backend direction after MVP proof

## Status

Accepted

## Date

2026-04-04

## Context

The current Chromium backend path successfully answered the MVP question:

- Chromium can be launched and controlled from the shell.
- Real pages render.
- Frames can be ingested into the app and presented.
- Basic input/navigation loops exist.

The current implementation path is:

- `headless_shell`
- DevTools session ownership
- `HeadlessExperimental.beginFrame` / screenshot capture
- PNG/base64 decode
- host-side frame presentation

This path was chosen because it was the fastest credible route to first real Chromium pixels without building a full Chromium embedder from scratch first.

Relevant repo context:

- The first-render plan explicitly chose the headless path because it was already the documented build target and avoided designing a custom embedder before showing pixels.
- The proven capture notes documented DevTools screenshot capture as the proven real-pixel acquisition path for the Chromium MVP.
- The runtime-session notes evolved that into a repeated `beginFrame(... screenshot: {format: 'png'})` loop as the preferred MVP frame-production path.

The current backend has now exposed its structural limitations:

- synchronous DevTools round-trips in hot paths
- screenshot-based frame transport
- expensive PNG/base64 decode path
- UI-thread sensitivity and poor responsiveness under real interaction
- poor optimization feedback loop when improvements appear to require Chromium binary rebuilds

The MVP backend achieved its purpose, but it should not be assumed to be the long-term Chromium architecture.

## Decision

We will treat the current `headless_shell` + DevTools + screenshot backend as a **reference / bring-up backend**, not the presumed long-term production Chromium architecture.

We will execute a **controlled pivot now**:

1. keep the current backend runnable for reference, demos, debugging, and regression comparison
2. limit work on the current backend to correctness, stability, and instrumentation
3. stop major architecture work on the screenshot/DevTools path
4. begin defining and executing the long-term Chromium integration path now

## Options considered

### Option A — Keep pushing the current headless/DevTools backend as the main track

#### Pros
- fastest path to more short-term visible functionality
- leverages existing momentum and code
- useful for demos and regression baselines

#### Cons
- high risk of polishing a dead-end
- structural transport and scheduling costs remain
- tends to pull the project toward Chromium binary patching / long rebuild loops
- increases the risk that an MVP path becomes permanent by accident

### Option B — Controlled pivot now, keep current backend as reference

#### Pros
- preserves current work as a validated reference backend
- prevents over-investing in the screenshot/DevTools path
- starts the real architecture work while lessons are fresh
- minimizes pressure to modify Chromium binaries during bring-up
- provides a stable baseline for future backend comparison

#### Cons
- introduces a temporary split between reference backend and target backend
- may feel slower in the short term than continuing to tweak the current backend

### Option C — Hard pivot immediately and stop active work on the current backend

#### Pros
- strongest architectural focus
- zero ambiguity about direction

#### Cons
- more abrupt transition
- risks giving up a useful reference/debug backend
- increases short-term execution risk if the next backend has unknowns

## Decision outcome

We choose **Option B**.

The current backend has already succeeded at the thing it was supposed to prove: that Chromium can be integrated into the shell and paint real content. That means further heavy investment in the screenshot/DevTools path is likely to have diminishing returns.

At the same time, preserving it as a reference backend is valuable:

- it validates shell/backend contracts
- it gives us a correctness baseline
- it provides a fallback for demos/debugging during the pivot

## Consequences

### Positive
- architectural intent is now explicit
- the MVP path is preserved without being promoted to the long-term target
- future work can compare against a real known-working baseline
- avoids deeper investment in a path with poor feedback loops

### Negative
- the repo will temporarily carry a reference backend and a target backend direction simultaneously
- some current-backend work that would make demos nicer will be intentionally deprioritized
- long-term backend work will require new planning and probably a new integration boundary

## Allowed work on the current backend

Allowed:

- correctness fixes
- crash / hang fixes
- test stability
- instrumentation / observability
- small quality-of-life improvements

Not allowed without explicit reconsideration:

- major architecture expansion of the screenshot/DevTools path
- heroic performance work aimed at making it production-worthy
- Chromium binary patch / rebuild efforts intended to rescue the current path as the long-term solution

## Next decision to make

The next major architectural question is:

> what should the long-term Chromium integration model be?

Candidates to evaluate include:

- a CEF / Alloy-style embedder route
- a deeper Chromium content-embedder route
- any other more native embedding model that fits the shell architecture better than the current headless screenshot path

## Follow-up actions

1. freeze the current backend as reference / bring-up status in docs and planning
2. snap and preserve a known-good baseline tag for the current functional backend
3. write the pivot execution plan for evaluating and starting the long-term backend
4. begin the architecture comparison for the next Chromium integration model
