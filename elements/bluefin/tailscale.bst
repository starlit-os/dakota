kind: manual

sources:
- kind: tar
  (?):
  - arch == "x86_64":
      url: tailscale_pkgs:tailscale_1.98.2_amd64.tgz
      ref: aae02be635e8bffbdaecefb3518344357d39d904c1bbe1e7ca95cd0cbb8ad21c
  - arch == "aarch64":
      url: tailscale_pkgs:tailscale_1.98.2_arm64.tgz
      ref: 6f56441fedd4309fb949e8f257d7bd93bc157191968918b906a781fc25029ad4

build-depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/sed.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 -t "%{install-root}%{bindir}" tailscale tailscaled
  - |
    sed -e 's|/usr/sbin/tailscaled|/usr/bin/tailscaled|g' \
        -e '/^EnvironmentFile=/d' \
        systemd/tailscaled.service > tailscaled.service.patched
    sed -i '/^\[Service\]/a Environment=FLAGS=' tailscaled.service.patched
    sed -i '/^\[Service\]/a Environment=PORT=41641' tailscaled.service.patched
    install -Dm644 -t "%{install-root}%{indep-libdir}/systemd/system" tailscaled.service.patched
    mv "%{install-root}%{indep-libdir}/systemd/system/tailscaled.service.patched" \
       "%{install-root}%{indep-libdir}/systemd/system/tailscaled.service"
  - |
    install -Dm644 /dev/stdin "%{install-root}%{indep-libdir}/systemd/system-preset/80-tailscale.preset" <<'PRESET'
    enable tailscaled.service
    PRESET
  - |
    %{install-extra}
