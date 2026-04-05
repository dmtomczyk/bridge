# Friend alpha implementation queue

_Date: 2026-04-05_

This document turns the friend-alpha readiness plan into a concrete ranked queue.

It is intentionally practical:
- what to do now
- what to do soon
- what to postpone
- which repo should own each slice
- how to split the work into believable commit-sized chunks

Use this as the working queue between strategy and implementation.

---

## 1. Priority buckets

### Do now
These are the highest-ROI slices for getting BRIDGE from demo-ready to friend-alpha-ready.

1. Minimal official runtime-host chrome
2. Persistent profile story
3. Clipboard / basic interaction comfort
4. Launcher / workbench v1
5. Friend-alpha bundle / release pipeline

### Do soon
These support friend alpha strongly, but should not block the first highest-ROI path from moving.

6. Popup / new-window / external handoff policy
7. Targeted real-site polish sweep
8. Runtime-host observability / telemetry surfaces
9. Friend-tester docs / issue reporting loop

### Later
These are valuable, but should not steal attention before the friend-alpha bar.

10. Tabs / richer multi-window story
11. Download manager / richer downloads UX
12. Settings UI / profile manager
13. Auto-update
14. Platform-native installers beyond the first primary OS

---

## 2. Ranked queue with ownership

## Queue 1 — Minimal official runtime-host chrome

### Why this is first
This is the single biggest “feels like a browser now” shift.

### Primary repo ownership
- **engine-cef** for runtime-host window/UI behavior
- **client** only if launch/config/runtime plumbing needs tiny support
- **root** docs only for checkpoint notes

### Near-term scope
- address bar
- back
- forward
- reload
- go/Enter
- visible current URL
- minimal loading/error indication

### What to avoid
- giant native GTK menu architecture
- overdesigned browser chrome
- tabs
- settings detour

### Suggested commit-sized chunks

#### 1A. Chrome layout scaffold
- reserve a top strip intentionally
- draw visible controls and address field shell
- do not wire full behavior yet

#### 1B. Navigation actions
- wire back/forward/reload/go
- keyboard Enter in address bar triggers navigation

#### 1C. URL/load state reflection
- reflect current URL into the address field
- reflect minimal loading/error state visually

#### 1D. Interaction cleanup
- focus rules between address field and page
- clicks/keyboard do not leak incorrectly

### Acceptance bar
- launch to a page
- type a new URL inside BRIDGE
- hit Enter/go
- navigate back/forward/reload
- clearly understand what page is loaded

---

## Queue 2 — Persistent profile story

### Why this is second
Without persistence, “use it for a day” testing is much weaker.

### Primary repo ownership
- **engine-cef** if profile/cache path behavior lives in runtime-host/bootstrap
- **client** if launcher/runtime flags select profile mode
- **root** docs for packaging/use notes

### Near-term scope
- define persistent default profile
- define optional temporary/dev profile mode
- document actual profile location
- keep behavior explicit and reproducible

### Suggested commit-sized chunks

#### 2A. Profile policy note
- document intended short-term profile model
- persistent default vs temporary mode

#### 2B. Runtime-host profile path plumbing
- set stable per-user persistent profile location
- ensure restarts reuse it intentionally

#### 2C. Temporary mode option
- add optional throwaway mode for debugging/smoke sessions

#### 2D. Validation + docs
- verify cookies/local storage survive restart in persistent mode
- document how to clear/reset profile manually

### Acceptance bar
- log into something lightweight or set persistent site state
- close BRIDGE
- reopen BRIDGE
- state is still there in normal mode

---

## Queue 3 — Clipboard / basic interaction comfort

### Why this is third
This is where “impressive prototype” often loses people quickly.

### Primary repo ownership
- **engine-cef** for runtime-host clipboard/input bridging
- **client** only if shell-level shortcut handling is needed

### Near-term scope
- copy
- paste
- maybe cut/select-all if cheap
- obvious keyboard-focus cleanup

### Suggested commit-sized chunks

#### 3A. Clipboard baseline
- copy selected text
- paste into text fields

#### 3B. Common editing shortcuts
- select-all / cut if straightforward
- verify no weird interference with page input

#### 3C. Focus polish
- make sure common field-entry scenarios do not lose focus unexpectedly

#### 3D. Real-site spot checks
- test on Google / GitHub / one docs site

### Acceptance bar
- text copy/paste works in common text-field flows
- no immediately embarrassing text-entry behavior in simple manual tests

---

## Queue 4 — Launcher / workbench v1

### Why this is fourth
This helps both internal development and eventual friend-alpha distribution.

### Primary repo ownership
- likely **client** if it lives close to current launch/session concepts
- could become its own small app later, but not required now
- **root** docs for usage/release notes

### Near-term scope
- start browser
- stop latest browser session
- restart
- open latest logs/session dir
- launch preset URLs
- toggle debug modes

### Suggested commit-sized chunks

#### 4A. Launcher skeleton
- minimal UI or TUI/desktop control surface
- launch the official runtime-host path

#### 4B. Session controls
- stop/restart latest locally launched BRIDGE browser session
- open latest session directory

#### 4C. Launch presets
- URL presets
- debug/perf/logging toggles
- maybe persistent vs temporary profile toggle

#### 4D. Telemetry panel (optional if cheap)
- current status
- first-frame seen
- latest title/URL
- maybe latest stderr tail

### Acceptance bar
- the launcher meaningfully reduces command-line friction
- it becomes the easiest way for you to start/stop debug runs

---

## Queue 5 — Friend-alpha bundle / release pipeline

