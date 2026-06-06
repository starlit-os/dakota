# starlit-cli sysext

Current status: **Dakota-targeted phase-1 sysext**

This sysext packages a small CLI collection without modifying the Dakota base image.

## Included tools

- `fish`
- `bat`
- `eza`

## Elements

- `elements/sysext/starlit-cli-fish.bst`
- `elements/sysext/starlit-cli-bat.bst`
- `elements/sysext/starlit-cli-eza.bst`
- `elements/sysext/starlit-cli-metadata.bst`
- `elements/sysext/starlit-cli.bst`
- `elements/sysext/starlit-cli-raw.bst`

## Current artifact shape

The default output is a **directory-form sysext** with this layout:

```text
usr/
├── bin/
│   ├── bat
│   ├── eza
│   └── fish
├── lib/
│   └── extension-release.d/
│       └── extension-release.starlit-cli
└── share/
    ├── bash-completion/
    ├── fish/
    ├── man/
    └── zsh/
```

The sysext metadata currently targets Dakota specifically:

```ini
ID=bluefin-dakota
ARCHITECTURE=x86-64|arm64
VERSION_ID=0
```

That is intentional for phase 1: `fish` ships as a static upstream standalone binary, but `bat` and `eza` are currently packaged from upstream GNU/Linux release tarballs and should be treated as Dakota-targeted until portability is proven on other hosts.

## Experimental `.raw` / sysupdate path

The repo now also includes `elements/sysext/starlit-cli-raw.bst`, which repacks the checked sysext tree as a **naked squashfs `.raw` image** named `starlit-cli.raw`.

This is the first step toward a `systemd-sysupdate`-managed delivery flow without changing the Dakota base image.

### Build the `.raw` artifact

- `just sysext-starlit-cli-raw` — build and check out the raw artifact
- `just sysext-starlit-cli-raw-build` — build only
- `just sysext-starlit-cli-raw-checkout` — check out the raw artifact to `.build-sysext/starlit-cli-raw`

Recommended:

```bash
just sysext-starlit-cli-raw
```

That produces:

```text
.build-sysext/starlit-cli-raw/
└── starlit-cli.raw
```

### Stage a sysupdate feed directory

- `just sysext-starlit-cli-sysupdate-feed <version>` — copy the raw image into a versioned filename, generate `SHA256SUMS`, and write a transfer-file example

Example:

```bash
just sysext-starlit-cli-sysupdate-feed 0.1.0
```

That writes:

```text
.build-sysext/starlit-cli-sysupdate/
├── SHA256SUMS
├── starlit-cli-0.1.0-x86-64.raw
├── starlit-cli.local.transfer
└── starlit-cli.transfer.example
```

If the build host architecture does not match the target sysupdate architecture naming you want, pass the final `arch` argument explicitly (for example `arm64`).

### Transfer-file examples

The generated remote example uses a `url-file` source and Dakota's current extension target path:

```ini
[Transfer]
Verify=false

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

For real publication, replace `Path=` with the feed URL that serves:

- the versioned `.raw` files
- `SHA256SUMS`
- optionally `SHA256SUMS.gpg` once signature verification is enabled

Keep `Verify=false` only for local experiments or unsigned test feeds. A published feed should eventually ship signed manifests and flip verification on.

The generated local example is intended for host-side smoke testing against the staged feed directory itself:

```ini
[Transfer]
Verify=false

[Source]
Type=regular-file
Path=/absolute/path/to/.build-sysext/starlit-cli-sysupdate
MatchPattern=starlit-cli-@v-%a.raw

