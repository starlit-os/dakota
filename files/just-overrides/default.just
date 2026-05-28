# vim: set ft=make :
# These are convenience shortcuts, they should not be specific to a desktop, aimed to be rather generic things for both Aurora and Bluefin

uid := `id -u`
shell := `grep :$(id -u): /etc/passwd | cut -d: -f7`

# Boot into this device's BIOS/UEFI screen
bios:
    #!/usr/bin/bash
    if [ ! -d /sys/firmware/efi ]; then
      echo "Rebooting to legacy BIOS from OS is not supported."
      exit 1
    fi

    if gum confirm "Reboot into BIOS?" ; then
      systemctl reboot --firmware-setup
    fi

# Show BIOS info
bios-info:
    #!/usr/bin/bash
    sudo bash <<'EOF'
    echo "Manufacturer: $(dmidecode -s baseboard-manufacturer)"
    echo "Product Name: $(dmidecode -s baseboard-product-name)"
    echo "Version: $(dmidecode -s bios-version)"
    echo "Release Date: $(dmidecode -s bios-release-date)"
    EOF

clean-system:
    #!/usr/bin/bash
    if gum confirm "Prune all Podman images and volumes?"; then
        podman image prune -af
        podman volume prune -f
    fi

    if command -v docker >/dev/null 2>&1; then
      if gum confirm "Prune all Docker images and volumes?"; then
        docker image prune -af
        docker volume prune -f
      fi
    fi

    flatpak uninstall --unused
    if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        brew autoremove
        brew cleanup
    fi

# Show all messages from this boot
logs-this-boot:
    sudo journalctl --no-hostname -b 0

# Show all messages from last boot
logs-last-boot:
    sudo journalctl --no-hostname -b -1

# Enroll Nvidia driver & KMOD signing key for secure boot - Enter password "universalblue" if prompted
enroll-secure-boot-key:
    #!/usr/bin/bash
    ENROLLMENT_PASSWORD="universalblue"
    sudo bash <<EOF
    mokutil --timeout -1
    echo -e "$ENROLLMENT_PASSWORD\n$ENROLLMENT_PASSWORD" | mokutil --import "/etc/pki/akmods/certs/akmods-ublue.der"
    EOF
    echo 'At next reboot, the mokutil UEFI menu UI will be displayed (*QWERTY* keyboard input and navigation).\nThen, select "Enroll MOK", and input "universalblue" as the password'

# Toggle display of the user-motd in terminal
toggle-user-motd:
    #!/usr/bin/bash
    if [ -e "${HOME}/.config/no-show-user-motd" ] ; then
      if gum confirm "Would you like to enable the MOTD?" ; then
        rm -f "${HOME}/.config/no-show-user-motd"
        echo "MOTD will now be shown on login."
        exit 0
      fi
    fi
    if gum confirm "Would you like to disable the MOTD?" ; then
      mkdir -p "${HOME}/.config"
      touch "${HOME}/.config/no-show-user-motd"
      echo "MOTD will not be shown anynow"
      exit 0
    fi

# Check for local overrides
check-local-overrides:
    #!/usr/bin/bash
    RESET="\x1b[0m"
    if [ "${NO_COLOR}" == 1 ]; then
        BLUE_COLOR=""
        GREEN_COLOR=""
        YELLOW_COLOR=""
    else
        BLUE_COLOR="${BLUE_COLOR:-\x1b[38;5;117m}"
        GREEN_COLOR="${GREEN_COLOR:-\x1b[38;5;85m}"
        YELLOW_COLOR="${YELLOW_COLOR:-\x1b[93m}"
    fi

    diff -qr \
      --suppress-common-lines \
      --color="always" \
      --exclude "passwd*" \
      --exclude "group*" \
      --exclude="subgid*" \
      --exclude="subuid*" \
      --exclude="machine-id" \
      --exclude="adjtime" \
      --exclude="fstab" \
      --exclude="system-connections" \
      --exclude="shadow*" \
      --exclude="gshadow*" \
      --exclude="ssh_host*" \
      --exclude="cmdline" \
      --exclude="crypttab" \
      --exclude="hostname" \
      --exclude="localtime" \
      --exclude="locale*" \
      --exclude="*lock" \
      --exclude=".updated" \
      --exclude="*LOCK" \
      --exclude="vconsole*" \
      --exclude="00-keyboard.conf" \
      --exclude="grub" \
      --exclude="system.control*" \
      --exclude="cdi" \
      --exclude="default.target" \
      /usr/etc /etc 2>/dev/null | sed \
          -e '/Binary\ files\ /d ; /Common subdirectories/d' \
          -e "/Files/ s/^/${BLUE_COLOR}&/g" \
          -e "/Files/ s/\$/&${RESET}/g" \
          -e "/Only in/ s/^/${GREEN_COLOR}&/g" \
          -e "/Only in/ s/\$/&${RESET}/g" \
          -e "s/\:.*/${RESET}${YELLOW_COLOR}&${RESET}/g"

