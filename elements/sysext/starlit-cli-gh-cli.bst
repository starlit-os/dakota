kind: manual

description: GitHub CLI binary for starlit-cli sysext

sources:
- kind: tar
  (?):
  - arch == "x86_64":
      url: github_files:cli/cli/releases/download/v2.93.0/gh_2.93.0_linux_amd64.tar.gz
      ref: "02d1290eba130e0b896f3709ffff22e1c75a51475ddb70476a85abc6b5807af0"
  - arch == "aarch64":
      url: github_files:cli/cli/releases/download/v2.93.0/gh_2.93.0_linux_arm64.tar.gz
      ref: "0000000000000000000000000000000000000000000000000000000000000000"

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 bin/gh "%{install-root}%{bindir}/gh"
  - |
    ./bin/gh completion -s fish | install -Dm644 /dev/stdin "%{install-root}%{datadir}/fish/vendor_completions.d/gh.fish"
  - |
    %{install-extra}
