# ADR-0002: Long-term Chromium integration options after MVP proof

## Status

Proposed

## Date

2026-04-04

## Context

ADR-0001 reclassified the current `headless_shell` + DevTools + screenshot path as a **reference / bring-up backend**, not the presumed long-term production Chromium architecture.

We now need to choose the most appropriate long-term Chromium integration model.

The MVP/reference backend has already proven:

- Chromium can be launched from the shell
- real pages can render
- the shell/backend split is viable
- basic input/navigation ownership in the shell is possible

It has also exposed the limitations of the current path:

- screenshot-oriented frame acquisition
- DevTools round-trips in hot paths
- PNG/base64/decode overhead
- poor responsiveness under realistic interaction
- weak feedback loop when trying to optimize by modifying Chromium binaries

This ADR compares the two most realistic long-term directions:

1. **CEF / Alloy-style embedder route**
2. **Chromium content-embedder route**

A third option — continuing to evolve the current headless screenshot backend — is intentionally treated here as the reference baseline, not the target architecture.

## Decision drivers

We should optimize for:

1. **Long-term runtime performance and responsiveness**
2. **Reasonable build and debug feedback loop**
3. **Maintainability for a small team**
4. **Ability to integrate with the existing shell architecture**
5. **Avoidance of unnecessary dependence on custom Chromium binary patching**
6. **Controlled migration from the current reference backend**

---

## Option A — CEF / Alloy-style embedder

## Summary

Adopt a more standard Chromium embedding surface rather than driving `headless_shell` remotely.

This would mean using an embedding layer that already knows how to host Chromium in an application, own browser lifecycle, and present real content in a more native way than screenshot capture.

## Pros

### 1. Much closer to a normal embedded browser architecture

This is the closest option to “implement Chromium more like other browsers/apps” without taking on Chromium’s deepest embedder surface directly.

### 2. Better chance of real interactivity/performance sooner

Compared with the screenshot/DevTools backend, this path is more likely to:

- avoid screenshot transport
- avoid PNG/base64 frame movement
- avoid repeated DevTools frame pumping in the hot path
- provide a more natural input/presentation model

### 3. Smaller architectural leap than a full content embedder

CEF/Alloy still requires work, but it gives us a substantial amount of browser hosting machinery that we do not currently have.

### 4. Better iteration economics than custom Chromium patching

Even if builds are still heavier than ordinary app code, this is more attractive than a workflow that depends on repeatedly modifying and rebuilding Chromium internals just to improve the current backend.

### 5. Good transitional fit

We can likely preserve:

- shell-owned chrome/UI concepts
- navigation/input intent model
- much of the debug/session/logging mindset
- some backend abstraction boundaries

## Cons

### 1. Adds a large dependency/runtime model of its own

CEF/Alloy is not “light.” It brings a significant ecosystem and integration surface.

### 2. May constrain some shell ambitions

Depending on how tightly we want to own painting/presentation/process behavior, the embedder may not fit every future design desire perfectly.

### 3. Migration still requires serious glue work

We still need to answer:

- how the shell chrome and browser content coexist
- who owns tabs/process lifecycle
- how input/focus/IME are routed
- what the backend abstraction looks like under the new model

### 4. Platform/build complexity remains non-trivial

This is still Chromium, so the toolchain/build/runtime packaging story will not be tiny.

## Risks

- we choose it because it feels safer, then later discover it fights some core shell requirement
- we under-estimate integration work around custom chrome, focus, or rendering ownership

## Fit for this project

High.

This looks like the best “serious long-term move with a still-human feedback loop” candidate.

---

## Option B — Chromium content embedder

## Summary

Build on Chromium’s deeper native embedding surface directly rather than using a higher-level embedder layer.

This is the most direct route to owning Chromium behavior on our terms, but also the most ambitious.

## Pros

### 1. Maximum control

This option gives the team the strongest say over:

- process model
- compositor ownership
- windowing integration
- input and focus routing
- rendering/presentation choices
- shell/browser boundary design

### 2. Best architectural purity if executed well

If the long-term vision involves a deeply custom browser/shell experience, this route may fit best in theory.

### 3. Easier to avoid “adapter tax” long-term

Higher-level embedders inevitably impose their own model. A content-embedder route avoids some of that if we are willing to do the work.

## Cons

### 1. Biggest engineering lift by far

This is the most expensive option in:

- build complexity
- integration complexity
- debugging complexity
- ownership burden

