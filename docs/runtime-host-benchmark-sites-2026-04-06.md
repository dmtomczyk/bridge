# Runtime-host benchmark sites — 2026-04-06

This document defines a small, practical benchmark site set for the official BRIDGE runtime-host browser path:

- `browser/build/cef-hybrid-real/browser --renderer=cef-runtime-host`

The point is not to collect random popular websites.
The point is to keep a stable set of sites that each validate a specific browser behavior.

---

# Core benchmark set

## 1. Long scroll / docs
**Site:** MDN Web Docs  
**URL:** <https://developer.mozilla.org/>

### Use it for
- smooth scrolling feel
- long-page readability
- code block rendering
- general docs browsing
- text selection sanity

### Notes
A strong baseline for whether the browser feels pleasant on long technical reading sessions.

---

## 2. Content-heavy reading
**Site:** Wikipedia  
**URL:** <https://en.wikipedia.org/wiki/Main_Page>

### Use it for
- long article scrolling
- anchor/link navigation
- mixed image/text rendering
- general reading comfort

### Notes
Useful as a simpler, less app-like complement to MDN.

---

## 3. Normal browsing / search baseline
**Site:** Google Search  
**URL:** <https://www.google.com/>

### Use it for
- search box focus/input
- normal browsing flow
- opening results in tabs
- back/forward/reload behavior

### Notes
Simple, common, and very useful as a reality check for basic browsing ergonomics.

---

## 4. Repo / app-like workflow
**Site:** GitHub  
**URL:** <https://github.com/>

### Use it for
- tab-heavy browsing
- authenticated workflow later
- modern app-like interactions
- keyboard/input coexistence with site UI

### Notes
A strong proxy for the kind of site power users actually leave open all day.

---

## 5. Video playback
**Site:** YouTube  
**URL:** <https://www.youtube.com/>

### Use it for
- video playback
- media controls
- dynamic page performance
- tab switching while media is active

### Notes
Good test of whether media playback feels credible, not just technically possible.

---

## 6. Audio playback
**Site:** SoundCloud  
**URL:** <https://soundcloud.com/discover>

### Use it for
- audio playback
- media continuity across tab switching
- app-like UI with active playback state

### Notes
Alternative sources are fine if SoundCloud becomes annoying or login-gated.

---

## 7. Auth / login flow
**Site:** GitHub Login  
**URL:** <https://github.com/login>

### Use it for
- auth flow sanity
- text input reliability
- session persistence
- redirect/login behavior

### Notes
Good low-drama baseline before testing more popup-heavy OAuth flows.

---

## 8. Upload flow
**Site:** Berkeley CGI file upload example  
**URL:** <https://cgi-lib.berkeley.edu/ex/fup.html>

### Use it for
- file picker behavior
- upload form interaction
- focus recovery after file chooser usage

### Notes
Simple, old-school, and useful precisely because it is boring.

---

## 9. Download flow
**Site:** Hetzner test file  
**URL:** <https://speed.hetzner.de/100MB.bin>

### Use it for
- download start behavior
- file naming/location behavior
- repeated download sanity

### Notes
Keep the file size practical for local testing if needed.

---

## 10. JS-heavy modern UI
**Site:** Notion  
**URL:** <https://www.notion.so/>

### Use it for
- JS-heavy rendering
- modern frontend interaction feel
- scrolling/input behavior in a contemporary UI

### Notes
Alternative modern-app candidates are fine if Notion changes behavior significantly.

---

# Optional bonus sites

## 11. Pointer / zoom / map interaction
**Site:** OpenStreetMap  
**URL:** <https://www.openstreetmap.org/>

### Use it for
- drag/pan interaction
- scroll wheel zoom behavior
- pointer precision
- dynamic tile rendering

### Notes
Very useful once input polish becomes a stronger focus.

---

## 12. Rendering weirdness / embeds / CSS-heavy interaction
**Site:** CodePen  
**URL:** <https://codepen.io/>

### Use it for
- embedded content
- rendering oddities
- animation/CSS sanity
- interactive frontend behavior

### Notes
A good catch-all compatibility sniff test.

---

# Suggested benchmark categories

Use these labels in sweep notes so results are easy to scan:

- long scroll/docs
- content-heavy reading
- normal browsing/search
- repo/app workflow
- video playback
- audio playback
- auth/login
- upload
- download
- JS-heavy modern UI
- pointer/zoom interaction
- rendering weirdness

---

# Suggested sweep format

For each site, record:

- **Status:** pass / rough but usable / broken
- **What worked:** short bullets
- **What felt rough:** short bullets
- **Blocker?:** yes/no

Example:

```markdown
## MDN
- Status: rough but usable
- What worked:
  - scrolling improved after smooth-scroll patch
  - links/navigation okay
- What felt rough:
  - trackpad delta still a little jumpy
- Blocker?: no
```

---

# Recommended first-pass benchmark order

If time is limited, run these first:

1. MDN
2. Google Search
3. GitHub
4. YouTube
5. GitHub Login
6. Upload test
7. Download test

That gives a fast but meaningful confidence pass.

---

# Notes

This list should stay small and stable.

If a site becomes unusable for reasons unrelated to BRIDGE (paywall, forced login, region weirdness, etc.), replace it with a site that tests the same behavior category rather than endlessly expanding the list.
