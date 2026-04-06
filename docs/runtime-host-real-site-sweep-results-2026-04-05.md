# Runtime-host real-site sweep results

_Date: 2026-04-05_

Companion to:
- `docs/runtime-host-real-site-polish-sweep-2026-04-05.md`

This file captures actual sweep outcomes for the official BRIDGE browser path:

- `browser --renderer=cef-runtime-host`

---

## Overall status

Current read:
- BRIDGE is no longer just a proof-of-life runtime-host shell.
- It now has a meaningful set of browser capabilities that feel real in use.
- Remaining work is increasingly about polish, confidence, and a few still-untested real-site flows rather than total missing fundamentals.

---

## A. Google

### Status
- Rerun live under the current formal sweep.

### Rating
- [x] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- Core flow passed:
  - search box focus
  - typing query
  - search/results navigation
  - back/forward
  - BRIDGE URL bar editing
  - reload
- One notable rough edge remains:
  - pressing Enter in the Google search field appears to insert a newline instead of submitting the form
  - likely an input/key-event handling issue worth following up later

---

## B. GitHub

### Status
- Rerun live under the current formal sweep.

### Rating
- [x] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- Core GitHub browsing flow passed:
  - homepage/repo navigation
  - internal links
  - longer-page scrolling
  - back/forward
  - BRIDGE URL bar editing
- General polish feedback noted (not GitHub-specific blockers):
  - cursor shape could better reflect link-hover state
  - right-click context menu in the BRIDGE URL bar would be nice for paste and other common edits

---

## C. Docs site

### Status
- Rerun live under the current formal sweep.

### Rating
- [x] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- Docs-heavy browsing passed.
- General non-site-specific UX feedback noted:
  - single click in the BRIDGE address bar should probably default to select-all
  - scrolling feels less smooth than major browsers even though general navigation/back-forward/load times feel very strong
- Performance impression was notably positive overall:
  - back/forward and general page load times felt very good, even compared with major browsers

---

## D. Popup/new-window policy

### Status
- Tested on local popup smoke page.

### Rating
- [x] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- Real target URL popup/new-window requests now open in the current BRIDGE window.
- Blank / `about:blank` / `javascript:` popup targets are blocked.
- External handoff is no longer the surprising default.

---

## E. Upload behavior

### Status
- Tested on local upload smoke page.

### Rating
- [x] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- Single-file chooser works.
- Multi-file chooser works.
- Files propagate back into page UI correctly.

---

## F. Download behavior

### Status
- Tested on local download smoke page.

### Rating
- [x] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- Download triggers correctly.
- File lands in predictable location under `~/Downloads/BRIDGE`.
- MVP path works even without richer download UI.

---

## G. Permissions behavior

### Status
- Tested on local permissions smoke page.

### Rating
- [x] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- Notification, geolocation, and media requests are denied explicitly.
- Denial path behaves clearly enough for current MVP expectations.
- Logging exists for requested permission types/origins.

---

## H. Profile behavior

### Status
- Tested directly via cookie/session persistence checks.

### Rating
- [x] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- Persistent default profile works.
- Session-cookie persistence across restart works.
- Guest/temp profile mode exists and is isolated in the workbench/browser flow.
- Profile label visibility exists in chrome/title.

---

## I. Workbench-assisted flow

### Status
- Tested directly.

### Rating
- [x] Pass
- [ ] Rough but acceptable
- [ ] Broken / follow-up needed

### Notes
- Workbench launches official runtime-host path.
- Stop works.
- Force Kill works via process-group targeting.
- Default/Guest mode controls work.
- URL editing precision in the workbench is now sane.

---

## Current open sweep targets

Still worth running live now:
- Google (fresh rerun under current build)
- GitHub
- one docs-heavy site

Optional after that:
- one login-ish/auth-ish flow
- one heavier JS/app-like site

---

## Current must-fix blockers found by this sweep

At the moment:
- none confirmed in the already-tested local capability flows

---

## Current likely next-browser-polish candidates

Most likely next follow-ups after the remaining live-site checks:
- GitHub/docs rough-edge fixes, if any show up
- richer denied-permission/download visibility in chrome/workbench
- download UX improvements
- custom profile path in workbench
- auth/login-specific rough edges if they appear

---

## Next sweep step

Run fresh live checks for:
1. Google
2. GitHub
3. one docs-heavy site

and update this file with concrete ratings/notes.
