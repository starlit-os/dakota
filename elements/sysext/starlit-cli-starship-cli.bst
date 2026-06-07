kind: manual

description: starship CLI binary for starlit-cli sysext

sources:
- kind: tar
  base-dir: ""
  (?):
  - arch == "x86_64":
      url: github_files:starship/starship/releases/download/v1.25.1/starship-x86_64-unknown-linux-musl.tar.gz
      ref: "c6ddd3ecb9c0071a2ad38d98cee748160066b7c4f197421268058f4a5d6f8504"
  - arch == "aarch64":
      url: github_files:starship/starship/releases/download/v1.25.1/starship-aarch64-unknown-linux-musl.tar.gz
      ref: "0000000000000000000000000000000000000000000000000000000000000000"

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 starship "%{install-root}%{bindir}/starship"
  - |
    ./starship completions fish | install -Dm644 /dev/stdin "%{install-root}%{datadir}/fish/vendor_completions.d/starship.fish"
  - |
    %{install-extra}
