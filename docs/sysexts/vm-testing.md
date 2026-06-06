# Sysext VM testing

Practical VM testing workflow for the current Dakota sysexts.

Current sysexts covered here:

- `pangolin`
- `proton-pass-cli`
- `starlit-cli`

## Goal

Verify that a sysext:

1. builds on the host
2. can be transferred into a Dakota VM
3. merges correctly with `systemd-sysext`
4. exposes the expected commands on `PATH`
5. still works after a guest reboot

## Recommendation: use `boot-vm` for the first pass

Prefer `just boot-vm` over `just boot-fast` for the initial sysext validation loop.

Why:

- `boot-vm` uses a normal bootable disk image
- sysexts are installed into `/var/lib/extensions`
- reboot persistence is part of the feature surface
- a disk-backed VM is the clearest way to validate install → merge → reboot → re-merge

`boot-fast` is still useful for quick image boot checks, but it is not the best first choice for persistence-oriented sysext testing.

## Full VM workflow

### 1. Build the Dakota image and bootable VM disk

On the host:

```bash
just build default
just generate-bootable-image default
```

Then boot it:

```bash
just boot-vm
```

## 2. Build the sysext artifacts on the host

On the host:

```bash
just sysext-pangolin
just sysext-pangolin-archive

just sysext-proton-pass-cli
just sysext-proton-pass-cli-archive

just sysext-starlit-cli
just sysext-starlit-cli-archive
```

That should produce:

```text
.build-sysext/pangolin.tar.gz
.build-sysext/proton-pass-cli.tar.gz
.build-sysext/starlit-cli.tar.gz
```

## 3. Transfer the sysext archives into the VM

Use any transfer method that is convenient in your environment:

- `scp` via the forwarded SSH port from `boot-vm`
- a temporary HTTP server
- manual copy through an existing shared path

If guest SSH is available, `boot-vm` forwards host port `2222` to guest port `22`, so the transfer pattern is typically:

```bash
scp -P 2222 .build-sysext/pangolin.tar.gz <vm-user>@127.0.0.1:/var/home/<vm-user>/
scp -P 2222 .build-sysext/proton-pass-cli.tar.gz <vm-user>@127.0.0.1:/var/home/<vm-user>/
scp -P 2222 .build-sysext/starlit-cli.tar.gz <vm-user>@127.0.0.1:/var/home/<vm-user>/
```

## 4. Install and smoke-test each sysext inside the VM

The easiest manual path is:

- unpack each archive into a temp directory
- copy the sysext root into `/var/lib/extensions/<name>`
- restart `systemd-sysext.service`
- run the command smoke test

### Pangolin

```bash
mkdir -p ~/sysext-test/pangolin
cd ~/sysext-test/pangolin
tar -xf ~/pangolin.tar.gz

sudo install -d /var/lib/extensions
sudo rm -rf /var/lib/extensions/pangolin
sudo cp -a pangolin /var/lib/extensions/pangolin
sudo systemctl restart systemd-sysext.service

systemd-sysext status
which pangolin
pangolin --help
```

### Proton Pass CLI

```bash
mkdir -p ~/sysext-test/proton-pass-cli
cd ~/sysext-test/proton-pass-cli
tar -xf ~/proton-pass-cli.tar.gz

sudo install -d /var/lib/extensions
sudo rm -rf /var/lib/extensions/proton-pass-cli
sudo cp -a proton-pass-cli /var/lib/extensions/proton-pass-cli
sudo systemctl restart systemd-sysext.service

systemd-sysext status
which pass-cli
pass-cli --help
```

### starlit-cli

```bash
mkdir -p ~/sysext-test/starlit-cli
cd ~/sysext-test/starlit-cli
tar -xf ~/starlit-cli.tar.gz

sudo install -d /var/lib/extensions
sudo rm -rf /var/lib/extensions/starlit-cli
sudo cp -a starlit-cli /var/lib/extensions/starlit-cli
sudo systemctl restart systemd-sysext.service

systemd-sysext status
which fish bat eza
fish --version
bat --version
eza --version
```

## 5. Reboot the guest once

After all three pass once interactively:

```bash
sudo systemctl reboot
```

Then re-check:

```bash
systemd-sysext status
which pangolin pass-cli fish bat eza
pangolin --help
pass-cli --help
fish --version
bat --version
eza --version
```

This confirms that the sysexts still merge correctly after a normal reboot.

## 6. Capture diagnostics if something fails

If merge or command execution fails, gather:

```bash
systemd-sysext status
systemctl --failed
journalctl -b --no-pager | tail -200
```

For command failures, also capture:

```bash
which <command>
<command> --help
```

## One-sysext-at-a-time checklist

Use this shorter checklist when you only want to validate one sysext.

### Host

```bash
just build default
just generate-bootable-image default
just boot-vm
```

Then build and archive just one sysext:

```bash
just sysext-<name>
just sysext-<name>-archive
```

### Guest

1. Copy `./build-sysext/<name>.tar.gz` into the VM
2. Unpack it into `~/sysext-test/<name>`
3. Copy the unpacked sysext root to `/var/lib/extensions/<name>`
4. Restart `systemd-sysext.service`
5. Run `systemd-sysext status`
6. Run the expected command smoke test
7. Reboot once
8. Run the same smoke test again

### Expected command checks

- `pangolin` → `pangolin --help`
- `proton-pass-cli` → `pass-cli --help`
- `starlit-cli` → `fish --version`, `bat --version`, `eza --version`

## Practical notes

### Use the archive artifacts for VM testing

For manual VM testing, prefer the `*-archive` outputs over raw BST checkouts. They are easier to move between host and guest, and the existing sysext helper workflows already support them.

### Install one sysext at a time first

When debugging a new failure, install a single sysext first before trying a stack of multiple sysexts at once. That keeps merge failures and command-path problems isolated.

### Test reboot persistence explicitly

A sysext is not fully validated just because it merged once after manual installation. Always include one reboot in the test loop before calling the result good.
