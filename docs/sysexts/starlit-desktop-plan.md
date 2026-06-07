# Starlit desktop sysext plan

Decision note for exposing the Starlit desktop worktree as **separate** Dakota sysexts rather than one combined bundle.

## Current recommendation

**Do not build one monolithic `starlit-desktop` sysext first.**

Instead, split the work into three opt-in extensions with different scopes and risk levels:

1. `starlit-niri` — optional Niri session sysext
2. `starlit-noctalia` — optional Noctalia shell payload sysext
3. `vicinae` — optional launcher sysext, scoped to a phase-1 core feature set

This matches the actual integration boundaries better than a single desktop bundle.

## Why split instead of bundling

The candidate payloads do not share the same lifecycle or host-integration surface:

- `niri` is a **session/compositor** payload
- `noctalia-v5` is a **shell/UI** payload layered on top of a compositor
- `vicinae` is a **launcher/service** payload with extra optional host integrations

A combined bundle would blur the validation story:

- if activation fails, it becomes unclear whether the problem is session files, shell assets, or launcher integration
- if one component wants a different release cadence, the whole bundle churns
- operator docs become harder because each component has different host-side expectations

The cleaner phase-1 story is one sysext per integration boundary.

## Source of truth for the Starlit payloads

The current Starlit work lives in the sibling worktree:

- `../dakota.worktrees/starlit-desktop/elements/starlit/`
- `../dakota.worktrees/starlit-desktop/elements/oci/bluefin-starlit.bst`

That worktree currently models Starlit as a **full image delta** layered on top of Dakota, not as sysexts. The sysext plan below translates that same payload into parallel additive artifacts under `elements/sysext/`.

## 1. `starlit-niri`

### Recommendation

Build `niri` as its **own** Dakota-targeted sysext first.

### Why it is the strongest first candidate

The current `starlit/niri.bst` shape already matches what `systemd-sysext` is good at shipping:

- `/usr/bin/niri`
- `/usr/bin/niri-session`
- `/usr/share/wayland-sessions/niri.desktop`
- `/usr/share/xdg-desktop-portal/niri-portals.conf`
- `/usr/lib/systemd/user/niri.service`
- `/usr/lib/systemd/user/niri-shutdown.target`

That is a clean `/usr`-only payload with no obvious `/etc` or `/var` requirement in the package itself.

### Phase-1 target

A directory-form sysext that makes the Niri session and related portal/user-unit assets visible on the host.

### Suggested files

- `elements/sysext/starlit-niri-metadata.bst`
- `elements/sysext/starlit-niri.bst`
- `justfiles/sysext-starlit-niri.just`
- `docs/sysexts/starlit-niri.md`

Optional later:

- `elements/sysext/starlit-niri-raw.bst`
- local sysupdate feed helpers if the directory-form flow proves useful

### Host smoke checks

- `command -v niri`
- `test -f /usr/share/wayland-sessions/niri.desktop`
- `test -f /usr/share/xdg-desktop-portal/niri-portals.conf`
- `systemd-sysext status`

### Main caveat

This should be treated as a **Dakota-targeted** sysext, not a portable one. It depends on the host runtime and portal stack matching Dakota expectations.

## 2. `starlit-noctalia`

### Recommendation

Build `noctalia-v5` as a **separate shell payload sysext**, not as part of the Niri sysext.

### Why it deserves its own boundary

`noctalia-v5` is not the session entrypoint. It is the shell/UI layer that should be allowed to evolve separately from the compositor/session package.

Keeping it separate makes the user-facing story clearer:

- `starlit-niri` = install the Niri session
- `starlit-noctalia` = install the Noctalia shell payload used on top of that session

### Upstream packaging shape

The current upstream `v5` Meson install shape is much cleaner than a traditional desktop app bundle:

- installs the `noctalia` executable
- installs `assets/` to `share/noctalia`
- does **not** appear to require GLib schema compilation, desktop-database updates, icon cache updates, or appstream cache generation as part of the package install itself

That makes it a much better sysext candidate than a GTK app that scatters install-time caches across the host.

### Suggested phase-1 scope

