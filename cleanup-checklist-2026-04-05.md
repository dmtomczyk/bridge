# Bridge cleanup checklist

_Date: 2026-04-05_

Ranked cleanup plan from the cross-repo pause/audit.

## P0 — Highest priority

### 1. Repo hygiene: ignore generated/runtime noise
- [x] Ignore `engine-cef/build-cef/`
- [ ] Check for other obviously missing build/output ignores in active repos

### 2. Build / launcher truthfulness
- [x] Update client launcher help/docs to mention `--renderer=cef`
- [x] Update client launcher help/docs to mention `--cef-runtime-probe`
- [x] Update workspace build wrapper docs/help to explain current CEF limitations/reality
- [ ] Decide whether root `compile.sh` should grow a real `--engine cef` mode or remain explicit about not owning that flow yet
- [ ] Add a small CEF-oriented smoke wrapper or documented command path at the workspace root

### 3. Current architecture truth pass
- [x] Clean obvious stale bits in `GIT.md` (engine API path / summary diagram / `engine-cef` visibility)
- [ ] Review root `refactor.md` for stale engine-chromium-centric language now that `engine-cef` is the active long-term Chromium lane
- [ ] Make `engine-chromium` reference-only status unmistakable in README/quickstart docs

### 4. CI/CD skeleton
- [ ] Add minimal `client` CI
- [ ] Add minimal `engine-cef` CI
- [ ] Add root integration CI for pinned submodule states

## P1 — Important, but after P0

### 5. Client doc drift cleanup
- [ ] Rewrite `client/docs/architecture.md` to current split/CEF truth
- [ ] Decide whether `client/docs/architecture-roadmap.md` should be rewritten, bannered, or partially archived
- [ ] Banner or archive `client/refactor.md` as historical/Blink-era planning if it is no longer a current source of truth

### 6. DX consistency
- [ ] Add more symmetric repo-local build/run docs/helpers across `engine-cef`, `engine-custom`, and `engine-chromium`
- [ ] Review workspace wrapper scripts for stale target/test defaults
- [ ] Decide whether root smoke scripts should include a CEF lane

### 7. Publish / integration hygiene
- [ ] Decide which local commits to push in `client`
- [ ] Decide which local commits to push in `engine-cef`
- [ ] Decide when to publish the root submodule pointer updates

## P2 — Nice to have / later

### 8. Diagram unification
- [ ] Pick one canonical current diagram set for the workspace/repo topology
- [ ] Pick one canonical current diagram set for the client shell/backend architecture
- [ ] Mark older Blink/modular-monolith diagrams as historical where needed

### 9. Engine-custom curation
- [ ] Consider adding a small `BUILD.md` or equivalent quickstart to `engine-custom`
- [ ] Review thin/legacy monorepo-reference docs there for cleanup or historical labeling

## Notes

- The code direction is healthier than the scripts/docs currently suggest.
- The main risk is stale documentation from older architectural eras (monolith/Blink/reference-Chromium-first) confusing the active CEF destination-lane direction.
- The immediate goal of this checklist is to tighten repo hygiene and truthfulness before deeper integration work resumes.
