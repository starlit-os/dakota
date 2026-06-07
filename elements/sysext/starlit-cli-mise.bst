kind: compose

description: mise CLI directory-form sysext

build-depends:
- sysext/starlit-cli-mise-cli.bst
- sysext/starlit-cli-mise-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