### Why this is fifth
This is the point where sharing becomes intentional instead of ad hoc.

### Primary repo ownership
- **root** for packaging/release assembly process
- **client** and **engine-cef** only as needed for runtime contents or install-path assumptions

### Near-term scope
- versioned Linux x64 bundle
- reproducible assembly process
- clear launch entrypoint
- clear logs/profile/session locations

### Suggested commit-sized chunks

#### 5A. Bundle layout spec
- define output tree
- define required binaries/resources/assets

#### 5B. Assembly script/process
- collect executables, assets, CEF resources, locales, runtime libs
- produce versioned output directory

#### 5C. Tester README
- how to launch
- where logs are
- where profile is
- how to reset state

#### 5D. Tarball packaging
- produce `bridge-linux-x64.tar.gz`
- test on a clean-ish machine or user account if possible

### Acceptance bar
- you can produce a bundle repeatably
- a technically tolerant friend can unpack it and run it without repo archaeology

---

## Queue 6 — Popup / new-window / external handoff policy

### Why this is soon-but-not-first
A lot of real sites feel broken without a policy, but you do not need a full window manager before the first friend alpha.

### Primary repo ownership
- **engine-cef**
- **client** only if there is shell-side routing/launch behavior

### Near-term scope
Pick one explicit short-term policy, for example:
- open externally
- open a second BRIDGE window
- block with explicit message/log

Just do not leave it ambiguous.

### Suggested commit-sized chunks

#### 6A. Policy doc
- define what BRIDGE does for popups and `target=_blank`

#### 6B. Basic implementation
- implement the simplest honest behavior

#### 6C. Login/auth verification
- make sure common popup-ish auth flows are not hopelessly confusing

### Acceptance bar
- popup/new-window behavior is understandable, even if minimal

---

## Queue 7 — Targeted real-site polish sweep

### Why this is soon
This validates the friend-alpha path, but should not be allowed to expand infinitely.

### Primary repo ownership
- shared across **client**, **engine-cef**, and **root docs** depending on what breaks

### Target matrix
- Google
- GitHub
- one docs site
- one app-like site
- one login-ish flow

### Suggested commit-sized chunks

#### 7A. Matrix doc/checklist
- explicit target sites and flows

#### 7B. Small bug batches
- fix only what blocks those concrete flows
- avoid giant speculative cleanup detours

#### 7C. Final checkpoint note
- what passed
- what still annoys
- what is acceptable for friend alpha

### Acceptance bar
- the target matrix feels sane enough to continue using, not just to launch once

---

## Queue 8 — Runtime-host observability / telemetry

### Why this is useful
Good leverage for both launcher/workbench and debugging, but not first-order friend-alpha product surface.

### Primary repo ownership
- **client** for session/log/status visibility
- **engine-cef** for runtime-host signals if additional seams are needed

### Near-term scope
- session status
- first-frame timestamps
- latest page URL/title
- maybe simple counters or state summary

### Suggested commit-sized chunks

#### 8A. Expose current useful signals
- reuse existing status/logging where possible

#### 8B. Surface them in launcher/workbench
- simple and factual, not overengineered

### Acceptance bar
- debugging a browser run becomes easier and faster

---

## Queue 9 — Friend-tester docs / feedback loop

### Why this matters
Once friends actually use it, you want useful feedback instead of vague impressions.

### Primary repo ownership
- **root** docs

### Near-term scope
- one short tester note
- what to try
- how to report bugs
- where logs live
- what kind of feedback is most useful

### Suggested commit-sized chunks

#### 9A. Tester quickstart
- unpack / launch / reset profile / find logs

#### 9B. Feedback template
- site
- action
- expected behavior
- actual behavior
- log/session attachment note

### Acceptance bar
- friends can give reproducible feedback with minimal back-and-forth

---

## 3. Repo-oriented view

## client

Likely owns:
- launcher/workbench v1
- any shell-side launch/profile toggles
- session/log surfacing
- packaging helpers if the launcher lives here
- some docs tied to actual launch/runtime usage

## engine-cef

Likely owns:
- official runtime-host chrome
- profile/cache/runtime-host persistence behavior
- clipboard/input comfort fixes in the GTK/CEF runtime host
- popup/new-window behavior in the short term
- runtime-host sizing/input/stability polish

## root

Likely owns:
- readiness docs
- packaging/release assembly process
- tester docs
- submodule checkpoints tying the release story together

---

## 4. Recommended working order

If choosing the most practical order right now:

### Immediate next two
1. Queue 1 — Minimal official runtime-host chrome
2. Queue 2 — Persistent profile story

### Next cluster after that
3. Queue 3 — Clipboard/basic comfort
4. Queue 4 — Launcher/workbench v1
5. Queue 5 — Friend-alpha bundle

### Supporting passes around them
- Queue 6 — popup/new-window policy
- Queue 7 — targeted real-site polish
- Queue 8 — observability
- Queue 9 — tester docs

---

## 5. If time/energy is limited

If only a few slices can be done before sharing with friends, the minimum strong combo is:

1. runtime-host chrome
2. persistent profile
3. clipboard basic comfort
4. one intentional bundle

That is the smallest set that most directly upgrades BRIDGE from:
- cool demo

to:
- credible friend alpha

---

## 6. Next planning move after this queue

The next useful follow-up would be to take **Queue 1** and split it one level further into a focused implementation note, for example:

- `docs/runtime-host-chrome-slice-plan.md`

That doc could specify:
- the exact UI elements
- ownership boundaries
- click/focus/input policy
- acceptance recipe
- commit-sized phases for the first chrome pass
