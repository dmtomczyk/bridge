# Runtime-host alpha readiness — 2026-04-06

This checklist reflects the current state of the official BRIDGE runtime-host browser path:

- `browser/build/cef-hybrid-real/browser --renderer=cef-runtime-host`

The goal is not "feature complete browser." The goal is:

- stable enough
- coherent enough
- useful enough
- honest enough

for an alpha aimed at people who value a lightweight, minimalist browser shell.

---

## Current baseline

As of this checkpoint, the runtime-host lane now has:

- visible tab strip in the official runtime-host window
- tab switch / close / new tab
- working shortcut set including:
  - `Ctrl+T`
  - `Ctrl+W`
  - `Ctrl+Shift+T`
  - `Ctrl+L`
  - `Ctrl+Tab`
  - `Ctrl+Shift+Tab`
  - `F5`
  - `Ctrl+R`
  - `Alt+1..9`
- popup/new-window → new-tab policy in the current minimal form
- browser-owned offline-capable BRIDGE Home page for startup/new-tab
- current-session closed-tab recovery
- at least one real close crash fixed at the container-mutation level

This is enough to justify a real alpha-readiness pass.

---

# Must-have before alpha

## 1. Stability and crash confidence

### Checklist
- [ ] Stress open/close many tabs in one session
- [ ] Stress repeated close/reopen cycles
- [ ] Stress `Ctrl+Shift+T` recovery repeatedly
- [ ] Verify startup/new-tab/home-page transitions do not crash
- [ ] Verify popup-created tabs do not introduce obvious instability
- [ ] Verify no obvious new crashers remain in normal use

### Deliverable
- Short note of:
  - known stable scenarios
  - known flaky scenarios
  - any remaining blockers

---

## 2. Real-site workflow sweep

### Checklist
- [ ] Google/search/navigation sweep
- [ ] GitHub sweep
- [ ] One docs-heavy site sweep
- [ ] One JS-heavy app sweep
- [ ] One login/OAuth/popup-ish flow sweep
- [ ] One upload flow sweep
- [ ] One download flow sweep
- [ ] One tab-heavy browsing session sweep

### Deliverable
- Short result grid:
  - pass
  - rough but usable
  - broken/blocking

---

## 3. Focus / input sanity pass

### Checklist
- [ ] After close, focus lands somewhere sane
- [ ] After reopen, focus behavior is sane
- [ ] Address bar focus/blur is consistent
- [ ] Tab switching preserves keyboard usability
- [ ] BRIDGE Home behaves coherently relative to normal sites
- [ ] No obvious focus/input regressions from popup-created tabs

### Deliverable
- Short fix list or explicit signoff that focus/input now feels coherent enough for alpha

---

## 4. Closed-tab recovery polish

### Checklist
- [ ] `Ctrl+Shift+T` reliably restores recently closed normal site tabs
- [ ] Repeated `Ctrl+Shift+T` behaves sanely across several tabs
- [ ] Home-born tabs that later navigate to normal sites reopen correctly
- [ ] Popup-created tabs are tested with closed-tab recovery
- [ ] Decide whether explicitly closed BRIDGE Home tabs should reopen or not

### Deliverable
- Stable expected behavior note for closed-tab recovery

---

## 5. BRIDGE Home polish

### Checklist
- [ ] Startup with no URL reliably opens BRIDGE Home
- [ ] New tab reliably opens BRIDGE Home
- [ ] BRIDGE Home links work
- [ ] Content is accurate and useful
- [ ] Layout feels intentional enough for alpha
- [ ] Wording is clean and not overly splashy/marketing-heavy

### Nice if cheap
- [ ] Add 1–2 extra useful links or hints
- [ ] Add a tiny note about profiles or current limitations

---

## 6. Smooth scrolling

This is important enough to track explicitly because rough scrolling can make a browser feel unfinished even if everything else works.

### Checklist
- [ ] Verify wheel scrolling feels acceptably smooth on common sites
- [ ] Verify touchpad/trackpad-style scrolling behavior if available in the target environment
- [ ] Check scrolling on docs-heavy pages and content-dense pages
- [ ] Check for jitter, jumpiness, or obvious stepwise roughness
- [ ] Decide whether current behavior is acceptable for alpha or needs a targeted fix

### Deliverable
- Short judgment:
  - acceptable for alpha
  - rough but tolerable
  - blocking/not acceptable

---

## 7. Documentation / install honesty

### Checklist
- [ ] Choose one recommended launch path
- [ ] Write short run/build instructions
- [ ] Document known limitations honestly
- [ ] Document what "alpha" means here
- [ ] Avoid implying mass-market polish where it does not exist yet

### Deliverable
- One concise alpha notes / getting-started doc

---

# Should-have before alpha

## 8. Popup / auth / login hardening

### Checklist
- [ ] Verify `_blank` flows in real login/auth cases
- [ ] Verify current-window fallback behavior is not surprising
- [ ] Verify file upload dialogs behave acceptably
- [ ] Verify permission-denial behavior is understandable

---

## 9. Tab overflow / dense-tab polish

### Checklist
- [ ] Many-tab state remains visually usable
- [ ] Tab clipping remains understandable
- [ ] Close hit targets remain reliable with dense tab counts
- [ ] Active tab remains visually clear in crowded conditions

---

## 10. Log hygiene

### Checklist
- [ ] Keep normal-run logs useful but not spammy
- [ ] Avoid noisy debug leftovers in non-debug runs
- [ ] Ensure runtime status logging remains intelligible

---

# Nice-to-have / likely post-alpha

## 11. More shortcut polish

### Candidates
- [ ] `Alt+Left` / `Alt+Right`
- [ ] `Ctrl+1..9`
- [ ] Better middle-click semantics

---

## 12. Better special-page model beyond Home

### Candidates
- [ ] Better internal error pages
- [ ] Additional internal help/settings surfaces

---

## 13. Session/history UI

### Candidates
- [ ] Lightweight history surface
- [ ] Reopen closed window/session semantics
- [ ] Richer recent-tab browsing

---

# Recommended execution order

## Phase A — stabilize what exists
- [ ] Stability / crash sweep
- [ ] Focus / input sanity pass
- [ ] Closed-tab recovery verification
- [ ] BRIDGE Home polish
- [ ] Smooth scrolling assessment

## Phase B — real-world confidence
- [ ] Real-site workflow sweep
- [ ] Popup/auth/login checks
- [ ] Upload/download checks
- [ ] Known limitations draft

## Phase C — alpha packaging
- [ ] Alpha notes doc
- [ ] Recommended launch path
- [ ] Decide friend-alpha vs wider alpha

---

# Alpha gate

Call the runtime-host browser alpha-ready when all of these are true:

- [ ] No obvious crash in normal open/close/reopen tab use
- [ ] Startup/new-tab page is reliable
- [ ] Normal tabs, home-born tabs, and reopened tabs behave coherently
- [ ] Popup/new-window flows are understandable enough
- [ ] Smooth scrolling is at least acceptable for alpha
- [ ] A short real-site matrix mostly passes
- [ ] Known rough edges are documented honestly

---

# Notes

This is not a checklist for becoming Chrome.

It is a checklist for becoming:

- lightweight
- coherent
- credible
- pleasant enough that the right users will keep it open
