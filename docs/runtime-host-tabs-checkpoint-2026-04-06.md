# Runtime-host tabs checkpoint — 2026-04-06

This note captures the first tabbed runtime-host checkpoint after the visible strip and popup/new-window policy work landed.

## What landed

On the official client/runtime-host lane (`browser/build/cef-hybrid-real/browser --renderer=cef-runtime-host`), BRIDGE now has:

- a minimal visible tab strip in the GTK/OSR host
- active/inactive tab visuals
- click-to-switch tabs
- close button in the strip
- new-tab `+` button
- `Ctrl+Tab` / `Ctrl+Shift+Tab` tab cycling from the earlier model slice
- popup/new-window requests with meaningful URLs preferring internal tab creation
- blank / junk / `javascript:` popup blocking

## Important validation gotcha

The first successful visual smoke happened in standalone `engine_cef_proof`, but normal startup did not show the tab strip until the client-side `cef-hybrid-real` build was rebuilt.

The key lesson:

- rebuilding `engine-cef/build-cef` is **not enough** to validate the official runtime-host browser lane
- the official lane re-execs into `client_cef_runtime_browser`
- that binary links the client build-tree copy of `engine_cef_runtime_host`

So future validation for runtime-host UI changes should explicitly rebuild and test:

```bash
cmake --build ~/code/foss/bridge/browser/build/cef-hybrid-real -j4 --target browser client_cef_runtime_browser
./browser/build/cef-hybrid-real/browser --renderer=cef-runtime-host <url>
```

## Stability hardening added after first smoke

After the initial tab strip work, a crash report came in during close churn / middle-mouse use with many tabs open.

The first hardening pass added:

- host ownership handoff to a neighbor before closing the active tab
- explicit clearing of the bound OSR browser when the active browser is closing
- swallowing middle mouse in the tab-strip chrome area instead of forwarding it ambiguously during close churn
- tab-strip double/triple-click suppression in the GTK hit path

A later, more important close crash turned out to be a classic container-mutation bug in `CefBrowserHandler::CloseAllBrowsers(bool)`: the code was iterating `browser_list_` while `CloseBrowser(...)` callbacks could synchronously/reentrantly mutate that same list via close handlers. The fix was to snapshot `browser_list_` into a temporary vector first, then iterate the snapshot.

## BRIDGE Home follow-up

The first internal BRIDGE Home implementation used generated data URLs inside `engine-cef`. That path caused rendering weirdness and was strongly correlated with close-crash reproduction.

The implementation was moved to a browser-owned file-backed asset:

- `browser/assets/bridge-home.html`

The client runtime browser now resolves it to a `file://` URL and passes that through launch config as `home_url`, while `engine-cef` simply consumes the configured home/new-tab URL.

A later follow-up refactor also stopped using raw URL string equality as the main special-case discriminator. Tabs now carry explicit page metadata (`CefTabPageKind`), and that page-kind is updated dynamically on main-frame address change so a tab that starts as BRIDGE Home but navigates to Google becomes `normal` instead of staying permanently tagged as the home page. That fix restored `Ctrl+Shift+T` for normal sites opened from home-born tabs.

## Logging / cleanup done in the same slice

- removed temporary tab-strip click logging once the strip was verified
- reduced secondary-process session logger noise in `client_cef_runtime_browser`
- updated the GTK pointer/modifier query to the newer seat/pointer API
- removed temporary stderr instrumentation that was only needed to diagnose the close/reopen regressions

## Current state

The runtime-host path now feels like a real minimal tabbed browser shell rather than a single-page proof window with hidden tab state.

It is still intentionally minimal.

Notable missing polish / likely follow-ups:

- more keyboard shortcuts (`Ctrl+T`, `Ctrl+W`, `F5`, `Ctrl+R`)
- close-active-tab behavior polish under more edge cases
- tab overflow / clipping polish
- broader popup/new-window real-site sweeps
- dedicated middle-click semantics if we decide to support them on tab strip items or links more explicitly

## Next discussion topic

Next intended topic after this checkpoint: keyboard shortcuts, especially:

- `Ctrl+T`
- `Ctrl+W`
- `F5` / `Ctrl+R`
- `Ctrl+Tab`
