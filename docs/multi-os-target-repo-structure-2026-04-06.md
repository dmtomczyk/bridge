# Multi-OS target repo structure guide — 2026-04-06

This document reviews the current Bridge workspace architecture and proposes a desired-state repository structure that can support multiple target operating systems without turning Bridge into two separately maintained products.

The explicit near-term motivation is Windows support.
Linux-only development is no longer enough if the likely alpha users are on Windows.

---

# 1. Current workspace reality

## Current repos/submodules

The Bridge workspace already operates as a multi-repo workspace pinned by a meta repo:

- `bridge/` — workspace/meta repo
- `client/` — shell/app/backend selection repo
- `engine-custom/` — custom backend repo
- `engine-chromium/` — Chromium-backed reference/demo repo
- `engine-cef/` — active long-term Chromium backend target repo

The meta repo already pins these as submodules.
So the real design question is not “single repo or many repos?”

The real question is:

> where should the platform split live, and how thick should that split be?

---

# 2. What the codebase looks like today

## 2.1 `client/` is both shell repo and build orchestrator

Current facts observed in `client/CMakeLists.txt`:

- `client` pulls sibling repos in via `add_subdirectory(...)`
- `client` enables/disables engines with `BRIDGE_ENABLED_ENGINES`
- `client` builds the user-facing binaries:
  - `browser`
  - `bridge_workbench`
  - `client_cef_runtime_probe`
  - `client_cef_runtime_browser`
- `client` currently owns the backend contract surface in:
  - `client/src/engine_api/*`

This means `client` is doing three jobs today:

1. product/shell repo
2. backend contract owner
3. top-level build composition repo

That is workable, but it is not the cleanest long-term shape if Windows becomes a first-class target.

---

## 2.2 The current backend contract already exists

A real shared seam already exists in:

- `client/src/engine_api/`

and in the backend-factory + attach seams in:

- `client/src/backend_factory/*`

That is important because it means Bridge is not starting from zero.
There is already a real conceptual split between:

- shell/product logic
- backend/engine logic

That existing seam should be preserved and moved to a cleaner shared home, not discarded.

---

## 2.3 `client/` is not yet a clean shared shell core

Current facts observed in `client/CMakeLists.txt` and `client/src/app/application.h`:

- `bridge_client_core` still compiles transitional implementation sources pulled directly from `engine-custom`
- `Application` still includes custom-engine internals directly:
  - DOM
  - parser
  - style/layout
  - JS runtime
  - software canvas
- SDL-backed shell logic lives directly in `client`

This means current `client/` is not yet a clean “portable shell core.”
It is still partially entangled with the legacy/custom engine path.

That matters for Windows planning because the first real step is not “copy client to Windows.”
The first real step is:

> extract a clean shared client core from the current mixed client repo.

---

## 2.4 `engine-cef/` currently mixes shared backend logic with Linux-only runtime host code

Current facts observed in `engine-cef/`:

Shared-ish/backend pieces:

- `cef_backend.*`
- `cef_integration_bridge.*`
- `cef_runtime_entry.*`
- parts of `cef_app_host.*`
- parts of `cef_browser_handler.*`

Linux/platform-specific pieces:

- `cef_osr_host_gtk.*`
- `cef_linux_main_runner.*`
- `main_linux.cc`
- GTK/GDK/X11 wiring in the runtime-host path

Current CMake fact:

- `engine-cef/CMakeLists.txt` currently errors out unless `OS_LINUX`

So the active runtime-host lane is explicitly Linux-only today.

This is a major architectural signal:

> `engine-cef` already contains both shared Chromium/CEF runtime logic and thick Linux host-shell/platform code in the same repo.

That is probably acceptable while there is only one platform.
It becomes much less attractive once Windows support becomes real.

---

## 2.5 The official runtime-host browser is not primarily the SDL shell

The current official runtime-host browser path:

- `browser --renderer=cef-runtime-host`

re-execs into:

- `client_cef_runtime_browser`

That lane is separate from the normal SDL `Application` path.

This means the thing that now feels most like the future product browser is not currently “just the `client` shell.”
It is a hybrid of:

- client launcher/runtime orchestration
- engine-cef runtime host
- GTK/X11 custom browser shell in `engine-cef`

That is another strong hint that the repo split should respect a real platform-host boundary.

---

## 2.6 Cross-repo ownership is still a bit backward in places

