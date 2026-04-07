# Current architecture overview

_Date: 2026-04-05_

This document is the current high-level architecture overview for the split Bridge workspace after the CEF pivot.

It is meant to answer four questions quickly:

1. What repos exist and what do they own?
2. What is the long-term destination lane?
3. What is the staging/runtime-host lane?
4. How do the shell, adapter, bridge, runtime host, and engine repos coordinate today?

For more detailed seam documents, also see:
- `../GIT.md`
- `../WORKSPACE.md`
- `../browser/docs/architecture.md`
- `../browser/docs/cef-runtime-lanes.md`
- `../browser/docs/cef-attach-seam.md`
- `../engine-cef/docs/runtime-integration-boundary-v1.md`
- `../engine-cef/docs/client-integration-bridge.md`
- `../engine-cef/docs/presentation-seam-v2.md`

---

## 1. Workspace / repo topology

```mermaid
flowchart TD
    subgraph WS["Workspace layer"]
        W["bridge\nworkspace / meta repo"]
    end

    subgraph FP["First-party repos"]
        C["client\nshell / app / backend selection"]
        EC["engine-custom\ncustom backend implementation"]
        ECH["engine-chromium\nreference Chromium backend"]
        ECEF["engine-cef\nactive long-term Chromium backend"]
    end

    subgraph API["Shared contract"]
        EAPI["client/src/engine_api\ncurrent shared engine/backend API"]
    end

    subgraph EXT["External dependency ownership"]
        CUSTOM_DEPS["Lexbor / V8\nowned by engine-custom"]
        CHROMIUM_DEPS["Chromium checkout / headless_shell / DevTools path\nowned by engine-chromium"]
        CEF_DEPS["CEF binary distribution / runtime glue\nowned by engine-cef"]
    end

    W -->|"pins submodule SHAs"| C
    W -->|"pins submodule SHAs"| EC
    W -->|"pins submodule SHAs"| ECH
    W -->|"pins submodule SHAs"| ECEF

    C --> EAPI
    EC --> EAPI
    ECH --> EAPI
    ECEF --> EAPI

    EC --> CUSTOM_DEPS
    ECH --> CHROMIUM_DEPS
    ECEF --> CEF_DEPS
```

### Repo roles

- `bridge/`
  - workspace/meta repo
  - submodule pointers
  - root docs, wrappers, integration workflows
- `client/`
  - shell/app repo
  - backend selection
  - backend-facing diagnostics and tests
- `engine-custom/`
  - in-house/custom backend implementation
- `engine-chromium/`
  - older Chromium-backed **reference/demo** backend lane
- `engine-cef/`
  - active long-term Chromium backend target

---

## 2. The two CEF-related lanes

The current architecture intentionally distinguishes two CEF-related lanes.

```mermaid
flowchart LR
    START["User / developer chooses a CEF-related path"]

    subgraph DEST["Destination lane: normal shell/backend path"]
        D1["browser --renderer=cef"]
        D2["backend factory selects renderer=cef"]
        D3["CefBackendAdapter"]
        D4["shell/backend contract remains in charge"]
    end

    subgraph STAGE["Staging lane: runtime-host bring-up path"]
        S1["browser --cef-runtime-probe"]
        S2["browser_cef_runtime_probe"]
        S3["attach_cef_runtime_host(...)"]
        S4["CefRuntimeHost validation / first-frame checks"]
    end

    START -->|"normal app/backend selection"| D1 --> D2 --> D3 --> D4
    START -->|"explicit runtime-host validation"| S1 --> S2 --> S3 --> S4
```

### Destination lane

This is the long-term architectural destination.

Examples:
- `browser --renderer=cef`
- `CreateRendererBackend("cef")`
- `CefBackendAdapter`

Characteristics:
- the shell stays in charge
- `renderer=cef` remains a backend under the shell/backend contract
- this lane is still hybrid today
- this is the lane that should mature over time

### Staging lane

This is a deliberate runtime-host bring-up/diagnostic lane.

Examples:
- `attach_cef_runtime_host(...)`
- `browser_cef_runtime_probe`
- `browser --cef-runtime-probe`
- `engine_cef_runtime_host_probe`

Characteristics:
- directly exercises `CefRuntimeHost`
- useful for Linux OSR/bootstrap/first-frame validation
- intentionally narrow and opt-in
- should remain distinct from the normal shell/backend path until deeper ownership changes are chosen on purpose

