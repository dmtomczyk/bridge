# Windows runtime-host milestone 1 — 2026-04-06

This document defines the first meaningful Windows target for BRIDGE runtime-host work.

The goal is **not** “CEF can launch on Windows somehow.”
The goal is:

> BRIDGE can build and run as a basic single-window browser on Windows using the same product semantics that now exist in the Linux runtime-host lane.

---

# 1. Why this milestone exists

Windows support is now a first-class product requirement.
Likely alpha users are on Windows, not Debian/Linux-only setups.

That means the project needs a concrete first Windows target that is:
- small enough to land in slices
- useful enough to prove the architecture is right
- scoped tightly enough to avoid trying to port the entire polished browser shell at once

---

# 2. Milestone 1 definition

## Milestone name
**Windows runtime-host bring-up — single-window usable browser**

## Success statement
A Windows build can launch BRIDGE in a native window, render pages through the CEF runtime-host path, and support the minimum navigation/browser behavior required to act like a basic browser shell.

---

# 3. Required acceptance criteria

## A. Build + launch
- [ ] Project configures on Windows without Linux/GTK/X11-only build failures
- [ ] Windows CEF runtime-host target builds successfully
- [ ] Built executable launches a native window on Windows
- [ ] The process stays alive and responsive after launch
- [ ] Closing the window exits cleanly without obvious crash behavior

## B. Basic browser rendering
- [ ] BRIDGE Home loads at startup when no initial URL is supplied
- [ ] External pages render in the runtime-host window
- [ ] OSR frame presentation is stable enough to use the browser interactively
- [ ] Resize handling works well enough that content updates after window resize

## C. Navigation baseline
- [ ] Typing a valid URL/host into the omnibox navigates correctly
- [ ] Typing natural-language input in the omnibox falls back to Google search
- [ ] Back works
- [ ] Forward works
- [ ] Reload works
- [ ] Address bar focus works well enough to enter/replace navigation text

## D. Product-semantics parity required even in milestone 1
These are shared product behaviors, not optional platform quirks:
- [ ] BRIDGE Home/startup semantics match the shared product behavior
- [ ] Omnibox URL normalization/search fallback behavior matches Linux runtime-host behavior
- [ ] Page-kind handling remains correct for special pages like BRIDGE Home

## E. Stability baseline
- [ ] Browser can navigate across multiple pages without immediate crash
- [ ] Close/quit path is stable for the single-window/single-tab case
- [ ] Runtime-host path does not depend on GTK/X11 presence

---

# 4. Explicit non-goals for milestone 1

These are valuable, but not required to call milestone 1 successful:
- [ ] full tab-strip parity
- [ ] popup/new-window → new-tab parity
- [ ] closed-tab recovery parity
- [ ] polished smooth scrolling
- [ ] native installer/distribution polish
- [ ] complete keyboard shortcut parity
- [ ] IME/high-DPI/native accessibility polish

Those belong in follow-up milestones once the Windows runtime-host foundation is real.

---

# 5. Milestone 2 preview

After milestone 1, the next milestone should be:

## Windows runtime-host milestone 2 — alpha-usable browser shell
Likely required additions:
- tab strip
- new tab / close tab
- reopen closed tab
- popup/new-window → new tab
- shortcut parity
- basic tab churn stability

This sequencing keeps milestone 1 focused on correct bring-up and shared browser semantics first.

---

# 6. Implementation dependencies for milestone 1

Milestone 1 depends on these architectural prerequisites:
- continued extraction of shared browser/product semantics into `core/`
- separation of shared CEF runtime/browser logic from Linux GTK host code
- introduction of a host abstraction seam so Windows can implement a native runtime host without copying Linux-specific code

Without those steps, a Windows build would likely become a forked or brittle port rather than a real platform target.

---

# 7. Suggested manual smoke checklist for milestone 1

When the first Windows bring-up exists, verify:

1. Launch BRIDGE runtime-host browser on Windows
2. Confirm BRIDGE Home appears by default
3. Click/focus the address bar
4. Enter `example.com` and confirm it resolves to a navigable URL
5. Enter `weather in boston` and confirm it performs a Google search
6. Navigate to a second page
7. Use back
8. Use forward
9. Use reload
10. Resize the window and confirm content updates
11. Close the window and confirm clean shutdown

If all of the above work, milestone 1 is meaningfully real.

---

# 8. Bottom line

Milestone 1 is the first serious Windows target:
- not polished
- not full-featured
- but truly a BRIDGE browser build that runs and navigates on Windows

That is the right first proof that the architecture is ready for multi-OS browser targets.
