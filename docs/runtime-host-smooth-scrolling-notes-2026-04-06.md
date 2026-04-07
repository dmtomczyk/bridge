# Runtime-host smooth scrolling notes — 2026-04-06

This document captures the current state of smooth-scrolling work in the official BRIDGE runtime-host browser path:

- `browser/build/cef-hybrid-real/browser --renderer=cef-runtime-host`

The goal is to preserve what was learned so future work can start from signal instead of guesswork.

---

# Current status

Smooth scrolling is now:

- better than the original coarse wheel-step behavior
- usable enough for local development/testing
- still noticeably rough compared with polished major browsers
- not yet at the level where it disappears as a quality issue

On a 144Hz monitor, remaining roughness is especially visible.

Current practical judgment:

- **usable for development**
- **probably not yet good enough for a polished alpha experience**

---

# What was changed so far

## 1. Added support for GTK smooth scroll events

The original scroll path only handled:

- `GDK_SCROLL_UP`
- `GDK_SCROLL_DOWN`
- `GDK_SCROLL_LEFT`
- `GDK_SCROLL_RIGHT`

with hardcoded `±120` wheel deltas.

That was upgraded to support:

- `GDK_SCROLL_SMOOTH`
- `gdk_event_get_scroll_deltas(...)`

So the runtime-host now receives precise GTK scroll deltas instead of only coarse wheel steps.

---

## 2. Added fractional accumulation for smooth deltas

Instead of immediately rounding every smooth delta, the host now keeps fractional remainder in:

- `pending_scroll_x_`
- `pending_scroll_y_`

This avoids throwing away tiny partial movement too early.

---

## 3. Added a small threshold/coalescing-style emission rule

Smooth deltas are now accumulated and only emitted once enough movement builds up to cross a meaningful threshold.

This reduced some micro-jitter compared with blindly sending every tiny integerized step.

---

## 4. Reintroduced 60 FPS more carefully

A major early clue was that OSR browser creation was still hardcoded to:

- `windowless_frame_rate = 30`

That is visibly rough even on 60Hz displays and especially rough on 144Hz displays.

The runtime-host was then moved to:

- `windowless_frame_rate = 60`

However, the first attempt exposed a startup/render bug.

### Important finding
The problem was not simply “60 FPS is too high.”
The first implementation also revealed a bad presentation pattern in:

- `CefOsrHostGtk::PresentFrame(...)`

At that point, `PresentFrame(...)` was doing:

- `gtk_widget_queue_draw(...)`
- followed by a nested re-entrant GTK event pump:
  - `while (gtk_events_pending()) gtk_main_iteration();`

That nested loop likely contributed to the broken half-rendered startup/home-page behavior seen after the first 60 FPS attempt.

The fix was to remove that re-entrant GTK pumping and let GTK paint normally after `gtk_widget_queue_draw(...)`.

With that change in place, 60 FPS could be reintroduced without immediately breaking startup rendering.

---

# What improved

Compared with the original runtime-host scrolling path:

- startup rendering is still working after the careful 60 FPS reintroduction
- docs-style scrolling feels noticeably better than the original coarse wheel-step behavior
- the browser feels more responsive than it did under the old 30 FPS OSR presentation limit

So the work was not wasted.
It produced real, user-visible gains.

---

# What still feels wrong

Even after the improvements above, scrolling still feels:

- a bit choppy
- slightly bursty/jumpy
- behind the quality bar set by major browsers

The roughness is especially visible on a 144Hz display.

The key product read at this checkpoint was:

> usable for building/testing at home, but not yet something you would choose to use purely on smoothness/feel

That is the correct frame for future prioritization.

---

# What was tried that did NOT fully solve it

## Lowering the smooth-scroll scale too far

A tuning pass reduced the smooth-scroll scale from:

- `80` to `60`

That made the experience feel worse:

- more obviously jittery
- more bursty
- more “wait, wait, jump”

Why this likely happened:

