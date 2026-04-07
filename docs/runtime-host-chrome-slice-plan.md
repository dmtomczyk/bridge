# Runtime-host chrome slice plan

_Date: 2026-04-05_

This document defines the next implementation slice for BRIDGE:

- **minimal official runtime-host chrome**

The goal is to move the official `browser --renderer=cef-runtime-host` path from:

- convincing runtime-host proof browser

closer to:

- small but usable browser shell

without turning this into a giant browser-UI rewrite.

---

## 1. Why this slice is first

This is the single biggest friend-alpha unlock.

Right now, BRIDGE can:
- launch
- load real sites
- paint real pages
- support meaningful interaction

But for normal use, it still lacks the minimum browser affordances people expect inside the window itself.

Adding a small amount of browser chrome should materially improve:
- first impression
- manual testing speed
- ability to self-drive navigation
- likelihood that a friend keeps it open longer than a few minutes

---

## 2. Scope

This slice is intentionally narrow.

### In scope
- top strip in the official runtime-host window
- back button
- forward button
- reload button
- address field
- go action via Enter and/or button
- visible current URL
- minimal loading/error indicator
- focus rules between chrome and page

### Nice-to-have if cheap
- stop button if load state makes it easy
- open externally button
- small BRIDGE identity mark in the strip

### Explicitly out of scope
- bookmarks
- settings UI
- download manager
- polished native GTK menus
- full window management system
- generalized launcher/workbench features
- deep theming

### Status note
This document started before tabs were reintroduced. As of 2026-04-06, the runtime-host path now has:
- a minimal visible tab strip
- click-to-switch / close / new-tab behavior
- initial popup/new-window → new-tab policy hardening

So this document should now be read as the chrome baseline that tabs were built on top of, not as proof that tabs are still out of scope.

This is **not** the final browser UX. It is the first usable chrome slice.

---

## 3. Constraints / design rules

### 3.1 Official path only
This is about:
- `browser --renderer=cef-runtime-host`

Treat that as the main/official path.

Do not frame the older SDL/Application-owned path as the normal browser while doing this work.

### 3.2 Keep it app-drawn / lightweight
The earlier discussion already favored an overlay/app-drawn approach rather than jumping straight into native GTK menu/chrome complexity.

That still seems right.

Recommended near-term direction:
- app-drawn strip inside the runtime-host window
- simple hit regions and text editing behavior
- no big native-menu detour yet

### 3.3 Avoid the earlier trap
An earlier first-pass top-strip attempt introduced geometry/input regressions and was intentionally backed out.

So for this slice:
- keep sizing logic boring and explicit
- keep page view rect and chrome rect rules simple
- do not entangle chrome work with speculative runtime-host layout rewrites beyond what the slice truly needs

### 3.4 Small-commit mindset
This should land in a few understandable slices, not one giant risky blob.

---

## 4. UX target

The target should feel like:
- a small branded browser shell
- not a toy debug badge
- not a giant desktop-browser clone

A reasonable first-pass strip might include:

- `[<] [>] [⟳] [ address field........................ ] [Go]`
- BRIDGE branding integrated modestly
- a tiny loading/error/status indicator if useful

That is enough.

---

## 5. Proposed UI model

## 5.1 Layout

Use a fixed top strip with a reserved height.

Suggested rough zones:
- left: BRIDGE mark / icon
- next: back / forward / reload
- center: address field
- right: optional Go or status affordance

### Simplicity rule
Make the strip height and button hit regions explicit constants.

Avoid clever dynamic layout at first.

## 5.2 Address field behavior

The address field should support:
- displaying current URL
- click to focus
- text editing
- Enter to navigate
- selecting/replacing contents cleanly

Short-term simplification is fine:
- single-line only
- no fancy history dropdown
- no autocompletion

## 5.3 Navigation button behavior

### Back
- enabled only when back is available
- disabled appearance when unavailable

### Forward
- enabled only when forward is available
- disabled appearance when unavailable

### Reload
- always visible
- triggers reload
- if a future stop action is easy, it can share the slot later

### Go
Optional if Enter in the address field is enough, but probably worth adding for clarity.

## 5.4 Status signal

Minimal is fine.

Enough to answer:
- loading?
- failed?
- idle?

This could be:
- tiny text
- color cue
- or very small indicator

Do not overdesign it.

---

## 6. Ownership boundaries

## 6.1 engine-cef

Primary owner for this slice.

Expected responsibilities:
- drawing the top strip in the runtime-host window
- input routing between chrome area and page area
- address-field editing behavior
- button hit handling
- mapping browser state into chrome state

## 6.2 client

Keep client changes minimal unless needed.

Possible responsibilities:
- tiny launch/config support if chrome needs an explicit runtime-host mode flag or debug affordance
- docs if acceptance recipe changes

## 6.3 root

Root only needs:
- checkpoint/update docs if the slice lands cleanly

---

## 7. State needed for the slice

The chrome needs a small amount of browser-facing state.

At minimum:
- current URL string
- canGoBack
- canGoForward
- isLoading
- last_error or equivalent failure signal if available

