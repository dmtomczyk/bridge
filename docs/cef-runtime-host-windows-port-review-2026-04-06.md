# CEF runtime-host Windows port review — 2026-04-06

This note captures the targeted architecture review of the current `engine-cef` runtime-host path, with the specific goal of identifying what in `cef_app_host.*` and `cef_browser_handler.*` is already shared enough for Windows, what is still Linux/GTK-coupled, and what the first host seam needs to cover.

Reviewed files:
- `engine-cef/src/cef_app_host.h`
- `engine-cef/src/cef_app_host.cc`
- `engine-cef/src/cef_browser_handler.h`
- `engine-cef/src/cef_browser_handler.cc`
- `engine-cef/src/cef_osr_host_gtk.h`
- `engine-cef/src/cef_osr_host_gtk.cc`

---

# 1. High-level conclusion

The current runtime-host lane is **not** a tiny Linux adapter wrapped around a shared engine core.

It is closer to this:
- `CefAppHost` = mostly shared browser/runtime orchestration, but directly constructs and drives the GTK host
- `CefBrowserHandler` = mostly shared browser/tab/runtime behavior, but directly talks to the GTK host and still contains some Linux/GTK-specific platform work
- `CefOsrHostGtk` = thick Linux platform host implementation, including native windowing, input routing, chrome drawing, address bar UI, tab strip UI, frame presentation, and shortcut handling

So the right Windows path is **not** “port `CefOsrHostGtk` later.”
The right Windows path is:
- keep the shared browser/runtime pieces
- replace direct `CefOsrHostGtk` coupling with a host interface
- then implement a Windows host against that interface

---

# 2. What in `CefAppHost` is genuinely shared

`CefAppHost` already owns a lot of browser/runtime behavior that should remain shared:

## Shared launch/runtime state
- `CefLaunchConfig`
- initial URL selection
- home/default-new-tab selection
- OSR vs native/view mode branching at a high level
- bridge/backend initialization

## Shared tab/session behavior
- tab creation bookkeeping
- active-tab tracking
- tab activation
- next/previous tab cycling
- close tab / close active tab
- reopen closed tab
- closed-tab stack retention policy
- startup validation/dev tab hooks

## Shared browser-product behavior
- popup request routing into new-tab creation
- startup/new-tab behavior via `DefaultNewTabUrl()`
- page-kind-aware reopen logic

These are exactly the kinds of things that should stay shared across Linux and Windows.

---

# 3. What in `CefAppHost` is still Linux/GTK-coupled today

The coupling is not about the tab model itself.
It is about host ownership.

## Direct GTK host dependency in the public shape
`cef_app_host.h` currently includes:
- `cef_osr_host_gtk.h`

and stores:
- `std::unique_ptr<CefOsrHostGtk> osr_host_{}`

That means the central runtime orchestrator is hard-wired to the Linux host type.

## Direct Linux-host construction
When OSR is enabled, `CreateInitialBrowser()` does this:
- constructs `CefOsrHostGtk`
- calls `Initialize()`
- treats failure as “Failed to initialize GTK/X11 OSR host”
- wires tab callbacks directly onto the GTK host
- passes `osr_host_->parent_handle()` into `SetAsWindowless(...)`

## Direct host-owned UI sync
`SyncTabUi()` currently builds `CefOsrHostGtk::TabUiItem` values and calls:
- `SetTabStatus(...)`
- `SetTabStripItems(...)`

That means even the shared tab-state synchronization path is currently typed in terms of the GTK host UI contract.

### Conclusion
`CefAppHost` is architecturally close to shared, but it still needs to be retargeted from:
- a concrete GTK host type

to:
- a host interface + host-agnostic tab UI data model

---

# 4. What in `CefBrowserHandler` is genuinely shared

`CefBrowserHandler` is farther along than it may first appear.
A lot of important behavior here should remain shared between Linux and Windows.

## Shared browser state tracking
- current URL
- current title
- loading state
- back/forward capability
- load error text
- page-kind transitions
- last rendered frame cache
- browser list / close lifecycle bookkeeping

## Shared runtime/browser behavior
- main-frame address observation
- title observation
- popup handling policy
- tab/popup disposition logic
- load-end/load-error behavior
- close-all-browsers snapshot fix
- frame observation into backend/bridge
- active-tab hydration behavior

## Shared CEF render-host responsibilities
The following handler methods conceptually belong to a platform-agnostic runtime/browser layer, even if they need host callbacks:
- `OnAddressChange`
- `OnTitleChange`
- `OnBeforePopup`
- `OnAfterCreated`
- `DoClose`
- `OnBeforeClose`
- `OnLoadingStateChange`
- `OnLoadError`
- `OnPaint`
- view/screen rect callbacks

