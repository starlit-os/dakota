# Building System Extension (sysext) Bundles

Use this when investigating or implementing optional system extension images for Dakota — especially additive CLI bundles that should live outside the base OCI image.

## When to Use

- Optional collections of CLI tools that should be installable/removable independently of the base image
- Additive `/usr` content that should appear on the host via `systemd-sysext`
- Bundles that may want separate release cadence or opt-in delivery

## When NOT to Use

- Base image package additions → `add-package.md`
- `/etc` overlays or config-only changes → use a base-image change, or investigate `confext` separately
- Services that require complex lifecycle, writable state, or heavy host integration
- Anything that expects package-manager semantics on the live system

## What sysext Can and Cannot Do

`systemd-sysext` overlays **only** `/usr` and optionally `/opt`.

| Path in sysext image | Effect on host |
|---|---|
| `/usr/...` | ✅ merged |
| `/opt/...` | ✅ merged |
| `/etc/...` | ❌ ignored |
| `/var/...` | ❌ ignored |

System extensions should be **purely additive**. Overlayfs technically allows replacing host files, but that is the wrong default for Dakota. Prefer new files, new binaries, new units, and private prefixes.

## Dakota-Specific Constraints

### 1. There is no sysext pipeline in-tree yet

Dakota currently builds a bootc OCI image via:

```text
elements/bluefin/deps.bst         ← stack of packages
  ↓
elements/oci/layers/bluefin.bst  ← compose filter
  ↓
elements/oci/bluefin.bst         ← final OCI assembly
```

That compose/script pattern is the closest in-repo analog for a future sysext pipeline, but there is no existing `elements/sysext/` tree today.

### 2. Phase 1 should assume **no base-image changes**

`elements/oci/os-release.bst` currently sets:

- `ID="bluefin-dakota"`
- `VERSION_ID="0"`

For the initial sysext rollout, assume the base image stays exactly as-is.
That means:

- do **not** add `SYSEXT_LEVEL` to the host yet
- do **not** depend on preinstalled sysupdate metadata in the base image
- do **not** require new base-image activation helpers just to consume a sysext

Upstream `systemd-sysext` matching only requires `ID`; `SYSEXT_LEVEL` is optional.
So the practical phase-1 choices are:

1. **Dakota-targeted sysexts** — set `ID=bluefin-dakota`, keep the payload additive/self-contained, and accept that compatibility gating is looser while `VERSION_ID="0"` remains unchanged.
2. **Portable sysexts** — use only for highly self-contained bundles where loose host matching is acceptable.

A stricter host compatibility contract via `SYSEXT_LEVEL` can be added later, but that should be treated as a separate phase because it modifies the base image.

## Required sysext Metadata

Each sysext must ship an `extension-release` file:

```text
/usr/lib/extension-release.d/extension-release.<image-name>
```

Example for a phase-1 bundle exposed to the host as `bluefin-cli.raw`:

```ini
ID=bluefin-dakota
ARCHITECTURE=x86-64
VERSION_ID=0
EXTENSION_RELOAD_MANAGER=1
```

If Dakota later grows a real host-side `SYSEXT_LEVEL`, prefer that over `VERSION_ID` for tighter compatibility checks.

### Important naming rule

The `<image-name>` suffix must match the **activated image name**. If you store versioned artifacts such as:

```text
/var/lib/extensions/bluefin-cli-1.0.0-x86-64.raw
```

then activate them via a stable symlink such as:

```text
/etc/extensions/bluefin-cli.raw -> /var/lib/extensions/bluefin-cli-1.0.0-x86-64.raw
```

and name the metadata file:

```text
/usr/lib/extension-release.d/extension-release.bluefin-cli
```

## Architecture Naming

BuildStream arch names do not exactly match systemd's extension metadata names.
Map them explicitly when writing `ARCHITECTURE=`:

| BuildStream `%{arch}` | `extension-release` `ARCHITECTURE=` |
|---|---|
| `x86_64` | `x86-64` |
| `aarch64` | `arm64` |
| `riscv64` | `riscv64` |

Do not blindly copy `%{arch}` into the metadata file.

## Recommended Dakota Design

For a first implementation, keep sysexts as a **parallel BuildStream output**, not part of `bluefin/deps.bst`.

Recommended element shape:

