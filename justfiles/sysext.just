# Shared sysext helper recipes.
#
# Imported by `justfiles/sysexts.just`, then used by per-extension justfiles.
# Keep these helpers private so only the user-facing per-extension entry points
# show up in `just --list` / `just --summary`.

[private]
_sysext-checkout element out_dir:
    #!/usr/bin/env bash
    set -euo pipefail

    HOST_OUT="{{justfile_directory()}}/{{out_dir}}"
    CONTAINER_OUT="/src/{{out_dir}}"

    rm -rf "$HOST_OUT"
    mkdir -p "$(dirname "$HOST_OUT")"

    echo "==> Checking out {{element}} to ${HOST_OUT}..."
    just bst artifact checkout {{element}} --directory "$CONTAINER_OUT"

[private]
_sysext-archive source_dir archive_path:
    #!/usr/bin/env bash
    set -euo pipefail

    SOURCE="{{justfile_directory()}}/{{source_dir}}"
    ARCHIVE="{{justfile_directory()}}/{{archive_path}}"

    if [ ! -d "$SOURCE" ]; then
        echo "ERROR: ${SOURCE} not found." >&2
        echo "Run the corresponding sysext checkout recipe first." >&2
        exit 1
    fi

    mkdir -p "$(dirname "$ARCHIVE")"
    rm -f "$ARCHIVE"

    echo "==> Creating archive ${ARCHIVE}..."
    tar -C "$(dirname "$SOURCE")" -czf "$ARCHIVE" "$(basename "$SOURCE")"

