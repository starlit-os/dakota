kind: manual

description: bat CLI binary for starlit-cli sysext

sources:
- kind: tar
  (?):
  - arch == "x86_64":
      url: github_files:sharkdp/bat/releases/download/v0.26.0/bat-v0.26.0-x86_64-unknown-linux-gnu.tar.gz
      ref: 7efed0c768fae36f18ddbbb4a38f5c4b64db7c55a170dfc89fd380805809a44b
  - arch == "aarch64":
      url: github_files:sharkdp/bat/releases/download/v0.26.0/bat-v0.26.0-aarch64-unknown-linux-gnu.tar.gz
      ref: eb8c96a2d9aaaf81cf7d8c3b7918a7336a06a1dec08878887963dc2cdd7db354

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
