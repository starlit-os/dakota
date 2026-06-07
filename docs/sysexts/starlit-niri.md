# starlit-niri sysext

Current status: **Dakota-targeted phase-1 sysext scaffold**

This sysext packages the Niri session payload from the Starlit work into a directory-form `systemd-sysext` without modifying the Dakota base image.

## Elements

- `elements/starlit/niri.bst`
- `elements/sysext/starlit-niri-metadata.bst`
- `elements/sysext/starlit-niri.bst`

## Current artifact shape

The current output is a **directory-form sysext** with this layout:

```text
usr/
├── bin/
│   ├── niri
│   └── niri-session
├── lib/
│   ├── extension-release.d/
│   │   └── extension-release.starlit-niri
│   └── systemd/user/
│       ├── niri.service
│       └── niri-shutdown.target
└── share/
    ├── wayland-sessions/
    │   └── niri.desktop
    └── xdg-desktop-portal/
        └── niri-portals.conf
```

The metadata currently targets Dakota specifically:

```ini
ID=bluefin-dakota
ARCHITECTURE=x86-64|arm64
VERSION_ID=0
```

That is intentional for phase 1: prove installability and host-side visibility first, then decide whether tighter compatibility gating or `.raw` packaging is worth adding.

## Helper workflow

The worktree now includes:

- `justfiles/sysexts.just`
- `justfiles/sysext.just`
- `justfiles/sysext-starlit-niri.just`

### Build / dev machine

- `just sysext-starlit-niri` — build and check out the sysext locally
- `just sysext-starlit-niri-build` — build only
- `just sysext-starlit-niri-checkout` — check out the sysext to `.build-sysext/starlit-niri`
- `just sysext-starlit-niri-archive` — create `.build-sysext/starlit-niri.tar.gz` for transfer

### Dakota target host

- `just sysext-starlit-niri-host` — install and smoke-test on the current host
- `just sysext-starlit-niri-host-install` — install a checked-out sysext directory or compatible archive into `/var/lib/extensions/starlit-niri`
- `just sysext-starlit-niri-host-smoke` — verify merge status and the expected Niri session files
- `just sysext-starlit-niri-host-remove` — remove the installed sysext and refresh `systemd-sysext`

## Manual build / checkout / install

### Build

```bash
just bst build sysext/starlit-niri.bst
```

### Check out the artifact

```bash
rm -rf .build-sysext/starlit-niri
just bst artifact checkout sysext/starlit-niri.bst --directory /src/.build-sysext/starlit-niri
```

### Install on a Dakota host

```bash
sudo install -d /var/lib/extensions
sudo rm -rf /var/lib/extensions/starlit-niri
sudo cp -a .build-sysext/starlit-niri /var/lib/extensions/starlit-niri
sudo systemctl restart systemd-sysext.service
```

## Smoke test

```bash
systemd-sysext status
command -v niri
command -v niri-session
test -f /usr/share/wayland-sessions/niri.desktop
test -f /usr/share/xdg-desktop-portal/niri-portals.conf
test -f /usr/lib/systemd/user/niri.service
```

Expected outcome:

- `systemd-sysext status` shows `starlit-niri` as merged
- the Niri binaries are on `PATH`
- the host sees the expected session, portal, and user-unit files

## Scope note

This scaffold intentionally covers only the **Niri session payload**. It does not try to package Noctalia, Vicinae, or any broader Starlit desktop bundle in the same sysext.
