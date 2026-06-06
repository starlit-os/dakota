kind: manual

description: Proton Pass CLI binary for sysext packaging

sources:
- kind: remote
  filename: pass-cli
  (?):
  - arch == "x86_64":
      url: github_files:protonpass/pass-cli/releases/download/2.1.2/pass-cli-linux-x86_64
      ref: 5291edd21d85d222538b91341345ae3b0a1479e254d42920c2bbbd34012c6243
  - arch == "aarch64":
      url: github_files:protonpass/pass-cli/releases/download/2.1.2/pass-cli-linux-aarch64
      ref: 0562625812f940bd4b7abd664b3bbcfefdeaf79d2f9b12f2d0a73be1ffc551ff

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 pass-cli "%{install-root}%{bindir}/pass-cli"
  - |
    %{install-extra}
