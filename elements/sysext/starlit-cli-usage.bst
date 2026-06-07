kind: compose

description: usage CLI directory-form sysext

build-depends:
- sysext/starlit-cli-usage-cli.bst
- sysext/starlit-cli-usage-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