# Collect a privacy-respecting diagnostic report and upload to your GitHub gist.
# The gist is yours — you can view, share, or delete it any time.
# ujust report
report:
    #!/usr/bin/bash
    set -euo pipefail

    REPORT_DIR="$(mktemp -d /tmp/ujust-report-XXXXXX)"
    OTEL_CONFIG=""
    cleanup() {
        rm -rf "$REPORT_DIR"
        [[ -n "$OTEL_CONFIG" ]] && rm -f "$OTEL_CONFIG"
    }
    trap cleanup EXIT

    # ── Pre-OTel: collect command-based data ─────────────────────────────────

    echo "Collecting system information..."

    BOOTC_JSON=$(sudo bootc status --json 2>/dev/null || echo '{}')
    BOOTED_IMAGE=$(echo "$BOOTC_JSON" | jq -r '.status.booted.image.image.image // "unknown"')
    BOOTED_DIGEST=$(echo "$BOOTC_JSON" | jq -r '.status.booted.imageDigest // "unknown"')
    STAGED_IMAGE=$(echo "$BOOTC_JSON" | jq -r '.status.staged.image.image.image // "none"')

    GNOME_VERSION=$(gnome-shell --version 2>/dev/null || echo "unknown")
    GNOME_EXTENSIONS=$(gnome-extensions list --enabled 2>/dev/null || echo "")

    FLATPAK_LIST=$(flatpak list --columns=application,version 2>/dev/null || echo "unavailable")

    LOAD_AVG=$(awk '{print $1", "$2", "$3}' /proc/loadavg)
    MEM_INFO=$(free -h --si | awk '/^Mem:/{print $3" used / "$2" total"}')
    FAILED_UNITS=$(systemctl list-units --state=failed --no-legend --plain 2>/dev/null \
                   | awk '{print $1}' | head -20 || echo "")
    KERNEL_VER=$(uname -r)

    # Scrub /home/<user>/ paths from collected strings
    FLATPAK_LIST=$(echo "$FLATPAK_LIST" | sed -E 's|/home/[^/[:space:]]+/|/home/<redacted>/|g')
    GNOME_EXTENSIONS=$(echo "$GNOME_EXTENSIONS" | sed -E 's|/home/[^/[:space:]]+/|/home/<redacted>/|g')

    # ── OTel phase: collect system information donation (opt-in) ─────────────────

    SKIP_OTEL=1
    if gum confirm "Collect detailed system metrics? (adds ~35s, useful for deep debugging)" --default=false; then
        SKIP_OTEL=0
    fi

    if [[ "$SKIP_OTEL" -eq 0 ]]; then
        echo "Collecting system information donation (35 seconds)..."

        OTEL_CONFIG="$(mktemp /tmp/ujust-report-otel-XXXXXX.yaml)"
        sed "s|/output/|${REPORT_DIR}/|g" \
            /usr/share/ublue-os/just/otel/ujust-report-config.yaml > "$OTEL_CONFIG"

    OTELCOL_BINARY=""
    for candidate in \
        "$HOME/.local/bin/otelcol-contrib" \
        "/usr/local/bin/otelcol-contrib" \
        "$(command -v otelcol-contrib 2>/dev/null || true)"; do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            OTELCOL_BINARY="$candidate"
            break
        fi
    done

    if [[ -n "$OTELCOL_BINARY" ]]; then
        timeout 35 "$OTELCOL_BINARY" --config "$OTEL_CONFIG" 2>/dev/null || true
    elif command -v podman &>/dev/null; then
        timeout 45 podman run --rm --privileged \
            --network=host \
            -v /proc:/proc:ro \
            -v /sys:/sys:ro \
            -v /var/log/journal:/var/log/journal:ro \
            -v /run/log/journal:/run/log/journal:ro \
            -v "${OTEL_CONFIG}:/etc/otelcol/config.yaml:ro" \
            -v "${REPORT_DIR}:/output" \
            docker.io/otel/opentelemetry-collector-contrib@sha256:a2a52e43c1a80aa94120ad78c2db68780eb90e6d11c8db5b3ce2f6a0cc6b5029 \
            2>/dev/null || true
    else
        echo "Warning: otelcol-contrib not found and podman unavailable."
        echo "         System information donation omitted from report."
    fi
    fi  # end SKIP_OTEL

    # ── Build summary.md ─────────────────────────────────────────────────────

    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    # Derive a stable anonymous ID via keyed hash — do not expose machine-id directly.
    # systemd treats /etc/machine-id as confidential; truncating it is not sufficient.
    if [[ -r /etc/machine-id ]]; then
        HOST_ID=$(printf 'ujust-report:%s' "$(cat /etc/machine-id)" | sha256sum | cut -c1-8)
    else
        HOST_ID="unknown"
    fi
    ARCH=$(uname -m)

    {
    printf '## Bluefin/Dakota Diagnostic Report\n'
    printf 'Generated: %s\n' "${TIMESTAMP}"
    printf 'Anonymous device ID: %s (truncated)\n' "${HOST_ID}"
    printf '\n### System\n'
    printf '* Kernel: %s\n' "${KERNEL_VER}"
    printf '* Architecture: %s\n' "${ARCH}"
    printf '* Load avg 1m/5m/15m: %s\n' "${LOAD_AVG}"
    printf '* Memory: %s\n' "${MEM_INFO}"
    printf '\n### Booted Image\n'
    printf '* Image: %s\n' "${BOOTED_IMAGE}"
    printf '* Digest: %s\n' "${BOOTED_DIGEST}"
    printf '* Staged: %s\n' "${STAGED_IMAGE}"
    printf '\n### GNOME\n'
    printf '* Version: %s\n' "${GNOME_VERSION}"
    printf '* Active extensions:\n'
    if [[ -n "$GNOME_EXTENSIONS" ]]; then
        echo "$GNOME_EXTENSIONS" | sed 's/^/  - /'
    else
        printf '  (none)\n'
    fi
    printf '\n### Failed Systemd Units\n'
    if [[ -n "$FAILED_UNITS" ]]; then
        echo "$FAILED_UNITS" | sed 's/^/  - /'
    else
        printf '  None\n'
    fi
    printf '\n### Installed Flatpaks\n'
    printf '\`\`\`\n'
    printf '%s\n' "${FLATPAK_LIST}"
    printf '\`\`\`\n'
    printf '\n### Full System Information Donation\n'
    printf 'See report.otlp.json in this gist for the full system information donation (structured metrics and journal logs).\n'
    } > "$REPORT_DIR/summary.md"

    # ── Review ────────────────────────────────────────────────────────────────

    echo ""
    echo "📊 Review what will be donated before uploading:"
    echo ""

    # Render summary in a forced pager — user must scroll through and press q
    if [[ -t 0 && -t 1 ]]; then
        if command -v glow &>/dev/null; then
            glow "$REPORT_DIR/summary.md" | gum pager
        else
            gum pager < "$REPORT_DIR/summary.md"
        fi
    else
        if command -v glow &>/dev/null; then
            glow "$REPORT_DIR/summary.md"
        else
            cat "$REPORT_DIR/summary.md"
        fi
    fi

    # Show file paths and sizes so user knows exactly what leaves their machine
    echo ""
    echo "📁 Files that will be uploaded to YOUR gist (you can delete them anytime):"
    echo ""
    ls -lh "$REPORT_DIR/"summary.md 2>/dev/null | awk '{print "   " $NF " (" $5 ") — human-readable summary"}'
    if [[ -f "$REPORT_DIR/report.otlp.json" ]]; then
        ls -lh "$REPORT_DIR/report.otlp.json" | awk '{print "   " $NF " (" $5 ") — structured system metrics + journal logs"}'
    fi
    echo ""
    echo "   Inspect anytime: cat $REPORT_DIR/summary.md"
    echo ""

    # ── Upload ────────────────────────────────────────────────────────────────

    if ! gum confirm "Donate this system information report to your GitHub gist?"; then
        echo "Donation cancelled. Files saved locally:"
        echo "  $REPORT_DIR/"
        trap - EXIT
        exit 0
    fi

    if ! gh auth status --active &>/dev/null; then
        echo ""
        echo "gh is not authenticated — no problem! Here are your options:"
        echo ""
        echo "Option 1: Copy to clipboard and paste into a GitHub issue:"
        if command -v wl-copy &>/dev/null; then
            wl-copy < "$REPORT_DIR/summary.md"
            echo "  ✅ Report copied to clipboard! Paste it into your issue."
        elif command -v xclip &>/dev/null; then
            xclip -selection clipboard < "$REPORT_DIR/summary.md"
            echo "  ✅ Report copied to clipboard! Paste it into your issue."
        else
            echo "  (clipboard not available — see file below)"
        fi
        echo ""
        echo "Option 2: Authenticate gh and upload as gist:"
        echo "  gh auth login"
        echo "  gh gist create --public --desc 'Bluefin diagnostic report' \\"
        echo "    $REPORT_DIR/summary.md"
        echo ""
        echo "Your files are saved locally:"
        echo "  $REPORT_DIR/"
        trap - EXIT
        exit 0
    fi

    GIST_FILES=("$REPORT_DIR/summary.md")
    [[ -f "$REPORT_DIR/report.otlp.json" ]] && GIST_FILES+=("$REPORT_DIR/report.otlp.json")

    trap - EXIT
    if ! GIST_URL=$(gh gist create --public \
        --desc "Bluefin system information donation $(date -I)" \
        "${GIST_FILES[@]}"); then
        echo ""
        echo "Upload failed. Your files are kept locally:"
        echo "  $REPORT_DIR/"
        exit 1
    fi
    cleanup

    echo ""
    echo "✅ Donated: $GIST_URL"
    echo ""
    echo "Your gist is in your own namespace — you can edit or delete it anytime:"
    echo "  $GIST_URL"
    echo ""

    # Offer to open the bug report form in browser with gist pre-filled
    ISSUE_URL="https://github.com/projectbluefin/dakota/issues/new?template=bug-report.yml&report-link=$(printf '%s' "$GIST_URL" | sed 's|:|%3A|g; s|/|%2F|g')"
    if gum confirm "Open a new issue in your browser with the gist attached?"; then
        xdg-open "$ISSUE_URL" 2>/dev/null || echo "  Could not open browser. Visit: $ISSUE_URL"
    else
        echo "To file an issue later:"
        echo "  xdg-open '$ISSUE_URL'"
    fi

