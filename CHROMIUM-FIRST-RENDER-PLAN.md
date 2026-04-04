# CHROMIUM-FIRST-RENDER-PLAN.md

## Goal

Reach the first honest Chromium integration milestone:

> Open the BROWZ app with the Chromium engine selected, navigate to a real internet URL, and paint real page pixels in the app window.

This plan is intentionally narrow.
It is **not** a plan for full Chromium parity.
It is a plan for the **minimum viable real render**.

---

## Success definition

The milestone is complete when all of the following are true:

- the browser can run with `--renderer=blink` / Chromium engine selected
- navigating to a real URL (for example `https://example.com`) triggers a real Chromium load
- Chromium produces at least one real rendered frame for the page
- that frame is converted into `BlinkProducedFrame`
- the frame is submitted through `BlinkFrameSource`
- `BlinkFrameBridge` presents it in the app instead of the placeholder frame
- the user can visibly see real website content in the app window
- screenshot capture proves the result

If those are true, this milestone is a success even if many browser features are still incomplete.

---

## Non-goals

This milestone does **not** require:

- full back/forward correctness
- editable forms working through Chromium
- full JS interactivity parity
- multi-process hardening
- production-quality performance
- clean final engine API for every seam
- full inspector/debugger integration
- shell/backend mutation contract fully finished
- perfect resize behavior
- advanced compositing or GPU acceleration

If the app can display a real page rendered by Chromium, the milestone is met.

---

## Critical-path strategy

## Key principle

Do **not** try to invent the final perfect Chromium embedder architecture first.

Use the shortest honest path:

> get a real rendered frame out of Chromium's headless/Blink path and bridge it into the existing `BlinkProducedFrame -> BlinkFrameSource -> BlinkFrameBridge -> RenderTarget` pipeline.

The downstream app-side plumbing already exists.
The missing work is the upstream real frame source.

---

## Existing assets we should reuse

The current repo already has useful scaffolding that should stay on the critical path:

- `engine-chromium/BUILD.md`
- `BlinkPlatformBootstrap`
- `BlinkNavigationController`
- `BlinkFrameSource`
- `BlinkFrameBridge`
- `BlinkEmbedderHost`
- `BlinkProducedFrame`
- app-side `render(RenderTarget&)`
- screenshot/debug plumbing

The shortest route is to make those abstractions honest, not replace them.

---

## Critical path work items

# 1. Lock the rendering source strategy

## Decision
Use Chromium's **headless** rendering path as the first real frame producer.

This is already consistent with `engine-chromium/BUILD.md`.

## Why
- it is a real Chromium/Blink path
- it is already the documented build target (`headless_shell`)
- it avoids designing a custom embedder from zero before we can even show pixels

## Requirement
Document and commit to one first-source path for real pixels.

### Done when
- the team agrees that first real render comes from the headless path
- no alternate integration strategy is allowed to distract the milestone

---

# 2. Prove the standalone Chromium target can render a real page artifact

Before integrating with the app, verify the Chromium side can render outside the app boundary.

## Minimum requirement
Using the built Chromium target (`headless_shell` or equivalent), produce a real artifact from a URL such as:

- `https://example.com`

Artifact can be one of:
- screenshot
- bitmap output
- other concrete rendered frame output

## Why this matters
If the standalone Chromium target cannot render a page artifact, app integration is premature.

### Done when
- a real external website is rendered by the Chromium target
- output artifact is captured and preserved
- the exact invocation is recorded in repo docs or scripts

---

# 3. Define the minimal frame ingestion contract

The app already expects frames through `BlinkProducedFrame`.

## Requirement
Define exactly how a Chromium-produced frame becomes:

- width
- height
- stride
- ARGB32 pixels
- timestamp
- damage rect
- content rect
- producer name

for `BlinkProducedFrame`.

## Why
This is the narrowest integration seam between real Chromium output and the existing BROWZ app pipeline.

### Done when
- there is one documented conversion path from Chromium output to `BlinkProducedFrame`
- format assumptions are explicit
- the first implementation can fill the struct without guessing

---

# 4. Implement a real frame producer inside `engine-chromium`

## Requirement
Replace the placeholder-only frame submission flow with a real producer that submits at least one real frame from Chromium.

Possible shape:
- a headless-shell driven capture path
- an embedder callback path
- a one-frame polling/export bridge

The exact mechanism can vary, but the result must be:
- real pixels from Chromium
- passed into `submit_produced_frame(...)`

## Important rule
The first implementation may be crude.
It does **not** need to be elegant.
It only needs to be real and reliable enough to show a page.

### Done when
- `BlinkEmbedderHost` can receive a non-placeholder real frame after navigation
- debug output reflects a real frame source, not just placeholder state

