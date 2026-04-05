# Friend alpha readiness plan

_Date: 2026-04-05_

This document turns the earlier strategy notes into a more execution-oriented plan for getting BRIDGE from:

- impressive prototype

to:

- something a few software-engineer friends might actually use for part of a day and give meaningful feedback on.

It is intentionally opinionated and short-horizon.

---

## 1. Goal

Ship a small friend-alpha build of BRIDGE that:

- launches cleanly
- can browse a meaningful subset of real sites
- feels like a browser rather than just a rendered web surface
- is stable enough that a technically tolerant friend might keep it open for hours instead of minutes
- produces useful feedback instead of only “cool demo” reactions

---

## 2. Non-goals for friend alpha

Do **not** block friend alpha on these:

- tabs
- sync
- extension/addon system
- polished settings UI
- auto-update
- cross-platform installers
- full native menu/chrome parity
- perfect site compatibility
- perfect performance

Those are important later, but they are not the current gate.

---

## 3. Readiness bars

### Bar A — Demo-ready

This is effectively already true.

Criteria:
- official runtime-host browser launches
- real sites paint
- basic interaction works on at least some real sites
- branding/identity is present enough that it feels like BRIDGE

### Bar B — Friend alpha

This is the target.

Criteria:
- a friend can launch BRIDGE without hand-holding
- a friend can navigate between pages from inside the browser
- sessions/profile state survive restart in an intentional way
- obvious interaction basics do not feel broken
- real-site testing shows a small but credible set of everyday paths work
- distribution bundle is intentional and repeatable

### Bar C — Keep-using-it beta-ish

Not the current target.

Would likely require:
- multi-window or tabs story
- download story
- richer settings/profile management
- stronger permissions handling
- more polished packaging/update UX

---

## 4. Acceptance criteria for the first friend-alpha drop

A first friend-alpha drop should meet **all** of these.

### 4.1 Browser basics

In the official runtime-host path:
- address bar exists
- back works
- forward works
- reload works
- Enter/go navigation works
- current URL is visible
- basic loading/error state is visible enough to understand what is happening

### 4.2 Persistence

There is an intentional profile mode for normal use:
- cookies persist across restart
- local storage/session-related behavior is stable enough for repeated use
- logged-in state is not lost every run unless explicitly using a temporary profile mode

### 4.3 Basic comfort

At minimum:
- copy works
- paste works
- text entry feels stable
- keyboard focus is not obviously broken
- common shortcuts used in forms do not feel fragile

### 4.4 Windowing / external handoff policy

There is a defined behavior for at least one of these classes:
- popup/new window requests
- target=_blank links
- OAuth/login popups
- open externally escape hatch

Friend alpha does not require a perfect multi-window system, but it does require a non-confusing policy.

### 4.5 Real-site pass list

At least a small pass list should feel sane, for example:
- Google search flow
- GitHub browsing flow
- one docs site
- one modern app-ish site
- one login-ish flow

“Feels sane” means:
- launches correctly
- paints correctly
- no immediate hang
- navigation/input are good enough to continue

### 4.6 Packaging / launch

A friend-alpha build must be distributable through a repeatable packaging path:
- versioned bundle
- documented contents
- known launch command or launcher entrypoint
- known place for logs/profile/session data

---

## 5. Ranked next slices

These are ranked by near-term ROI.

### Slice 1 — Minimal official runtime-host chrome

#### Scope
Add the minimum browser controls to the official runtime-host path:
- address bar
- back
- forward
- reload
- go action
- maybe stop if it is cheap

#### Why it matters
This is the single biggest shift from “prototype” to “usable browser.”

#### Acceptance
- user can navigate entirely from inside the app
- no command-line relaunch needed for common navigation
- controls are visibly part of BRIDGE, not a throwaway dev affordance

#### Suggested size
A few small commits, not a giant chrome architecture detour.

---

### Slice 2 — Persistent profile story

#### Scope
Define and implement the short-term profile model.

At minimum answer:
- where profile data lives
- whether runtime-host uses a persistent default profile
- whether there is also a temporary/dev profile mode
- how profile selection works in local/dev usage

#### Why it matters
Without persistence, friend-alpha feedback quality is dramatically worse.

#### Acceptance
- restart preserves cookies/storage in persistent mode
- temporary mode is clearly separate if it exists
- profile location is documented

---

### Slice 3 — Clipboard / basic interaction comfort

#### Scope
Focus on the boring essentials:
- copy
- paste
- maybe cut/select-all if cheap
- text focus sanity
- obvious keyboard annoyances

#### Why it matters
This is disproportionately important for “would someone actually keep using this?”

#### Acceptance
- copy/paste work in common text-field flows
- no obviously broken text-entry/focus path in simple real-site tests

---

### Slice 4 — Launcher / workbench v1

#### Scope
Build a small developer-facing launcher/workbench.

