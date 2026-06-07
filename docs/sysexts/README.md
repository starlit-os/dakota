# Sysexts

Implementation and operator notes for Dakota system extension (`systemd-sysext`) experiments.

This directory is for sysext-specific documentation that is useful to humans working on or testing a concrete extension. It is intentionally separate from `docs/skills/`, which is the agent knowledge base.

## Current layout

- [`pangolin.md`](pangolin.md) — current Pangolin CLI sysext, install/test flow, and future portability plan
- [`proton-pass-cli.md`](proton-pass-cli.md) — single-tool sysext for Proton Pass CLI
- [`starlit-cli.md`](starlit-cli.md) — CLI bundle sysext for `fish`, `bat`, and `eza`
- [`starlit-cli-design.md`](starlit-cli-design.md) — collection-vs-single-tool decision note for `starlit-cli`
- [`starlit-desktop-plan.md`](starlit-desktop-plan.md) — plan for splitting the Starlit desktop worktree into separate `starlit-niri`, `starlit-noctalia`, and `vicinae` sysexts
- [`vm-testing.md`](vm-testing.md) — VM workflow and one-sysext-at-a-time checklist for manual sysext validation
- `justfiles/sysexts.just` — top-level sysext recipe dispatcher imported by the root `Justfile`
- `justfiles/sysext.just` — shared private helper recipes reused by per-sysext justfiles
- `justfiles/sysext-pangolin.just` — Pangolin-specific sysext helper recipes
- `justfiles/sysext-proton-pass-cli.just` — Proton Pass CLI-specific sysext helper recipes
- `justfiles/sysext-starlit-cli.just` — starlit-cli-specific sysext helper recipes
- [`../../justfiles/templates/sysext-single-tool.just`](../../justfiles/templates/sysext-single-tool.just) — reusable helper recipe template for future single-tool sysext workflows

## Current Dakota approach

At the moment Dakota sysexts are:

- built as **parallel BuildStream artifacts** under `elements/sysext/`
- kept **out of the base image**
- packaged first as **directory-form sysexts** rather than `.raw` images
- beginning to grow an **experimental `.raw` + sysupdate feed path** for bundles that are ready to test versioned delivery

That keeps the first experiments additive and low-risk while still letting individual bundles start the next phase.

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
