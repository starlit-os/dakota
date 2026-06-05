# Sysexts

Implementation and operator notes for Dakota system extension (`systemd-sysext`) experiments.

This directory is for sysext-specific documentation that is useful to humans working on or testing a concrete extension. It is intentionally separate from `docs/skills/`, which is the agent knowledge base.

## Current layout

- [`pangolin.md`](pangolin.md) — current Pangolin CLI sysext, install/test flow, and future portability plan
- `justfiles/sysexts.just` — top-level sysext recipe dispatcher imported by the root `Justfile`
- `justfiles/sysext.just` — shared private helper recipes reused by per-sysext justfiles
- `justfiles/sysext-pangolin.just` — Pangolin-specific sysext helper recipes
- [`../../justfiles/templates/sysext-single-tool.just`](../../justfiles/templates/sysext-single-tool.just) — reusable helper recipe template for future single-tool sysext workflows

## Current Dakota approach

At the moment Dakota sysexts are:

- built as **parallel BuildStream artifacts** under `elements/sysext/`
- kept **out of the base image**
- packaged first as **directory-form sysexts** rather than `.raw` images

That keeps the first experiments additive and low-risk.

## Why directory-form first

`systemd-sysext` can activate a plain directory tree directly, so a directory artifact is enough to prove:

- metadata shape
- host matching
- payload layout under `/usr`
- runtime behavior of the bundled tool

without first solving filesystem-image generation.

## Host-targeted vs host-independent

Current sysexts should be assumed to be **Dakota-targeted** unless explicitly documented otherwise.

A sysext may be a candidate for host-independent use if it is:

- additive only
- built from a static or otherwise self-contained binary
- free of `/etc` and `/var` assumptions
- not dependent on host-specific services or ABI details

Do not relax metadata matching until that portability has been tested and documented.

## Workflow split

Keep sysext workflows split between:

- **build/dev machine** steps — build and check out the artifact
- **target host** steps — install into `/var/lib/extensions` and activate with `systemd-sysext`

Recipe names should make that split obvious. In the current Pangolin workflow, host-side commands are named with a `-host-` infix.
