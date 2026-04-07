# Multi-OS migration checklist — 2026-04-06

This document turns the target-state repo guide into a tactical migration checklist.

Reference:
- `docs/multi-os-target-repo-structure-2026-04-06.md`

The goal is to move Bridge from its current Linux-centric split workspace into a structure that supports multiple target operating systems without turning Bridge into two duplicated applications.

This is not a mandate to do everything at once.
It is an ordered checklist for how to extract the right seams without losing the ability to ship and test.

---

# 1. Migration goals

## Product goal
- one shared product behavior
- multiple target operating systems
- no duplicated browser/product logic across platforms

## Codebase goal
- shared core repos own shared behavior/contracts
- platform repos own native shell/host/presentation/input code
- repo boundaries match maintenance boundaries

## Immediate practical goal
Make Windows support possible **without** forcing Linux GTK/X11 host code and future Windows host code into one noisy mixed implementation blob.

---

# 2. Current pain points to address

## In `client/`
- [ ] `client` currently acts as shell repo, shared contract owner, and top-level build orchestrator all at once
- [ ] `bridge_client_core` still compiles transitional implementation sources directly from `engine-custom`
- [ ] shared product/shell logic is not yet cleanly separated from platform/launcher concerns

## In `engine-cef/`
- [ ] shared CEF runtime/browser logic is mixed with Linux-only GTK/X11 host code
- [ ] `engine-cef/CMakeLists.txt` is explicitly Linux-only today
- [ ] the current official runtime-host browser path depends on a thick Linux-specific host layer

## Across repos
- [ ] some ownership boundaries are still backward or transitional
- [ ] shared product/runtime logic is not yet cleanly isolated from platform-specific code

---

# 3. Desired end state

## Shared repos
- [ ] `bridge/` meta repo remains the workspace pin/orchestration repo
- [ ] `bridge-client-core` exists and owns shared client/product/shell contracts and logic
- [ ] `bridge-engine-cef-core` exists and owns shared CEF runtime/browser logic
- [ ] `bridge-engine-custom` remains engine-specific
- [ ] `bridge-engine-chromium` remains optional reference/demo lane if still useful

## Platform repos
- [ ] `bridge-client-linux` exists for Linux launcher/package/platform behavior
- [ ] `bridge-client-win` exists for Windows launcher/package/platform behavior
- [ ] `bridge-engine-cef-linux` exists for GTK/X11/Linux runtime-host code
- [ ] `bridge-engine-cef-win` exists for Win32/Windows runtime-host code

---

# 4. Recommended order of work

## Phase 0 — Freeze current truths in docs

### Checklist
- [ ] Keep current runtime-host architecture docs up to date
- [ ] Record that Windows support is now a first-class product requirement
- [ ] Record that Linux-only local development is no longer enough for the intended alpha audience
- [ ] Record the current repo ownership model clearly before extraction begins

### Deliverable
- docs already in place, plus this migration checklist as the tactical plan

---

## Phase 1 — Extract `bridge-client-core`

This is the most important first extraction.

### Why this comes first
The current `client/` repo is doing too many jobs:
- shared product/shell logic
- backend contract ownership
- launcher/executable ownership
- top-level build composition

Windows support will be messy unless shared client/product logic gets its own clean home.

### Create repo
- [ ] Create `bridge-client-core`

### Move / extract first
#### Shared contracts
- [ ] move `client/src/engine_api/*`
- [ ] move or re-home shared backend-facing contract headers used by multiple engines

#### Shared product/shell logic
- [ ] move `client/src/browser/navigation_controller.*`
- [ ] move shared browser behavior/state logic that is not inherently SDL/launcher/platform-specific
- [ ] move shared chrome model/state if it can be separated from specific native rendering implementations

#### Shared product assets
- [ ] move `browser/assets/bridge-home.html`
- [ ] move other truly shared product assets/branding that should not belong to a platform-specific launcher repo

#### Shared docs/tests/benchmarks
- [ ] move shared benchmark definitions/docs if they conceptually belong to product core
- [ ] keep platform-specific benchmark/run instructions outside if needed

### Clean up transitional leaks
- [ ] stop compiling `engine-custom` implementation sources directly into `bridge_client_core`
- [ ] replace transitional source inclusion with a cleaner dependency boundary
- [ ] make `bridge-client-core` depend on engine contracts, not engine implementation sources

