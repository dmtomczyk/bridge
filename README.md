# bridge

This directory is the **workspace/meta repo** for the split Bridge project.

## Naming note

The workspace/repo architecture is now named **Bridge**, while much of the browser-product-specific material in child repos still uses **BROWZ** as the product/browser name.

In practice:

- `bridge/` = workspace/meta repo
- `client/` = shell/app repo for the browser project
- `engine-custom/` = custom engine repo
- `engine-chromium/` = Chromium-backed engine repo
- `BROWZ` in historical docs/code usually refers to the browser product being split into this workspace structure

That naming cleanup is still in progress.

## Repositories

- `browser/` — the app/browser repo; owns the browser shell, chrome, navigation UX, diagnostics, and backend orchestration
- `engine-custom/` — the custom/native engine repo
- `engine-chromium/` — the Chromium-backed **reference** backend repo (headless/DevTools/screenshot bring-up path)
- `engine-cef/` — the active long-term Chromium backend target repo

> Submodules are pinned in this repo. After cloning, initialize them before build/test work:
>
> ```bash
> git submodule update --init --recursive
> ```

## What belongs at the workspace root

Only cross-repo coordination items should live here:

- workspace-level docs
- wrapper scripts
- integration/bootstrap helpers
- submodule metadata (eventually)
- migration/archive folders

This repo should **not** become an implementation monorepo again.

## Current workspace status

Today the split is real at the repository level, but still transitional at the implementation level.

- the child repos exist as separate sibling repos
- `browser` builds against `core`, `engine-custom`, `engine-chromium`, and `engine-cef` by sibling path
- the shell/backend seam is partially in place
- some engine behavior is still being migrated behind cleaner backend boundaries

So treat the workspace shape as established, while treating some internal repo boundaries as still under active cleanup.

## Architecture / workspace docs

- `WORKSPACE.md` — workspace purpose, ownership, and current migration notes
- `GIT.md` — repository topology, submodule strategy, and dependency-management plan
- `IDENTITY.md` — naming/identity decision guide
- `refactor.md` — current execution plan for the split/refactor
- `notes.md` — shell scope, renderer interface, and roadmap notes

## Common commands

### Quick start

Linux/macOS:

```bash
./bootstrap.sh
./scripts/status.sh
./compile.sh --engine custom --js off
./startbrowser.sh
```

Windows PowerShell:

```powershell
.\bootstrap.ps1
.\build.ps1 -Engine chromium -Js off

# CEF Windows preflight / smoke helper
$env:CEF_ROOT = 'C:\path\to\cef_binary_...'
.\scripts\windows-smoke-bootstrap.ps1 -PreflightOnly
.\scripts\windows-smoke-bootstrap.ps1

# or pass it explicitly
.\scripts\windows-smoke-bootstrap.ps1 -CefRoot C:\path\to\cef_binary_... -PreflightOnly
.\scripts\windows-smoke-bootstrap.ps1 -CefRoot C:\path\to\cef_binary_...
```

Prerequisites:
- CMake + C++ toolchain
- populated submodules (`core`, `browser`, `engine-custom`, `engine-chromium`, `engine-cef`)
- `xvfb-run` for smoke scripts that drive browser flows in headless CI/dev setups

Build from the workspace root with engine/JS selection:

```bash
./compile.sh --engine custom --js off
./compile.sh --engine custom --js v8
./compile.sh --engine chromium --js off
./compile.sh --engine all --js both
```

Windows PowerShell equivalents:

```powershell
.\build.ps1 -Engine custom -Js off
.\build.ps1 -Engine custom -Js v8
.\build.ps1 -Engine chromium -Js off
.\build.ps1 -Engine all -Js both
```

Notes:
- `./build.sh` now forwards to `./compile.sh` for backward compatibility.
- `./bootstrap.sh` / `./bootstrap.ps1` give you a cleaner first-run workspace setup than remembering raw submodule commands.
- `--engine` changes the default target/test focus, so you do not have to rebuild every engine/test combination every time.
- The current browser CMake graph still configures both engine repos during configure time, but root-level compile selection now keeps build/test execution focused.

Launch the client/browser app:

```bash
./startbrowser.sh
```

Check repo status:

```bash
./scripts/status.sh
```

Run the Chromium end-to-end smoke under Xvfb (launch app, trigger screenshot, verify session artifacts):

```bash
./scripts/chromium-e2e-smoke.sh
./scripts/chromium-e2e-smoke.sh https://example.com
```

Run the Chromium interaction/key/page-reaction smokes under Xvfb:

```bash
# Enter key reaches Chromium and the page reacts (title changes to key:Enter)
./scripts/chromium-input-smoke.sh

# Tab moves focus between elements and the page reacts (title changes to b)
./scripts/chromium-tab-smoke.sh

# Printable text reaches Chromium input/editing path and the page reacts (title changes to bridge)
./scripts/chromium-text-smoke.sh
```

Run the real-CEF runtime-host smoke lane (requires `CEF_ROOT` / `BRIDGE_CEF_ROOT`):

```bash
CEF_ROOT=/path/to/cef_binary_... ./scripts/cef-runtime-smoke.sh
CEF_ROOT=/path/to/cef_binary_... ./scripts/cef-runtime-smoke.sh 'data:text/html,<html><body>hi</body></html>'
```

Smoke-script notes:
- Run these scripts serially, not in parallel. They discover the newest `browser/artifacts/sessions/...` directory and will interfere with each other if launched at the same time.
- To target the `v8-on` browser instead of the default `v8-off` browser, set `BRIDGE_BUILD_DIR`:

```bash
BRIDGE_BUILD_DIR=./browser/build/v8-on ./scripts/chromium-e2e-smoke.sh https://example.com
BRIDGE_BUILD_DIR=./browser/build/v8-on ./scripts/chromium-input-smoke.sh
```

## Troubleshooting

- `CMake Error: .../browser does not appear to contain CMakeLists.txt`
  - Run `./bootstrap.sh` (or `git submodule update --init --recursive`) and verify `browser/` is populated.
- `ctest ... build dir ... does not exist`
  - Build first with `./compile.sh ...` and point smoke/test helpers to the expected build directory.
- V8 mode (`--js v8`) fails due to missing includes/libs
  - Set `--v8-include` and `--v8-lib`, or provide `BRIDGE_V8_INCLUDE_DIR` / `BRIDGE_V8_LIBRARY_DIR`.
- Real CEF smoke lane fails to locate CEF
  - Export `CEF_ROOT` (or `BRIDGE_CEF_ROOT`) before running `./scripts/cef-runtime-smoke.sh`.
- Windows helper reports missing `cl` / `link` / `ninja` / CEF files
  - Run `./scripts/windows-smoke-bootstrap.ps1 -PreflightOnly` in PowerShell if `CEF_ROOT` or `BRIDGE_CEF_ROOT` is already set, or pass `-CefRoot C:\path\to\cef_binary_...` explicitly to get a dependency report with fix hints before building.