For the address field itself, also need local UI state:
- current edit buffer
- whether address field is focused
- cursor position
- maybe selection state later

### Important distinction
Separate:
- browser current URL
nfrom:
- address field edit buffer

Otherwise typing into the field while the page updates will be annoying.

---

## 8. Input / focus policy

This is the most important part of the slice after layout.

## 8.1 Hit routing

The window needs a clear rule:
- clicks in the chrome strip go to chrome
- clicks below the strip go to the page

No ambiguity.

## 8.2 Address field focus

When the address field is focused:
- text input goes to the address field
- editing/navigation keys relevant to the field should stay in the field
- page should not also receive those keystrokes

When the page is focused:
- input goes to the page as normal

## 8.3 Focus transfer

Need simple rules for:
- clicking address field -> focus address field
- clicking page -> focus page
- Enter in focused address field -> navigate, then focus policy should be explicit

Suggested first-pass rule:
- Enter navigates
- page regains focus after navigation starts

## 8.4 Avoid overbuilding selection behavior

For the first slice, basic address editing is enough.

If text selection inside the address field becomes annoying, improve it later, but do not block the whole slice on perfect field UX.

---

## 9. Navigation policy for typed input

Need one simple normalization rule.

Suggested short-term behavior:
- if the user types a full URL with scheme, use it
- if they type a bare hostname like `google.com`, normalize to `https://google.com`
- if input is empty, do nothing

A search-from-address-bar mode is probably out of scope for this first slice unless it is almost free.

---

## 10. Implementation phases

## Phase A — Chrome layout scaffold

### Goal
Reserve the top strip and render visible controls without wiring everything yet.

### Likely work
- define chrome strip constants
- reserve browser content rect below the strip
- draw buttons and address field shell
- keep branding modest but visible

### Acceptance
- strip renders reliably
- page content renders in the correct remaining region
- no geometry regression

---

## Phase B — Browser-state reflection

### Goal
Reflect live browser state into the strip.

### Likely work
- current URL updates into field display when not actively editing
- back/forward enabled state reflects actual browser state
- loading/error state becomes visible enough to interpret

### Acceptance
- navigation state shown in strip matches live page state
- field display updates coherently

---

## Phase C — Navigation actions

### Goal
Make the strip useful.

### Likely work
- back click
- forward click
- reload click
- address Enter/go navigation
- URL normalization for simple hostnames

### Acceptance
- user can navigate entirely from inside BRIDGE
- no command-line relaunch needed for common page changes

---

## Phase D — Focus / input cleanup

### Goal
Make the strip not feel fragile.

### Likely work
- address field focus rules
- click routing between strip and page
- keyboard ownership while editing field text
- page regains normal input behavior when chrome is not focused

### Acceptance
- no obvious key leakage between chrome and page
- address typing works predictably
- page interaction still feels normal

---

## Phase E — Short polish pass

### Goal
Remove the most obvious rough edges before calling the slice done.

### Likely work
- spacing/legibility cleanup
- better disabled-state rendering
- modest status polish
- one or two quality-of-life fixes found during manual use

### Acceptance
- slice feels intentionally designed, not just barely wired

---

## 11. Acceptance recipe

The slice should not be called done until it passes a real manual run in the official path.

### Command
Use the official runtime-host path, e.g.:

```bash
./build/cef-hybrid-real/browser --renderer=cef-runtime-host https://google.com
```

### Manual acceptance checklist

#### Launch / layout
- browser opens cleanly
- chrome strip appears correctly
- page content is not geometrically broken

#### Address field
- current URL is visible
- click address field
- type a new URL
- press Enter or click Go
- navigation occurs

#### Navigation controls
- back works
- forward works
- reload works
- enabled/disabled state feels honest

#### Focus / typing
- typing in the address field does not leak to page input
- clicking back into the page restores page interaction
- no obvious stuck-focus bug

#### Site sanity
At least test on:
- Google
- GitHub
- one additional modern site

---

## 12. Risks

### Risk 1 — Geometry regressions
The strip changes the view rect, so it can reawaken layout/sizing bugs if done carelessly.

**Mitigation:**
- keep geometry rules explicit
- validate startup and resize behavior early
- avoid mixing unrelated runtime-host changes into this slice

### Risk 2 — Input leakage
Chrome and page input routing can interfere with each other.

**Mitigation:**
- keep focus ownership explicit
- implement one simple address-field state model first

### Risk 3 — Overbuilding
It is easy to drift from minimal chrome into “full browser UI project.”

**Mitigation:**
- stop at back/forward/reload/address/go/status
- push tabs/history/search UX out of scope

---

## 13. What success looks like

Success for this slice is not:
- “BRIDGE now has final browser chrome”

Success is:
- the official runtime-host path now has a believable small browser shell
- navigation can happen from inside the app
- the window feels much less like a proof host and much more like a browser someone could keep open

That is enough to materially improve friend-alpha readiness.

---

## 14. Recommended next action after this doc

Start with:

- **Phase A — chrome layout scaffold**

and keep it very honest:
- no giant feature grab
- no old top-strip retry blob
- no premature menu system

Just get the strip in cleanly with the right geometry and state boundaries first.