### Result of Phase 1
After this phase, both Linux and Windows client repos should be able to depend on a real shared client/product core.

---

## Phase 2 — Convert current `client/` toward `bridge-client-linux`

Once shared client core exists, the current `client/` repo can become a thinner Linux-focused client repo.

### Checklist
- [ ] decide whether to rename `client/` → `bridge-client-linux`, or keep repo name and change role explicitly
- [ ] remove shared-core responsibilities that were moved to `bridge-client-core`
- [ ] keep Linux launcher and Linux-specific runtime behavior here
- [ ] keep SDL workbench/launcher code here only if it is truly Linux-specific
- [ ] if SDL shell pieces are portable enough, push them down into `bridge-client-core` instead

### Likely current candidates to keep here
- [ ] `src/main.cpp` launcher behavior if Linux-specific
- [ ] `src/cef_runtime_browser_main.cpp` if still Linux-oriented launcher/runtime entry behavior
- [ ] Linux packaging/install scripts/docs

### Result of Phase 2
Current `client/` is no longer pretending to be both shared client core and Linux client target at the same time.

---

## Phase 3 — Split `engine-cef` into core vs Linux host

This is the second major extraction.

### Why this is necessary
`engine-cef` currently mixes:
- shared runtime/browser logic
- Linux GTK/X11 host-shell code

That will become painful immediately once Windows host work starts.

### Create repos
- [ ] create `bridge-engine-cef-core`
- [ ] create `bridge-engine-cef-linux`

### Move to `bridge-engine-cef-core`
These are the first candidates for shared CEF runtime/browser logic:

- [ ] `src/cef_backend.*`
- [ ] `src/cef_backend_types.h`
- [ ] `src/cef_integration_bridge.*`
- [ ] `src/cef_runtime_entry.*`
- [ ] shared parts of `src/cef_app_host.*`
- [ ] shared parts of `src/cef_browser_handler.*`
- [ ] shared tests that do not require Linux-specific host code

### Move to `bridge-engine-cef-linux`
These are the clearest Linux/platform-specific candidates:

- [ ] `src/cef_osr_host_gtk.*`
- [ ] `src/cef_linux_main_runner.*`
- [ ] `src/main_linux.cc`
- [ ] Linux/GTK/X11-specific runtime-host probe entry points
- [ ] Linux-specific build rules and GTK package discovery

### Important refactor task during the split
- [ ] identify what pieces of `cef_app_host` / `cef_browser_handler` are truly shared vs currently assuming a GTK host
- [ ] replace direct GTK-host assumptions with a host-facing abstraction where necessary

### Result of Phase 3
The shared CEF runtime/tab/browser logic becomes reusable, and Linux host code gets its own clean home.

---

## Phase 4 — Introduce host abstraction seam explicitly

This seam does not need to be over-designed, but it does need to be real.

### Checklist
- [ ] define the minimal host-facing interface that shared CEF runtime/browser logic actually needs
- [ ] move Linux GTK host implementation behind that seam
- [ ] ensure shared tab/browser logic no longer depends directly on GTK/X11 types

### Likely responsibilities of the host seam
- [ ] native window lifecycle
- [ ] present/copy frame into native host surface
- [ ] native input event forwarding
- [ ] focus/resize hooks
- [ ] host/browser activation plumbing
- [ ] chrome/tab-strip hit routing if kept at the host layer

### Result of Phase 4
A future Windows host implementation becomes a matter of implementing the host seam, not copying Linux code.

---

## Phase 5 — Create `bridge-client-win`

Once `bridge-client-core` exists and current `client` has been reduced toward Linux-specific ownership, add the Windows client target repo.

### Checklist
- [ ] create `bridge-client-win`
- [ ] make it depend on `bridge-client-core`
- [ ] keep it thin: launcher, packaging, Windows-specific startup logic
- [ ] do **not** reimplement shared browser/product behavior here

### Result of Phase 5
Windows becomes a real product target repo without duplicating shared client/product code.

---

## Phase 6 — Create `bridge-engine-cef-win`

Once `bridge-engine-cef-core` and the host seam exist, add the Windows host repo.

### Checklist
- [ ] create `bridge-engine-cef-win`
- [ ] implement the Windows native runtime-host shell there
- [ ] wire it against `bridge-engine-cef-core`
- [ ] ensure it can satisfy the same product semantics as Linux:
  - tabs
  - popup/new-tab behavior
  - closed-tab recovery
  - BRIDGE Home
  - shortcuts

