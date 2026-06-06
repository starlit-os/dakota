kind: manual

description: systemd-sysext metadata for Proton Pass CLI

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm644 /dev/stdin "%{install-root}%{indep-libdir}/extension-release.d/extension-release.proton-pass-cli" <<EOF
    ID=bluefin-dakota
    ARCHITECTURE=%{systemd-arch}
    VERSION_ID=0
    EOF
  - |
    %{install-extra}
