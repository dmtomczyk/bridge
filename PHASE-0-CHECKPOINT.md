# PHASE-0-CHECKPOINT.md

Phase 0 local checkpoint for the `bridge` workspace.

Date:
- 2026-04-04

## Purpose

Freeze the current known-good split-workspace baseline before Phase 1 submodule conversion.

## First-party repo matrix

- `bridge` — root/meta checkpoint commit created in Phase 0 (see `git rev-parse HEAD`)
- `client` — `383c777f74a38f61227c3a83beeb9d34cb1b68c6`
- `engine-custom` — `f1850e6944dcdd23cd67d9af50d4f20660ed7662`
- `engine-chromium` — `b1114c819074aecc967de79f6fe96a123f5ea0e6`

## Validation status

### Client test lanes

Validated from `~/code/foss/bridge/client`:

- `ctest --test-dir build/v8-off --output-on-failure`
  - result: `21/21` passing
- `ctest --test-dir build/v8-on --output-on-failure`
  - result: `24/24` passing

## Chromium known-good metadata

### Chromium checkout revision

- `engine-chromium/third_party/src` revision:
  - `9a91367675bf2aaf813385e17ab9043f0503f067`

### Current known-good output target

- `engine-chromium/third_party/src/out/browz-headless/headless_shell`

### Current args.gn

```gn
import("//build/args/headless.gn")
is_debug = false
symbol_level = 0
blink_symbol_level = 0
is_component_build = false
dcheck_always_on = false
use_sysroot = false
use_remotexec = false
treat_warnings_as_errors = false
```

## Notes

- The root `bridge/` repo is still transitional at this checkpoint.
- `.gitmodules` does not exist yet.
- Child repos now have real remotes and local baseline commits, so Phase 1 can focus on submodule formalization instead of rescue work.
- Ignore hygiene was tightened so heavyweight dependency trees are not accidentally swept into first-party commits:
  - `engine-custom`: ignore `third_party/v8/`, `third_party/depot_tools/`, and sync artifacts while keeping vendored `third_party/lexbor/` in the repo baseline
  - `engine-chromium`: ignore `third_party/src/`, sync artifacts, and backups