These methods should not have to know whether the host is GTK or Win32.

---

# 5. What in `CefBrowserHandler` is still Linux/GTK-coupled today

## Direct host type dependency
`cef_browser_handler.h` currently includes:
- `cef_osr_host_gtk.h`

and stores:
- `CefOsrHostGtk* osr_host_ = nullptr;`

That is the biggest structural coupling.

## OSR host callback coupling
The handler currently directly calls GTK host methods such as:
- `NotifyBrowserCreated(...)`
- `NotifyBrowserClosing(...)`
- `SetCurrentUrl(...)`
- `SetWindowTitle(...)`
- `SetLoadingState(...)`
- `SetLoadError(...)`
- `PresentFrame(...)`
- `GetRootScreenRect(...)`
- `GetScreenPoint(...)`
- `GetScreenInfo(...)`
- `GetViewRect(...)`

These should be redirected through a host interface.

## GTK file dialog implementation embedded in handler
`OnFileDialog(...)` currently contains GTK-native file chooser logic under `CEF_X11`.

That almost certainly should not stay inside a supposedly shared browser handler.
Either:
- file dialog support moves behind the host interface
- or it becomes a platform callback/utility owned by platform host code

## Linux-only external open behavior
`TryOpenExternally(...)` currently uses `xdg-open` on Linux.
That is a platform operation and should not remain hardcoded in shared browser/runtime code.

## Minor platform-path behavior still embedded here
The download directory fallback and some shell/process assumptions are still closer to platform behavior than shared browser semantics.
Those are smaller than the host coupling problem, but still worth classifying as platform-owned over time.

---

# 6. What `CefOsrHostGtk` clearly owns today

The GTK host is a thick platform implementation.
It currently owns:
- GTK window creation/destruction
- X11 parent handle resolution
- drawing area setup
- native event hookup
- native key/mouse/wheel translation
- address bar UI and editing behavior
- tab strip drawing and hit testing
- browser chrome drawing
- scroll handling/pacing details
- browser action execution for runtime-host UI
- OSR frame presentation into the native surface
- screen/view rect reporting

This is exactly the kind of platform-specific host code that should remain host-owned.
A future Windows host will need a comparable implementation, not a fake shim.

---

# 7. Immediate refactor implications

## A. `CefAppHost` should stop naming GTK host types
The first structural step is to remove direct `CefOsrHostGtk` ownership from `CefAppHost` and replace it with a host abstraction.

## B. `CefBrowserHandler` should stop naming GTK host types
The browser handler should depend on a host-facing interface, not on a GTK implementation class.

## C. Tab-strip/status payloads should become host-agnostic
`CefOsrHostGtk::TabUiItem` should not be the type shared runtime code depends on.
A neutral host/UI payload type should live outside the GTK host implementation.

## D. File dialogs and external URL handoff are platform services
These should move behind host callbacks or platform utility seams.

---

# 8. Recommended classification of responsibilities

## Shared runtime/browser core
Keep here:
- launch config
- page-kind semantics
- tab creation/activation/close/reopen logic
- popup policy
- current URL/title/loading state tracking
- frame caching and backend/bridge observation
- browser close lifecycle bookkeeping
- browser action meaning where appropriate

## Host interface layer
Expose hooks for:
- native host initialization
- windowless parent handle access
- browser attach/detach notification
- frame presentation
- title/url/loading/error hydration
- geometry/screen information
- tab-strip/status UI hydration
- platform services such as file dialog/external-open where needed

## Linux host implementation
Keep here:
- GTK/X11 windowing
- drawing area and Cairo drawing
- native event processing
- tab strip and address bar presentation/hit testing
- Linux-specific shortcut/input mapping
- Linux-specific file dialogs and shell handoff behavior

## Windows host implementation
Future equivalent to Linux host:
- Win32/native windowing
- OSR surface presentation
- Windows input/event translation
- Windows-native dialogs/shell handoff behavior
- browser chrome/tab-strip UI implementation on Windows

---

# 9. Bottom line

The code review confirms that the project is already closer to a real multi-OS architecture than it may feel.
The browser/runtime semantics are mostly in the right place.

The real missing piece is not “invent browser behavior for Windows.”
The real missing piece is:

> replace direct GTK host coupling with a small host seam, then implement that seam on Windows.

That is the correct next step for the Windows port.
