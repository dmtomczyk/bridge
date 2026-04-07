# Runtime-host tabs plan

_Date: 2026-04-05_

This document defines the MVP tabs plan for the official BRIDGE browser path:

- `browser --renderer=cef-runtime-host`

This plan intentionally targets a **limited, shippable first tabs feature**, not a full desktop-browser tab system.

---

## 1. Goal

Add **MVP tabs** to BRIDGE so the official runtime-host browser can support:

- one window
- multiple tabs
- a simple tab strip
- new tab button
- close tab button
- click tab to switch
- active tab state reflected in the current chrome
- popup/new-window with real URL opens a new tab

And explicitly **not** support, yet:

- drag reorder
- tab groups
- pinned tabs
- session restore
- detached windows
- full keyboard shortcut parity
- tab search
- reopen closed tab
- per-tab context menus

The point is to make BRIDGE feel like a normal modern browser in the most important way first.

---

## 2. Why do this now

Tabs are no longer a nice-to-have for browser credibility.

Recent work already gave BRIDGE:
- real runtime-host browser chrome
- in-window navigation
- URL editing
- profile persistence
- clipboard comfort
- popup/new-window policy
- upload/download support
- permission policy
- workbench support

The next big step from “credible prototype” to “normal-feeling browser” is:

- keeping more than one page alive in one window
- making target/new-window behavior feel natural

That is exactly what MVP tabs unlock.

---

## 3. Product definition for MVP tabs

### In scope
- one BRIDGE window
- multiple live tabs
- click tab to activate
- close active or inactive tab
- open new blank/default tab
- popup/new-window with real URL opens a new tab
- active tab controls the URL bar / loading state / back-forward state / page surface

### Out of scope
- drag to reorder
- pinned tabs
- groups
- tab strip overflow polish
- tear-off windows
- restore previous tab sets
- tab history UI
- favicon support if costly
- complex keyboard shortcuts beyond maybe 1–2 basics

---

## 4. Architecture direction

## Decision
Use **multiple live browser instances** in one runtime-host window.

### Why
A browser-feeling tab system wants:
- state preserved when switching tabs
- forms/pages not constantly recreated
- popup/new-window flows that feel immediate

So the recommended model is:
- each tab owns its own live CEF browser instance
- only one tab is active/visible/input-focused at a time
- inactive tabs stay alive in the background

### Explicit non-goal
Do **not** implement tabs by constantly destroying/recreating pages on switch.
That would feel fake and fragile.

---

## 5. Core model

Add a runtime-host tab model, conceptually something like:

```text
Tab
- id
- browser instance
- title
- url
- is_loading
- can_go_back
- can_go_forward
- maybe last load error

RuntimeHostWindow
- tabs[]
- active_tab_id / active_tab_index
```

### Important rule
All existing chrome state must become **active-tab derived state**.

That means the BRIDGE URL bar, title, loading indicator, back/forward state, popup behavior, etc. must bind to the currently active tab, not to one global browser singleton.

---

## 6. Major implementation areas

## A. Tab model and lifecycle

Need the basics for:
- create tab
- close tab
- switch tab
- active tab lookup
- safe cleanup of closed tab browser instances

Questions this slice must answer:
- what is the default new-tab URL?
- what happens when last tab closes?
- what happens if active tab closes?
- what happens if a background tab finishes loading?

### Recommended short-term answers
- new tab URL: `https://www.google.com/` or a simple internal new-tab page later
- closing last tab closes the window
- closing active tab activates nearest neighbor tab
- background tab updates its stored title/url/loading state but does not steal focus

---

## B. Multi-browser runtime-host management

Today the runtime-host path is effectively shaped around one browser.

Tabs require changing that to:
- many browser instances
- one active view rect
- one active input target
- per-tab state updates

### This is the biggest architectural change
Likely affected areas:
- `engine-cef/src/cef_browser_handler.*`
- `engine-cef/src/cef_osr_host_gtk.*`
- possibly supporting runtime-host/container types