[Target]
Type=regular-file
Path=/var/lib/extensions
MatchPattern=starlit-cli-@v-%a.raw
CurrentSymlink=/etc/extensions/starlit-cli.raw
InstancesMax=2
```

### Host-side local sysupdate smoke flow

The repo now includes host-side recipes for installing the generated local transfer file and exercising `systemd-sysupdate` directly:

- `just sysext-starlit-cli-host-sysupdate-install-transfer` — install the generated local transfer file to `/etc/sysupdate.starlit-cli.d/starlit-cli.transfer`
- `just sysext-starlit-cli-host-sysupdate-list` — run `systemd-sysupdate -C starlit-cli list`
- `just sysext-starlit-cli-host-sysupdate-status` — show the installed transfer definition, current `/etc/extensions/starlit-cli.raw` symlink target, `systemd-sysupdate -C starlit-cli list`, and `systemd-sysext status`
- `just sysext-starlit-cli-host-sysupdate-update` — run `systemd-sysupdate -C starlit-cli update`, restart `systemd-sysext`, and reuse the normal bundle smoke test
- `just sysext-starlit-cli-host-sysupdate-vacuum` — remove older installed `starlit-cli` sysupdate versions beyond the configured retention window and show the remaining versions
- `just sysext-starlit-cli-host-sysupdate-remove-transfer` — remove the installed transfer file
- `just sysext-starlit-cli-host-sysupdate-reset` — reset the local host-side experiment by removing the transfer definition, symlink, installed versioned raw files, and unpacked directory-form extension, then restart `systemd-sysext`
- `just sysext-starlit-cli-host-sysupdate` — install transfer, list, and update in one flow

Recommended local smoke path on a Dakota host:

```bash
just sysext-starlit-cli-raw
just sysext-starlit-cli-sysupdate-feed 0.1.0
just sysext-starlit-cli-host-sysupdate
```

This assumes the host has `systemd-sysupdate` available. The recipe installs only the transfer definition; the staged `.raw` file remains in the working tree feed directory you generated locally.

If you repeat the smoke flow with multiple versions, use:

```bash
just sysext-starlit-cli-host-sysupdate-vacuum
```

That delegates cleanup to `systemd-sysupdate vacuum`, which is safer than manually deleting versioned files under `/var/lib/extensions` because it respects the transfer definition's naming and retention rules.

For a quick consolidated view of the current host state, use:

```bash
just sysext-starlit-cli-host-sysupdate-status
```

To return the host to a clean slate for another local test cycle, use:

```bash
just sysext-starlit-cli-host-sysupdate-reset
```

This intentionally only removes `starlit-cli`-specific state under `/etc/extensions`, `/etc/sysupdate.starlit-cli.d`, and `/var/lib/extensions`.

## Helper workflow

The repo now includes:

- `justfiles/sysexts.just` — top-level dispatcher
- `justfiles/sysext.just` — shared reusable helper recipes
- `justfiles/sysext-starlit-cli.just` — starlit-cli-specific entry points

The recipes are split by environment:

### Build / dev machine

- `just sysext-starlit-cli` — build and check out the starlit-cli sysext locally
- `just sysext-starlit-cli-build` — build only
- `just sysext-starlit-cli-checkout` — check out the directory-form sysext to `.build-sysext/starlit-cli`
- `just sysext-starlit-cli-archive` — create `.build-sysext/starlit-cli.tar.gz` for transfer to another machine

Recommended on a build machine:

```bash
just sysext-starlit-cli
just sysext-starlit-cli-archive
```

### Dakota target host

- `just sysext-starlit-cli-host` — install and smoke-test the bundle on the current Dakota host
- `just sysext-starlit-cli-host-install` — install a checked-out sysext directory or compatible archive into `/var/lib/extensions/starlit-cli`
- `just sysext-starlit-cli-host-smoke` — verify merge status and run `fish`, `bat`, and `eza`
- `just sysext-starlit-cli-host-remove` — remove the installed sysext and refresh `systemd-sysext`

Recommended on a Dakota host:

```bash
just sysext-starlit-cli-host-install /path/to/starlit-cli
just sysext-starlit-cli-host-smoke
```

The `source` argument may point to either:

- a checked-out sysext directory
- an archive that unpacks to a sysext root containing `usr/`

## Manual build / checkout / install

### Build

```bash
just bst build sysext/starlit-cli.bst
```

### Check out the artifact

```bash
rm -rf .build-sysext/starlit-cli
just bst artifact checkout sysext/starlit-cli.bst --directory /src/.build-sysext/starlit-cli
```

### Archive for transfer

```bash
just sysext-starlit-cli-archive
```

That writes:

```text
.build-sysext/starlit-cli.tar.gz
```

### Install on a Dakota host

The directory name matters: it should match `extension-release.starlit-cli`.

If you are using the helper recipe:

```bash
just sysext-starlit-cli-host-install .build-sysext/starlit-cli
```

Or, if you are installing manually from a checked-out directory:

```bash
sudo install -d /var/lib/extensions
sudo rm -rf /var/lib/extensions/starlit-cli
sudo cp -a .build-sysext/starlit-cli /var/lib/extensions/starlit-cli
sudo systemctl restart systemd-sysext.service
```

## Smoke test

```bash
systemd-sysext status
which fish bat eza
fish --version
bat --version
eza --version
```

Expected outcome:

- `systemd-sysext status` shows the `starlit-cli` extension as merged
- `which fish bat eza` resolves under `/usr/bin`
- each command prints its version successfully

## Remove / disable

```bash
sudo rm -rf /var/lib/extensions/starlit-cli
sudo systemctl restart systemd-sysext.service
```

## Notes for future work

- If `bat` or `eza` move to more self-contained upstream Linux artifacts on both supported architectures, revisit whether this bundle can become host-independent.
- If we want completions or docs beyond what upstream release tarballs provide, add them in the per-tool payload elements rather than in the metadata/bundle element.