Examples observed during the sweep:

- `engine-cef` historically referenced client asset paths directly for branding
- BRIDGE Home recently moved into `browser/assets/bridge-home.html`, which is healthier
- the client still owns contracts that the engine repos depend on
- the client still compiles transitional custom-engine implementation sources into its own core target

These are all signs of a codebase mid-refactor, not signs of a broken project.
But they do matter for the next split.

---

# 3. Practical conclusion from the current architecture

The platform-specific shell/host layer is **not tiny**.

That is the most important conclusion from the repo/code review.

The Linux-specific runtime-host/browser path already contains substantial platform-bound behavior:

- GTK windowing
- GDK input translation
- X11 integration
- Cairo drawing
- off-screen-rendered frame presentation
- resize/focus/event-loop behavior
- platform-specific scrolling/input behavior

A Windows implementation will need equivalents for most of that.

So this is **not** a situation where Windows support is just a 5% adapter layer.

That means your instinct is correct:

> if the platform-specific chunk is substantial, do not force all of it into one repo unless that repo is intentionally platform-host code.

---

# 4. Design principles for the desired state

The desired state should preserve four truths:

## 4.1 One product, not two apps

Windows and Linux should be build targets / platform targets, not separately evolving browser products.

Shared product behavior should stay shared:

- tab model
n- page-kind model
- closed-tab recovery
- popup/new-tab policy
- startup/home-page behavior
- backend contracts
- benchmark/docs/acceptance behavior

---

## 4.2 Shared core should not depend on platform host code

Anything that represents product behavior or browser/runtime semantics should live outside platform-specific repos.

---

## 4.3 Platform shells should own native window/input/presentation code

Anything that is substantially GTK/X11-specific or Win32-specific should be isolated.

---

## 4.4 Repo boundaries should match maintenance boundaries

If a code area will be actively developed differently per platform, it is a candidate for either:

- a dedicated platform folder in a host repo, or
- a dedicated platform repo

The deciding factor is not ideology.
The deciding factor is code weight and maintenance cost.

---

# 5. Recommended desired-state repo structure

## Recommended shape

### A. `bridge/`
**Role:** workspace/meta repo  
**Owns:**
- submodule pointers
- workspace-wide docs
- integration notes
- CI orchestration pointers
- developer scripts that span repos

Keep this.

---

### B. `bridge-client-core`
**Role:** shared product/shell/core repo  
**Owns:**
- shared shell/product logic
- backend contracts / engine API
- navigation/controller logic
- shared browser semantics
- shared UI/chrome model (not native drawing implementation)
- shared assets like BRIDGE Home
- benchmark docs / acceptance docs / user-facing product notes
- shared tests that do not require a specific native shell implementation

This is the most important new repo to create.

### Why
Today the current `client/` repo mixes:

- shared shell/product concerns
- Linux/launcher/runtime specifics
- transitional custom-engine internals

That should be separated.

### What should move here first
- `src/engine_api/*`
- shared backend-factory contracts/seams
- navigation/controller code
- non-platform-specific shell/product logic
- BRIDGE Home and other shared product assets
- benchmark docs and readiness docs

### What should *not* stay here
- heavy GTK-specific host code
- Win32-specific host code
- platform packaging/installers
- OS-specific launch wrappers if they become nontrivial

---

### C. `bridge-client-linux`
**Role:** Linux desktop/client target repo  
**Owns:**
- Linux launcher binary/wrapper behavior
- Linux packaging/install behavior
- Linux-specific runtime/browser startup details
- any Linux-specific workbench/launcher code that is not truly portable
- dependency wiring for Linux targets

### Notes
This repo should be as thin as possible.
It should depend on `bridge-client-core` for shared behavior.

If the SDL shell/workbench proves truly portable, much of it can stay in `bridge-client-core` and this repo can remain mostly a launcher/packaging repo.

---

### D. `bridge-client-win`
**Role:** Windows desktop/client target repo  
**Owns:**
- Windows launcher/wrapper behavior
- Windows packaging/install behavior
- Windows-specific startup/runtime details
- Windows-only desktop integration and distribution concerns

### Notes
Like the Linux client repo, this should be thin where possible and depend on `bridge-client-core` for shared product behavior.

---

### E. `bridge-engine-custom`
**Role:** custom backend repo  
**Owns:**
- current custom engine internals
- parser/layout/style/js/paint implementation
- custom backend adapter

