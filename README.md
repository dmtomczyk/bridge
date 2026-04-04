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

- `client/` — the app/client repo; owns the browser shell, chrome, navigation UX, diagnostics, and backend orchestration
- `engine-custom/` — the custom/native engine repo
- `engine-chromium/` — the Chromium-backed engine repo

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
- `client` builds against `engine-custom` and `engine-chromium` by sibling path
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

Build via the client repo through the workspace wrapper:

```bash
./build.sh off
./build.sh on --v8-include /path/to/v8/include --v8-lib /path/to/v8/out.gn/x64.release/obj
```

Launch the client/browser app:

```bash
./startbrowser.sh
```

Check repo status:

```bash
./scripts/status.sh
```
