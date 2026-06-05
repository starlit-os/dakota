# Pangolin CLI sysext

Current status: **Dakota-targeted phase-1 sysext**

This sysext packages the Pangolin CLI from upstream release artifacts without modifying the Dakota base image.

## Elements

- `elements/sysext/pangolin-cli.bst`
- `elements/sysext/pangolin-metadata.bst`
- `elements/sysext/pangolin.bst`

## Current artifact shape

The current output is a **directory-form sysext** with this layout:

```text
usr/
├── bin/
│   └── pangolin
└── lib/
    └── extension-release.d/
        └── extension-release.pangolin
```

The sysext metadata currently targets Dakota specifically:

```ini
ID=bluefin-dakota
ARCHITECTURE=x86-64|arm64
VERSION_ID=0
```

That is intentional for phase 1: prove installability and runtime behavior first, then decide whether to relax matching later.

## Helper workflow

The repo now includes:

- `justfiles/sysexts.just` — top-level dispatcher
- `justfiles/sysext.just` — shared reusable helper recipes
- `justfiles/sysext-pangolin.just` — Pangolin-specific entry points

The recipes are split by environment:

### Build / dev machine

- `just sysext-pangolin` — build and check out the Pangolin sysext locally
- `just sysext-pangolin-build` — build only
- `just sysext-pangolin-checkout` — check out the directory-form sysext to `.build-sysext/pangolin`
- `just sysext-pangolin-archive` — create `.build-sysext/pangolin.tar.gz` for transfer to another machine

Recommended on a build machine:

```bash
mise exec -- just sysext-pangolin
mise exec -- just sysext-pangolin-archive
```

### Dakota target host

- `just sysext-pangolin-host` — install and smoke-test Pangolin on the current Dakota host
- `just sysext-pangolin-host-install` — install a checked-out sysext directory or compatible archive into `/var/lib/extensions/pangolin`
- `just sysext-pangolin-host-smoke` — verify merge status and run `pangolin --help`
- `just sysext-pangolin-host-remove` — remove the installed sysext and refresh `systemd-sysext`

Recommended on a Dakota host:

```bash
mise exec -- just sysext-pangolin-host-install /path/to/pangolin
mise exec -- just sysext-pangolin-host-smoke
```

The `source` argument may point to either:

- a checked-out sysext directory
- an archive that unpacks to a sysext root containing `usr/`

## Manual build / checkout / install

If you need the lower-level flow, the helper recipes above wrap these steps.

### Build

```bash
mise exec -- just bst build sysext/pangolin.bst
```

### Check out the artifact

`just bst` runs inside the pinned `bst2` container with the repo mounted at `/src`, so checkout destinations should be written under `/src/...` if you want the files on the host.

Example:

```bash
rm -rf .build-sysext/pangolin
mise exec -- just bst artifact checkout sysext/pangolin.bst --directory /src/.build-sysext/pangolin
```

After that, the host working tree will contain:

```text
.build-sysext/pangolin/
```

### Archive for transfer

To create a transport-friendly archive:

```bash
mise exec -- just sysext-pangolin-archive
```

That writes:

```text
.build-sysext/pangolin.tar.gz
```

### Install on a Dakota host

The directory name matters: it should match `extension-release.pangolin`.

If you are using the helper recipe:

```bash
mise exec -- just sysext-pangolin-host-install .build-sysext/pangolin
```

Or, if you are installing manually from a checked-out directory:

```bash
sudo install -d /var/lib/extensions
sudo rm -rf /var/lib/extensions/pangolin
sudo cp -a .build-sysext/pangolin /var/lib/extensions/pangolin
sudo systemctl restart systemd-sysext.service
```

## Smoke test

```bash
systemd-sysext status
which pangolin
pangolin --help
```

Expected outcome:

- `systemd-sysext status` shows the `pangolin` extension as merged
- `which pangolin` resolves to `/usr/bin/pangolin`
- `pangolin --help` runs successfully

## Remove / disable

```bash
sudo rm -rf /var/lib/extensions/pangolin
sudo systemctl restart systemd-sysext.service
```

## Why Pangolin is a good first sysext

Pangolin is a strong first candidate because it is:

- one additive CLI
- shipped as an upstream Linux release binary
- built upstream with `CGO_ENABLED=0`
- free of `/etc` payloads in the current sysext
- free of systemd service integration in the current sysext

That makes it a much better portability candidate than daemon-heavy bundles.

## Path to a host-independent Pangolin sysext

Do **not** convert the metadata yet. First prove portability.

### Step 1 — verify the binary remains self-contained upstream

On every upstream version bump, re-check the upstream build shape:

- release automation still uses `CGO_ENABLED=0`
- the shipped Linux assets are still single binaries
- no new external runtime files are required

Suggested checks:

```bash
# upstream repository inspection
# - Makefile / release workflow still builds linux artifacts with CGO_ENABLED=0
```

If you inspect the built artifact locally, prefer checks like:

```bash
file /path/to/pangolin
ldd /path/to/pangolin
```

Desired outcome:

- `file` indicates a normal Linux ELF binary
- `ldd` reports `not a dynamic executable` or otherwise shows no problematic host-library dependency chain

### Step 2 — confirm runtime portability on multiple hosts

Before changing metadata, run the same directory-form sysext on multiple target systems.

Minimum recommended matrix:

| Host | Why |
|---|---|
| Dakota | current target |
| GNOME OS | closest upstream image-based host |
| Zirconium Hawaii | BuildStream/FDO-based but non-Dakota host |
| One general systemd+glibc distro | catches non-image-based assumptions |

For each host, validate:

```bash
systemd-sysext status
which pangolin
pangolin --help
```

And, if practical, a real login/connect flow against a Pangolin environment.

### Step 3 — confirm there are no host-specific hidden dependencies

Portability is not only about libc.

Confirm Pangolin does not unexpectedly require:

- Dakota-specific files under `/etc`
- Dakota-specific units or services
- a host path convention unique to Dakota
- capabilities or kernel interfaces that only happen to be present on one test host

### Step 4 — choose and validate a more portable metadata policy

Only after steps 1–3 pass should you relax `elements/sysext/pangolin-metadata.bst`.

At that point, validate against the actual `systemd-sysext` versions on target hosts and choose a less host-coupled metadata scheme.

Keep two constraints in mind:

- `ARCHITECTURE=` should stay explicit (`x86-64`, `arm64`, etc.)
- the chosen `ID` / version matching behavior must be supported by the target hosts' systemd versions

Do not assume a fully generic `ID` strategy is safe until it has been tested on the actual host matrix above.

### Step 5 — only then rename it in docs as host-independent

After the metadata is relaxed and the host matrix passes, update this document to say the Pangolin sysext is host-independent and record:

- exact metadata used
- exact host matrix tested
- any known exclusions

## Notes for future work

- A `.raw` image format can come later; the current directory-form artifact is enough for functional proof.
- If a future Pangolin release starts depending on host libraries or extra runtime files, reconsider whether it should remain a portability candidate.
