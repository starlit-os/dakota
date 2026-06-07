kind: manual

description: systemd-sysext metadata for fnox CLI

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm644 /dev/stdin "%{install-root}%{indep-libdir}/extension-release.d/extension-release.fnox" <<EOF
    ID=bluefin-dakota
    ARCHITECTURE=%{systemd-arch}
    VERSION_ID=20260530
    EOF
  - |
    %{install-extra}
