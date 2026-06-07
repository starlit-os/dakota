kind: manual

description: dysk CLI binary for starlit-cli sysext

sources:
- kind: remote
  url: github_files:Canop/dysk/releases/download/v3.6.1/dysk_3.6.1.zip
  ref: "fa2d50341f105e564695c905681d493807f880fa38647e8fb53125f4a10b5037"
  filename: dysk_3.6.1.zip

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst
- freedesktop-sdk.bst:components/libarchive.bst
- freedesktop-sdk.bst:components/bzip2.bst

variables:
  strip-binaries: ""

config:
  install-commands:
  - |
    bsdtar -xvf dysk_3.6.1.zip 'build/*/dysk'
    (?)
    - arch == "x86_64":
        install -Dm755 build/x86_64-unknown-linux-musl/dysk "%{install-root}%{bindir}/dysk"
    - arch == "aarch64":
        install -Dm755 build/aarch64-unknown-linux-musl/dysk "%{install-root}%{bindir}/dysk"
  - |
    %{install-extra}
