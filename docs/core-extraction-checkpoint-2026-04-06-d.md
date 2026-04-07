# Core extraction checkpoint D — 2026-04-06

This note records the follow-up state after checkpoint C, where the shared `BrowserAction` semantics work was pushed a little further, tested against the real build, and then narrowed back to the stable truth.

Reference earlier checkpoints:
- `docs/core-extraction-checkpoint-2026-04-06.md`
- `docs/core-extraction-checkpoint-2026-04-06-b.md`
- `docs/core-extraction-checkpoint-2026-04-06-c.md`

---

# What changed in this checkpoint

## 1. We tested how far the shared `BrowserAction` seam really reaches today

After checkpoint C, the next idea was to keep moving along the same path:
- use the shared `BrowserAction` enum not only in the CEF runtime-host path
- but also broaden browser-app shortcut handling in `browser/src/app/application.cpp`

The intent was good:
- reduce semantic drift between runtime paths
- centralize user-facing action meaning before doing heavier backend or platform restructuring

---

## 2. The CEF runtime-host side remains the strong/shared side of this seam

The runtime-host path in `engine-cef` continues to be the place where the broader shared action vocabulary is real and useful.

Shared `BrowserAction` semantics actively used there include:
- reload
- new tab
- close tab
- reopen closed tab
- focus address bar
- next tab
- previous tab

That means the CEF runtime-host lane now has a meaningful browser-level action identity layer rather than only ad hoc shortcut wiring.

---

## 3. The browser app path does **not** yet support the same action surface cleanly

A follow-up attempt broadened browser-app shortcut handling so `Application` would route more of its shortcuts through the shared `BrowserAction` model.

That overreached the current app surface.

The browser app path does have clear/local support for:
- reload
- navigate back
- navigate forward
- address-bar focus toggling in its existing form

But it does **not** yet expose a clean matching set of app-level helpers for the fuller tab/action surface that the CEF runtime-host path already has.

The attempted expansion ran into exactly that mismatch during build verification.

### Concrete symptoms from the failed browser-app expansion
The attempted browser-app shortcut/action expansion called helpers that do not currently line up in the app path, including unresolved or mismatched calls such as:
- `new_tab()`
- `close_active_tab()`
- `reopen_closed_tab()`
- `advance_active_tab(...)`
- a zero-arg `focus_address_bar()` call even though the local method expects a boolean

So the lesson here is important:

> the shared `BrowserAction` model is ahead of the browser app path’s concrete execution surface.

That is not a failure of the shared model.
It simply means the app path has not yet grown the matching command helpers needed for full shortcut/action unification.

---

## 4. We reverted the browser-app overreach to restore the stable baseline

Rather than checkpointing a broken or half-forced state, the browser-app shortcut expansion was backed out.

That restored the stable, accurate arrangement:

### Browser app path currently using shared `BrowserAction` for:
- reload
- navigate back
- navigate forward

### CEF runtime-host path currently using shared `BrowserAction` for:
- reload
- new tab
- close tab
- reopen closed tab
- focus address bar
- next tab
- previous tab
- navigate/back-forward style behavior where wired in runtime-host handling

This is the truthful and buildable checkpoint state.

---

# Why this checkpoint matters

Checkpoint C showed that `core/` could carry real browser behavior semantics.

Checkpoint D is valuable because it establishes the **actual boundary** of that progress instead of pretending the seam is already wider than it is.

That matters for future work because it tells us:
- shared browser action identity is working
- runtime-host integration is ahead of browser-app integration
- the next step is not “force more enum usage everywhere”
- the next step is “grow or formalize the browser app execution surface if we want fuller parity”

In other words, this checkpoint turns a nice architectural idea into a more trustworthy map of where the codebase really is.

---

# Build verification at this checkpoint

The attempted browser-app expansion initially broke the real build.

After reverting just that overreach, the active browser/CEF lane built cleanly again, including the usual runtime-host/browser targets:
- `browser`
- `browser_cef_runtime_probe`
- `browser_cef_runtime_browser`

So the repo is back at a green/stable baseline after the experiment.

---

# Current interpretation of the `BrowserAction` extraction work

At this point, the right way to describe the state is:

- `core/include/browser/browser_action.h` is a real shared semantic layer
- `engine-cef` is consuming that layer in a meaningful way
- `browser/src/app/application.cpp` only partially participates so far
- full browser-app action parity is still future work, not current reality

That is still good progress.
It is just narrower and more honest progress than the first ambitious follow-up attempt implied.

---

# Recommended next directions after this checkpoint

## Option A — grow the browser-app execution surface intentionally
Examples:
- add explicit app-level helpers for tab creation/closing/reopen/switching
- define a single `Application::execute_browser_action(...)` helper once those operations really exist
- then route more shortcuts through shared action semantics again

## Option B — keep extracting adjacent shared browser/runtime semantics
Examples:
- shared startup/home/new-tab behavior models
- shared browser config/state models
- shared navigation intent semantics

## Option C — leave action semantics here for now and continue another structural seam
Examples:
- another medium-weight `core/` contract/model slice
- a cleaner boundary around platform/browser host responsibilities

---

# Bottom line

Checkpoint D is the “trustworthy scope” checkpoint.

It confirms that shared `BrowserAction` semantics are real and useful, especially in the CEF runtime-host lane, while also documenting that the browser app path is not yet ready for full action-surface unification.

That gives us a stable green baseline and a clearer map for the next port/extraction steps.
