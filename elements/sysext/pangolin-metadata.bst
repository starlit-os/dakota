kind: manual

description: systemd-sysext metadata for Pangolin CLI

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""
  (?):
  - arch == "x86_64":
      sysext-arch: "x86-64"
  - arch == "aarch64":
      sysext-arch: "arm64"

config:
  install-commands:
  - |
    install -Dm644 /dev/stdin "%{install-root}%{indep-libdir}/extension-release.d/extension-release.pangolin" <<EOF
    ID=bluefin-dakota
    ARCHITECTURE=%{sysext-arch}
    VERSION_ID=0
    EOF
  - |
    %{install-extra}
