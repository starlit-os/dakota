kind: manual

description: fish shell standalone binary for starlit-cli sysext

sources:
- kind: tar
  base-dir: ""
  (?):
  - arch == "x86_64":
      url: github_files:fish-shell/fish-shell/releases/download/4.7.1/fish-4.7.1-linux-x86_64.tar.xz
      ref: 345388add316b94a847b08cef01f1b46e85b98215328271ee22a21555a3204df
  - arch == "aarch64":
      url: github_files:fish-shell/fish-shell/releases/download/4.7.1/fish-4.7.1-linux-aarch64.tar.xz
      ref: 72957265b8629fbb3cdb215260c302f6154403dbaf35d38103aac6af689fb7f6

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 fish "%{install-root}%{bindir}/fish"
  - |
    %{install-extra}