# Deprecated alias for ujust report.
device-info:
    #!/usr/bin/bash
    echo ""
    echo "⚠️  'ujust device-info' has been renamed to 'ujust report'."
    echo "    Running 'ujust report' now..."
    echo ""
    just report

# Open the Dakota issue tracker in your browser.
# Usage: ujust file-issue
file-issue:
    #!/usr/bin/bash
    TEMPLATE=$(gum choose "Bug report" "Feature request" "Help this project")
    case "$TEMPLATE" in
        Bug*)     URL="https://github.com/projectbluefin/dakota/issues/new?template=bug-report.yml" ;;
        Feature*) URL="https://github.com/projectbluefin/dakota/issues/new?template=feature-request.yml" ;;
        Help*)    URL="https://github.com/projectbluefin/dakota/issues/new?template=help-this-project.yml" ;;
    esac
    echo "Opening: $URL"
    xdg-open "$URL" 2>/dev/null || echo "Could not open browser. Visit: $URL"

# Confirm you also experience an issue ("me too" with system context).
# Usage: ujust confirm 531
confirm issue_number:
    #!/usr/bin/bash
    set -euo pipefail

    ISSUE="{{issue_number}}"
    REPO="projectbluefin/dakota"

    echo "📋 Confirming you also experience issue #${ISSUE}..."
    echo ""

    # Collect lightweight system fingerprint
    BOOTC_JSON=$(sudo bootc status --json 2>/dev/null || echo '{}')
    BOOTED_IMAGE=$(echo "$BOOTC_JSON" | jq -r '.status.booted.image.image.image // "unknown"')
    BOOTED_DIGEST=$(echo "$BOOTC_JSON" | jq -r '.status.booted.imageDigest // "unknown"')
    KERNEL_VER=$(uname -r)
    ARCH=$(uname -m)
    FAILED_UNITS=$(systemctl list-units --state=failed --no-legend --plain 2>/dev/null \
                   | awk '{print $1}' | head -10 || echo "")

    if [[ -r /etc/machine-id ]]; then
        HOST_ID=$(printf 'ujust-confirm:%s' "$(cat /etc/machine-id)" | sha256sum | cut -c1-8)
    else
        HOST_ID="unknown"
    fi

    # Build the comment
    COMMENT=$(printf '### ✋ I also experience this issue\n\n')
    COMMENT+=$(printf '| Field | Value |\n|-------|-------|\n')
    COMMENT+=$(printf '| Image | `%s` |\n' "$BOOTED_IMAGE")
    COMMENT+=$(printf '| Digest | `%s` |\n' "$BOOTED_DIGEST")
    COMMENT+=$(printf '| Kernel | `%s` |\n' "$KERNEL_VER")
    COMMENT+=$(printf '| Arch | `%s` |\n' "$ARCH")
    COMMENT+=$(printf '| Device ID | `%s` |\n' "$HOST_ID")
    if [[ -n "$FAILED_UNITS" ]]; then
        COMMENT+=$(printf '\n**Failed units:** ')
        COMMENT+=$(echo "$FAILED_UNITS" | tr '\n' ',' | sed 's/,$//')
        COMMENT+=$(printf '\n')
    fi
    COMMENT+=$(printf '\n_Submitted via `ujust confirm %s`_\n' "$ISSUE")

    # Show user what will be posted
    echo "$COMMENT"
    echo ""

    if ! gum confirm "Post this as a comment on issue #${ISSUE}?"; then
        echo "Cancelled."
        exit 0
    fi

    if gh auth status --active &>/dev/null; then
        gh issue comment "$ISSUE" --repo "$REPO" --body "$COMMENT"
        echo ""
        echo "✅ Confirmation posted on issue #${ISSUE}"
    else
        echo ""
        if command -v wl-copy &>/dev/null; then
            printf '%s' "$COMMENT" | wl-copy
            echo "📋 Copied to clipboard! Paste it as a comment on:"
        else
            echo "📋 Copy the text above and paste it as a comment on:"
        fi
        echo "  https://github.com/${REPO}/issues/${ISSUE}"
        echo ""
        echo "Or authenticate gh first: gh auth login"
    fi

