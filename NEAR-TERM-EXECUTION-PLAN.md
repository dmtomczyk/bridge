# NEAR-TERM-EXECUTION-PLAN.md

Near-term execution plan for the `bridge` workspace.

This is the practical plan for getting from the current transitional multi-repo state to:

1. a real submodule-managed workspace root, and
2. the first genuinely functional Chromium-backed engine path.

---

## 0. Current state snapshot

### What is already true

- The intended 4-repo architecture is real in practice:
  - `bridge/`
  - `client/`
  - `engine-custom/`
  - `engine-chromium/`
- All 4 repos now have real Git remotes.
- The renamed `bridge` workspace builds again.
- `client` test lanes are green:
  - `v8-off`: passing
  - `v8-on`: passing
- Chromium has been fetched/synced under `engine-chromium/third_party/src`.
- A real Chromium target has already been built successfully:
  - `out/browz-headless/headless_shell`
- The shell/backend split exists and works.
- The Blink/Chromium backend seam exists, but is still scaffold-level rather than a full real rendering path.

### What is not done yet

- `bridge/` is not yet a true submodule-managed root.
- There is no finalized `.gitmodules` workflow yet.
- `engine-chromium` is not yet providing real Chromium-rendered output through the Bridge backend contract.
- `client` still contains some transitional compile/link impurities.

---

## 1. Near-term strategic goal

The near-term goal is:

> Turn the current transitional split into a stable working workspace, then cross the next real technical milestone: make Chromium real enough inside the backend path that it stops being just a scaffold.

That means the next work should be split into two parallel tracks:

- **Track A — workspace/submodule formalization**
- **Track B — Chromium functionalization**

With one rule:

> Do not get distracted by broad custom-engine feature work until the Chromium path is materially more real.

---

## 2. Track A — Submodule/workspace formalization

### Objective

Make `bridge/` the real orchestration/meta repo and pin `client`, `engine-custom`, and `engine-chromium` as child submodules.

### Why this matters

Right now the architecture is conceptually correct, but the Git topology is still transitional.

We want the root repo to become:
- thin
- reproducible
- pin-based
- integration-oriented

We do **not** want `bridge/` to drift back into being a code-owning monorepo.

### Deliverables

- `.gitmodules` created in `bridge/`
- `client`, `engine-custom`, and `engine-chromium` registered as submodules
- root docs updated to reflect the actual submodule workflow
- root wrappers validated against submodule paths
- a clean bootstrap/update flow for fresh clones

### Concrete steps

#### A1. Clean the root repo into true meta-only shape

Make sure `bridge/` only owns:
- docs
- wrappers
- integration scripts
- `.gitmodules`
- submodule SHAs

Check for anything in root that should move elsewhere.

#### A2. Convert child repos into formal submodules

From the root workspace:
- add `client` as a submodule
- add `engine-custom` as a submodule
- add `engine-chromium` as a submodule

Use the real GitHub remotes now that they exist.

#### A3. Validate fresh-clone bootstrap workflow

A fresh workspace clone should work with a documented flow like:

```bash
git clone <bridge>
cd bridge
git submodule update --init --recursive
```

Then repo-local dependency bring-up remains owned by child repos.

#### A4. Add/update root helper flows

Root should provide convenience wrappers for:
- workspace status
- build by variant
- smoke tests
- submodule update/sync/bootstrap

### Exit criteria for Track A

Track A is done when:
- `bridge/` contains a working `.gitmodules`
- fresh clone + submodule init reproduces the first-party repo set cleanly
- root docs reflect the real workflow
- root remains orchestration-only

---

## 3. Track B — Chromium functionalization

### Objective

Turn the successfully built Chromium bring-up milestone into the first real Bridge-facing Chromium backend capability.

### Why this matters

We have already proven:
- Chromium can be owned in `engine-chromium`
- Chromium can be synced
- Chromium can be built

The next question is no longer “can we build Chromium?”

The next question is:

> What is the smallest honest integration step that makes the Chromium backend do real work through the Bridge renderer contract?

### Deliverables

- working validation of the built `headless_shell`
- documented behavior/artifact expectations for the Chromium path
- first real frame/content/state bridge from Chromium into `engine-chromium`
- meaningful improvement in the `blink` backend from scaffold → early functional backend

### Concrete steps

#### B1. Freeze and verify the known-good Chromium build state

Capture and preserve:
- exact revision
- GN args
- output dir metadata
- current known-good build command

Confirm these are all represented in:
- `engine-chromium/config/chromium.env`
- `out/browz-headless/args.gn`
- docs in `engine-chromium/BUILD.md`

#### B2. Exercise `headless_shell` directly

Do honest direct validation runs with the built binary.

Minimum checks:
- `--help`
- simple page load (`example.com` or a local file)
- see what output modes/artifacts it supports
- identify the cleanest possible way to extract rendered page results

