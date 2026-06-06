kind: compose

description: Proton Pass CLI directory-form sysext

build-depends:
- sysext/proton-pass-cli-cli.bst
- sysext/proton-pass-cli-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
