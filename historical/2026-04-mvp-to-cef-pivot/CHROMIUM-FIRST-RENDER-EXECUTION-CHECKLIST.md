# CHROMIUM-FIRST-RENDER-EXECUTION-CHECKLIST.md

## Current status snapshot

### Verified
- `engine-chromium/third_party/src/out/browz-headless/headless_shell` exists
- Chromium-only build path works
- app-side frame queue / present bridge already exists via:
  - `BlinkProducedFrame`
  - `BlinkFrameSource`
  - `BlinkFrameBridge`
  - `BlinkEmbedderHost`

### Main missing link
There is still **no real frame producer** feeding `BlinkProducedFrame` from actual Chromium output.

That is the critical blocker.

---

## Immediate execution checklist

# Phase A — standalone proof (already mostly done)
- [x] verify `headless_shell` binary exists
- [ ] record exact known-good standalone invocation for a real URL render artifact
- [ ] preserve one proof artifact (screenshot/bitmap)

## Notes
This is already close enough to "done" operationally, but the exact invocation still needs to be recorded in-repo.

---

# Phase B — frame seam definition
- [x] confirm existing bridge target type is `BlinkProducedFrame`
- [x] confirm accepted format is CPU bitmap `ARGB32`
- [x] confirm bridge already carries:
  - width
  - height
  - stride
  - sequence
  - timestamp
  - device scale factor
  - content rect
  - damage rect
  - producer name
  - ARGB pixel buffer
- [ ] document the exact source-to-`BlinkProducedFrame` conversion path from the real Chromium output

## Minimum requirement
Populate:
- `width`
- `height`
- `stride_bytes`
- `format=ARGB32`
- `pixels_argb`
- `producer_name`

Everything else can be coarse but should be filled honestly if available.

---

# Phase C — real frame producer inside `engine-chromium`

## MVP requirement
Implement the smallest possible producer that can:
1. request/load a real URL via Chromium
2. obtain a rendered frame/screenshot bitmap
3. convert it to `BlinkProducedFrame`
4. call `submit_produced_frame(...)`

## Acceptable first implementation
The first version may be crude, including a screenshot/export based producer, as long as:
- pixels are real Chromium-rendered pixels
- the app displays them through the existing frame bridge

## Explicitly acceptable compromises for MVP
- single-frame or low-frequency frame updates
- coarse damage rect (`full frame dirty`)
- simplistic timestamp/sequence generation
- slower screenshot-based bridging before deeper embedder callbacks exist

## Not required for MVP
- smooth continuous compositing
- efficient incremental damage updates
- high-performance frame streaming
- final embedder architecture

---

# Phase D — real navigation hookup
- [ ] `BlinkEmbedderHost::navigate(url)` must trigger a real Chromium navigation
- [ ] load state should reflect real progress/results instead of scaffold-only placeholder text
- [ ] successful navigation should eventually cause a produced frame to appear

## Minimal honest behavior
Even if everything else is rough, a call to navigate must do more than set `page_state_.current_url`.

---

# Phase E — app-visible success
- [ ] `tick()` presents the queued real frame
- [ ] `render()` displays real website pixels instead of placeholder output
- [ ] app screenshot capture works against the real frame
- [ ] one smoke URL renders visibly in the app window

---

## Most likely critical-path implementation target

If choosing the single most important first coding target, it is:

### Implement a real `BlinkProducedFrame` producer in `engine-chromium`

Everything else already has enough scaffolding to support that path.

---

## Recommended coding order

1. **Record standalone render command**
   - exact command
   - exact output artifact path

2. **Add a small internal note or code comment** documenting the first frame-source strategy
   - likely headless-shell artifact capture -> ARGB32 bridge

3. **Implement a one-shot real frame submit path**
   - enough to test one page / one frame

4. **Hook navigation to that path**
   - navigate URL
   - receive frame
   - submit frame

5. **Verify app display**
   - Chromium engine selected
   - page visible

Only after that should iteration move to polish.

---

## Practical MVP bar

The MVP is achieved when this works:

```text
launch app with Chromium engine
-> navigate to https://example.com
-> Chromium produces a real bitmap
-> bitmap becomes BlinkProducedFrame
-> BlinkFrameBridge presents it
-> screenshot proves visible page content
```

That is enough.

---

## Stretch goals if time remains
- [ ] cleaner root/browser startup wrapper for Chromium engine
- [ ] screenshot-on-success helper
- [ ] improved debug lines for real-frame source activation
- [ ] known-good smoke URL list
- [ ] cached known-good Chromium revision + GN args note
- [ ] follow-up automation script after manual path works
