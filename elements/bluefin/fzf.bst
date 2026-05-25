kind: manual

sources:
- kind: tar
  base-dir: ""
  (?):
  - arch == "x86_64":
      url: github_files:junegunn/fzf/releases/download/v0.73.1/fzf-0.73.1-linux_amd64.tar.gz
      ref: f3252c2c366bc1700d3c85781ec8c9695998927ac127870eb049ceea2d540f8a
  - arch == "aarch64":
      url: github_files:junegunn/fzf/releases/download/v0.73.1/fzf-0.73.1-linux_arm64.tar.gz
      ref: a408b0b6c08d486307b8f1554f967b8b50ee1b3ea8b4035e3161bab31fdfc28d

build-depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    install -Dm755 -t "%{install-root}%{bindir}" fzf
  - |
    %{install-extra}
