# bridge workspace notes

## Purpose

`~/code/foss/bridge/` is the parent workspace/meta repo for four sibling repositories:

- `client`
- `engine-custom`
- `engine-chromium`
- `engine-cef`

See also:
- `README.md` — quick workspace orientation
- `GIT.md` — source-code/dependency management architecture and recommended submodule topology
- `IDENTITY.md` — naming system decision guide

## Ownership

### client
Owns:
- application/client layer
- browser chrome and navigation UX
- session/debug/tooling surfaces
- current renderer/engine API contract (transitional home)
- backend/engine factory and selection
- end-to-end tests/benchmarks/examples

### engine-custom
Owns:
- DOM/parser/style/layout/paint/js/loader
- `CustomBackend` / custom engine implementation
- Lexbor/V8-related custom-engine dependencies

### engine-chromium
Owns:
- Chromium-backed reference engine adapter
- Chromium/Blink bring-up and engine plumbing for the headless/DevTools reference path
- reference/demo backend maintenance

### engine-cef
Owns:
- active long-term Chromium backend bootstrap and integration work
- CEF binary-distribution bring-up
- future shell/backend migration away from the screenshot reference path

## Current migration status

- split repo skeletons exist and build together
- `client` builds against sibling `engine-custom` and `engine-chromium`
- focused split-build tests already pass for custom/chromium engine seams
- the first split-only client regression (`application_interaction_test`) was traced to an SDL compile-definition leak and fixed
- Chromium checkout/bootstrap is now owned under `engine-chromium/third_party/src`

## Archive policy

Old root-level monorepo content was moved to:
- `_archive/root-pre-split-cleanup-2026-04-03/`

Additional historically useful but non-active planning/proof material may be moved under:
- `historical/`

The goal is to preserve context without cluttering the active workspace root.
