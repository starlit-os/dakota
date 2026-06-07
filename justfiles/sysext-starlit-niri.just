# starlit-niri sysext helper workflows.

[group('sysext')]
sysext-starlit-niri:
    #!/usr/bin/env bash
    set -euo pipefail
    just sysext-starlit-niri-build
    just sysext-starlit-niri-checkout

[group('sysext')]
sysext-starlit-niri-build:
    just bst build sysext/starlit-niri.bst

[group('sysext')]
sysext-starlit-niri-checkout out_dir=".build-sysext/starlit-niri":
    just _sysext-checkout sysext/starlit-niri.bst "{{out_dir}}"

[group('sysext')]
sysext-starlit-niri-archive source_dir=".build-sysext/starlit-niri" archive_path=".build-sysext/starlit-niri.tar.gz":
    just _sysext-archive "{{source_dir}}" "{{archive_path}}"

[group('sysext')]
sysext-starlit-niri-host source=".build-sysext/starlit-niri":
    #!/usr/bin/env bash
    set -euo pipefail
    just sysext-starlit-niri-host-install "{{source}}"
    just sysext-starlit-niri-host-smoke

[group('sysext')]
sysext-starlit-niri-host-install source=".build-sysext/starlit-niri":
    just _sysext-host-install starlit-niri "{{source}}" niri

[group('sysext')]
sysext-starlit-niri-host-smoke:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "==> Checking sysext merge status..."
    systemd-sysext status
    echo ""

    echo "==> Checking niri binaries and session files..."
    command -v niri
    command -v niri-session
    test -f /usr/share/wayland-sessions/niri.desktop
    test -f /usr/share/xdg-desktop-portal/niri-portals.conf
    test -f /usr/lib/systemd/user/niri.service
    echo "PASS: starlit-niri sysext is active and the Niri session payload is present"

[group('sysext')]
sysext-starlit-niri-host-remove:
    just _sysext-host-remove starlit-niri
