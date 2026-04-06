# Runtime-host real-site polish sweep

_Date: 2026-04-05_

This document defines a targeted real-site sweep for the **official BRIDGE browser path**:

- `browser --renderer=cef-runtime-host`

The goal is not endless QA.
The goal is to answer a practical question:

> Is BRIDGE now good enough that a few software-engineer friends might actually keep using it for a while instead of just saying “cool demo” and closing it?

---

## 1. Scope

This sweep is for:
- the official runtime-host browser path only
- live interactive behavior
- realistic user flows

This is **not** a unit-test plan and **not** a generic browser certification effort.

---

## 2. Current capability baseline

At the time of this sweep, BRIDGE runtime-host already has:

- official runtime-host launcher path
- branded in-window browser chrome
- in-window navigation controls
- current URL / loading state reflection
- interactive URL editing with cursor placement
- persistent profile behavior
- visible profile label
- clipboard/basic edit command support
- popup/new-window policy
- file chooser/upload support
- download behavior
- explicit permission deny policy
- a small SDL workbench for local launch/control loops

So this sweep is meant to discover what still feels rough in real browsing, not whether BRIDGE is alive at all.

---

## 3. Rating scale

Each scenario should be marked as one of:

### Pass
- behavior works cleanly enough to keep using without hesitation

### Rough but acceptable
- behavior basically works
- rough edges are noticeable
- still acceptable for friend alpha unless multiple rough spots stack up badly

### Broken / follow-up needed
- flow cannot complete
- behavior is misleading or confusing enough to stop use
- or reliability is too poor to count as usable

---

## 4. General sweep rules

### Rule 1
Only score against the **real browser path**:

```bash
./build/cef-hybrid-real/browser --renderer=cef-runtime-host <url>
```

### Rule 2
Favor real user flows over synthetic edge cases.

### Rule 3
When something is rough, capture:
- what page/site
- what action you took
- what happened
- whether it is tolerable or actually blocking

### Rule 4
Do not call the overall sweep “done” just because most things launch.

The bar is:
- does it still feel usable after several site hops and feature interactions?

---

## 5. Core matrix

## A. Google

### Target URL
- `https://google.com`

### Scenarios
- load homepage
- click search box
- type a query
- run search
- open a result
- go back
- edit URL bar in BRIDGE chrome
- reload

### What to watch
- startup correctness
- text entry comfort
- navigation state honesty
- scroll behavior
- back/forward/reload sanity

### Rating
- [ ] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- 

---

## B. GitHub

### Target URL
- `https://github.com`

### Scenarios
- load homepage or logged-out page
- navigate to a repo
- click a few links between pages
- scroll a longer page
- use in-browser back/forward
- try URL-bar editing to move between pages

### What to watch
- complex page rendering
- navigation across many internal links
- long-page scrolling
- perceived responsiveness
- whether site feels “normal enough”

### Rating
- [ ] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- 

---

## C. Docs site

### Suggested target
- any docs-heavy site with lots of text and links
- examples:
  - MDN
  - a framework docs site
  - internal docs if useful

### Scenarios
- open docs homepage
- use a search field if available
- scroll a long article/page
- open links in same tab
- use back/forward

### What to watch
- long-scroll smoothness
- text legibility
- search-field comfort
- whether docs browsing feels boring in a good way

### Rating
- [ ] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- 

---

## D. Popup/new-window policy

### Target
- local smoke page:
  - `client/examples/popup-smoke.html`

### Recommended launch
```bash
cd client/examples
python3 -m http.server 8000
```
Then open:
```bash
http://127.0.0.1:8000/popup-smoke.html
```

### Scenarios
- `target="_blank"` link
- `window.open(url)`
- `window.open('', '_blank')`

### Current expected behavior
- real target URL opens in the current BRIDGE window
- blank / `about:blank` / `javascript:` style popup is blocked

### Rating
- [ ] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- 

---

## E. Upload behavior

### Target
- local smoke page:
  - `client/examples/upload-smoke.html`

### Scenarios
- choose one file in single-file input
- choose multiple files in multi-file input
- confirm file list appears in page UI

### What to watch
- chooser appears reliably
- multi-select behaves honestly
- chosen files propagate back into the page correctly

### Rating
- [ ] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- 

---

## F. Download behavior

### Target
- local smoke page:
  - `client/examples/download-smoke.html`

### Scenarios
- click download link
- verify file lands in expected location

### Current expected behavior
- BRIDGE saves to:
  - `~/Downloads/BRIDGE`

### What to watch
- does the download trigger reliably?
- is the save location predictable?
- does it feel acceptable even without richer download UI?

### Rating
- [ ] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- 

---

## G. Permissions behavior

### Target
- local smoke page:
  - `client/examples/permissions-smoke.html`

### Scenarios
- notifications request
- geolocation request
- media/camera+mic request

### Current expected behavior
- denied explicitly
- failed in a clear/logged way

### What to watch
- whether denial feels clear instead of mysterious
- whether the page behavior is understandable
- whether logs confirm what happened

### Rating
- [ ] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- 

---

## H. Profile behavior

### Suggested targets
- any cookie/session-preserving site
- or local smoke plus a known real site

### Scenarios
- run in default profile mode
- create/persist state
- restart BRIDGE
- verify persistence
- run in guest/temp mode
- verify that guest state is isolated/throwaway

### What to watch
- persistence honesty
- no cross-mode confusion
- profile label remains understandable

### Rating
- [ ] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- 

---

## I. Workbench-assisted flow

### Target
- `bridge_workbench`

### Scenarios
- launch browser from workbench
- use Default mode
- use Guest mode
- Stop
- Force Kill
- edit URL precisely in workbench field

### What to watch
- whether the workbench meaningfully speeds up iteration
- whether Stop/Force Kill are trustworthy enough
- whether mode selection is obvious

### Rating
- [ ] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- 

---

## 6. Optional stretch scenarios

These are useful if energy/time remain after the core matrix.

## J. Auth / login-ish flow
- one safe site where login flow is easy to test
- watch popup handling, redirects, persistence, text input, copy/paste

## K. Heavier app-ish site
- one modern JS-heavy page/app
- watch responsiveness and rendering correctness

## L. Media/document site
- PDF-ish or embedded media page if relevant
- only if it matters for friend alpha

These are helpful, but should not block the first pass through the core matrix.

---

## 7. Exit criteria for the sweep

The sweep is successful enough for friend-alpha planning when:

1. most core scenarios are **Pass** or **Rough but acceptable**
2. no major everyday flow is still obviously broken
3. rough spots are specific and finite, not “browser still feels fundamentally fake”
4. the remaining blockers feel like polish/prioritization choices rather than missing core capabilities

---

## 8. What to do with results

After running the sweep, group findings into:

### A. Must fix before friend alpha
- directly blocks normal use
- or creates obvious confusion/instability

### B. Nice next polish
- works, but is a little rough
- worth improving soon

### C. Can wait
- noticeable, but not important enough to hold progress

That grouping matters more than trying to “finish” every rough edge immediately.

---

## 9. Recommended next step after creating this doc

Actually run the matrix and capture ratings/notes directly in this file or a short follow-up checkpoint note.

A good follow-up could be:
- `docs/runtime-host-real-site-sweep-results-2026-04-05.md`

if the notes start getting large.
