kind: manual

description: usage CLI binary for starlit-cli sysext

sources:
- kind: tar
  base-dir: ""
  (?):
  - arch == "x86_64":
      url: github_files:jdx/usage/releases/download/v3.4.0/usage-x86_64-unknown-linux-musl.tar.gz
      ref: "1a54260df50f1764bc8cbabf8763f2a6314c5025d3b06b512d02898eb28768b3"
  - arch == "aarch64":
      url: github_files:jdx/usage/releases/download/v3.4.0/usage-aarch64-unknown-linux-musl.tar.gz
      ref: "0000000000000000000000000000000000000000000000000000000000000000"

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 usage "%{install-root}%{bindir}/usage"
  - |
    ./usage fish | install -Dm644 /dev/stdin "%{install-root}%{datadir}/fish/vendor_completions.d/usage.fish"
  - |
    %{install-extra}