# Verify that a fix works on your hardware after upgrading.
# Usage: ujust verify 531
verify issue_number:
    #!/usr/bin/bash
    set -euo pipefail

    ISSUE="{{issue_number}}"
    REPO="projectbluefin/dakota"

    echo "🔍 Verifying fix for issue #${ISSUE}..."
    echo ""

    # Fetch issue context if gh is available
    ISSUE_TITLE=""
    VERIFY_STEPS=""
    if gh auth status --active &>/dev/null; then
        ISSUE_TITLE=$(gh issue view "$ISSUE" --repo "$REPO" --json title --jq '.title' 2>/dev/null || echo "")
        ISSUE_BODY=$(gh issue view "$ISSUE" --repo "$REPO" --json body --jq '.body' 2>/dev/null || echo "")
        # Extract verify-steps block (between ```verify and ```)
        VERIFY_STEPS=$(echo "$ISSUE_BODY" | sed -n '/^```verify/,/^```/p' | sed '1d;$d' || echo "")
    fi

    if [[ -n "$ISSUE_TITLE" ]]; then
        echo "Issue: #${ISSUE} — ${ISSUE_TITLE}"
        echo ""
    fi

    if [[ -n "$VERIFY_STEPS" ]]; then
        echo "── Verification steps from maintainer ──"
        echo "$VERIFY_STEPS"
        echo "─────────────────────────────────────────"
        echo ""
        echo "Please check the steps above on your system."
        echo ""
    else
        echo "No specific verify-steps found in the issue."
        echo "Check whether the bug you experienced is still present after upgrading."
        echo ""
    fi

    # Ask user for their verdict
    VERDICT=$(gum choose "✅ Fixed — bug is gone" "❌ Still broken" "⚠️ Different behavior" "ℹ️ Cannot confirm (did not have the bug)")

    case "$VERDICT" in
        *Fixed*) RESULT="fixed" ; EMOJI="✅" ;;
        *broken*) RESULT="still-broken" ; EMOJI="❌" ;;
        *Different*) RESULT="different" ; EMOJI="⚠️" ;;
        *) RESULT="cannot-confirm" ; EMOJI="ℹ️" ;;
    esac

    # Collect system context
    BOOTC_JSON=$(sudo bootc status --json 2>/dev/null || echo '{}')
    BOOTED_IMAGE=$(echo "$BOOTC_JSON" | jq -r '.status.booted.image.image.image // "unknown"')
    BOOTED_DIGEST=$(echo "$BOOTC_JSON" | jq -r '.status.booted.imageDigest // "unknown"')
    KERNEL_VER=$(uname -r)
    ARCH=$(uname -m)

    if [[ -r /etc/machine-id ]]; then
        HOST_ID=$(printf 'ujust-verify:%s' "$(cat /etc/machine-id)" | sha256sum | cut -c1-8)
    else
        HOST_ID="unknown"
    fi

    # Optional: collect relevant journal if user wants
    JOURNAL_SNIPPET=""
    if [[ "$RESULT" == "still-broken" || "$RESULT" == "different" ]]; then
        if gum confirm "Include recent journal logs for debugging? (last 50 lines of relevant services)" --default=false; then
            JOURNAL_SNIPPET=$(journalctl --no-pager -b -n 50 --priority=err..emerg 2>/dev/null \
                | sed -E 's|/home/[^/[:space:]]+/|/home/<redacted>/|g' \
                | sed -E 's/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/<ip>/g' || echo "")
        fi
    fi

    # Build the verification comment
    COMMENT=$(printf '### %s Verification: **%s**\n\n' "$EMOJI" "$RESULT")
    COMMENT+=$(printf '| Field | Value |\n|-------|-------|\n')
    COMMENT+=$(printf '| Image | `%s` |\n' "$BOOTED_IMAGE")
    COMMENT+=$(printf '| Digest | `%s` |\n' "$BOOTED_DIGEST")
    COMMENT+=$(printf '| Kernel | `%s` |\n' "$KERNEL_VER")
    COMMENT+=$(printf '| Arch | `%s` |\n' "$ARCH")
    COMMENT+=$(printf '| Device ID | `%s` |\n' "$HOST_ID")
    if [[ -n "$JOURNAL_SNIPPET" ]]; then
        COMMENT+=$(printf '\n<details><summary>Journal (errors, last 50 lines)</summary>\n\n```\n%s\n```\n</details>\n' "$JOURNAL_SNIPPET")
    fi
    COMMENT+=$(printf '\n_Submitted via `ujust verify %s`_\n' "$ISSUE")

    # Show user what will be posted
    echo ""
    echo "$COMMENT"
    echo ""

    if ! gum confirm "Post this verification on issue #${ISSUE}?"; then
        echo "Cancelled. You can paste the text above manually."
        exit 0
    fi

    if gh auth status --active &>/dev/null; then
        gh issue comment "$ISSUE" --repo "$REPO" --body "$COMMENT"
        echo ""
        echo "✅ Verification posted on issue #${ISSUE}"
        echo ""
        echo "Thank you for helping confirm whether this fix works!"
    else
        echo ""
        if command -v wl-copy &>/dev/null; then
            printf '%s' "$COMMENT" | wl-copy
            echo "📋 Copied to clipboard! Paste it as a comment on:"
        else
            echo "📋 Copy the text above and paste it as a comment on:"
        fi
        echo "  https://github.com/${REPO}/issues/${ISSUE}"
        echo ""
        echo "Or authenticate gh first: gh auth login"
    fi

# Measure Idle Power Draw
check-idle-power-draw:
    #!/usr/bin/bash
    if ! command -v powerstat ; then
        echo "Powerstat is not available"
        exit 1
    fi
    sudo powerstat -a -r

# Run a one minute system benchmark
[group('System')]
benchmark:
    #!/usr/bin/env bash
    if ! command -v "stress-ng" ; then
        if gum confirm "Stress does not seem to be on your path, do you wish to install it?" ; then
            set -eu
            brew install stress-ng
            brew link stress-ng
            set +eu
        else
            exit 0
        fi
    fi

    echo "Running a 1 minute benchmark ..."
    trap popd EXIT
    pushd "$(mktemp -d)"
    stress-ng --matrix 0 -t 1m --times
