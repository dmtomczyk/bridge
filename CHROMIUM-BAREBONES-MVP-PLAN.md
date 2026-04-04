# CHROMIUM-BAREBONES-MVP-PLAN.md

## Goal

Pivot from a screenshot-proof approach to a **real bare-bones Chromium frame-loop MVP**.

The target is:

> run the browser with the Chromium engine selected, load a real web page through Chromium, and present repeated real Chromium-generated frames in the app window.

This is still intentionally minimal.
It is not full browser parity.
But it must be more honest than a one-shot screenshot bridge.

---

## What counts as MVP now

The Chromium MVP is successful when all of the following are true:

- the app launches with the Chromium engine selected
- a real URL is loaded through Chromium
- Chromium remains alive as an active session, not just a one-shot artifact producer
- Chromium produces page frames through a repeatable frame loop
- those frames are bridged into `BlinkProducedFrame`
- `BlinkFrameSource` / `BlinkFrameBridge` present them in the app window
- the user sees real page content that can update over time

This does **not** require rich interactivity yet, but it must be more than a static screenshot export.

---

## Non-goals

Still explicitly out of scope for this MVP:

- full editable/form support
- full JS event/input parity with the shell
- browser history correctness
- multi-tab support
- optimized compositor/frame transport
- GPU acceleration
- final embedder architecture
- perfect engine_api cleanup
- production performance
- complete debugging/inspector tooling

---

## Key decision

## Do not use screenshot-file export as the MVP path

The proven screenshot path was useful because it answered the question:

> can Chromium provide real pixels in this environment?

Answer: yes.

But for MVP purposes it is too static and too far from a real browser engine session.

### Therefore
The screenshot path becomes:
- proof-of-feasibility
- debugging fallback
- artifact capture tool

It is **not** the target MVP architecture.

---

## Chosen MVP direction

Use a **live headless Chromium session** driven through DevTools protocol, with a repeated frame loop.

### Preferred shape
- launch `headless_shell` in remote-debug mode
- attach to the page target
- navigate a real page
- drive frame production using DevTools frame/screenshot mechanisms (`HeadlessExperimental.beginFrame` or equivalent)
- decode returned image data into ARGB32
- submit frames to `BlinkFrameSource`
- present them through the existing bridge

This is still CPU-oriented and not final, but it is a real engine session.

---

## Why this is acceptable as MVP

Because it satisfies the important truth conditions:

- Chromium owns page loading
- Chromium stays alive as a session
- page frames are requested repeatedly
- the app presents real frame updates from Chromium

Even if the loop is crude or low-frequency, it is still a real Chromium-backed rendering path.

---

## Critical-path architecture

## New core runtime object

The next major missing piece is a small Chromium session/controller object inside `engine-chromium`.

Possible shape:
- `blink_devtools_session.*`
- `blink_frame_loop_session.*`
- or similar

### Responsibilities
- launch and own the `headless_shell` process
- select an ephemeral debugging port
- query `/json/list` or create/attach a target
- own a WebSocket connection to the page target
- send DevTools commands
- manage navigation state
- request frames repeatedly
- decode returned image payloads
- expose produced frames to `BlinkEmbedderHost`

### Non-responsibilities
- final browser architecture
- multi-process sophistication
- full shell/engine contract design
- complex event/input mapping

---

## MVP frame loop design

### Session start
- launch headless shell with remote debugging enabled
- create/attach to one page target
- configure viewport / window size

### Navigation
- send `Page.navigate` for the requested URL
- optionally wait for load/dom events as needed

### Frame production
- request a frame using:
  - `HeadlessExperimental.beginFrame`
  - or a similarly suitable DevTools capture path
- receive encoded image data (likely PNG initially)
- decode to ARGB32
- assign sequence/timestamp
- submit as `BlinkProducedFrame`

### Presentation
- existing queue/bridge activates the latest frame
- app window renders real Chromium content

### Repetition
- on `tick()` or a simple timer, request another frame
- low frequency is acceptable for MVP if updates are real

---

## Minimum requirements for the frame loop

To count as MVP, the loop only needs:

- one active Chromium session
- one active page target
- one real URL load
- one repeatable frame request path
- decoded frame data in `BlinkProducedFrame`
- visible app presentation

That is enough.

---

## MVP-quality compromises explicitly allowed

These are acceptable for the first working version:

- single page / single target only
- one navigation at a time
- repeated PNG/base64 frame capture before more efficient transport exists
- coarse polling or tick-driven frame requests
- full-frame damage rect only
- simplistic title/load-state handling
- no user input routed into Chromium yet
- no editable support
- no shell/backend DOM synchronization through Chromium yet

The goal is real session-based rendering, not completeness.

---

## Recommended implementation order

### Phase 1 — session skeleton
1. create a Chromium session/controller object
2. launch `headless_shell` with remote debugging
3. discover/attach target
4. send basic DevTools commands reliably

### Phase 2 — first repeated frame
5. navigate to a URL
6. request frame data repeatedly through DevTools
7. decode frame payload into ARGB32
8. populate `BlinkProducedFrame`

### Phase 3 — host integration
9. plug session/controller into `BlinkEmbedderHost`
10. feed frames into `BlinkFrameSource`
11. present in app window through `BlinkFrameBridge`

### Phase 4 — basic session polish
12. update minimal page/load state honestly
13. keep screenshot capture as a debugging/proof tool
14. document the known-good launch recipe

---

## What should remain stubbed for now

To avoid scope creep, these should stay stubbed or partial until after MVP:

- editable APIs
- click/input routing into Chromium
- shell DOM synchronization from Chromium
- back/forward correctness
- high-frequency frame pacing
- damage-region optimization
- perf tuning

---

## Existing assets we should reuse

This pivot still reuses most of the existing Chromium scaffold work:

- `BlinkProducedFrame`
- `BlinkFrameSource`
- `BlinkFrameBridge`
- `BlinkEmbedderHost`
- navigation state scaffolding
- proven DevTools endpoint bring-up
- proven DevTools screenshot capture path

What changes is the architecture target:
- session + repeated frame production
- not one-shot file export

---

## First concrete implementation target

The next implementation target should be:

> create a live Chromium DevTools session object that can navigate one URL and return repeated decoded frames.

That is the smallest honest step toward the real MVP.

---

## Success smell vs failure smell

### Success smell
- Chromium process stays alive
- page target is attached
- frames keep arriving
- app presents real page updates

### Failure smell
- everything still revolves around writing screenshot files
- no persistent session exists
- no repeated frame loop exists
- the app only ever shows a static capture

---

## Final principle

The MVP should be:

- crude
- narrow
- CPU-based
- low-feature

But it must still be **session-based and frame-loop-based**, not just artifact-based.
