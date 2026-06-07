kind: manual

description: atuin CLI binary for starlit-cli sysext

sources:
- kind: tar
  (?):
  - arch == "x86_64":
      url: github_files:atuinsh/atuin/releases/download/v18.16.1/atuin-x86_64-unknown-linux-musl.tar.gz
      ref: "aeee16faab126d2f11658ad4920c73fa8479b25fbd3e26570450af7310aac70a"
  - arch == "aarch64":
      url: github_files:atuinsh/atuin/releases/download/v18.16.1/atuin-aarch64-unknown-linux-musl.tar.gz
      ref: "0000000000000000000000000000000000000000000000000000000000000000"

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 atuin "%{install-root}%{bindir}/atuin"
  - |
    ./atuin gen-completions --shell fish | install -Dm644 /dev/stdin "%{install-root}%{datadir}/fish/vendor_completions.d/atuin.fish"
  - |
    %{install-extra}
