# Runtime-host workbench v1 plan

_Date: 2026-04-05_

This document defines the next planning slice for BRIDGE after the current runtime-host browser improvements:

- branded official runtime-host browser chrome
- self-navigation inside the window
- persistent profile behavior
- visible profile context
- clipboard/basic edit-command comfort
- explicit popup/new-window policy

The goal of the workbench is to make BRIDGE easier to:
- launch repeatedly during development
- inspect while debugging
- hand to trusted alpha testers later without relying on ad hoc shell commands

---

## 1. Goal

Build a small **BRIDGE workbench** that acts as:
- the easiest way to launch the official runtime-host browser locally
- a control surface for common debug/test launch presets
- a visibility surface for session/log/profile locations
- the future seed of a friend-alpha launcher

Short version:

> Start as a dev/test workbench first. Let it earn its way into becoming the alpha launcher later.

---

## 2. Why this is next

The official runtime-host browser is now far enough along that the main friction is shifting from:
- “does the browser path basically work?”

to:
- “how fast can we repeatedly launch, test, inspect, and switch modes?”

A workbench helps with:
- faster dev loop
- easier smoke testing
- easier switching between default / guest / custom profile modes
- easier access to logs and session dirs
- eventual distribution ergonomics

It also gives BRIDGE a natural place for future instrumentation without stuffing too much into the browser chrome.

---

## 3. Product framing

### What it is
A small local app/window that helps launch and inspect BRIDGE runtime-host sessions.

### What it is not
Not yet:
- the final user-facing installer
- a full settings application
- a profile manager UI
- a package/update manager
- a window manager for multiple BRIDGE sessions

This is a **developer-facing control panel first**.

---

## 4. Primary use cases

### Use case A — Start a normal runtime-host session fast
User opens the workbench, types or selects a URL, and clicks **Run BRIDGE**.

### Use case B — Start a guest/throwaway session
User wants a quick smoke run without polluting the default persistent profile.

### Use case C — Relaunch with debug toggles
User wants to turn on extra logging or use a custom profile directory without remembering flags.

### Use case D — Inspect latest run
User wants one-click access to:
- latest session directory
- logs
- profile path
- maybe current status/title/URL later

### Use case E — Restart quickly during iterative testing
User wants a single obvious relaunch path without retyping commands.

---

## 5. Scope for v1

## In scope
- launch the official runtime-host browser
- URL input
- a few URL presets
- profile mode controls:
  - default
  - guest / temp
  - custom path (if cheap)
- launch/relaunch/stop latest session
- open latest session folder
- open logs / maybe open latest stderr log directly
- show the resolved profile root/mode before launch
- show very small factual status text

## Nice to have if cheap
- show latest page title
- show latest URL
- show first-frame-seen status
- show last launch command preview
- show current session path inline

## Explicitly out of scope
- package installer flow
- update engine
- account/settings sync
- multi-profile picker UX beyond basic controls
- full telemetry dashboards
- embedding the browser inside the workbench
- tabs / multi-window orchestration UI

---

## 6. UX recommendation

## Recommended shape
A very small desktop app/window, probably a single panel.

Suggested sections:

### A. Launch
- URL input field
- Run BRIDGE button
- Restart button
- Stop button

### B. Mode
- Profile mode toggle:
  - Default
  - Guest
  - Custom
- custom profile path field (only active when Custom selected)

### C. Presets
- Google
- GitHub
- popup smoke page
- last URL
- maybe one docs/login-ish site later

### D. Diagnostics
- latest session path
- latest profile root
- latest status
- open logs button
- open session dir button

### E. Optional later footer/status line
- last launch result
- first-frame seen
- latest title/url

### Visual principle
This should feel more like:
- compact workbench / control surface

than:
- giant general desktop shell

---

## 7. Repo ownership

## Primary repo
- **client**

Reason:
- it already owns top-level launch concepts
- it already owns session logging concepts
- it is the natural place for a local launcher/workbench executable

## Supporting repos
- **engine-cef** only if the workbench needs new runtime-host signals not already exposed
- **root** for docs/checkpoints and later packaging notes

---

## 8. Architecture recommendation

## Short-term architecture
A separate executable in `client`, something conceptually like:

- `bridge_workbench`

This executable should:
- launch the existing official browser path
- not replace the browser executable itself
- not embed CEF directly
- not fork into a second product architecture

That keeps the layering clean:
- workbench = launcher/control surface
- runtime-host browser = actual browser

## Why not embed immediately?
Because the problem we are solving right now is:
- launch/orchestration convenience
- status visibility
- profile/debug switching

not:
- a new browser architecture

---

## 9. Suggested implementation strategy

There are three realistic UI approaches.

### Option A — Tiny SDL app inside `client`
Pros:
- aligns with existing client tech familiarity
- no extra UI framework decision
- lives comfortably in current build system

Cons:
- more manual widget/layout work
- not ideal for native file/folder pickers unless kept minimal

