kind: manual

description: Starlit Niri directory-form sysext

build-depends:
- starlit/niri.bst
- starlit/xwayland-satellite.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    # Install systemd-sysext extension metadata
    install -Dm644 /dev/stdin "%{install-root}%{indep-libdir}/extension-release.d/extension-release.starlit-niri" <<EOF2
    ID=bluefin-dakota
    ARCHITECTURE=%{systemd-arch}
    VERSION_ID=20260530
    EOF2
  - |
    # Copy only niri's own files (the host base image provides all runtime deps)
    install -Dm755 /usr/bin/niri "%{install-root}%{bindir}/niri"
    install -Dm755 /usr/bin/niri-session "%{install-root}%{bindir}/niri-session"
    install -Dm644 /usr/share/wayland-sessions/niri.desktop "%{install-root}%{datadir}/wayland-sessions/niri.desktop"
    install -Dm644 /usr/share/xdg-desktop-portal/niri-portals.conf "%{install-root}%{datadir}/xdg-desktop-portal/niri-portals.conf"
    install -Dm644 /usr/lib/systemd/user/niri.service "%{install-root}%{indep-libdir}/systemd/user/niri.service"
    install -Dm644 /usr/lib/systemd/user/niri-shutdown.target "%{install-root}%{indep-libdir}/systemd/user/niri-shutdown.target"
    # Runtime libraries not guaranteed on the base image
    install -Dm755 /usr/lib/x86_64-linux-gnu/libseat.so.1 "%{install-root}%{libdir}/libseat.so.1"
  - |
    # Copy xwayland-satellite
    install -Dm755 /usr/bin/xwayland-satellite "%{install-root}%{bindir}/xwayland-satellite"
  - |
    %{install-extra}