### Principle
Only the active tab should:
- receive page input
- define the drawn page surface
- drive the current chrome controls

Inactive tabs should:
- keep their own browser state alive
- not steal focus
- not render into the active view surface

---

## C. Tab strip UI

Need a simple, intentionally modest strip.

### MVP strip contents
For each tab:
- title text (clipped)
- active/inactive styling
- close button

Global strip controls:
- new tab button

### Non-goals for first pass
- reordering
- drag behavior
- tab previews
- favicons if costly
- overflow menus if avoidable

### First-pass layout recommendation
- fixed-height tab strip above the current navigation/address chrome
- active tab clearly highlighted
- max visible tab width clamped, clip title text aggressively

This can be ugly-but-honest first.

---

## D. Active-tab chrome binding

When active tab changes, the browser chrome must update immediately:
- URL field
- loading indicator
- title
- back/forward enabled state
- maybe profile label remains global (not per-tab)

### Rule
The current browser chrome should not become “shared stale state.”
It must always reflect the selected tab.

---

## E. Input / focus routing

Need clear routing among:
- tab strip
- address/navigation chrome
- active page surface

### Required behaviors
- clicking a tab activates it
- clicking a close button closes that tab
- clicking page focuses active tab’s page
- typing in URL bar affects active tab
- switching tabs should not break page focus permanently

This area needs care because it is a likely regression source.

---

## F. Popup/new-window integration

This is one of the main benefits of tabs.

### New short-term policy after tabs
For popup/new-window requests with a real URL:
- open a **new tab**

For blank/junk popup targets:
- keep blocking them

This will feel much more normal than the current “load into current window” fallback.

---

## 7. Suggested MVP scope boundary

The cleanest MVP tabs feature is:

### Must have
- multiple live tabs
- simple tab strip
- new tab button
- close tab button
- click to switch
- popup/new-window with real URL opens new tab
- current chrome reflects active tab

### Nice if cheap
- middle-click close later
- Ctrl+T and Ctrl+W maybe later in same phase if trivial

### Do not include in MVP
- tab drag reorder
- tab persistence/session restore
- detached windows
- bookmark/history integration
- advanced keyboard navigation

---

## 8. Recommended implementation phases

## Phase 1 — Internal tab model, no visible strip yet

### Goal
Break the “single browser only” assumption internally.

### Work
- create tab data structure
- support more than one browser instance internally
- define active tab switching in code
- bind current chrome state to active tab

### Acceptance
- engine/runtime-host can conceptually hold multiple tabs and switch active browser without visible tab UI yet

### Why first
This separates the architecture work from the UI work and keeps regressions easier to reason about.

---

## Phase 2 — Simple visible tab strip

### Goal
Expose the tab model in the window UI.

### Status
Landed on 2026-04-06 in the runtime-host GTK/OSR path and verified on the official browser lane after rebuilding `browser/build/cef-hybrid-real`.

### Landed work
- draw tab strip
- active/inactive tab visuals
- click to switch tabs
- new tab button
- close button
- double-click suppression in the tab strip hit path

### Notes
- The first successful smoke happened in standalone `engine_cef_proof`, but the official `browser --renderer=cef-runtime-host` path did not show the strip until the client-side `cef-hybrid-real` build was rebuilt. Future validation should always confirm the client launcher lane, not just the standalone proof binary.
- A follow-up hardening pass moved host ownership to a neighbor before closing the active tab and clears the bound OSR browser when the closing browser is going away. This was added after a crash report during close churn / middle-mouse use with many tabs open.
- A later close crash was traced with `gdb` to `CefBrowserHandler::CloseAllBrowsers(bool)`, which had been iterating `browser_list_` while close callbacks could mutate it. The fix was to close from a stable snapshot instead of the live container.
- BRIDGE Home started as an engine-generated data URL but was moved to a browser-owned file-backed asset (`browser/assets/bridge-home.html`) and passed into the runtime-host launch config as `home_url`.
- Special-page handling now uses explicit page metadata (`CefTabPageKind`) instead of raw URL-string equality, and page kind is updated dynamically on main-frame address change so closed-tab recovery does not permanently misclassify tabs that were born as home tabs and later navigated elsewhere.

