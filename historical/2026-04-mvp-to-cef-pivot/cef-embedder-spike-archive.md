# Archived CEF embedder spike

This spike has been **promoted into the standalone `engine-cef/` repo**.

## Current status

- active CEF backend work now lives in: `engine-cef/`
- the spike was useful to prove the first native CEF browser window and bootstrap the build/runtime flow
- the workspace root keeps this archived note only so the history remains easy to follow

## Promotion note

Promoted to local `engine-cef` repo at:

- `engine-cef` commit `0bd3d23` — `Bootstrap engine-cef from first native proof`

## Why archive it

The root repo should stay focused on:

- workspace/meta coordination
- ADRs
- wrapper scripts
- integration notes

Keeping a live CEF implementation spike here after `engine-cef/` exists would just add noise.
