# sysext-bakery — moving CLI sysexts out of the BuildStream pipeline

> **TL;DR**: single-binary, additive CLI sysexts (pangolin, proton-pass-cli,
> btop, tailscale, …) should live in `starlit-os/sysext-bakery`, not as
> `kind: manual` `.bst` elements in this repo. The bakery is a Shell-only
> system that builds `.raw` squashfs images, ships per-extension releases
> with SHA256SUMS, and lets consumers install via `systemd-sysupdate` (or
> copy-into-`/var/lib/extensions`). Dakota's BuildStream pipeline has no
> role for these images.

## When to use the bakery

Use the bakery when **all** of the following are true:

- The sysext ships one or a few prebuilt binaries (no compile, no junction).
- It is purely additive `/usr` content — no services, no `/etc`, no `/var`.
- You want a release cadence independent of the Dakota OCI image.
- Consumers may want to install on a non-Dakota systemd-sysext-capable host.

**Do not** use the bakery for:

- Anything that should be baked into the base OCI image (use `add-package.md`).
- `/etc` overlays or config-only changes (use a base-image change, or
  investigate `confext` separately).
- Services that need a writable `/var`, lifecycle hooks, or a `chmod`
  side effect on merge.

## Why not a `.bst` element

A `kind: manual` `.bst` element that does `install -Dm755 bin "%{install-root}%{bindir}/bin"`
plus a metadata file is overkill:

- It depends on the BST build environment, the freedesktop SDK bootstrap,
  and a remote artifact cache — none of which the consumer needs.
- It produces a directory-form sysext inside the OCI pipeline. Consumers
  can't install it without the BST artifact and a separate squashfs step.
- It tights the sysext's release cadence to the Dakota image cadence.

The bakery reduces the same outcome to a 30-line Shell script plus a
pinned SHA, runs on a plain `ubuntu-latest` GitHub Actions runner, and
produces a `.raw` that drops into `/var/lib/extensions/`.

## Recipe shape (port from `_skel.sysext/create.sh`)

The bakery uses the upstream `flatcar/sysext-bakery` shape:

```
<name>.sysext/
├── create.sh            # REQUIRED: defines populate_sysext_root()
├── test.sh              # OPTIONAL marker; actual test logic in lib/test.sh
├── files/               # OPTIONAL: static /usr content to ship
│   └── ...
└── README.md            # OPTIONAL, but recommended
```

`create.sh` must define `populate_sysext_root <sysextroot> <arch> <version>`
and may define `list_available_versions` (used by `bakery.sh list`).

**Metadata is generated at create time** — you do **not** ship a
`extension-release.<name>` file in `files/`. The bakery's
`lib/generate.sh::_create_metadata` writes it with `ID=_any` (host-agnostic)
and `ARCHITECTURE=<x86-64|arm64>` based on the build matrix.

**sysupdate.conf is generated at create time** — you do **not** ship
`sysupdate.<name>.conf` either. The bakery's
`lib/generate.sh::_create_sysupdate` renders it from
`lib/sysupdate.conf.tmpl` pointing at
`https://extensions.flatcar.org/extensions/<name>/`.

## Building locally

```sh
# From the bakery repo checkout
./bakery.sh list                       # see all sysexts
./bakery.sh list pangolin              # see available upstream versions
./bakery.sh create pangolin 0.9.0      # writes pangolin.raw + SHA256SUMS.pangolin
./bakery.sh create pangolin 0.9.0 --sysupdate true  # also writes pangolin.conf
```

Requires `mksquashfs` (`apt install squashfs-tools`), `curl`, `sha256sum`,
and `jq` (for the GitHub release lister).

## Pinning upstream binaries

The current Dakota recipes ship pangolin and proton-pass-cli with pinned
SHA256 sums baked into the script via a `declare -A <NAME>_SHAS=([<ver>]="...")`
map. Update the version and the SHA in the **same commit** — never bump
the version without re-fetching the binary and updating the SHA.

To fetch a fresh SHA:

```sh
curl -fsSL -o /tmp/bin https://github.com/<org>/<repo>/releases/download/<ver>/<asset>
sha256sum /tmp/bin
```

## ID policy — generic (`ID=_any`)

Both ported sysexts use `ID=_any` to match the upstream bakery default.
This means a single `.raw` will install on any systemd-sysext-capable
host — Dakota, stock Fedora, Arch, etc.

**Caveat for dynamically linked binaries**: `pass-cli` is a Rust binary
with dynamic libstdc++/glibc dependencies. `ID=_any` is the correct
bakery default, but the README for the recipe must warn consumers to
smoke-test `pass-cli --help` on at least one non-Dakota glibc distro
before treating it as fully host-agnostic. Pangolin is `CGO_ENABLED=0`
static Go, so it has no such caveat.

If a future recipe ships a binary that is **known** to only work on
Dakota (e.g. it depends on a custom `/usr/lib` shipped only by the
image), pass `--os bluefin-dakota` to `bakery.sh create` and add
`VERSION_ID=<date>` to the metadata. The bakery's metadata writer will
add `SYSEXT_LEVEL=1.0` automatically when `--os` is not `_any`.

## Where the bakery repo lives

| Repo | Purpose |
|---|---|
| `flatcar/sysext-bakery` | Upstream. Apache-2.0. Don't fork casually. |
| `starlit-os/sysext-bakery` | Dakota's bakery. Apache-2.0. Vendored helpers (`lib/`, `bakery.sh`, `release*.sh`) come from upstream with the Apache-2.0 attribution header preserved. |
| Dakota `elements/sysext/` | **Legacy**. The pangolin and proton-pass-cli BuildStream elements live here on the `starlit-sysexts` branch for historical reasons. The follow-up PR (after the bakery ships a tagged release) deletes them. |

## Lessons Learned

### Single-binary sysexts don't need a junction or stack (2026-06-10)

Pangolin and proton-pass-cli were implemented as `kind: compose` of
two `kind: manual` elements (binary + metadata). The compose/metadata
split was inherited from older, more complex sysexts that needed a
build-time pre-processing step. For a single prebuilt binary that
just gets `install`'d into `usr/bin/`, one `kind: manual` element
would have sufficed — and even that one element was overkill: the
bakery does the same job in 30 lines of Shell without BST in the loop.

**Rule of thumb**: if the recipe would be one `install -m 0755` command
in a Dockerfile, the bakery is the right place.
