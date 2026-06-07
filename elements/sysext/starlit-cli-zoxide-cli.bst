kind: manual

description: zoxide CLI binary for starlit-cli sysext

sources:
- kind: tar
  base-dir: ""
  (?):
  - arch == "x86_64":
      url: github_files:ajeetdsouza/zoxide/releases/download/v0.9.9/zoxide-0.9.9-x86_64-unknown-linux-musl.tar.gz
      ref: "4ff057d3c4d957946937274c2b8be7af2a9bbae7f90a1b5e9baaa7cb65a20caa"
  - arch == "aarch64":
      url: github_files:ajeetdsouza/zoxide/releases/download/v0.9.9/zoxide-0.9.9-aarch64-unknown-linux-musl.tar.gz
      ref: "96e6ea2e47a71db42cb7ad5a36e9209c8cb3708f8ae00f6945573d0d93315cb0"

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 zoxide "%{install-root}%{bindir}/zoxide"
    install -Dm644 completions/zoxide.fish "%{install-root}%{datadir}/fish/vendor_completions.d/zoxide.fish"
  - |
    %{install-extra}
