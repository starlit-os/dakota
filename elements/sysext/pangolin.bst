kind: compose

description: Pangolin CLI directory-form sysext

build-depends:
- sysext/pangolin-cli.bst
- sysext/pangolin-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