This step is specifically about learning what the built Chromium target can practically provide.

#### B3. Choose the first real integration shape

Pick the narrowest real Bridge-facing integration target.

Candidate possibilities:
- image/screenshot/frame capture path
- DOM/content snapshot path
- navigation/load-state bridge
- headless output artifact ingestion into `BlinkBackend`

Rule:
- choose the smallest path that proves real Chromium work is happening
- avoid designing the final perfect embedder too early

#### B4. Implement the first real `engine-chromium` bridge

Use the results of B2/B3 to make `BlinkBackend` do at least one thing for real:
- real navigation through Chromium
- real frame/artifact capture
- real page/load/debug state propagated back to the client

Even if the first version is limited, it must be materially more real than the current placeholder frame path.

#### B5. Add tests/docs around the first real milestone

Once the first real Chromium behavior exists:
- update docs
- add narrow regression coverage where practical
- document limitations honestly

### Exit criteria for Track B

Track B is done when:
- `blink` backend is no longer just a placeholder/scaffold
- at least one real Chromium-produced output or state path flows through the renderer contract
- the new behavior is documented and reproducible

---

## 4. Track C — boundary cleanup after the first Chromium milestone

This is important, but second-order relative to Track B.

### Remaining cleanup items

#### C1. Stop `client` from compiling engine-owned custom sources directly

Desired end state:
- `engine-custom` exports stable library targets
- `client` links those targets cleanly
- direct `.cpp` compilation from sibling repos goes away

#### C2. Reduce `engine-chromium` dependence on `engine-custom` internals

Desired end state:
- `engine-chromium` is not leaning on `engine-custom` implementation details
- only shared interface/support code remains shared

#### C3. Formalize the engine API contract

Current location is acceptable for now:
- `client/src/renderer_api`

But it should be treated as:
- public
- stable-ish
- extractable later if needed

### Exit criteria for Track C

- `client` no longer compiles engine-owned `.cpp` files directly
- `engine-chromium` depends only on intentional shared API/support boundaries
- the client/engine contract is clearer and more maintainable

---

## 5. Recommended order of execution

This is the recommended near-term order.

### Phase 0 — Stabilize the current baseline

Do this first.

- commit/push the current workspace rename/build/test fixes
- make sure root docs and wrappers are in a sane state
- preserve the current known-good Chromium build metadata

### Phase 1 — Finish the Git topology

Do this next because the remotes now exist.

- add `.gitmodules`
- convert child repos into formal submodules
- validate fresh clone/bootstrap flow

### Phase 2 — Make Chromium more real

This is the main technical priority.

- validate `headless_shell`
- decide the narrowest first real integration path
- implement the first real Bridge-facing Chromium backend behavior

### Phase 3 — Clean boundary leaks

Only after Chromium has crossed the scaffold → real milestone.

- reduce compile/link impurities
- harden API ownership
- continue repo-local helper symmetry

---

## 6. What we should explicitly avoid right now

To keep focus, avoid these until the near-term goals above are met:

- broad new custom-engine feature work unrelated to Chromium integration
- large-scale renaming churn of every remaining historical symbol/string
- trying to design the final perfect Chromium embedder before proving the first real integration path
- letting the root repo accumulate required build/runtime artifacts

---

## 7. Definition of success for the near-term plan

We should consider the near-term plan successful when all of the following are true:

### Workspace / Git
- `bridge/` is the real thin meta repo
- child repos are formal submodules
- fresh clone/bootstrap is documented and reproducible

### Build / test
- `client` lanes remain green
- repo-local build helpers are consistent enough to use daily

### Chromium
- `engine-chromium` owns a stable known-good Chromium checkout/build state
- `blink` backend performs at least one real Chromium-backed behavior through the client/backend seam

### Architecture
- the split is no longer just structurally correct, but operationally disciplined

---

## 8. Immediate next actions

If starting now, do these in order:

1. Commit and push the current `bridge/client/engine-custom` build/test stabilization work.
2. Add `.gitmodules` and convert `client`, `engine-custom`, and `engine-chromium` into formal submodules under `bridge/`.
3. Validate the fresh workspace bootstrap path.
4. Freeze the known-good Chromium build metadata (`revision`, `args.gn`, config docs, backup notes).
5. Run direct `headless_shell` smoke checks and document exactly what artifacts/outputs it can provide.
6. Choose and implement the smallest honest first Chromium integration path into `BlinkBackend`.
7. After that lands, resume cleanup of the transitional compile/link boundaries.

---

## 9. Bottom line

We are no longer trying to prove the architecture is possible.

We have already proved:
- the split is possible
- the backend seam is possible
- the Chromium ownership boundary is possible
- the Chromium build is possible

The near-term mission now is to:
- formalize the workspace Git topology, and
- make Chromium real enough inside Bridge that it stops being just a scaffold.
