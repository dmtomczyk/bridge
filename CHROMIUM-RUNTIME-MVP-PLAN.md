# CHROMIUM-RUNTIME-MVP-PLAN.md

## Goal

Build a **real bare-bones Chromium runtime MVP** for BROWZ.

The target is:

> run BROWZ with the Chromium engine selected, load a real page through a live Chromium runtime session, and present real Chromium-generated frames in the app window.

This plan intentionally prefers a more typical Chromium ownership model over screenshot-export hacks.

---

## Why this plan exists

Several lower-effort paths were explored conceptually:

- one-shot screenshot export
- DevTools-driven screenshot loop
- proof-of-feasibility artifact capture

Those were useful for de-risking whether Chromium pixels are obtainable at all.

That question is now answered: **yes**.

However, those paths are not honest enough to count as the intended browser MVP.

This document resets the target to a more realistic Chromium-based architecture while still keeping scope intentionally small.

---

## MVP definition

The runtime MVP is successful when all of the following are true:

- BROWZ launches with the Chromium engine selected
- `engine-chromium` owns a live Chromium runtime session
- a real URL is loaded through that session
- Chromium owns page/render lifecycle for that page
- frames are produced from the live session on an ongoing basis
- frames are bridged into `BlinkProducedFrame`
- BROWZ presents those frames in its app window

This MVP may still be crude, but it must be a **real session-based runtime**, not a static artifact exporter.

---

## Non-goals

Still out of scope for MVP:

- full browser correctness
- full shell/backend API cleanup
- editable/form support
- click/input routing into Chromium
- multi-tab support
- extension support
- GPU optimization
- perfect frame pacing
- back/forward parity
- production performance
- full inspector integration

---

## Desired ownership model

## BROWZ client owns
- app UI and browser chrome
- address bar / shell behavior
- engine selection
- frame presentation bridge
- session/debug tooling

## engine-chromium owns
- live Chromium runtime session
- browser/context/web contents lifecycle
- page navigation through Chromium
- frame production from Chromium-owned rendering
- conversion into `BlinkProducedFrame`

## Important principle

BROWZ should not treat Chromium as a screenshot tool.
It should treat Chromium as a live embedded rendering runtime.

---

## MVP architecture

## 1. Runtime session object

Create a dedicated Chromium runtime/session object inside `engine-chromium`.

Suggested names:
- `blink_runtime_session.*`
- `blink_embedder_session.*`

### Responsibilities
- initialize and own a Chromium session/runtime
- create one browser/page target (or equivalent)
- manage viewport size
- navigate to a URL
- expose page/load state
- produce frames continuously or on tick

### Non-responsibilities
- final multi-tab model
- full engine API cleanup
- shell UI logic

---

## 2. Real page target / WebContents ownership

The session should own one real page target.

Depending on the exact technical path chosen, this may be represented as:
- a real `WebContents`
- a headless browser target
- another thin Chromium-owned live page primitive

The important point is that this is a **live runtime object**, not a one-shot capture request.

---

## 3. Real frame production path

The session must produce frames from the live page session.

For MVP, the frame source may still be CPU-oriented and crude.
That is acceptable.

What matters is:
- the frame comes from a live Chromium session
- the session continues to exist
- repeated frames are possible

### Acceptable MVP mechanisms
- begin-frame driven capture
- compositor/readback path
- another live rendering callback/readback path

### Unacceptable as the main MVP path
- one-shot screenshot file export treated as the product architecture

---

## 4. Frame conversion

The produced frame must become:
- `BlinkProducedFrame`

Minimum fields:
- width
- height
- stride
- sequence
- timestamp
- format `ARGB32`
- pixel buffer
- content/damage rects
- producer name

---

## 5. Host integration

`BlinkEmbedderHost` should orchestrate:
- session lifetime
- navigation handoff
- tick/poll/frame pump
- frame submission into `BlinkFrameSource`
- state export for debug/UI

This keeps the existing downstream bridge architecture intact.

---

## Implementation strategy

## Phase 1 — runtime session skeleton

### Goal
Create a live Chromium session/controller abstraction.

### Deliverables
- runtime session class exists
- session can launch the Chromium runtime path
- session can attach to one page target
- session can report basic status

### Notes
This may initially reuse remote debugging transport internally if needed, but the *architecture* should be framed as a live runtime session, not a screenshot tool.

---

## Phase 2 — first live frame loop

### Goal
Produce repeated frames from the live session.

### Deliverables
- navigation to one URL works
- first frame arrives
- subsequent frames can be requested/received
- frames are decoded/populated into `BlinkProducedFrame`

### Acceptable compromises
- low-frequency frame loop
- polling/tick-driven updates
- full-frame damage only
- CPU decode/readback only

---

## Phase 3 — app integration

### Goal
Display Chromium-driven frames in BROWZ.

### Deliverables
- host pumps the runtime session on `tick()`
- produced frames are submitted to `BlinkFrameSource`
- `BlinkFrameBridge` presents them in the app window
- placeholder path becomes fallback only

---

## Phase 4 — honest state reporting

### Goal
Make the Chromium path introspectable enough to be debuggable.

### Deliverables
- navigation state is real, not placeholder text
- load state is minimally honest
- debug output distinguishes:
  - session alive
  - page target attached
  - frame loop active
  - placeholder fallback vs real frame path

---

## Immediate technical decision

## Which runtime path should we use first?

For MVP, choose the narrowest runtime path that still feels like real Chromium ownership.

### Recommended answer
Use a live headless Chromium session as the first runtime substrate **only if** it is treated as a persistent session with repeated frame production.

Why this is acceptable:
- it is still a live Chromium runtime
- it is much closer to a real embedder/browser model than screenshot-export
- it gets BROWZ onto a real session/frame-loop architecture quickly

This should be treated as a stepping stone toward deeper embedder integration, not the final shape.

---

## MVP-quality compromises explicitly allowed

These are acceptable for first success:

- one page only
- one viewport only
- one active session only
- no input support
- no editable support
- no shell DOM sync from Chromium
- no tab history complexity
- frame updates only on tick or timer
- CPU bitmap/frame readback only

If the session is live and frames repeat, it still counts.

---

## First concrete coding target

The first implementation target should be:

> create `blink_runtime_session` that can keep a Chromium page session alive and return repeated frames for one URL.

That is the next real milestone.

---

## Success criteria for the first coding milestone

The first coding milestone after this document is complete when:

- a runtime session object exists
- the session can attach to one live Chromium page
- the session can request and receive at least two frames over time
- those frames can be surfaced as `BlinkProducedFrame`
- no one-shot artifact-export assumptions are baked into the main architecture

---

## Final principle

This MVP should be:
- minimal
- crude
- narrow
- CPU-based if necessary

But it must still feel like:

> BROWZ hosting a real Chromium runtime session

not:

> BROWZ taking screenshots of Chromium.