Phase-1 features:
- start browser
- stop latest browser session
- restart
- open latest logs/session dir
- launch URL presets
- debug toggle presets
- simple status/telemetry surface later if useful

#### Why it matters
This accelerates both internal testing and future alpha distribution work.

#### Acceptance
- it meaningfully reduces command-line friction
- it can launch the official runtime-host path intentionally
- it can expose useful session/log locations

---

### Slice 5 — Friend-alpha bundle/release pipeline

#### Scope
Create the first intentional distribution bundle.

Short-term preferred output:
- Linux x64 tarball bundle

Bundle likely includes:
- launcher entrypoint
- browser executable(s)
- runtime assets
- CEF resources/locales/libs
- docs/readme for launch/profile/logs

#### Why it matters
This is the point where “send to a friend” becomes real rather than informal file copying.

#### Acceptance
- bundle can be assembled repeatably
- bundle contents are documented
- a friend can unpack and launch without repo archaeology

---

## 6. Supporting stability pass

This should run in parallel with the slices above, but should stay focused.

### Target real-site matrix
Use a small explicit matrix, for example:
- Google
- GitHub
- one docs site
- one app-like site
- one login-related flow

### Focus areas
- launch correctness
- first paint correctness
- resize/move sanity
- input sanity
- navigation sanity
- obvious hangs/stalls

### Rule
Do not let this become an endless generic QA bucket.

Use it to support alpha readiness, not to avoid shipping.

---

## 7. Recommended implementation order

Opinionated recommended order:

### Phase 1
**Minimal runtime-host chrome**

Reason:
- highest user-visible ROI
- immediately improves every test session

### Phase 2
**Persistent profile decision + implementation**

Reason:
- unlocks meaningful longer-use testing

### Phase 3
**Clipboard/basic interaction comfort**

Reason:
- removes a bunch of fast-frustration moments

### Phase 4
**Launcher/workbench v1**

Reason:
- improves testing velocity
- creates a future launcher/install surface

### Phase 5
**Friend-alpha bundle/release pipeline**

Reason:
- makes actual sharing intentional and repeatable

### Phase 6
**Targeted friend-alpha real-site sweep**

Reason:
- final confidence pass before sending it out

---

## 8. Launcher / workbench plan

The launcher idea is strong, but scope discipline matters.

### Phase 1 — Developer workbench

Include:
- run BRIDGE
- stop current/latest BRIDGE session
- relaunch
- URL presets
- debug toggle presets
- open logs
- open latest session dir

Optional if cheap:
- session status
- first-frame seen indicator
- latest title/url

### Phase 2 — Alpha launcher

Extend toward:
- profile selection
- normal vs debug launch modes
- maybe bundle-aware launching
- maybe update/check version later

### Phase 3 — Installer-facing surface

Only later:
- install/update UX
- channel management
- richer diagnostics

### Recommendation
Do **not** try to make phase 1 also be the final installer architecture.

---

## 9. Deliverable plan

### Short term
Primary deliverable:
- `bridge-linux-x64.tar.gz`

Contents:
- versioned app bundle
- clear launcher entrypoint
- profile/log location notes
- maybe one short README for testers

### Medium term
Likely next step:
- launcher/workbench integrated with that bundle

### Long term
Platform-native distribution:
- Linux: AppImage and/or .deb
- macOS: signed app bundle / DMG
- Windows: MSI or equivalent installer

---

## 10. Suggested commit-sized roadmap

One plausible breakdown:

### Batch A — Runtime-host chrome
- add address bar UI
- add back/forward/reload controls
- wire go/Enter navigation
- expose basic load/error feedback

### Batch B — Profile mode
- document profile layout
- default persistent profile
- optional temporary profile mode
- verify persistence on restart

### Batch C — Interaction comfort
- clipboard plumbing
- keyboard/focus fixes
- small real-site interaction checks

### Batch D — Workbench v1
- launcher shell
- presets/toggles
- logs/session access

### Batch E — Alpha bundle
- release assembly script/process
- versioned tarball
- test README / launch notes

### Batch F — Final alpha sweep
- explicit site matrix pass
- bug triage
- go/no-go check

---

## 11. Go / no-go questions before sending to friends

Before sending out the first alpha, ask:

1. Can they navigate from inside the browser without command-line help?
2. Will their session persist across restarts in the normal mode?
3. Will basic text and clipboard flows annoy them immediately?
4. Is there a sane policy for popups/new windows/external handoff?
5. Can they unpack and launch the build without repo-specific tribal knowledge?
6. Do at least a few real sites feel good enough to continue using?

If the answer is “yes” to all six, it is probably time.

---

## 12. Current recommendation

Right now, the next best move is still:

1. **minimal runtime-host chrome**
2. **persistent profile story**
3. **clipboard/basic comfort**
4. **launcher/workbench v1**
5. **friend-alpha bundle**
6. **targeted real-site sweep**

That is the most practical path to a friend-alpha build that generates meaningful feedback instead of only admiration.
