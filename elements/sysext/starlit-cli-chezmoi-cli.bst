kind: manual

description: chezmoi CLI binary for starlit-cli sysext

sources:
- kind: tar
  base-dir: ""
  (?):
  - arch == "x86_64":
      url: github_files:twpayne/chezmoi/releases/download/v2.70.5/chezmoi_2.70.5_linux_amd64.tar.gz
      ref: "6a76a0ac3718f0d45b34b4b57067f9556f8f6042e3da710a3c496838362aca14"
  - arch == "aarch64":
      url: github_files:twpayne/chezmoi/releases/download/v2.70.5/chezmoi_2.70.5_linux_arm64.tar.gz
      ref: "0000000000000000000000000000000000000000000000000000000000000000"

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 chezmoi "%{install-root}%{bindir}/chezmoi"
    install -Dm644 completions/chezmoi.fish "%{install-root}%{datadir}/fish/vendor_completions.d/chezmoi.fish"
  - |
    %{install-extra}
