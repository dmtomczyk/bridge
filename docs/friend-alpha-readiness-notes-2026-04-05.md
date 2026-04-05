# Friend alpha readiness notes

_Date: 2026-04-05_

This note captures the high-level strategy discussion about what BRIDGE needs before it is worth distributing to a small number of software-engineer friends for real messing-around / day-use feedback.

---

## Short version

- **Could you hand it to a couple engineer friends now?** Yes, as a cool prototype.
- **Would they actually use it for half a day and keep coming back?** Not quite yet.
- **What gets it over that line?** A small set of pragmatic improvements, mostly around usability and shipping, not giant architecture changes.

---

## 1. What BRIDGE needs before it is worth handing to friends for real use

Think about this in three bars.

### A. Show-and-tell build

This is basically where BRIDGE is now.

People can:
- open it
- load real sites
- see that it is real
- click around a bit
- say “oh damn, this is working”

That is already a real milestone.

### B. Friend alpha

This is the next bar to aim for.

This means:
- they might actually leave it open for a few hours
- they might browse several sites
- they might form opinions about it as a browser, not just as a demo

To hit that bar, the biggest needs are:

#### 1. Basic browser chrome in the official runtime-host path

Not fancy. Just enough to feel like a usable browser:
- back
- forward
- reload
- address bar
- load/go button or Enter-to-navigate
- maybe open current page in external browser as an escape hatch

Without this, it still feels more like a hosted web surface than a browser.

#### 2. Persistent profile behavior

This is a major requirement for “use it for a day” testing.

Users will expect:
- cookies/session persistence
- logged-in state not disappearing constantly
- local storage working predictably
- preferences/profile directory surviving restarts

If every run feels stateless or weirdly ephemeral, people bounce fast.

#### 3. Clipboard / text / keyboard comfort

For real use, this needs to feel boring:
- copy
- paste
- select all
- eventually Ctrl/Cmd-L equivalent for the location bar
- keyboard focus behaving sanely
- text entry not feeling fragile

This has an outsized “feels real vs feels fake” impact.

#### 4. Popup / new-window / auth-flow sanity

A lot of real sites break emotionally if this is bad:
- OAuth/login popups
- links with `target=_blank`
- `window.open(...)` flows
- maybe basic downloads or at least handoff behavior

A polished tab system is not required yet, but a clear policy is.

#### 5. A small stability/polish sweep on real sites

Not abstract testing — real site passes.

Suggested sweep:
- Google
- GitHub
- one Gmail/Calendar-like app
- one docs site
- one heavy JS app
- one login flow

The goal is not perfection. The goal is:
- no obvious hangs
- no obviously broken first impression
- no immediately embarrassing paper cuts

### C. People might actually keep using this

That is a later bar.

That probably wants:
- tabs or a multi-window story
- download story
- settings/profile management
- better page permissions
- more refined install/update experience
- crash recovery / session restore
- stronger UX identity

This should **not** be the bar before friend alpha.

---

## Recommendation for sending to a few software friends

Do not wait for a full browser.

Wait until BRIDGE has:
- minimal runtime-host chrome
- persistent profile behavior
- clipboard/basic keyboard sanity
- popup/new-window story
- one packaging path that feels intentional

That is enough for:

> “Here, try this for an afternoon and tell me what annoys you first.”

That is the right kind of early external test.

---

## 2. Installer / deliverable: short term vs long term

### Short term: one clean Linux alpha bundle

If the near-term audience is a couple engineer friends, keep this much simpler than a full installer.

#### Near-term deliverable

One versioned bundle, probably something like:

- `bridge-linux-x64/`
  - `bridge` launcher script
  - `browser`
  - `client_cef_runtime_browser`
  - CEF runtime libs/resources/locales
  - assets
  - maybe default config/profile-dir bootstrap

Then ship it as:
- `.tar.gz`

That is totally fine for engineer friends.

#### Why do this first

Because it gives:
- reproducible release assembly
- explicit runtime contents
- fewer “works on my machine” mysteries
- a path to alpha testing now

#### What not to start with

Too early:
- distro-native packages
- fancy installer UI
- auto-update
- cross-platform packaging matrix

### Medium-short term: one-click launcher + bundle

Once the bundle exists, add:
- `bridge-launcher` or `bridge-workbench`
- start/stop buttons
- debug/profile toggles
- open logs
- open latest session dir
- maybe launch profiles:
  - normal
  - verbose logs
  - perf tracing
  - safe mode

That gives a much better internal/dev/testing story.

### Long term: proper platform-native distribution

#### Linux
Probably one or more of:
- AppImage
- `.deb`
- maybe `.rpm`