```text
elements/sysext/<bundle>-stack.bst      ← kind: stack, selected CLI elements
elements/sysext/<bundle>-runtime.bst    ← kind: compose, strips debug/devel/static
elements/sysext/<bundle>-image.bst      ← kind: script/manual, writes extension-release + packs .raw
```

### Why this shape

- `stack` is the natural dependency aggregator for a bundle
- `compose` is required to produce actual filesystem output
- a final `script`/`manual` element can inject `extension-release.*` and pack the tree into a sysext filesystem image

### Minimal sketch

```yaml
# elements/sysext/bluefin-cli-stack.bst
kind: stack

depends:
  - bluefin/glow.bst
  - bluefin/gum.bst
  - bluefin/fzf.bst
  - bluefin/tealdeer.bst
```

```yaml
# elements/sysext/bluefin-cli-runtime.bst
kind: compose

build-depends:
  - sysext/bluefin-cli-stack.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
```

```yaml
# elements/sysext/bluefin-cli-image.bst
kind: script

build-depends:
  - filename: sysext/bluefin-cli-runtime.bst
    config:
      location: /sysroot
  # add whichever tool element provides mkfs.erofs or mksquashfs

config:
  commands:
    - mkdir -p /sysroot/usr/lib/extension-release.d
    - |
      cat >/sysroot/usr/lib/extension-release.d/extension-release.bluefin-cli <<'EOF'
      ID=bluefin-dakota
      ARCHITECTURE=x86-64
      VERSION_ID=0
      EOF
    - mkfs.erofs "%{install-root}/bluefin-cli.raw" /sysroot
```

## Payload Strategy: Prefer Self-Contained CLI Bundles

There are two safe models:

### 1. Dakota-targeted phase-1 sysexts

Build the sysext from the same BuildStream graph as the base image, but keep it as a separate artifact and match the current host identity without changing the base image.

Use this for:

- CLI bundles built from the same SDK/runtime as Dakota
- tools that can tolerate loose initial gating via `ID=bluefin-dakota` and `VERSION_ID=0`
- the first rollout where the explicit goal is adding features without modifying the base image

If Dakota later adopts host-side `SYSEXT_LEVEL`, these bundles can be tightened in a follow-up phase.

### 2. Host-independent sysexts

Use static binaries, or ship private libraries under a private prefix rather than the host library paths.

Use this for:

- portable CLI bundles intended to work across multiple systemd/glibc distros
- software distributed from upstream prebuilt artifacts

## Dynamic Linking Risks

The biggest sysext failure mode is shipping dynamically linked binaries that assume a host ABI the base image does not provide.

Avoid installing alternate shared libraries directly into normal host search paths such as `/usr/lib` unless the bundle is tightly coupled to the exact Dakota ABI level.

Safer patterns:

- static binaries
- private prefix such as `/usr/lib/<bundle>` or `/opt/<bundle>`
- wrapper scripts or patched RPATH/interpreter for bundled libraries

This matches the main lesson from Flatcar sysext bakery and related experiments: **static or self-contained bundles scale; loosely-coupled dynamic bundles break.**

## Filesystem Format

Good sysext output formats for Dakota:

- `erofs` `.raw` image — good fit for the GNOME OS / composefs / image-based ecosystem
- `squashfs` `.raw` image — common and well understood

Prefer `erofs` if the required build tool is readily available in the BuildStream graph. Otherwise start with `squashfs`.

## Distribution Options

### Option A — publish raw sysexts directly

Ship versioned `.raw` artifacts plus checksums.

Pros:
- simple
- native `systemd-sysext` format

Cons:
- separate hosting/update UX needed

### Option B — pair raw sysexts with `systemd-sysupdate`

This is closest to the Flatcar bakery model.

Ship:
- versioned `.raw` files
- checksum metadata
- per-bundle sysupdate config snippets

Pros:
- host can auto-stage updates
- clean rollback story with versioned artifacts + stable symlink

Cons:
- more release plumbing

### Option C — distribute via OCI, extract locally

This is the `fishtank`-style pattern: publish an OCI image that carries the sysext payload, then extract the `.raw` into `/var/lib/extensions/` and refresh `systemd-sysext`.

Pros:
- fits existing OCI/GHCR habits
- good for bootc-centric workflows

Cons:
- sysext is still not consumed directly from OCI; you need an installer/extractor layer

## Recommended Rollout Order

### Phase 1 — no base-image changes

Start with:

- one optional CLI-only sysext
- no host `os-release` changes
- no preinstalled base-image plumbing beyond what Dakota already has
- manual install or an external installer/extractor flow

