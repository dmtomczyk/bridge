# ADR-0003: Execute a CEF/Alloy-style Chromium embedder spike as the first long-term pivot

## Status

Accepted

## Date

2026-04-04

## Context

ADR-0001 reclassified the current `headless_shell` + DevTools + screenshot backend as a **reference / bring-up backend**.

ADR-0002 compared the realistic long-term Chromium integration directions and recommended pursuing a **CEF / Alloy-style embedder route first**, ahead of a deeper Chromium content-embedder route.

We now need a concrete execution plan that turns that architectural preference into a practical spike with clear boundaries and success criteria.

The current tagged reference baseline remains:

- root / workspace tag: `chromium-mvp-reference-2026-04-04`
- root reference commit: `a40fa15` and later ADR commits in the root repo
- client reference commit: `9d831d0`
- engine-chromium reference commit: `a693273`
- engine-custom reference commit: `ce7091b`

The current backend remains useful as:

- a correctness baseline
- a demo/reference backend
- a shell/backend contract reference
- a fallback while the embedder spike is explored

## Decision

We will execute a **small, explicit CEF / Alloy-style embedder spike** as the first long-term Chromium pivot.

This spike is not a production migration. It is a deliberate feasibility and architecture-validation phase.

The spike should answer:

1. can we host Chromium in a more native way than the current screenshot backend?
2. can we get a materially better responsiveness story without touching Chromium internals directly?
3. what parts of the current shell/backend architecture can be preserved cleanly?
4. how painful is the build, packaging, and iteration loop compared with the current path?

## Scope of the spike

## In scope

- selecting and wiring one serious CEF/Alloy-style embedding route
- standing up a minimal desktop host that opens a real Chromium-powered window
- loading a real page such as `https://example.com`
- basic input validation:
  - click
  - text input
  - navigation
- collecting build/runtime observations
- comparing responsiveness and integration complexity against the current reference backend
- documenting what current shell abstractions survive and what must change

## Out of scope

- full migration of the current shell to the new backend
- full tab model
- production packaging/distribution
- accessibility completeness
- polished browser chrome
- full settings/profile management
- cross-platform support beyond the current desktop target
- deleting the current reference backend

## Primary candidate

The spike should evaluate a **CEF / Alloy-style embedder route first**.

The exact sub-choice may still be refined during spike setup, but the goal is to use the smallest serious embedding layer that provides:

- native window/browser hosting
- navigation lifecycle
- input handling
- a realistic path toward replacing the screenshot-driven reference backend

## Why this is the right first pivot

This route best balances:

- more native browser integration than the screenshot path
- less engineering cost than a full Chromium content embedder
- better performance potential than the current frame-capture model
- a much healthier feedback loop than custom Chromium binary patching

## Spike deliverables

The spike is considered real only if it produces all of the following:

### 1. Running proof

A runnable host application that:

- launches successfully on the desktop target
- opens a Chromium-backed window
- loads `https://example.com`
- responds to at least basic click and text input

### 2. Short technical write-up

A document summarizing:

- which embedder flavor was chosen
- how it is built and run
- what external runtime pieces it requires
- what worked quickly
- what felt painful
- what looked promising

### 3. Migration-boundary notes

A first-pass list of:

- what from the current shell/backend can be preserved
- what probably needs adaptation
- what should be retired entirely

### 4. Comparison against the reference backend

At minimum, qualitative comparison on:

- responsiveness
- complexity
- build loop
- likely long-term maintainability

## Repo / code-organization plan

The spike should be isolated from the current reference backend.

## Preferred shape

Create a dedicated path for the spike rather than blending it into the current screenshot backend.

Recommended options, in order:

### Option A — new child repo / submodule for the spike

Example shape:

- `engine-chromium-cef/`
- or `engine-embedder-cef/`

#### Why

- keeps the experimental backend isolated
- avoids contaminating the current `engine-chromium` reference backend
- makes the eventual keep/throw-away decision much easier

### Option B — isolated directory under the root repo

Example shape:

- `spikes/cef-embedder/`

#### Why

- still isolated
- lower ceremony than a whole new child repo
- acceptable for a short exploratory phase

### Avoid

