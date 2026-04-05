# Runtime-host profile policy

_Date: 2026-04-05_

This note defines the short-term profile behavior for the official BRIDGE runtime-host browser path:

- `browser --renderer=cef-runtime-host`

---

## Goals

The short-term profile policy should:
- preserve cookies and local browser state across restarts in normal use
- make it possible to try BRIDGE for longer than a few minutes without feeling stateless
- keep throwaway/dev runs available when needed
- stay simple enough that we do not overbuild profile management before friend alpha

---

## Short-term policy

### Default mode

BRIDGE runtime-host should use a **persistent default profile**.

That means:
- cookies persist across restart
- local storage persists across restart
- login/session continuity is possible in normal use

### Default profile root

On Linux, the default persistent profile root should live at:

- `$XDG_DATA_HOME/bridge/runtime-host/default`

If `XDG_DATA_HOME` is not set, fall back to:

- `$HOME/.local/share/bridge/runtime-host/default`

If neither is available, fall back to a stable per-user directory under `/tmp`.

The goal is for normal runtime-host browsing to stop using an ephemeral per-PID `/tmp` profile by default.

---

## Explicit overrides

### Custom profile dir

The runtime-host browser should accept:

- `--profile-dir=/absolute/or/relative/path`

This is useful for:
- custom test profiles
- controlled experiments
- release/testing workflows

### Temporary profile mode

The runtime-host browser should accept:

- `--temp-profile`

Short-term meaning:
- use a throwaway profile rooted under the current session artifacts directory
- useful for smoke checks and debug runs where state persistence is undesirable

---

## Non-goals for now

Not part of the current slice:
- multi-profile UI
- profile picker UI
- profile migration UX
- profile import/export
- settings surface for profile management

Those can come later.

---

## Acceptance

The short-term profile slice is successful when:

1. normal runtime-host launches use a stable persistent profile by default
2. restarting BRIDGE preserves cookies/storage in normal mode
3. `--profile-dir=...` works as an override
4. `--temp-profile` gives a throwaway profile without polluting the default one
5. the behavior is documented clearly enough for friend-alpha testers and future us
