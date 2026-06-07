kind: manual

description: mise CLI binary for starlit-cli sysext

sources:
- kind: tar
  (?):
  - arch == "x86_64":
      url: github_files:jdx/mise/releases/download/v2026.6.1/mise-v2026.6.1-linux-x64-musl.tar.gz
      ref: "1c82e40ff6e87657fe60acfe75a9e269402fc4246d86f673528efd6168a1cf97"
  - arch == "aarch64":
      url: github_files:jdx/mise/releases/download/v2026.6.1/mise-v2026.6.1-linux-arm64-musl.tar.gz
      ref: "0000000000000000000000000000000000000000000000000000000000000000"

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 bin/mise "%{install-root}%{bindir}/mise"
  - |
    %{install-extra}