Keep this, but stop leaking its implementation directly into client-core over time.

---

### F. `bridge-engine-chromium`
**Role:** Chromium reference/demo repo  
**Owns:**
- reference/demo Chromium lane
- comparison/debugging lane
- historical/reference tooling

Keep this if it remains useful as a reference lane.
If it stops earning its keep, archive/freeze it intentionally.

---

### G. `bridge-engine-cef-core`
**Role:** shared CEF/Chromium runtime core repo  
**Owns:**
- CEF runtime entry/config/status model
- CEF integration bridge
- backend snapshot/presentation contracts
- shared tab/runtime host logic that is not native-host-specific
- popup/new-tab policy
- tab model / closed-tab recovery / page-kind model
- browser/runtime orchestration that should behave the same on every platform

### Why this deserves its own core repo
Right now `engine-cef` mixes shared Chromium/CEF runtime logic with Linux-only GTK/X11 host code.
That is the exact kind of repo boundary that becomes painful once Windows becomes real.

This is the second most important split after `bridge-client-core`.

---

### H. `bridge-engine-cef-linux`
**Role:** Linux CEF host/runtime-host repo  
**Owns:**
- GTK host implementation
- X11 integration
- Cairo-drawn browser chrome in the Linux runtime-host path
- Linux-specific OSR presentation/input code
- Linux main runner/bootstrap pieces

### Concretely, current likely candidates to move here
- `cef_osr_host_gtk.*`
- `cef_linux_main_runner.*`
- `main_linux.cc`
- related GTK/X11-specific runtime-host glue

---

### I. `bridge-engine-cef-win`
**Role:** Windows CEF host/runtime-host repo  
**Owns:**
- Win32/Windows host implementation
- Windows native window/input/presentation code
- Windows-specific OSR/browser shell integration
- Windows runtime bootstrap/main runner pieces

### Notes
This repo does not exist yet, but this is the cleanest conceptual home for the future Windows host layer.

---

# 6. Why this split is recommended

## 6.1 It matches the actual thickness of the platform layer

The current Linux runtime-host/browser shell is thick enough that pretending it is a tiny adapter would be dishonest.

## 6.2 It keeps product behavior shared

The thing that must stay unified is not “all code in one repo.”
The thing that must stay unified is:

- tab behavior
- popup policy
- special-page behavior
- shortcuts semantics
- closed-tab recovery semantics
- product identity

Those belong in shared core repos.

## 6.3 It avoids giant mixed-platform soup

Because the platform-specific host layer is not tiny, keeping GTK/X11 and Win32 implementations in the same repo is likely to become noisy unless that repo is explicitly a host-platform repo.

## 6.4 It fits the workspace you already have

Bridge is already a multi-repo workspace.
This recommendation works with the grain of the existing project rather than fighting it.

---

# 7. What should stay shared vs platform-specific

## Shared across OS

These should live in shared core repos:

### In `bridge-client-core`
- backend contract / engine API
- shared navigation/controller logic
- shared benchmark/test definitions
- shared product assets (like BRIDGE Home)
- shared product/browser behavior docs
- shared shell/chrome state model if kept independent of native drawing

### In `bridge-engine-cef-core`
- runtime host status/config model
- tab model / closed-tab recovery
- page-kind model
- popup/new-window policy
- CEF integration bridge
- backend snapshot/presentation contracts
- browser lifecycle coordination that should not vary by OS

---

## Platform-specific

These should live in platform repos:

### In `bridge-client-linux` / `bridge-client-win`
- launch wrappers
- packaging/installer behavior
- OS-specific file/path conventions that are product-layer concerns
- any native launcher/workbench glue that is not truly portable

### In `bridge-engine-cef-linux` / `bridge-engine-cef-win`
- native window creation
- OSR frame presentation into native surfaces
- native input translation
- scroll wheel / smooth-scroll native event handling
- native focus/resize/window-state behavior
- platform bootstrap/main-loop glue

---

# 8. What should change in the current codebase before the Windows port starts

## Priority 1 — extract `bridge-client-core`

This is the first cleanup needed.

### Immediate goals
- move shared contracts out of the current mixed `client/` repo
- stop treating `client/` as both product-core and platform-specific launcher repo
- make BRIDGE Home and shared docs/assets clearly belong to shared product core