#### macOS
- signed `.app`
- DMG
- notarization eventually

#### Windows
- MSI or packaged installer
- signed binaries eventually

#### Across all of them
- versioned releases
- profile migration story
- update story
- crash logs / diagnostics
- optional telemetry, opt-in only

### Short-term packaging recommendation

The right progression is:

#### Step 1
**Versioned tarball bundle**

#### Step 2
**Launcher/workbench sitting on top of the bundle**

#### Step 3
**AppImage or first real installer for the primary OS**

That is the highest-leverage order.

---

## 3. Next 5 highest-ROI features / improvements

Ranked for actual leverage, not just what sounds cool.

### 1. Minimal official runtime-host browser chrome

Highest ROI.

Specifically:
- address bar
- back
- forward
- reload
- maybe stop
- clear load/error feedback

Why:
- instantly changes perception from prototype to browser
- lets friends self-drive instead of relying on command-line launch URLs
- improves every manual test loop

### 2. Persistent profile / day-use story

If this is not solid, outside testing quality drops hard.

Need a clear answer for:
- where the profile lives
- whether sessions persist
- whether cookies/local storage persist
- whether there is a throwaway/dev profile mode

Why:
- this is what makes “try it for a day” plausible

### 3. Launcher / workbench

Yes, this is high ROI.

Why:
- makes testing loops faster
- gives a place for debug toggles and telemetry
- can later become the embryo of shipping/install UX
- separates developer control panel from browser window

### 4. Real-site stability / polish sweep

A targeted one, not endless.

Suggested explicit sweep:
- Google
- GitHub
- one account/login flow
- one docs app
- one heavy JS site

Focus on:
- startup correctness
- resize/move sanity
- text entry
- scrolling
- navigation
- obvious hangs

Why:
- a handful of strong live-site passes gives the biggest trust boost

### 5. Clipboard / popups / external handoff policy

Need clear behavior for:
- copy/paste
- `target=_blank`
- popup windows
- auth flows
- maybe download handoff
- maybe “open externally”

Why:
- this is where prototypes start feeling annoying fast

### What not to prioritize yet

Not first:
- tabs
- sync
- big settings UI
- deep theming
- giant native menu system
- broad plugin/addon ambitions

Those are later multipliers, not immediate alpha unlocks.

---

## 4. Thoughts on a small launcher / workbench

### Strong yes

This is a very good idea.

And it should start as:

**a dev/test workbench first**

not as the final user launcher.

That is the cleanest version.

### Phase 1 should be

A small BRIDGE workbench with:

#### Launch controls
- Start browser
- Stop latest browser session
- Restart
- Open latest session folder

#### Toggleable launch options
- normal
- verbose logs
- perf debug
- trace/network logging
- chosen URL
- maybe profile mode:
  - persistent
  - temporary

#### Visibility
- current session dir
- first-frame seen / not seen
- current page title/url if available
- status text
- maybe latest stderr tail

#### Convenience buttons
- Google
- GitHub
- a local smoke page
- last URL
- open logs

That alone would be extremely useful.

### Why it is smart

Because it gives:

#### 1. Better internal workflow
No more retyping long launch commands.

#### 2. Better debugging
A natural place for:
- instrumentation
- runtime state
- session controls
- profile switching

#### 3. Better future distribution story
Later it can evolve into:
- alpha installer/launcher
- channel selector
- update entry point
- diagnostics app

So yes — it can become both:
- **workbench now**
- **installer/launcher shell later**

### Scope warning

Avoid making it do everything at once.

Keep the phases crisp:

#### Phase 1: Dev workbench
- launch/stop
- toggles
- logs
- sessions
- simple telemetry

#### Phase 2: Alpha launcher
- bundled app
- “run BRIDGE”
- maybe profile selection
- maybe update check

#### Phase 3: User-facing install surface
- real packaging/install/update UX

If Phase 1 is forced to also be the final installer architecture, it will bloat fast.

---

## Opinionated near-term roadmap

Recommended order:

1. **minimal runtime-host chrome**
2. **persistent profile decision + implementation**
3. **small launcher/workbench**
4. **bundle/release pipeline for Linux alpha**
5. **real-site polish sweep with a friends-in-mind checklist**

That is the cleanest path from:
- impressive prototype

to:
- a couple engineer friends may actually try living in it for a bit

---

## Suggested next doc

A good next step after this strategy discussion would be to turn it into a more execution-oriented plan, for example:

- `docs/friend-alpha-readiness-plan.md`

That could capture:
- readiness bar
- packaging plan
- launcher phases
- ranked next slices
- acceptance criteria for the first friend alpha drop
