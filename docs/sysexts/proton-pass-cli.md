# Proton Pass CLI sysext

Current status: **Dakota-targeted phase-1 sysext**

This sysext packages the Proton Pass CLI from upstream Linux release binaries without modifying the Dakota base image.

## Elements

- `elements/sysext/proton-pass-cli-cli.bst`
- `elements/sysext/proton-pass-cli-metadata.bst`
- `elements/sysext/proton-pass-cli.bst`

## Current artifact shape

The current output is a **directory-form sysext** with this layout:

```text
usr/
├── bin/
│   └── pass-cli
└── lib/
    └── extension-release.d/
        └── extension-release.proton-pass-cli
```

The sysext metadata currently targets Dakota specifically:

```ini
ID=bluefin-dakota
ARCHITECTURE=x86-64|arm64
VERSION_ID=0
```

That is intentional for phase 1. The upstream Linux binary is currently dynamically linked, so this should be treated as Dakota-targeted until portability is proven on other hosts.

## Helper workflow

The repo now includes:

- `justfiles/sysexts.just` — top-level dispatcher
- `justfiles/sysext.just` — shared reusable helper recipes
- `justfiles/sysext-proton-pass-cli.just` — Proton Pass CLI-specific entry points

The recipes are split by environment:

### Build / dev machine

- `just sysext-proton-pass-cli` — build and check out the Proton Pass CLI sysext locally
- `just sysext-proton-pass-cli-build` — build only
- `just sysext-proton-pass-cli-checkout` — check out the directory-form sysext to `.build-sysext/proton-pass-cli`
- `just sysext-proton-pass-cli-archive` — create `.build-sysext/proton-pass-cli.tar.gz` for transfer to another machine

Recommended on a build machine:

```bash
just sysext-proton-pass-cli
just sysext-proton-pass-cli-archive
```

### Dakota target host

- `just sysext-proton-pass-cli-host` — install and smoke-test Proton Pass CLI on the current Dakota host
- `just sysext-proton-pass-cli-host-install` — install a checked-out sysext directory or compatible archive into `/var/lib/extensions/proton-pass-cli`
- `just sysext-proton-pass-cli-host-smoke` — verify merge status and run `pass-cli --help`
- `just sysext-proton-pass-cli-host-remove` — remove the installed sysext and refresh `systemd-sysext`

Recommended on a Dakota host:

```bash
just sysext-proton-pass-cli-host-install /path/to/proton-pass-cli
just sysext-proton-pass-cli-host-smoke
```

The `source` argument may point to either:

- a checked-out sysext directory
- an archive that unpacks to a sysext root containing `usr/`

## Manual build / checkout / install

### Build

```bash
just bst build sysext/proton-pass-cli.bst
```

### Check out the artifact

```bash
rm -rf .build-sysext/proton-pass-cli
just bst artifact checkout sysext/proton-pass-cli.bst --directory /src/.build-sysext/proton-pass-cli
```

### Archive for transfer

```bash
just sysext-proton-pass-cli-archive
```

That writes:

```text
.build-sysext/proton-pass-cli.tar.gz
```

### Install on a Dakota host

The directory name matters: it should match `extension-release.proton-pass-cli`.

If you are using the helper recipe:

```bash
just sysext-proton-pass-cli-host-install .build-sysext/proton-pass-cli
```

Or, if you are installing manually from a checked-out directory:

```bash
sudo install -d /var/lib/extensions
sudo rm -rf /var/lib/extensions/proton-pass-cli
sudo cp -a .build-sysext/proton-pass-cli /var/lib/extensions/proton-pass-cli
sudo systemctl restart systemd-sysext.service
```

## Smoke test

```bash
systemd-sysext status
which pass-cli
pass-cli --help
```

Expected outcome:

- `systemd-sysext status` shows the `proton-pass-cli` extension as merged
- `which pass-cli` resolves to `/usr/bin/pass-cli`
- `pass-cli --help` runs successfully

## Update behavior caveat

The upstream CLI ships an `update` subcommand intended for manually installed binaries. For the sysext-packaged copy, prefer replacing the sysext artifact itself rather than invoking `pass-cli update` on the host.