### Most important cleanup
Stop `bridge_client_core` from directly compiling implementation sources out of `engine-custom` as a transitional crutch.
That is one of the biggest current architecture leaks.

---

## Priority 2 — split `engine-cef` into core vs Linux host

This is the second cleanup needed.

### Immediate goals
- isolate Linux-only host code from shared CEF runtime/browser logic
- make a Windows CEF host repo possible without duplicating core logic

### Most important cleanup
Move GTK/X11/OSR host-shell code out of the same repo area that owns the reusable CEF runtime/tab/browser logic.

---

## Priority 3 — reduce backward asset/dependency ownership

Examples of the kind of cleanup to continue:

- shared product assets should be owned by shared client/product core, not engine repos
- engine repos should not depend on client repo internals for things that are actually shared contracts

---

# 9. Recommended migration sequence

## Phase 0 — freeze the current truths in docs
- [ ] Keep current architecture docs updated
- [ ] Record that Windows support is now a first-class requirement
- [ ] Record that the Linux runtime-host path is no longer the only intended deployment target

---

## Phase 1 — create shared client core
- [ ] Create `bridge-client-core`
- [ ] Move `engine_api/` and shared shell/product logic there
- [ ] Move BRIDGE Home and shared assets there
- [ ] Move shared acceptance/benchmark docs there or give them a clearly shared home
- [ ] Stop compiling `engine-custom` implementation sources directly into client core

### Exit condition
A Linux launcher/client repo and a future Windows launcher/client repo can both depend on the same shared client core.

---

## Phase 2 — split CEF core from Linux host
- [ ] Create `bridge-engine-cef-core`
- [ ] Create `bridge-engine-cef-linux`
- [ ] Move GTK/X11/OSR host code into the Linux repo
- [ ] Keep tab/runtime/browser/popup/page-kind logic in CEF core

### Exit condition
A future `bridge-engine-cef-win` repo can be created without copying core runtime/browser logic.

---

## Phase 3 — establish thin platform client repos
- [ ] Convert current `client/` role into `bridge-client-linux` (or equivalent)
- [ ] Add `bridge-client-win`
- [ ] Keep shared browser/product behavior in `bridge-client-core`
- [ ] Keep launch/package/platform-specific behavior in the platform client repos

### Exit condition
Linux and Windows are now product targets sharing a real common client core.

---

## Phase 4 — add Windows CEF host repo
- [ ] Create `bridge-engine-cef-win`
- [ ] Implement Windows runtime-host shell/host there
- [ ] Hook `bridge-client-win` to the same shared client core + CEF core

### Exit condition
Linux and Windows runtime-host builds use the same shared product and runtime logic, with different native host implementations.

---

# 10. What should NOT be duplicated across repos

These must stay single-source-of-truth:

- tab model semantics
- closed-tab recovery semantics
- popup/new-window policy
- BRIDGE Home behavior/content intent
- benchmark definitions / alpha-readiness expectations
- backend contracts / engine API
- special-page semantics like page kind

If those drift between repos, the split has failed.

---

# 11. What can safely differ by platform

These can differ as long as user-facing behavior stays aligned:

- native windowing code
- native input plumbing
- presentation path implementation details
- packaging/install format
- launcher specifics
- platform bootstrap/main-loop details
- native scrolling/event translation details

---

# 12. Final recommendation

## Recommended desired-state shape

### Shared repos
- `bridge/` (workspace/meta)
- `bridge-client-core`
- `bridge-engine-custom`
- `bridge-engine-chromium` (reference lane, if still useful)
- `bridge-engine-cef-core`

### Platform repos
- `bridge-client-linux`
- `bridge-client-win`
- `bridge-engine-cef-linux`
- `bridge-engine-cef-win`

That sounds like more repos, but it is not “more products.”
It is:

- one shared product/client core
- one shared CEF runtime core
- platform-specific shells/hosts where the code is genuinely platform-thick

That is the cleanest path to Windows support without turning Bridge into two separate applications.

---

# 13. Plain-English summary

Based on the current codebase and repo layout:

- Windows support should be planned now
- the platform-specific shell/host layer is too substantial to pretend it is a tiny shim
- the right answer is not duplicated apps
- the right answer is shared core repos plus platform-specific client/host repos

The first two major refactors to unlock that cleanly are:

1. extract a real `bridge-client-core`
2. split `engine-cef` into shared CEF core and Linux host/platform code

That creates the architecture Windows support actually needs.
