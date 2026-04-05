# Runtime-host workbench Slice A

_Date: 2026-04-05_

This document locks the first implementation slice for the BRIDGE runtime-host workbench.

It follows:
- `docs/runtime-host-workbench-plan.md`

and turns the first step into something directly buildable.

---

## 1. Chosen UI approach

For Slice A, choose:

# **Tiny SDL workbench inside `client`**

### Why this is the right choice now

Based on the current repo:
- `client` already has SDL wiring in `CMakeLists.txt`
- the team/repo already tolerates SDL as an app-shell dependency
- adding one more tiny SDL executable in `client` is cheaper than inventing another framework choice right now
- this keeps the workbench in the same repo layer as the launch/session concepts it needs to orchestrate

### Why not GTK for v1

GTK is already present in `engine-cef`, but mostly because the current Linux OSR host needs it.

Using GTK for the workbench would:
- add another UI style into `client`
- make the first workbench feel more Linux-specific than necessary
- create more cross-layer weirdness than we need for Slice A

### Why not TUI

A TUI would be fast, but it does not feel like the right seed for:
- later friend-alpha launcher behavior
- a compact desktop control surface

So the choice is:

> **SDL workbench in `client`, simple and utility-first.**

---

## 2. Slice A goal

Build the first runnable workbench skeleton that proves:
- BRIDGE can be launched from a small dedicated workbench window
- the official runtime-host path is the thing being launched
- the workbench is already more convenient than typing the command manually

This slice is **not** about full controls yet.

---

## 3. Slice A scope

## In scope
- add a new executable in `client`, conceptually:
  - `bridge_workbench`
- open a small SDL window
- draw a very simple static layout
- include a URL input field
- include a **Run BRIDGE** button
- launch:
  - `browser --renderer=cef-runtime-host <url>`
- show a small factual status line
- keep one in-memory “last launched URL” value

## Nice if cheap
- one preset button (e.g. Google)
- one preset button for `client/examples/popup-smoke.html` if easy

## Explicitly out of scope
- stop/restart
- profile mode controls
- custom profile path controls
- logs/session-dir buttons
- telemetry/status parsing
- first-frame visibility
- settings persistence
- native file pickers
- fancy widget behavior

This is only the first proof that the workbench should exist.

---

## 4. Acceptance bar

Slice A is successful when:

1. `bridge_workbench` builds and runs locally
2. it shows a small SDL window
3. the user can type or edit a URL
4. clicking **Run BRIDGE** launches the official runtime-host browser path
5. the launched browser actually opens to the requested URL
6. the workbench updates a small status line like:
   - `Ready`
   - `Launching...`
   - `Launched browser`
   - or a launch failure message

If those six are true, Slice A is worth keeping.

---

## 5. Recommended UI for Slice A

Keep it extremely simple.

### Window contents

#### Header
- BRIDGE Workbench
- small subtitle like:
  - `Launch the official runtime-host browser`

#### URL row
- label: `URL`
- text input field

#### Action row
- `Run BRIDGE`
- optional preset button if cheap, e.g. `Google`

#### Footer/status
- one status line
- maybe one line showing the exact launch target URL

### Visual style
- dark utility panel is fine
- use BRIDGE-ish colors if easy
- do not spend much time on polish yet

---

## 6. Command contract

The workbench must launch the exact official path conceptually equivalent to:

```bash
./build/cef-hybrid-real/browser --renderer=cef-runtime-host <url>
```

### Important rule
Do not invent a separate browser path for the workbench.

The workbench must drive the same official runtime-host lane we are already accepting against.

---

## 7. Process model for Slice A

## Minimal process model
- workbench launches the browser as a child process
- workbench does not yet try to deeply manage that child
- workbench only needs to know whether launch was attempted successfully

### For Slice A, enough is enough
It is okay if Slice A only does:
- launch child process
- remember PID or process handle if convenient
- report immediate success/failure of spawn

Full stop/restart lifecycle belongs in Slice B.

---

## 8. Repo touch points

## Primary repo
- `client`

## Likely file additions
Something like:
- `client/src/workbench/workbench_app.h`
- `client/src/workbench/workbench_app.cpp`
- `client/src/workbench_main.cpp`

Or a flatter equivalent if that is cheaper.

## Likely build changes
- add `bridge_workbench` executable in `client/CMakeLists.txt`
- link it with the same SDL-enabled client support that already exists in `client`

### Important implementation bias
Prefer the smallest file structure that stays readable.

Do not pre-architect a large workbench subsystem in Slice A.

---

## 9. Input model for Slice A

Keep the text-entry model intentionally small.

At minimum support:
- clicking/focusing the URL field
- typing characters
- backspace
- Enter as an alternate launch action if cheap
- basic cursor-at-end editing is enough for Slice A

### Deliberate simplification
It is okay if Slice A URL editing is simpler than the browser chrome URL field.

This is a launcher field, not a full editor.

---

## 10. Initial defaults

### Default URL
Suggested default:
- `https://www.google.com/`

### Window title
Suggested:
- `BRIDGE Workbench`

### Initial status
Suggested:
- `Ready`

---

## 11. Error handling

Slice A only needs basic honesty.

Examples:
- if browser executable path cannot be found:
  - show `Launch failed: browser binary not found`
- if child spawn fails:
  - show `Launch failed: <reason>`

Do not overbuild diagnostics yet.

---

## 12. Implementation order inside Slice A

### Step 1
Create `bridge_workbench` executable and SDL window.

### Step 2
Render static layout with URL field and Run button.

### Step 3
Add minimal text input handling for the URL field.

### Step 4
Wire child-process launch of the official runtime-host browser path.

### Step 5
Show small launch status feedback.

That is enough for the first checkpoint.

---

## 13. Risks

### Risk 1 — UI yak shave
Manual SDL widgets can sprawl.

**Mitigation:**
Use primitive rectangles/text/buttons only. Avoid building a general widget toolkit.

### Risk 2 — Path confusion
The workbench might accidentally launch a different browser path than the accepted official one.

**Mitigation:**
Use the same `browser --renderer=cef-runtime-host` path and document it explicitly.

### Risk 3 — Process-management rabbit hole
Trying to solve stop/restart/state tracking in Slice A would slow everything down.

**Mitigation:**
Keep Slice A to launch-only.

### Risk 4 — Too much polish too early
A launcher can easily become a design toy.

**Mitigation:**
Prefer functional, ugly, honest.

---

## 14. Suggested checkpoint message when Slice A lands

Something like:
- `Add SDL runtime-host workbench skeleton`

That would cleanly describe what was achieved without overselling it.

---

## 15. What comes immediately after Slice A

If Slice A works, next should be:

### Slice B — session controls
- track last launched process/session
- Stop button
- Restart button
- show latest session path

That is the point where the workbench starts materially accelerating the dev loop.