### Result of Phase 6
Windows runtime-host becomes a platform target built on the same shared runtime core.

---

# 5. Concrete file/module candidates to move first

## From current `client/` to `bridge-client-core`
- [ ] `src/engine_api/*`
- [ ] `src/browser/navigation_controller.*`
- [ ] shared backend-factory contract headers/seams where practical
- [ ] shared UI/chrome state model if separable from SDL/native rendering details
- [ ] `assets/bridge-home.html`
- [ ] shared benchmark/readiness docs that are product-wide rather than Linux-launch-specific

## Likely to remain in Linux client repo initially
- [ ] `src/main.cpp` launcher behavior
- [ ] `src/cef_runtime_browser_main.cpp` until a clearer cross-platform launcher abstraction exists
- [ ] `src/cef_runtime_probe_main.cpp` if still Linux/CEF-runtime-lane-specific
- [ ] Linux-local build/packaging glue
- [ ] SDL workbench pieces only if they remain Linux-focused in practice

## From current `engine-cef/` to `bridge-engine-cef-core`
- [ ] `src/cef_backend.*`
- [ ] `src/cef_integration_bridge.*`
- [ ] `src/cef_runtime_entry.*`
- [ ] shared parts of `src/cef_app_host.*`
- [ ] shared parts of `src/cef_browser_handler.*`

## From current `engine-cef/` to `bridge-engine-cef-linux`
- [ ] `src/cef_osr_host_gtk.*`
- [ ] `src/cef_linux_main_runner.*`
- [ ] `src/main_linux.cc`
- [ ] Linux-specific probe/proof runners
- [ ] GTK/X11 build plumbing

---

# 6. Things that must stay single-source-of-truth during migration

These must **not** fork between Linux and Windows repos:

- [ ] tab model semantics
- [ ] page-kind / special-page semantics
- [ ] closed-tab recovery semantics
- [ ] popup/new-window policy
- [ ] BRIDGE Home behavior/content intent
- [ ] shortcut semantics
- [ ] benchmark definitions / alpha-readiness expectations
- [ ] engine/backend contracts

If these drift, the migration has failed even if the repos look neat.

---

# 7. Things that are allowed to stay platform-specific

These can differ by OS as long as user-visible product behavior stays aligned:

- [ ] native windowing implementation
- [ ] native input event plumbing
- [ ] OSR presentation implementation details
- [ ] packaging/install format
- [ ] launcher specifics
- [ ] file path conventions and platform runtime defaults
- [ ] native scrolling/event translation implementation

---

# 8. Suggested checkpoint commits / milestones

## Checkpoint A — client core extraction begins
- [ ] create `bridge-client-core`
- [ ] move shared contracts/assets there
- [ ] keep Linux build green

## Checkpoint B — client repo role clarified
- [ ] current `client/` is clearly a Linux client target, not generic shared core

## Checkpoint C — CEF core/linux split begins
- [ ] create `bridge-engine-cef-core`
- [ ] create `bridge-engine-cef-linux`
- [ ] move GTK/X11 host code out of shared CEF runtime area

## Checkpoint D — host seam established
- [ ] shared CEF runtime logic can talk to an abstract host layer

## Checkpoint E — Windows client repo exists
- [ ] `bridge-client-win` created and consuming shared client core

## Checkpoint F — Windows CEF host repo exists
- [ ] `bridge-engine-cef-win` created against shared CEF runtime core

---

# 9. Recommended near-term next actions

If this migration starts soon, the best first concrete actions are:

## Next 3 actions
- [ ] decide the exact repo names to use for shared client core and shared CEF core
- [ ] identify the first file move set from `client/` into `bridge-client-core`
- [ ] identify the first file move set from `engine-cef/` into `bridge-engine-cef-core` vs `bridge-engine-cef-linux`

## After that
- [ ] create the new repos
- [ ] perform the smallest viable extraction while keeping Linux builds green
- [ ] only then begin Windows host implementation work

---

# 10. Plain-English summary

This migration should not start with “build Windows now.”
It should start with:

1. extract a real shared client core
2. split shared CEF runtime logic from Linux GTK/X11 host code
3. create thin platform client repos
4. then add the Windows host implementation against the new shared seams

That is the safest path to Windows support without duplicating Bridge into two separate applications.
