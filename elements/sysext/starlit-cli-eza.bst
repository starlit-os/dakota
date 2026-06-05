kind: manual

description: eza CLI binary for starlit-cli sysext

sources:
- kind: tar
  base-dir: ""
  (?):
  - arch == "x86_64":
      url: github_files:eza-community/eza/releases/download/v0.22.1/eza_x86_64-unknown-linux-gnu.tar.gz
      ref: 520097840b7e63de71aeb02e8aac990ea07a658ac9d2dfbedb02efee58619605
  - arch == "aarch64":
      url: github_files:eza-community/eza/releases/download/v0.22.1/eza_aarch64-unknown-linux-gnu.tar.gz
      ref: 83b76d684964cf437a3377f2dc16c76e3692adb888636dfc111aed986c3c3a6d

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 eza "%{install-root}%{bindir}/eza"
  - |
    %{install-extra}