### Core rule

- `--renderer=cef` = destination lane
- `--cef-runtime-probe` = staging lane

The architecture should continue to reinforce that distinction.

---

## 3. Destination lane coordination

This is the current long-term lane: the shell selects a backend, and the CEF path is carried under the backend contract.

```mermaid
flowchart TD
    USER["User runs browser --renderer=cef"]

    subgraph SHELL["Client shell"]
        MAIN["client main / launcher"]
        APP["Application"]
        FACTORY["CreateRendererBackend('cef')"]
    end

    subgraph CLIENT_CEF["Client CEF destination-lane objects"]
        ADAPTER["CefBackendAdapter"]
        ATTACH["attach_cef_bridge()\nor richer CEF attach result"]
    end

    subgraph ECEF_LANE["engine-cef public contract"]
        BRIDGE["integration bridge"]
        SNAP["backend snapshot + load/page state"]
        PRESENT["presentation-v2 frame state"]
    end

    subgraph TRANSITIONAL["Current hybrid / transitional pieces"]
        FALLBACK["custom-backend fallback\nfor remaining draw/runtime/input pieces"]
    end

    subgraph OBS["Observability"]
        DEBUG["adapter debug snapshot"]
        HUD["Application backend logging / HUD"]
    end

    USER --> MAIN --> APP --> FACTORY --> ADAPTER
    ADAPTER --> ATTACH --> BRIDGE
    BRIDGE --> SNAP
    BRIDGE --> PRESENT
    ADAPTER --> FALLBACK
    ADAPTER --> DEBUG --> HUD
    BRIDGE --> DEBUG
```

### Current truth of the destination lane

Today `renderer=cef` is **not** a fully native CEF-owned browser shell.

It is a hybrid backend path where:
- the shell remains in charge
- the adapter consumes the public `engine-cef` contract
- bridge/presentation/frame/debug metadata can already flow into the shell/backend observability path
- some draw/runtime/input behavior still contains transitional borrowing from the custom backend

That is intentional. The goal is to make the destination lane more truthful over time without pretending the migration is finished.

---

## 4. Staging lane coordination

This is the runtime-host validation lane.

```mermaid
flowchart TD
    USER["User runs browser --cef-runtime-probe"]

    subgraph CLIENT_STAGE["Client staging lane"]
        LAUNCH["browser launcher"]
        DISPATCH["exec into browser_cef_runtime_probe"]
        ATTACH["attach_cef_runtime_host(...)"]
        HOST["CefRuntimeHost"]
    end

    subgraph HOST_RUNTIME["Runtime-host seam"]
        RUN["host.Run(...)"]
        BRIDGE["host bridge"]
        OBS["runtime observer + bridge observer"]
        READY["first_frame_ready"]
        QUIT["RequestQuit()"]
    end

    subgraph ENGINE_STAGE["engine-cef runtime-host lane"]
        RUNNER["CefLinuxMainRunner / runtime host"]
        BACKEND["engine-cef backend / presentation"]
    end

    USER --> LAUNCH --> DISPATCH --> ATTACH --> HOST --> RUN
    HOST --> BRIDGE
    HOST --> OBS
    RUN --> RUNNER --> BACKEND
    BACKEND --> BRIDGE
    BACKEND --> READY --> QUIT
```

### Current truth of the staging lane

This lane exists to validate:
- runtime bootstrap
- OSR first-frame readiness
- runtime-host lifecycle
- bridge/snapshot observation

It is useful and real, but it is **not** the same thing as saying the normal shell/backend lane is already complete.

---

## 5. Runtime-boundary ownership today

The current runtime boundary is intentionally small.

```mermaid
flowchart LR
    CALLER["non-proof caller"]
    HOST["CefRuntimeHost"]
    CONFIG["CefRuntimeEntryConfig"]
    RUNNER["CefLinuxMainRunner"]
    BRIDGE["integration bridge"]
    STATUS["CefRuntimeStatus"]
    SNAP["BackendSnapshot / PresentationState"]

    CALLER -->|"constructs / configures"| HOST
    CALLER --> CONFIG
    CONFIG --> HOST
    HOST -->|"Run()"| RUNNER
    HOST -->|"bridge()"| BRIDGE
    HOST -->|"runtime_status()"| STATUS
    BRIDGE --> SNAP
    SNAP --> STATUS
```