### Option B — Tiny GTK app
Pros:
- natural fit on current Linux dev machine
- easier basic desktop controls/file chooser
- visually straightforward

Cons:
- another UI path in the repo
- more Linux-specific as a first implementation

### Option C — Very minimal terminal/TUI wrapper
Pros:
- fastest to build
- possibly enough for internal use

Cons:
- does not really become the seed of an alpha launcher very gracefully
- less aligned with eventual user-facing trajectory

## Recommendation
For now, favor:

### **Option A or B, whichever is cheaper in this repo next**

My planning recommendation:
- prefer a **small dedicated desktop workbench window** over a TUI
- but keep the UI extremely simple and utility-first

If implementation friction matters more than elegance, a tiny SDL control app in `client` is probably the cleanest repo story.

---

## 10. Process model

The workbench needs a clear relationship to the launched browser process.

## v1 process model
- one active launched session tracked at a time
- launch creates a new browser process
- stop sends a normal termination signal or otherwise closes the tracked process cleanly
- restart = stop current tracked process, then relaunch with current settings

### Important simplification
The workbench only needs to manage:
- the sessions it launched itself

It does **not** need to become a global BRIDGE session manager in v1.

That keeps the model sane.

---

## 11. Data/state the workbench should own

At minimum:
- current URL field value
- selected profile mode
- custom profile path (optional)
- last-launched URL
- last-launched session path
- last-resolved profile root
- current tracked child process/session info
- current status string

Optional later:
- latest title
- latest browser URL from logs
- first-frame timestamp/status

---

## 12. Launch contract

The workbench should launch the same official path people already use manually.

Conceptually:

```bash
./build/cef-hybrid-real/browser --renderer=cef-runtime-host <url>
```

With profile variants such as:

```bash
./build/cef-hybrid-real/browser --renderer=cef-runtime-host --temp-profile <url>
./build/cef-hybrid-real/browser --renderer=cef-runtime-host --profile-dir=/path/to/profile <url>
```

### Principle
The workbench should assemble and run an honest command equivalent to what a human would run.

This is useful for:
- transparency
- debugging
- later documentation

---

## 13. v1 feature slices

## Slice A — Workbench skeleton

### Scope
- create workbench executable
- render a minimal window/panel
- URL input
- Run button

### Acceptance
- easiest local path to launching BRIDGE becomes the workbench

---

## Slice B — Session controls

### Scope
- track the last-launched browser process/session
- Stop button
- Restart button
- show latest session path

### Acceptance
- local testing loop is noticeably faster than manual relaunching

---

## Slice C — Profile controls

### Scope
- Default / Guest toggle
- optional Custom profile path field
- display resolved profile root before launch

### Acceptance
- user can intentionally pick persistent vs throwaway behavior from the workbench

---

## Slice D — Presets and convenience

### Scope
- preset buttons:
  - Google
  - GitHub
  - popup smoke
  - maybe last URL
- open latest session dir
- open logs

### Acceptance
- common smoke actions become one-click

---

## Slice E — Lightweight status surface

### Scope
- current status line
- maybe latest stderr tail or first-frame status
- maybe latest title/url if easy to extract

### Acceptance
- workbench provides enough visibility that users rarely need to go hunting manually

---

## 14. Acceptance bar for workbench v1

Workbench v1 is successful when:

1. launching BRIDGE from the workbench is easier than doing it manually
2. default vs guest profile mode is easy and obvious
3. latest session/log location is easy to access
4. restarting during manual debugging is fast and boring
5. the workbench does not introduce a second confusing browser architecture

---

## 15. Risks

### Risk 1 — Scope bloat
The workbench could accidentally become:
- installer
- settings app
- session manager
- telemetry dashboard

**Mitigation:**
Keep v1 ruthlessly focused on launch + inspect + relaunch.

### Risk 2 — Too much UI engineering
If the UI framework choice turns into a project, progress stalls.

**Mitigation:**
Choose the cheapest workable UI path and optimize for usefulness over polish.

### Risk 3 — Fighting process management
Trying to manage every possible BRIDGE/browser process would get messy fast.

**Mitigation:**
Only track/manage the sessions launched by the workbench itself.

### Risk 4 — Duplication of browser chrome concerns
The workbench could drift into becoming “another browser shell.”

**Mitigation:**
Keep actual browsing inside BRIDGE; keep the workbench as control surface only.

---

## 16. Recommendation on immediate next move

If we implement this next, the cleanest order is:

1. **Slice A — workbench skeleton**
2. **Slice B — session controls**
3. **Slice C — profile controls**
4. **Slice D — presets and convenience**
5. **Slice E — lightweight status surface**

That order gets value on-screen quickly without overcommitting.

---

## 17. Suggested follow-up doc after this one

If we decide to build it, the next useful planning step would be a smaller implementation note such as:

- `docs/runtime-host-workbench-slice-a.md`

That should specify:
- chosen UI approach
- exact v1 layout
- command/process model
- file/repo touch points
- acceptance steps for the first runnable workbench skeleton