[private]
_sysext-host-install name source probe_command:
    #!/usr/bin/env bash
    set -euo pipefail

    INPUT="{{source}}"
    INPUT_ABS="$(realpath -m "$INPUT")"
    STAGE_DIR=""
    CLEANUP_DIR=""

    resolve_sysext_root() {
        local candidate="$1"

        if [ -d "$candidate/usr" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi

        local entries=()
        while IFS= read -r entry; do
            entries+=("$entry")
        done < <(find "$candidate" -mindepth 1 -maxdepth 1 -type d | sort)

        if [ "${#entries[@]}" -eq 1 ] && [ -d "${entries[0]}/usr" ]; then
            printf '%s\n' "${entries[0]}"
            return 0
        fi

        return 1
    }

    if [ -d "$INPUT_ABS" ]; then
        STAGE_DIR="$(resolve_sysext_root "$INPUT_ABS")" || {
            echo "ERROR: ${INPUT_ABS} does not look like a sysext directory." >&2
            echo "Expected a root containing usr/ or a single top-level directory containing usr/." >&2
            exit 1
        }
    elif [ -f "$INPUT_ABS" ]; then
        CLEANUP_DIR="$(mktemp -d)"
        if command -v bsdtar >/dev/null 2>&1; then
            bsdtar -xf "$INPUT_ABS" -C "$CLEANUP_DIR"
        else
            tar -xf "$INPUT_ABS" -C "$CLEANUP_DIR"
        fi

        STAGE_DIR="$(resolve_sysext_root "$CLEANUP_DIR")" || {
            echo "ERROR: ${INPUT_ABS} did not unpack into a recognizable sysext directory." >&2
            rm -rf "$CLEANUP_DIR"
            exit 1
        }
    else
        echo "ERROR: ${INPUT} not found." >&2
        echo "Pass a checked-out sysext directory or an archive containing one." >&2
        exit 1
    fi

    trap '[ -n "$CLEANUP_DIR" ] && rm -rf "$CLEANUP_DIR"' EXIT

    SUDO_CMD=""
    if [ "$(id -u)" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi

    echo "==> Installing {{name}} sysext from ${INPUT_ABS}..."
    $SUDO_CMD install -d /var/lib/extensions
    $SUDO_CMD rm -rf /var/lib/extensions/{{name}}
    $SUDO_CMD cp -a "$STAGE_DIR" /var/lib/extensions/{{name}}
    $SUDO_CMD systemctl restart systemd-sysext.service

    echo ""
    echo "==> systemd-sysext status"
    systemd-sysext status || true
    echo ""
    echo "==> Probe command on PATH"
    command -v {{probe_command}} || true

[private]
_sysext-host-smoke binary pass_name:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "==> Checking sysext merge status..."
    systemd-sysext status
    echo ""

    echo "==> Checking {{binary}}..."
    command -v {{binary}}
    {{binary}} --help >/dev/null
    echo "PASS: {{pass_name}} sysext is active and {{binary}} runs"

[private]
_sysext-host-remove name:
    #!/usr/bin/env bash
    set -euo pipefail

    SUDO_CMD=""
    if [ "$(id -u)" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi

    echo "==> Removing {{name}} sysext..."
    $SUDO_CMD rm -rf /var/lib/extensions/{{name}}
    $SUDO_CMD systemctl restart systemd-sysext.service

[private]
_sysext-host-sysupdate-install-transfer component transfer_source transfer_directory transfer_filename:
    #!/usr/bin/env bash
    set -euo pipefail

    TRANSFER_SOURCE="{{transfer_source}}"

    if [ ! -f "$TRANSFER_SOURCE" ]; then
        echo "ERROR: ${TRANSFER_SOURCE} not found." >&2
        echo "Generate the sysupdate feed and local transfer file first." >&2
        exit 1
    fi

    SUDO_CMD=""
    if [ "$(id -u)" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi

    echo "==> Installing sysupdate transfer for {{component}}..."
    $SUDO_CMD install -d {{transfer_directory}}
    $SUDO_CMD install -m0644 "$TRANSFER_SOURCE" {{transfer_filename}}

[private]
_sysext-host-sysupdate-list component:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "==> Listing {{component}} sysupdate versions..."
    systemd-sysupdate --no-pager -C {{component}} list

[private]
_sysext-host-sysupdate-status component transfer_filename symlink_path:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "==> Installed transfer definition"
    if [ -f {{transfer_filename}} ]; then
        echo "{{transfer_filename}}"
    else
        echo "(not installed)"
    fi
    echo ""

    echo "==> Current symlink target"
    if [ -L {{symlink_path}} ]; then
        readlink -f {{symlink_path}} || true
    else
        echo "(no {{symlink_path}} symlink)"
    fi
    echo ""

    echo "==> sysupdate versions"
    systemd-sysupdate --no-pager -C {{component}} list || true
    echo ""

    echo "==> systemd-sysext status"
    systemd-sysext status || true

[private]
_sysext-host-sysupdate-update component smoke_recipe:
    #!/usr/bin/env bash
    set -euo pipefail

    SUDO_CMD=""
    if [ "$(id -u)" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi

    echo "==> Updating {{component}} via systemd-sysupdate..."
    $SUDO_CMD systemd-sysupdate --no-pager -C {{component}} update
    $SUDO_CMD systemctl restart systemd-sysext.service
    just {{smoke_recipe}}

[private]
_sysext-host-sysupdate-vacuum component:
    #!/usr/bin/env bash
    set -euo pipefail

    SUDO_CMD=""
    if [ "$(id -u)" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi

    echo "==> Vacuuming old {{component}} sysupdate versions..."
    $SUDO_CMD systemd-sysupdate --no-pager -C {{component}} vacuum
    echo ""
    echo "==> Remaining {{component}} sysupdate versions"
    systemd-sysupdate --no-pager -C {{component}} list

[private]
_sysext-host-sysupdate-remove-transfer component transfer_directory transfer_filename:
    #!/usr/bin/env bash
    set -euo pipefail

    SUDO_CMD=""
    if [ "$(id -u)" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi

    echo "==> Removing {{component}} sysupdate transfer..."
    $SUDO_CMD rm -f {{transfer_filename}}
    $SUDO_CMD rmdir {{transfer_directory}} 2>/dev/null || true

[private]
_sysext-host-sysupdate-reset component transfer_directory transfer_filename symlink_path versioned_glob unpacked_path:
    #!/usr/bin/env bash
    set -euo pipefail

    SUDO_CMD=""
    if [ "$(id -u)" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi

    echo "==> Resetting local {{component}} sysupdate state..."

    if command -v systemd-sysupdate >/dev/null 2>&1; then
        $SUDO_CMD systemd-sysupdate --no-pager -C {{component}} vacuum || true
    fi

    $SUDO_CMD rm -f {{transfer_filename}}
    $SUDO_CMD rmdir {{transfer_directory}} 2>/dev/null || true

    $SUDO_CMD rm -f {{symlink_path}}
    $SUDO_CMD rm -f {{versioned_glob}}
    $SUDO_CMD rm -rf {{unpacked_path}}

    $SUDO_CMD systemctl restart systemd-sysext.service

    echo ""
    echo "==> Post-reset sysext status"
    systemd-sysext status || true
