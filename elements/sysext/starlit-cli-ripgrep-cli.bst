kind: manual

description: ripgrep CLI binary for starlit-cli sysext

sources:
- kind: tar
  (?):
  - arch == "x86_64":
      url: github_files:BurntSushi/ripgrep/releases/download/15.1.0/ripgrep-15.1.0-x86_64-unknown-linux-musl.tar.gz
      ref: "1c9297be4a084eea7ecaedf93eb03d058d6faae29bbc57ecdaf5063921491599"
  - arch == "aarch64":
      url: github_files:BurntSushi/ripgrep/releases/download/15.1.0/ripgrep-15.1.0-aarch64-unknown-linux-musl.tar.gz
      ref: "0000000000000000000000000000000000000000000000000000000000000000"

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 rg "%{install-root}%{bindir}/rg"
    install -Dm644 complete/rg.fish "%{install-root}%{datadir}/fish/vendor_completions.d/rg.fish"
  - |
    %{install-extra}
