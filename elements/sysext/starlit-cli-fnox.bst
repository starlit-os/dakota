kind: compose

description: fnox CLI directory-form sysext

build-depends:
- sysext/starlit-cli-fnox-cli.bst
- sysext/starlit-cli-fnox-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