### Runtime-boundary rules

For now:
- caller owns `CefRuntimeHost`
- caller does **not** own `CefAppHost` directly
- readiness is first-frame based
- `Run(...)` is still blocking
- async runtime-manager ownership is not yet the architecture

That runtime boundary is a staging/runtime-host seam, not yet the final shell/app ownership model.

### Runtime phase model

```mermaid
stateDiagram-v2
    [*] --> idle
    idle --> running
    running --> first_frame_ready
    running --> failed
    first_frame_ready --> stopped
    first_frame_ready --> failed
    stopped --> [*]
    failed --> [*]
```

---

## 6. Current observability flow

One of the important improvements in the current architecture is that richer CEF/debug metadata now reaches the shell-visible path.

```mermaid
flowchart LR
    subgraph ENGINE_STATE["Engine / runtime-derived state"]
        B1["bridge snapshot"]
        B2["presentation metadata"]
        B3["optional host runtime status"]
    end

    subgraph ADAPTER_STATE["Client adapter debug state"]
        A1["frame-source"]
        A2["bridge-presentation"]
        A3["attach-kind / attach-host"]
        A4["attach-runtime phase / error"]
    end

    subgraph APP_STATE["App-visible diagnostics"]
        APPLOG["Application backend logging"]
        HUD["HUD / debug view"]
    end

    USER["developer / operator"]

    ENGINE_STATE --> ADAPTER_STATE --> APP_STATE --> USER
```

Examples of metadata now visible in the destination lane:
- `frame-source ...`
- `bridge-presentation ...`
- `attach-kind ...`
- `attach-host present=...`
- `attach-runtime phase=... saw_first_frame=... exit=...`
- `attach-runtime error=...`

That means the destination lane can get richer and more honest before the project commits to deeper runtime-host ownership changes.

---

## 7. Coordination summary: destination lane vs staging lane

```mermaid
flowchart LR
    subgraph DEST["Destination lane"]
        D1["browser --renderer=cef"]
        D2["Application"]
        D3["CefBackendAdapter"]
        D4["engine-cef bridge / snapshots / presentation"]
    end

    subgraph STAGE["Staging lane"]
        S1["browser --cef-runtime-probe"]
        S2["browser_cef_runtime_probe"]
        S3["CefRuntimeHost"]
        S4["engine-cef runtime host / first-frame validation"]
    end

    D1 --> D2 --> D3 --> D4
    S1 --> S2 --> S3 --> S4

    D3 -. "may carry host-backed attach metadata" .-> S3
    S4 -. "validates runtime seam\nwithout redefining app ownership" .-> D4
```

### What this means

- the destination lane is where the long-term architecture should mature
- the staging lane is where runtime-host/bootstrap validation happens
- the two lanes are related, but they should not be collapsed into one thing prematurely

---

## 8. What is long-term destination vs current staging tool?

### Long-term destination

- one shell/app repo
- multiple backend repos
- `renderer=cef` becoming a proper backend under the shell/backend contract
- `engine-cef` carrying the active long-term Chromium integration work

### Current staging tools

- `attach_cef_runtime_host(...)`
- `browser_cef_runtime_probe`
- `browser --cef-runtime-probe`
- `engine_cef_runtime_host_probe`

These are valuable, but they are staging/diagnostic tools, not the final app architecture.

---

## 9. Official browser runtime wireframes

The diagrams above explain the historical split between destination lane and staging lane.

The two diagrams below answer a slightly different question:

- when the **official/main** browser is running today,
- what are the runtime layers inside it,
- and how does it interface with the operating system?

For this section, the official/main browser pairing means:

- `browser --renderer=cef-runtime-host`

That is the current proof/production-direction path for the live interactive browser.

### 9.1 Official browser internal runtime layers