Ship only the shell payload and its runtime dependencies as a Dakota-targeted sysext.

Likely dependency surface:

- `starlit/noctalia-v5.bst`
- `starlit/libqalculate.bst`
- `starlit/sdbus-cpp.bst`

### Suggested files

- `elements/sysext/starlit-noctalia-metadata.bst`
- `elements/sysext/starlit-noctalia.bst`
- `justfiles/sysext-starlit-noctalia.just`
- `docs/sysexts/starlit-noctalia.md`

### Host smoke checks

- `command -v noctalia`
- `test -d /usr/share/noctalia/assets`
- `systemd-sysext status`
- a lightweight `noctalia --help` or version probe if upstream supports one

### Main caveat

This is still a dynamically linked desktop payload, so it should be treated as ABI-coupled to Dakota unless proven otherwise.

## 3. `vicinae`

### Recommendation

Investigate and package Vicinae as a **separate launcher sysext**, but keep the first implementation deliberately narrower than the upstream install script.

### Why Vicinae should stay separate

Vicinae has a meaningfully different integration surface from both `niri` and `noctalia`:

- command palette / launcher UX
- user service management
- optional browser integration
- optional `uinput`-based paste support
- additional assets and helper binaries

That makes it a poor fit for the same bundle as the session or shell.

### Upstream install footprint

Upstream Vicinae installation expects more than just one binary. The source and install docs indicate a package shape that includes:

- binaries under `/usr/bin`
- helper binaries under `/usr/libexec/vicinae`
- themes under `/usr/share/vicinae/themes`
- desktop files under `/usr/share/applications`
- icon assets under `/usr/share/icons`
- user service under `/usr/lib/systemd/user/vicinae.service`

The upstream convenience installer and docs also cover optional integrations such as:

- browser native-messaging manifests
- `uinput` access helpers
- modules-load / udev rules
- a `vicinae-node` runtime path for TypeScript extensions

### Phase-1 sysext scope

A practical first Dakota sysext should aim only for **Vicinae core launcher functionality**:

- `vicinae` command works
- basic assets are present
- user service file is available
- the launcher can be started manually or through host-side service activation

### Phase-1 non-goals

Do **not** require the first sysext to provide every upstream integration automatically. Treat these as separate follow-up investigations:

- Chromium native-messaging manifests under `/etc`
- zero-touch browser extension setup
- guaranteed `uinput`/paste integration on all hosts
- full TypeScript extension workflow unless `vicinae-node` pathing is verified in the packaged result

### Suggested files

- `elements/sysext/vicinae-metadata.bst`
- `elements/sysext/vicinae.bst`
- `justfiles/sysext-vicinae.just`
- `docs/sysexts/vicinae.md`

### Host smoke checks

- `command -v vicinae`
- `vicinae version`
- `test -f /usr/share/applications/vicinae.desktop`
- `test -f /usr/lib/systemd/user/vicinae.service`
- `systemd-sysext status`

### Main caveat

Vicinae is a good sysext candidate only if phase 1 is framed as a **core launcher payload**, not as full parity with the upstream `/usr/local` installer flow.

## Recommended implementation order

### 1. `starlit-niri`

This gives the fastest feedback with the cleanest `/usr` payload.

### 2. `starlit-noctalia`

Once the Niri session sysext flow is proven, add the shell payload as a second layer.

### 3. `vicinae`

Only after the session/shell sysext workflow is stable, add the launcher sysext with an explicitly scoped core feature set.

## Shared implementation rules

All three should follow the existing Dakota sysext pattern:

- keep them out of the base image
- build them as **parallel BuildStream artifacts** under `elements/sysext/`
- start with **directory-form sysexts**
- add `.raw` or sysupdate flows only after the directory-form host validation is solid

They should also reuse the current helper structure:

- `justfiles/sysext.just`
- `justfiles/sysexts.just`
- one per-extension justfile and docs page

## Explicit non-goal

Do not create a single `starlit-desktop` sysext unless later experience shows that all three components genuinely want the same release cadence, compatibility contract, and operator workflow. The current evidence points in the opposite direction.