### 2. Worst feedback loop

This is the route most likely to recreate the “Chromium rebuild hell” problem at a much larger scale.

### 3. Highest maintenance burden

A small team can get buried here if we are not ruthless about scope.

### 4. Hardest path to a quick second proof

Compared with a CEF/Alloy route, the time from “decision” to “something visibly working” is likely much longer.

## Risks

- architecture is attractive on paper but too expensive in practice
- deep integration work delays visible progress for too long
- project energy gets consumed by platform/build plumbing instead of browser product behavior

## Fit for this project

Medium, maybe high only if we explicitly want a highly custom browser platform and are willing to pay for it.

Right now, this feels more like a second-stage option than the first pivot target.

---

## Option C — Keep the current headless screenshot backend as the destination

## Summary

Continue evolving the `headless_shell` + DevTools + screenshot backend until it is “good enough.”

## Pros

- lowest immediate switching cost
- leverages current momentum
- useful as a debugging/reference backend

## Cons

- weak long-term fit for responsive browsing
- structurally tied to screenshot/transport overhead
- too easy to over-invest in a path that was originally meant for MVP proof only
- increasingly pushes toward custom Chromium patching with a terrible feedback loop

## Fit for this project

Low as the destination.

Keep only as a reference backend.

---

## Comparison summary

### Performance potential
- **CEF / Alloy-style embedder:** high
- **Content embedder:** highest
- **Current headless screenshot path:** low-to-medium at best, with structural ceiling

### Build/debug feedback loop
- **CEF / Alloy-style embedder:** moderate
- **Content embedder:** poor
- **Current headless screenshot path:** good on the host side, terrible if Chromium patching enters the loop

### Engineering cost
- **CEF / Alloy-style embedder:** significant but tractable
- **Content embedder:** very high
- **Current headless screenshot path:** low-to-medium only if treated as reference; high if pushed beyond its natural limit

### Fit with “implement Chromium more like other browsers”
- **CEF / Alloy-style embedder:** high
- **Content embedder:** highest
- **Current headless screenshot path:** low

### Small-team maintainability
- **CEF / Alloy-style embedder:** best of the serious options
- **Content embedder:** most dangerous
- **Current headless screenshot path:** maintainable only as a reference backend, not as a heavily optimized destination

---

## Recommendation

### Recommended direction

Pursue **Option A: CEF / Alloy-style embedder first** as the primary long-term Chromium pivot target.

### Why

It best balances:

- real browser-style integration
- performance potential
- tractable engineering scope
- tolerable feedback loop
- compatibility with keeping the current backend around as a reference baseline

### Why not jump directly to the content-embedder route?

Because it is the highest-cost option with the slowest likely path to useful validation. It may still become the right final destination later, but it is too expensive as the first pivot target unless we have already ruled out the embedder route on hard technical grounds.

### Why not keep investing in the current backend instead?

Because it already succeeded as an MVP/reference backend, and additional architecture work there is increasingly likely to produce diminishing returns.

---

## Consequences

### Positive
- preserves a practical path toward a more native Chromium integration
- avoids further over-investment in the screenshot-based backend
- gives the team a cleaner narrative: MVP proof is done; now we are choosing the real architecture

### Negative
- requires fresh investigation/prototyping work
- adds a transition period where the reference backend and target backend coexist
- may still reveal new complexity once the embedder spike begins

---

## Execution plan if this ADR is accepted

### Phase 1 — Research and spike definition

1. confirm the exact embedder candidate and build/distribution story
2. define the smallest meaningful spike goal:
   - open a window
   - load `https://example.com`
   - show real content
   - basic click/input
3. define what existing shell/backend abstractions we expect to preserve

### Phase 2 — Minimal embedder spike

1. create a dedicated spike path or branch
2. bring up the embedded browser in the smallest possible host app shape
3. measure build complexity, runtime behavior, and responsiveness
4. compare against the current reference backend

### Phase 3 — Integration boundary design

1. define how shell chrome and browser content coexist
2. define ownership of tabs, navigation, focus, and window lifecycle
3. define migration approach from reference backend to target backend

---

## Follow-up actions

1. preserve the current tagged MVP/reference backend as the baseline
2. keep current-backend work limited to maintenance and instrumentation
3. prepare the embedder spike plan
4. explicitly archive or park the raw-transport/Chromium-patching experiments as exploratory work, not the mainline path