This keeps the experiment honest: the feature should work as an add-on, not because the base image was reshaped around it.

### Phase 2 — better compatibility and updates

Only after phase 1 proves useful, consider:

- adding host `SYSEXT_LEVEL`
- generating sysupdate metadata in-tree
- publishing an OCI installer/extractor image or dedicated update UX

## Practical First Bundle for Dakota

Dakota already ships several CLI-friendly elements in `elements/bluefin/deps.bst` that are good candidates for a first opt-in sysext bundle:

- `bluefin/glow.bst`
- `bluefin/gum.bst`
- `bluefin/fzf.bst`
- `bluefin/tealdeer.bst`

A reasonable first experiment is a `bluefin-cli` sysext built from those four, because:

- they are already packaged in BST terms
- they are additive user-facing tools
- they are easier than daemon-heavy bundles like Docker/libvirt/Kubernetes

## Validation Workflow

After building a sysext artifact:

```bash
# Inspect its filesystem contents after checkout
just bst artifact checkout sysext/bluefin-cli-image.bst --directory /tmp/bluefin-cli

# On a test host
sudo install -d /var/lib/extensions /etc/extensions
sudo cp bluefin-cli-1.0.0-x86-64.raw /var/lib/extensions/
sudo ln -snf /var/lib/extensions/bluefin-cli-1.0.0-x86-64.raw /etc/extensions/bluefin-cli.raw
sudo systemctl restart systemd-sysext.service
systemd-sysext status
which glow gum fzf tldr
```

If the merge fails, check:

1. `extension-release.*` exists
2. `ID=` matches host `os-release`
3. `SYSEXT_LEVEL=` or `VERSION_ID=` matches what the host expects
4. `ARCHITECTURE=` uses systemd names, not raw BST names
5. the image contains only `/usr` and `/opt` payloads

## Reference Patterns

- Flatcar sysext bakery: strong reference for versioned `.raw` artifacts, sysupdate integration, and self-contained payloads
- `jumpyvi/fishtank`: useful for OCI transport plus local extraction to `/var/lib/extensions`
- `zirconium-dev/zirconium-hawaii`: closest mental model for a BuildStream/Freedesktop SDK based distro producing sysext artifacts in-tree

## Lessons Learned

### Phase 1 sysexts should not assume host-side `SYSEXT_LEVEL` exists (2026-06-05)

Dakota's current `os-release` sets `VERSION_ID="0"` because the exported OCI image patches the human-facing build date later. Since the current goal is to add features **without modifying the base image**, the first sysexts should match the existing host identity and keep their payloads self-contained. A real host-side `SYSEXT_LEVEL` may still be worth adding later, but that is a separate phase.

### Treat dynamically linked sysexts as ABI-coupled unless proven otherwise (2026-06-05)

The easiest sysexts are static CLI bundles. Once a bundle ships host-visible shared libraries, it becomes tightly coupled to the target OS ABI unless everything is kept in a private prefix with controlled launch wrappers. Prefer static or self-contained bundles for the first Dakota sysexts.

### Directory-form sysexts are the lowest-friction phase-1 artifact (2026-06-05)

For the first Dakota sysexts, a plain directory artifact is enough. `systemd-sysext` can activate a directory tree directly, so you do not need to solve `mkfs.erofs`/`mksquashfs` packaging before proving the feature works. Build the payload as a `kind: compose` element, then check it out to a directory named after the extension (for example `pangolin`) so it matches `extension-release.<name>`.

### Tiny manual sysext elements still need shell + coreutils at build time (2026-06-05)

Even when a sysext element only installs one prebuilt binary or writes one metadata file, BuildStream runs the element commands inside a sandbox that still needs `sh` and standard file utilities like `install`. For small prebuilt-binary sysext elements, `freedesktop-sdk.bst:bootstrap/bash.bst` plus `freedesktop-sdk.bst:bootstrap/coreutils.bst` is sufficient and much lighter than pulling a full runtime stack.

### Multi-tool sysext bundles are easier to maintain when each tool has its own payload element (2026-06-05)

For a bundle like `starlit-cli`, keep each upstream tool in its own `elements/sysext/<bundle>-<tool>.bst` payload element and compose them together in one top-level sysext element. That keeps per-tool version bumps and archive layout fixes local to one file, and avoids hiding bundle membership behind an extra `kind: stack` layer when a directory-form `kind: compose` output is the actual artifact.

