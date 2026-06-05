kind: manual

description: Pangolin CLI binary for sysext packaging

sources:
- kind: remote
  (?):
  - arch == "x86_64":
      url: github_files:fosrl/cli/releases/download/0.9.0/pangolin-cli_linux_amd64
      ref: 6056da7b3cea8a9ebc36c0ef9e003bf505f8957a38d11f445d070a0a56e46764
  - arch == "aarch64":
      url: github_files:fosrl/cli/releases/download/0.9.0/pangolin-cli_linux_arm64
      ref: 39427a82db6f77d5ba6e61c11e0b1c022aa93542efbf606a2723b5198ceb9f3e

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 pangolin-cli_linux_* "%{install-root}%{bindir}/pangolin"
  - |
    %{install-extra}