```mermaid
flowchart TD
    USER["User"]

    subgraph NATIVE["Native desktop shell / window manager"]
        WM["window manager / task switcher / app icon / title bar"]
    end

    subgraph CLIENT["bridge-client (official runtime entry)"]
        MAIN["main.cpp launcher"]
        ROUTE["renderer=cef-runtime-host\nre-exec into browser_cef_runtime_browser"]
        SESSION["session logger / stdout+stderr / perf logs"]
    end

    subgraph RUNTIME_BROWSER["browser_cef_runtime_browser"]
        BROWSER_MAIN["cef_runtime_browser_main.cpp"]
        ATTACH["attach_cef_runtime_host(config)"]
        HOST["CefRuntimeHost"]
        OBS["runtime observer\nstatus + first-frame events"]
    end

    subgraph ENGINE_CEF["engine-cef runtime-host lane"]
        RUN["host.Run(argc, argv)"]
        RUNNER["CefLinuxMainRunner\nCEF bootstrap + message loop"]
        APPHOST["CefAppHost / CefBrowserHandler"]
        OSR["CefOsrHostGtk\nwindow + paint + input forwarding"]
        BRIDGE["integration bridge / BackendSnapshot / PresentationState"]
    end

    subgraph WEB["Web/content side"]
        NET["network fetch / real websites"]
        DOM["Chromium/CEF page runtime"]
    end

    USER --> WM --> MAIN --> ROUTE --> BROWSER_MAIN
    BROWSER_MAIN --> SESSION
    BROWSER_MAIN --> ATTACH --> HOST --> OBS
    HOST --> RUN --> RUNNER --> APPHOST
    APPHOST --> OSR
    APPHOST --> BRIDGE
    APPHOST --> DOM --> NET
    BRIDGE --> OBS
    OSR --> WM

    DOM -. page title / page URL / load state .-> APPHOST
    APPHOST -. first frame / paint buffers .-> OSR
    APPHOST -. snapshots / presentation metadata .-> BRIDGE
```

### 9.2 Official browser ↔ operating system interface layers

```mermaid
flowchart LR
    subgraph APP["BRIDGE application layer"]
        ENTRY["browser_cef_runtime_browser"]
        HOST["CefRuntimeHost"]
        HANDLER["CefBrowserHandler"]
        OSR["CefOsrHostGtk"]
    end

    subgraph TOOLKIT["Toolkit / native windowing layer"]
        GTK["GTK window + drawing area"]
        GDK["GDK events / pixbuf / screen info"]
        X11["X11 window handle / WM_CLASS / class hints"]
    end

    subgraph DESKTOP["Desktop OS surface"]
        WM["window manager\nmove / resize / minimize / maximize / close"]
        INPUT["mouse / keyboard / wheel"]
        TASK["task switcher / title / app icon"]
    end

    subgraph WEBRT["CEF / Chromium runtime"]
        LOOP["CEF message loop"]
        PAINT["OSR paint callbacks"]
        INP["browser host input APIs"]
        PAGE["web page runtime"]
    end

    subgraph SYSTEM["System services"]
        NET["network stack / TLS / HTTP"]
        FS["filesystem / session logs / local assets"]
    end

    ENTRY --> HOST --> LOOP
    HOST --> HANDLER
    HANDLER --> PAINT --> OSR --> GTK --> GDK --> X11 --> WM
    INPUT --> GTK --> OSR --> INP --> PAGE
    PAGE --> NET
    ENTRY --> FS
    WM --> TASK
    TASK --> X11
```

### Reading these diagrams

The key point is that the official/main browser path today is **not** the old browser-owned shell/chrome loop.

Instead, it is:

- a launcher-level runtime-host browser entry,
- owning the CEF runtime/message loop directly,
- painting through an OSR host window,
- and forwarding input from GTK/GDK into `CefBrowserHost`.

That is why this path now behaves differently from the older/legacy shell-owned route.

---

## 10. What should happen next?

The intended direction from here is:

1. keep strengthening the destination lane (`renderer=cef`) under the shell/backend contract
2. keep the staging lane available for runtime validation and bring-up
3. move more truth/state/ownership into the destination lane only when the seams are ready
4. avoid turning `Application` into a bespoke CEF runtime launcher by default

---

## Plain-English summary

The architecture today is:

- `bridge/` = workspace/meta repo
- `client/` = shell/app repo
- `engine-custom/` = custom backend
- `engine-chromium/` = runnable reference Chromium backend
- `engine-cef/` = active long-term Chromium backend target

And within the client, there are **two different CEF lanes**:

- **destination lane**: `--renderer=cef`
- **staging lane**: `--cef-runtime-probe`

The project should keep making the destination lane stronger while keeping the staging lane useful and separate.
