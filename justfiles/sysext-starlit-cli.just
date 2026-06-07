# starlit-cli sysext helper workflows.
_raw := ".raw"

[group('sysext')]
sysext-starlit-cli:
    #!/usr/bin/env bash
    set -euo pipefail
    just sysext-starlit-cli-build
    just sysext-starlit-cli-checkout

[group('sysext')]
sysext-starlit-cli-build:
    just bst build sysext/starlit-cli.bst

[group('sysext')]
sysext-starlit-cli-checkout out_dir=".build-sysext/starlit-cli":
    just _sysext-checkout sysext/starlit-cli.bst "{{out_dir}}"

[group('sysext')]
sysext-starlit-cli-raw:
    #!/usr/bin/env bash
    set -euo pipefail
    just sysext-starlit-cli-raw-build
    just sysext-starlit-cli-raw-checkout

[group('sysext')]
sysext-starlit-cli-raw-build:
    just bst build sysext/starlit-cli-raw.bst

[group('sysext')]
sysext-starlit-cli-raw-checkout out_dir=".build-sysext/starlit-cli-raw":
    just _sysext-checkout sysext/starlit-cli-raw.bst "{{out_dir}}"

[group('sysext')]
sysext-starlit-cli-sysupdate-feed version source_dir=".build-sysext/starlit-cli-raw" out_dir=".build-sysext/starlit-cli-sysupdate" base_url="https://example.invalid/starlit-cli" arch="":
    #!/usr/bin/env bash
    set -euo pipefail

    if [ -z "{{version}}" ]; then
        echo "ERROR: version is required." >&2
        echo "Usage: just sysext-starlit-cli-sysupdate-feed <version> [source_dir] [out_dir] [base_url] [arch]" >&2
        exit 1
    fi

    SOURCE_DIR="{{justfile_directory()}}/{{source_dir}}"
    OUT_DIR="{{justfile_directory()}}/{{out_dir}}"
    BASE_URL="{{base_url}}"
    ARCH="{{arch}}"

    if [ -z "$ARCH" ]; then
        case "$(uname -m)" in
            x86_64) ARCH="x86-64" ;;
            aarch64) ARCH="arm64" ;;
            riscv64) ARCH="riscv64" ;;
            *)
                echo "ERROR: unsupported host arch $(uname -m). Pass the arch argument explicitly." >&2
                exit 1
                ;;
        esac
    fi

    SOURCE_RAW="$SOURCE_DIR/starlit-cli.raw"
    if [ ! -f "$SOURCE_RAW" ]; then
        echo "ERROR: ${SOURCE_RAW} not found." >&2
        echo "Run 'just sysext-starlit-cli-raw-checkout' first." >&2
        exit 1
    fi

    mkdir -p "$OUT_DIR"
    VERSIONED_RAW="starlit-cli-{{version}}-${ARCH}.raw"
    cp -f "$SOURCE_RAW" "$OUT_DIR/$VERSIONED_RAW"

    (
        cd "$OUT_DIR"
        sha256sum --binary "$VERSIONED_RAW" > SHA256SUMS
    )

    ARCH_SPEC="$(printf '\x25a')"
    MATCH_PATTERN="starlit-cli-@v-$ARCH_SPEC.raw"

    {
        echo "[Transfer]"
        echo "Verify=false"
        echo
        echo "[Source]"
        echo "Type=url-file"
        echo "Path=$BASE_URL"
        echo "MatchPattern=$MATCH_PATTERN"
        echo
        echo "[Target]"
        echo "Type=regular-file"
        echo "Path=/var/lib/extensions"
        echo "MatchPattern=$MATCH_PATTERN"
        echo "CurrentSymlink=/etc/extensions/starlit-cli{{_raw}}"
        echo "InstancesMax=2"
    } > "$OUT_DIR/starlit-cli.transfer.example"

    {
        echo "[Transfer]"
        echo "Verify=false"
        echo
        echo "[Source]"
        echo "Type=regular-file"
        echo "Path=$OUT_DIR"
        echo "MatchPattern=$MATCH_PATTERN"
        echo
        echo "[Target]"
        echo "Type=regular-file"
        echo "Path=/var/lib/extensions"
        echo "MatchPattern=$MATCH_PATTERN"
        echo "CurrentSymlink=/etc/extensions/starlit-cli{{_raw}}"
        echo "InstancesMax=2"
    } > "$OUT_DIR/starlit-cli.local.transfer"

    echo "==> Sysupdate feed staged in $OUT_DIR"
    echo "    - $VERSIONED_RAW"
    echo "    - SHA256SUMS"
    echo "    - starlit-cli.transfer.example"
    echo "    - starlit-cli.local.transfer"

[group('sysext')]
sysext-starlit-cli-archive source_dir=".build-sysext/starlit-cli" archive_path=".build-sysext/starlit-cli.tar.gz":
    just _sysext-archive "{{source_dir}}" "{{archive_path}}"

[group('sysext')]
sysext-starlit-cli-host source=".build-sysext/starlit-cli":
    #!/usr/bin/env bash
    set -euo pipefail
    just sysext-starlit-cli-host-install "{{source}}"
    just sysext-starlit-cli-host-smoke

[group('sysext')]
sysext-starlit-cli-host-install source=".build-sysext/starlit-cli":
    #!/usr/bin/env bash
    set -euo pipefail
    just _sysext-host-install starlit-cli "{{source}}" fish
    echo ""
    echo "==> Additional CLI tools on PATH"
    for cmd in bat eza atuin chezmoi dysk fd gh rg starship zoxide mise usage fnox; do
        command -v "$cmd" || true
    done

