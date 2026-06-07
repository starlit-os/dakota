kind: manual

description: fnox CLI binary for starlit-cli sysext

sources:
- kind: tar
  base-dir: ""
  (?):
  - arch == "x86_64":
      url: github_files:jdx/fnox/releases/download/v1.25.1/fnox-x86_64-unknown-linux-musl.tar.gz
      ref: "9bb4f563a65ba89e5a6759e95658eafbd1e32d8bd8cb1bf72fc5ff652566eaf5"
  - arch == "aarch64":
      url: github_files:jdx/fnox/releases/download/v1.25.1/fnox-aarch64-unknown-linux-musl.tar.gz
      ref: "1e5e902a941d3a7eea262699d0f7169da5e5d06155c2f82def0baff086f9d3a4"

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 fnox "%{install-root}%{bindir}/fnox"
  - |
    %{install-extra}
