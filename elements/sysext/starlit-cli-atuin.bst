kind: compose

description: Atuin CLI directory-form sysext

build-depends:
- sysext/starlit-cli-atuin-cli.bst
- sysext/starlit-cli-atuin-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