[group('sysext')]
sysext-starlit-cli-host-sysupdate source_dir=".build-sysext/starlit-cli-sysupdate":
    #!/usr/bin/env bash
    set -euo pipefail
    just sysext-starlit-cli-host-sysupdate-install-transfer "{{source_dir}}"
    just sysext-starlit-cli-host-sysupdate-list
    just sysext-starlit-cli-host-sysupdate-update

[group('sysext')]
sysext-starlit-cli-host-sysupdate-remote base_url="" transfer_path="/etc/sysupdate.starlit-cli.d/starlit-cli.transfer":
    #!/usr/bin/env bash
    set -euo pipefail

    if [ -z "{{base_url}}" ]; then
        echo "ERROR: base_url is required." >&2
        echo "Usage: just sysext-starlit-cli-host-sysupdate-remote <R2-feed-url>" >&2
        echo "Example: just sysext-starlit-cli-host-sysupdate-remote https://sysexts.example.com" >&2
        exit 1
    fi

    ARCH=""
    case "$(uname -m)" in
        x86_64) ARCH="x86-64" ;;
        aarch64) ARCH="arm64" ;;
        *)
            echo "ERROR: unsupported host arch $(uname -m)" >&2
            exit 1
            ;;
    esac

    ARCH_SPEC="$(printf '\x25a')"
    MATCH_PATTERN="starlit-cli-@v-$ARCH_SPEC.raw"

    SUDO_CMD=""
    if [ "$(id -u)" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi

    $SUDO_CMD install -d /etc/sysupdate.starlit-cli.d

    {
        echo "[Transfer]"
        echo "Verify=false"
        echo ""
        echo "[Source]"
        echo "Type=url-file"
        echo "Path={{base_url}}"
        echo "MatchPattern=$MATCH_PATTERN"
        echo ""
        echo "[Target]"
        echo "Type=regular-file"
        echo "Path=/var/lib/extensions"
        echo "MatchPattern=$MATCH_PATTERN"
        echo "CurrentSymlink=/etc/extensions/starlit-cli{{_raw}}"
        echo "InstancesMax=2"
    } > /tmp/starlit-cli.transfer

    $SUDO_CMD install -m0644 /tmp/starlit-cli.transfer "{{transfer_path}}"
    rm /tmp/starlit-cli.transfer

    echo "==> Remote sysupdate transfer installed"
    just sysext-starlit-cli-host-sysupdate-list
    just sysext-starlit-cli-host-sysupdate-update

[group('sysext')]
sysext-starlit-cli-host-sysupdate-install-transfer source_dir=".build-sysext/starlit-cli-sysupdate":
    just _sysext-host-sysupdate-install-transfer starlit-cli "{{justfile_directory()}}/{{source_dir}}/starlit-cli.local.transfer" /etc/sysupdate.starlit-cli.d /etc/sysupdate.starlit-cli.d/starlit-cli.transfer

[group('sysext')]
sysext-starlit-cli-host-sysupdate-list:
    just _sysext-host-sysupdate-list starlit-cli

[group('sysext')]
sysext-starlit-cli-host-sysupdate-status:
    just _sysext-host-sysupdate-status starlit-cli /etc/sysupdate.starlit-cli.d/starlit-cli.transfer /etc/extensions/starlit-cli{{_raw}}

[group('sysext')]
sysext-starlit-cli-host-sysupdate-update:
    just _sysext-host-sysupdate-update starlit-cli sysext-starlit-cli-host-smoke

[group('sysext')]
sysext-starlit-cli-host-sysupdate-vacuum:
    just _sysext-host-sysupdate-vacuum starlit-cli

[group('sysext')]
sysext-starlit-cli-host-sysupdate-remove-transfer:
    just _sysext-host-sysupdate-remove-transfer starlit-cli /etc/sysupdate.starlit-cli.d /etc/sysupdate.starlit-cli.d/starlit-cli.transfer

[group('sysext')]
sysext-starlit-cli-host-sysupdate-reset:
    just _sysext-host-sysupdate-reset starlit-cli /etc/sysupdate.starlit-cli.d /etc/sysupdate.starlit-cli.d/starlit-cli.transfer /etc/extensions/starlit-cli{{_raw}} '/var/lib/extensions/starlit-cli-*.raw' /var/lib/extensions/starlit-cli

[group('sysext')]
sysext-starlit-cli-host-smoke:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "==> Checking sysext merge status..."
    systemd-sysext status
    echo ""

    echo "==> Checking fish..."
    command -v fish
    fish --version
    echo ""

    echo "==> Checking bat..."
    command -v bat
    bat --version
    echo ""

    echo "==> Checking eza..."
    command -v eza
    eza --version
    echo ""

    echo "==> Checking atuin..."
    command -v atuin
    atuin --version
    echo ""

    echo "==> Checking chezmoi..."
    command -v chezmoi
    chezmoi --version
    echo ""

    echo "==> Checking dysk..."
    command -v dysk
    dysk --version
    echo ""

    echo "==> Checking fd..."
    command -v fd
    fd --version
    echo ""

    echo "==> Checking gh..."
    command -v gh
    gh --version
    echo ""

    echo "==> Checking ripgrep..."
    command -v rg
    rg --version
    echo ""

    echo "==> Checking starship..."
    command -v starship
    starship --version
    echo ""

    echo "==> Checking zoxide..."
    command -v zoxide
    zoxide --version
    echo ""

    echo "==> Checking mise..."
    command -v mise
    mise --version
    echo ""

    echo "==> Checking usage..."
    command -v usage
    usage --version
    echo ""

    echo "==> Checking fnox..."
    command -v fnox
    fnox --version
    echo ""

    echo "PASS: starlit-cli sysext is active and all tools run"

[group('sysext')]
sysext-starlit-cli-host-remove:
    just _sysext-host-remove starlit-cli