Do **not** start by heavily modifying the current `engine-chromium` reference backend to host the spike.

That would immediately blur the boundary we just established.

## Recommended choice

Start with:

- `spikes/cef-embedder/`

If the spike becomes promising enough to continue beyond the first proof, promote it into a dedicated engine/backend repo.

## Architectural assumptions for the spike

These are the assumptions we want to test, not take on faith.

### Assumption 1

The shell can keep owning high-level browser chrome and intent while the embedder owns native page content.

### Assumption 2

The current screenshot-oriented `BlinkRuntimeSession` should **not** be migrated forward as the main long-term abstraction.

### Assumption 3

The new backend will likely need a different contract than “repeated screenshot frames become `BlinkProducedFrame`.”

### Assumption 4

Some current abstractions are still worth preserving, especially:

- backend factory direction
- renderer/backend selection concepts
- debug/session logging mentality
- smoke/regression harnesses
- shell-owned navigation/input intent vocabulary where it remains sensible

## Acceptance criteria

The spike is successful if all of these are true:

1. a Chromium-backed embedded window runs locally
2. `https://example.com` renders without the screenshot/PNG path
3. click/input/navigation are functional enough to prove interactivity
4. the iteration loop is materially healthier than the Chromium-patching route
5. the result appears architecturally more native and more promising than the current reference backend

The spike does **not** need to win on every axis yet. It only needs to prove the route is viable enough to continue.

## Failure criteria

The spike should be considered a failed first target if any of these become clear:

1. the build/distribution story is effectively as painful as direct Chromium patching
2. the embedder model fundamentally fights the shell architecture we want
3. the responsiveness/integration benefits are too small to justify the migration
4. the amount of glue required is so high that a content-embedder route becomes clearly preferable

If the spike fails for these reasons, the next decision is **not** to run back to the screenshot backend. The next decision is to reassess the deeper content-embedder route.

## Execution phases

## Phase 1 — Setup and choose the exact embedder path

### Tasks

- choose the exact CEF / Alloy-style starting point
- document dependency/build assumptions
- choose spike location (`spikes/cef-embedder/` unless a better reason appears)
- define the minimal host app skeleton

### Deliverable

- checked-in spike scaffold
- short README with build/run expectations

## Phase 2 — First real embedded page

### Tasks

- open a native window
- initialize the embedder runtime
- load `https://example.com`
- confirm real content is visible

### Deliverable

- first real embedded-browser proof

## Phase 3 — Minimal interaction validation

### Tasks

- click inside the page
- basic text input
- basic navigation event/state observation
- capture notes on focus/input behavior

### Deliverable

- minimal interaction proof

## Phase 4 — Comparison and migration notes

### Tasks

- compare to the tagged reference backend
- document observed strengths/weaknesses
- record likely migration boundary

### Deliverable

- short comparison memo or doc update

## Immediate execution checklist

These are the first concrete actions to take.

- [ ] create `spikes/cef-embedder/`
- [ ] add a spike README describing goal and non-goals
- [ ] choose the exact embedder flavor and bootstrap method
- [ ] create a tiny host app that opens a window
- [ ] load `https://example.com`
- [ ] record the exact run/build steps
- [ ] capture first impressions of responsiveness and integration pain
- [ ] write migration-boundary notes after the first proof

## Rules during the pivot

1. do not treat the current screenshot backend as the mainline optimization target
2. do not let the embedder spike silently mutate the reference backend
3. keep the reference backend runnable during the spike
4. prefer isolated spike code over broad repo churn
5. document observations early, even if the spike is rough

## Consequences

### Positive

- the project now has a concrete first long-term execution path
- the screenshot backend remains useful without dominating future architecture
- feedback loops should improve relative to Chromium binary patching
- the next major uncertainty becomes specific and testable

### Negative

- the project will temporarily support both a reference backend and a spike path
- some time will go into scaffold/build work that may later be discarded
- there is still meaningful technical uncertainty in the embedder choice

## Follow-up actions

1. optionally push ADR-0001/0002/0003 and the reference tags once desired
2. create the spike directory and README
3. begin Phase 1 of the embedder spike
4. keep current-backend work limited to maintenance and instrumentation only