Use a bundle-specific host smoke recipe when the sysext exposes multiple commands. A single generic `command -v <name>` check is fine for one-binary bundles like Pangolin, but a collection sysext should explicitly validate each expected CLI.

### `squashfs-tools` is a practical first `.raw` backend when the SDK already carries it (2026-06-05)

If `freedesktop-sdk.bst:components/squashfs-tools.bst` is available, a naked squashfs image is the lowest-friction way to start a `.raw` sysext path. A `kind: script` element can stage the checked-out sysext tree at a fixed location such as `/sysroot` and run:

```yaml
- filename: sysext/<bundle>.bst
  config:
    location: /sysroot
```

```sh
mksquashfs /sysroot "%{install-root}/<bundle>.raw" -noappend -all-root -no-progress
```

That yields a native `systemd-sysext`-consumable image without introducing host-side image-packing assumptions into the just recipes.

### Sysupdate feeds for sysexts need both source and target `MatchPattern=` values (2026-06-05)

When defining a `systemd-sysupdate` transfer for versioned sysext `.raw` files, specify `MatchPattern=` in **both** `[Source]` and `[Target]`. For regular-file targets, the target pattern is mandatory too, and it defines both how existing versions are discovered and how new downloaded versions are named.

A practical sysext pattern is:

```ini
[Source]
Type=url-file
Path=https://example.invalid/starlit-cli
MatchPattern=starlit-cli-@v-%a.raw

[Target]
Type=regular-file
Path=/var/lib/extensions
MatchPattern=starlit-cli-@v-%a.raw
CurrentSymlink=/etc/extensions/starlit-cli.raw
InstancesMax=2
```

For local smoke testing, the same target pattern works with a `regular-file` source pointing at a local feed directory. This is a good way to validate version naming and activation behavior before publishing any remote feed.

### `systemd-sysupdate --definitions=` and `-C` are the safest ways to isolate sysext experiments (2026-06-05)

Do not mix experimental sysext update definitions into the generic host update set. Put them in a dedicated component directory such as `/etc/sysupdate.starlit-cli.d/` and invoke them with `systemd-sysupdate -C starlit-cli ...`, or point `--definitions=` at a temporary directory while testing.

That keeps the experiment self-contained and avoids accidental interaction with unrelated OS-level update definitions.

### Shared private just helpers keep per-sysext sysupdate entry points small (2026-06-05)

Once a bundle grows host-side `systemd-sysupdate` workflows, the public just targets become repetitive: install transfer, list versions, show status, update, vacuum, remove transfer, reset local state. Keep those shell implementations in private helpers in `justfiles/sysext.just` and let the per-bundle justfile pass only the component name and bundle-specific paths.

This keeps `just --summary` readable, reduces copy/paste drift between sysexts, and makes it much easier to add the same host-side sysupdate lifecycle to the next bundle.

### `just bst artifact checkout` writes to the container path, not the host path (2026-06-05)

Dakota's `just bst ...` wrapper runs inside the pinned `bst2` container with the repo mounted at `/src`. When checking out a sysext artifact to a host-visible path from a just recipe, pass the container path (for example `/src/.build-sysext/pangolin`), not the host path. Wrapping this in a dedicated just recipe avoids repeatedly getting the destination wrong.

### Separate build-machine and target-host sysext recipes (2026-06-05)

Sysext workflows naturally split across two environments: a build machine that runs BuildStream and a target host that actually activates the extension with `systemd-sysext`. Name the recipes so that split is obvious. A good pattern is `sysext-<name>` for build/check-out workflows and `sysext-<name>-host-*` for install/smoke/remove steps on the destination system.

### Host install recipes should accept either a directory or an archive (2026-06-05)

Sysext handoff between machines is easier if the target-host install recipe accepts either a checked-out directory or an archive containing the sysext root. The host recipe should normalize both inputs to a directory containing `usr/` before copying it into `/var/lib/extensions/<name>`.

### Keep a small sysext dispatcher and split per-extension justfiles (2026-06-05)

As sysext support grows, a single monolithic sysext justfile becomes hard to maintain. Keep one top-level dispatcher (for example `justfiles/sysexts.just`) imported by the root `Justfile`, keep shared private helper recipes in a common file (for example `justfiles/sysext.just`), and put each extension's user-facing workflow in its own file (for example `justfiles/sysext-pangolin.just`).
