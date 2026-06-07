kind: manual

description: bat CLI binary for starlit-cli sysext

sources:
- kind: tar
  (?):
  - arch == "x86_64":
      url: github_files:sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-gnu.tar.gz
      ref: "726f04c8f576a7fd18b7634f1bbf2f915c43494c1c0f013baa3287edb0d5a2a3"
  - arch == "aarch64":
      url: github_files:sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-aarch64-unknown-linux-gnu.tar.gz
      ref: "0000000000000000000000000000000000000000000000000000000000000000"

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 bat "%{install-root}%{bindir}/bat"
  - |
    install -Dm644 autocomplete/bat.bash "%{install-root}%{datadir}/bash-completion/completions/bat"
    install -Dm644 autocomplete/bat.zsh "%{install-root}%{datadir}/zsh/site-functions/_bat"
    install -Dm644 autocomplete/bat.fish "%{install-root}%{datadir}/fish/vendor_completions.d/bat.fish"
  - |
    install -Dm644 bat.1 "%{install-root}%{datadir}/man/man1/bat.1"
  - |
    %{install-extra}