---

# 5. Wire real navigation into the Chromium path

## Requirement
A call to:
- `navigate(url)`

must cause a real Chromium page load rather than only scaffold state changes.

## Minimum expectation
- one successful remote HTTP(S) URL load
- one resulting rendered frame

## Not required yet
- robust history model
- cancellation
- full error taxonomy

### Done when
- a real URL is loaded by Chromium
- load state/debug state shows something more honest than placeholder messaging

---

# 6. Replace placeholder presentation with real frame presentation

## Requirement
Once a real frame exists, `BlinkFrameBridge::render(...)` must present it in the app window instead of the placeholder card.

## Good news
Most of this path is already scaffolded.

### Done when
- app visibly shows the rendered website content
- placeholder path only appears as fallback/error behavior

---

# 7. Add one reproducible smoke test workflow

## Requirement
Define one reproducible workflow for humans to verify the milestone.

Example:

```bash
./compile.sh --engine chromium --js off
./startbrowser.sh --renderer=blink https://example.com
```

or whatever the real invocation becomes.

## Verification criteria
- app launches
- Chromium engine is selected
- page content appears
- screenshot can be captured

### Done when
- one short bring-up recipe exists
- someone new can follow it
- it produces visible output

---

## Implementation order (recommended)

Follow this order strictly unless reality forces a change.

### Phase A — standalone proof
1. build / preserve working Chromium target
2. run standalone real render against a real URL
3. capture proof artifact

### Phase B — frame seam
4. define conversion into `BlinkProducedFrame`
5. implement real frame submission in `engine-chromium`

### Phase C — app display
6. connect `navigate(...)` to real Chromium load
7. present frame in app window
8. verify visible page output

### Phase D — smoke workflow
9. document exact commands
10. capture screenshot proof

Do not jump to polish before Phase C works.

---

## Critical blockers to watch for

These are the things most likely to waste time if not handled explicitly.

### Blocker 1: trying to solve final architecture too early
Avoid:
- perfect engine API cleanup before first render
- final multiprocess design before first render
- final input model before first render

### Blocker 2: building Chromium successfully but not extracting usable pixels
A successful `headless_shell` build is necessary but not sufficient.
The milestone requires **usable frame data**.

### Blocker 3: getting real pixels but not integrating them into the existing bridge
Do not bypass the existing frame abstractions unless absolutely necessary.
Use:
- `BlinkProducedFrame`
- `BlinkFrameSource`
- `BlinkFrameBridge`

### Blocker 4: spreading effort across too many nice-to-haves
Stay focused on:
- one URL
- one frame path
- one visible render

---

## Bare minimum technical requirements list

If reduced to the shortest possible list, the project needs:

- a real Chromium rendering source (`headless_shell` path or equivalent)
- one successful remote page load
- one way to extract rendered pixels from Chromium
- one conversion into `BlinkProducedFrame`
- one successful frame submission into `BlinkFrameSource`
- one successful app-side present into the browser window
- one screenshot proving it worked

That is the absolute minimum.

---

## Stretch goals / QoL goals

These are valuable, but explicitly **not required** for first real render.

### Stretch goal 1 — better smoke URL set
Add 2-3 canonical smoke URLs:
- `https://example.com`
- a slightly more styled page
- one JS-heavy page later if needed

### Stretch goal 2 — friendlier startup flags
Make root/browser startup simpler, such as:
- `./startbrowser.sh --renderer=blink <url>`
- or equivalent root-level wrapper

### Stretch goal 3 — screenshot-on-success helper
Add an easy path that automatically captures a proof screenshot after first paint.

### Stretch goal 4 — clearer debug HUD/status lines
Show:
- Chromium selected
- page loaded
- real frame source active
- placeholder vs real frame state

### Stretch goal 5 — minimal failure reporting
If real render fails, show one useful error state instead of ambiguous placeholder messaging.

### Stretch goal 6 — cached known-good smoke recipe
Document exact known-good:
- Chromium revision
- GN args
- build command
- run command
- test URL

### Stretch goal 7 — one automated smoke check later
After manual success exists, add a focused smoke script or test lane for:
- launch
- navigate
- screenshot capture
- artifact assertion

---

## Recommended immediate next actions

If work starts right now, the next concrete actions should be:

1. verify/record the exact standalone command that makes the built Chromium target render a real URL artifact
2. define the exact `BlinkProducedFrame` population path from that output
3. implement the smallest possible real-frame submission path in `BlinkEmbedderHost`
4. verify the app window can display that frame

That is the critical path.

---

## Final principle

For this milestone, there is only one question that matters:

> Can Chromium produce real page pixels, and can BROWZ display them?

If yes, the milestone is achieved.
If no, everything else is secondary.
