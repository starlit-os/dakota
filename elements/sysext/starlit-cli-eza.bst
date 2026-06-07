kind: manual

description: eza CLI binary for starlit-cli sysext

sources:
- kind: tar
  base-dir: ""
  (?):
  - arch == "x86_64":
      url: github_files:eza-community/eza/releases/download/v0.23.4/eza_x86_64-unknown-linux-gnu.tar.gz
      ref: "0c38665440226cd8bef5d1d4f3bc6ff77c927fb0d68b752739105db7ab5b358d"
  - arch == "aarch64":
      url: github_files:eza-community/eza/releases/download/v0.23.4/eza_aarch64-unknown-linux-gnu.tar.gz
      ref: "0000000000000000000000000000000000000000000000000000000000000000"

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
