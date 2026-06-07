kind: compose

description: fd CLI directory-form sysext

build-depends:
- sysext/starlit-cli-fd-cli.bst
- sysext/starlit-cli-fd-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
