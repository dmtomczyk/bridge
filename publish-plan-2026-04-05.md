# Publish plan

_Date: 2026-04-05_

This note groups the current local-only commit stacks into sensible publish batches.

## Goal

Avoid publishing a giant undifferentiated blob.

Preferred order:
1. push child repos first
2. then push root submodule-pointer updates and workspace/docs batches

## Current local-only shape

### `engine-custom`
Small, safe doc batch:
- `cc0e4f4` — `Add engine-custom build quickstart`
- `2253fbf` — `Clarify engine-custom role in split architecture`

### `engine-chromium`
Small, safe doc batch:
- `7ffc184` — `Clarify reference-only role of engine-chromium`

### `engine-cef`
Large, meaningful runtime/presentation stack plus cleanup:
- `1e6b07a` — `Split runtime host config from proof CLI`
- `a2015d8` — `Add reusable engine-cef runtime entry helper`
- `b9d649c` — `Add minimal engine-cef runtime host wrapper`
- `c3249fe` — `Add runtime integration checkpoint note`
- `f06bf68` — `Define runtime integration boundary v1`
- `d7abf90` — `Make runtime host the real proof entry path`
- `b338088` — `Add runtime host observer guardrail and probe`
- `8b4695b` — `Add runtime host status and readiness observer`
- `921bbd4` — `Align Linux GTK OSR bootstrap with upstream`
- `009c755` — `Improve engine-cef runtime failure reporting`
- `c6b59ab` — `Add runtime host status transition regression test`
- `bddc0d3` — `Clarify staging lane in runtime boundary note`
- `6a35e76` — `Ignore build-cef output`
- `883d9d5` — `Add minimal engine-cef CI workflow`
- `ac39233` — `Add engine-cef build quickstart`

### `client`
Large CEF destination-lane/runtime-handoff stack plus cleanup:
- `8523d2a` — `Expose bridge presentation metadata in client debug path`
- `ffc7d19` — `Log bridge frame activation in client runtime`
- `4740a8a` — `Add client runtime host smoke test`
- `75487c5` — `Add client runtime host attach seam`
- `8173852` — `Add client runtime probe executable`
- `f26e740` — `Add browser launcher path for CEF runtime probe`
- `26c2be2` — `Document and enforce CEF runtime lane split`
- `96f0152` — `Unify client CEF attach contract`
- `42ef388` — `Add runtime-host attach metadata test for CEF adapter`
- `43a6594` — `Expose runtime-host status in CEF adapter debug`
- `5085d8c` — `Surface adapter runtime metadata in app logging`
- `9f538f7` — `Document CEF lanes in client launcher help`
- `6e6d1b9` — `Add minimal client CI workflow`
- `0ba181f` — `Mark historical Blink-era docs more clearly`
- `d2635f0` — `Rewrite client architecture doc for CEF split reality`

### `bridge` root
Large set of pointer updates plus workspace/docs/CI cleanup:
- many submodule-pointer commits capturing the runtime-host / client integration work
- workspace doc truth passes
- cleanup checklist
- root integration workflow
- root CEF smoke helper
- wrapper-script refreshes

## Recommended push order

### Batch A — safe doc/hygiene repos first
1. push `engine-custom`
2. push `engine-chromium`

These are low-risk and reduce ambiguity quickly.

### Batch B — `engine-cef` runtime-host stack
Push `engine-cef` as one coherent runtime-boundary/runtime-host batch.

Reason:
- the commits form a clear story
- tests/probes/quickstart/CI all reinforce the same lane
- splitting too finely risks publishing intermediate weirdness

### Batch C — `client` CEF handoff/destination-lane stack
Push `client` after `engine-cef`.

Reason:
- client commits depend conceptually on the richer engine-cef runtime/attach story
- destination-lane docs/tests/debugging will read better once engine-cef is already published

### Batch D — root workspace/meta repo
Push root last.

Reason:
- root should point at already-published child commits
- root workflows/docs/wrappers should describe repo states that exist remotely

## Suggested root publish shape

Before pushing root, consider squashing or at least grouping root commits into a smaller number of logical batches:

1. child pointer updates for runtime-host / destination-lane work
2. cleanup checklist + doc truthfulness
3. CI/workflow additions
4. wrapper-script / root smoke helper updates

## Pre-push checks

Before any push wave:
- verify each child repo has the intended remote/branch
- re-run the focused validation commands you care about most
- verify root submodule pointers match the child commits you intend to publish
- decide whether any local-only exploratory commits should stay unpublished

## Plain-English summary

Push the child repos first.

- `engine-custom` / `engine-chromium` docs
- `engine-cef` runtime-host stack
- `client` handoff/destination-lane stack
- then root/meta repo last

That is the least confusing publication path from the current local state.