### Acceptance
- user can create, switch, and close tabs from the strip

---

## Phase 3 — Popup/new-window to new-tab policy

### Goal
Make `_blank` / popup behavior feel natural.

### Status
Initial policy hardening landed on 2026-04-06.

### Landed work
- meaningful popup/new-window targets prefer opening as internal tabs
- blank/junk/javascript popup targets remain blocked
- true new-surface dispositions no longer quietly collapse into the current tab as the first fallback when tab creation fails
- external handoff remains a fallback when internal tab creation fails

### Remaining validation
- more real-site/manual sweeps for `_blank`, auth/login, and other popup-heavy flows
- decide whether middle-click-on-link/background-tab intent needs a dedicated follow-up beyond the current disposition handling

### Acceptance
- popup/new-window with real target URL opens a new tab
- blank/junk popup still blocked

---

## Phase 4 — Focus and polish pass

### Goal
Make tabs feel stable instead of merely functional.

### Work
- input/focus cleanup
- close active tab behavior
- neighbor tab activation
- title clipping polish
- maybe 1–2 keyboard shortcuts if cheap

### Acceptance
- tab interactions stop feeling fragile

---

## 9. Acceptance bar for MVP tabs

MVP tabs are successful when all of these are true:

1. user can open multiple tabs in one BRIDGE window
2. switching tabs preserves each page’s state
3. active tab’s URL/title/loading/back-forward state reflect honestly in current chrome
4. user can close tabs reliably
5. popup/new-window with real URL opens a new tab
6. last-tab close behavior is sane
7. tabs do not introduce obvious instability in the current runtime-host path

---

## 10. Biggest risks

## Risk 1 — single-browser assumptions are everywhere
The current runtime-host stack likely assumes one browser more often than is obvious.

### Mitigation
Do Phase 1 first and audit single-browser assumptions before polishing UI.

## Risk 2 — input/focus regressions
Tabs touch page focus, chrome focus, and routing.

### Mitigation
Keep focus rules explicit and test switching repeatedly while editing/searching.

## Risk 3 — memory/resource use grows quickly
Multiple live tabs mean more live browser instances.

### Mitigation
Start with modest expectations and no background fancy features.

## Risk 4 — tabs sprawl into a huge browser project
Easy to drift into pinned tabs, drag reorder, restore, etc.

### Mitigation
Keep strict MVP boundary and defer all “nice browser” extras.

---

## 11. Repo ownership

## Primary
- `engine-cef`

Because the real tab complexity lives in:
- multiple CEF browser instances
- runtime-host rendering/input binding
- popup-to-tab behavior

## Secondary
- `root`
  - planning/checkpoint docs

## Maybe minimal `client`
Only if launch/config/test surfaces need support.

---

## 12. Honest effort estimate

Tabs are not a tiny next tweak.

Compared to recent slices:
- upload/download/permissions = small-medium
- workbench = medium
- tabs = large

This is probably the next **major feature phase**, not the next tiny polish pass.

That said, it is still worth doing because it materially changes how normal BRIDGE feels.

---

## 13. Recommended immediate next step

Do **not** start with the strip UI.

Start with:

### Phase 1 — internal tab model

Specifically:
- identify single-browser assumptions in runtime-host code
- define tab container/state objects
- make active browser binding explicit

Once that exists, the visible tab strip becomes much safer to add.

---

## 14. Suggested follow-up doc

If we proceed, the next practical planning note should be:

- `docs/runtime-host-tabs-phase-1.md`

That should identify:
- likely files to touch
- single-browser assumptions to break
- minimal container/state structures
- acceptance recipe for the first non-UI tabs milestone