- smaller deltas took longer to cross the integer/emission threshold
- quantization became more visible, not less

Conclusion:

- the issue is not simply “too much scroll speed”
- the issue is more about discretization, pacing, and event shaping

---

# Key architectural context

## What major Chromium browsers do differently

Major browsers do more than “set a higher frame rate.”

They typically benefit from some combination of:

- higher-quality input/event handling
- better delta coalescing and momentum behavior
- better frame pacing
- GPU/compositor integration
- async/threaded scrolling and compositing
- a rendering path that is less manual than a simple OSR-host-copy-draw loop

So while big Chromium browsers often effectively push beyond 60 FPS on high-refresh displays, that is only part of the reason they feel smooth.

### Important takeaway
Higher FPS helps, but it is **not sufficient by itself**.
A browser can still feel rough at 60 if:

- input is bursty
- redraws are irregular
- wheel deltas are shaped poorly
- the present path is expensive or uneven

---

## CEF / Chromium context

CEF can absolutely support smooth-feeling applications, but OSR is usually the trickier path if the quality bar is “native-feeling browser smoothness.”

Why OSR is harder:

- frame-copy overhead
- presentation timing issues
- host-managed input shaping
- more chances for uneven pacing between input, paint, and display

That does not mean smoothness is impossible.
It means the remaining work is likely deeper than simple wheel-delta tuning.

---

# Best current interpretation

The obvious/easy wins have probably already been taken:

- coarse wheel-step-only input was replaced with smooth GTK delta support
- fractional accumulation was added
- thresholded emission was added
- 30 FPS OSR presentation was raised to 60 FPS
- a bad re-entrant GTK event loop inside `PresentFrame(...)` was removed

The remaining roughness now likely belongs to a deeper class of problem such as:

- uneven frame pacing
- imperfect event coalescing
- mismatch between GTK smooth deltas and CEF wheel semantics
- OSR presentation overhead/cadence limits

---

# Recommendation going forward

## Short version
Do not keep blindly tuning constants.

The next gains, if pursued, should come from a **deeper smooth-scrolling slice**, not more random scale changes.

---

## What a deeper scrolling slice would mean

A real next-phase smooth-scrolling investigation should likely examine some combination of:

### 1. Better event coalescing
- merge smooth deltas across a short time window
- reduce visible burstiness from uneven micro-events
- preserve remainder/momentum sanely

### 2. Better pacing
- investigate whether scroll-triggered frame presentation is arriving irregularly
- inspect whether OSR paint cadence and GTK draw cadence are well matched
- confirm whether 60 FPS is actually being realized consistently in practice

### 3. Better differentiation between input types
- discrete mouse wheel
- smooth touchpad/trackpad scrolling

These may deserve different shaping strategies.

### 4. Present-path cost / cadence
- inspect whether copying/presenting frames in the current OSR host path is itself a bottleneck
- inspect whether further re-entrancy or scheduling issues remain in the presentation flow

### 5. High-refresh expectations
On 120Hz/144Hz displays, roughness that might be acceptable at 60Hz becomes much easier to spot.
Future tuning should keep that in mind.

---

# Product recommendation at this checkpoint

Two reasonable choices exist:

## Option A — backlog the deeper scrolling slice
If momentum toward alpha matters more right now:

- record the current state honestly
- accept that scrolling is improved but not polished
- continue with other alpha-readiness items
- revisit smooth scrolling as a focused quality pass later

## Option B — keep going now
If scrolling feel is central enough to the product identity, the next work should be treated as a dedicated rendering/input quality project rather than a small tweak.

That means:

- time-based coalescing investigation
- pacing investigation
- possibly deeper OSR presentation work

---

# Bottom-line summary

Current smooth scrolling in BRIDGE runtime-host is:

- **better**
- **usable for development**
- **still below polished-browser expectations**

The remaining problem is probably no longer an easy wheel-delta constant issue.
It is more likely a deeper pacing / coalescing / OSR presentation quality problem.

That is the right frame to carry forward.
