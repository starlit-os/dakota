kind: compose

description: Starlit CLI directory-form sysext

build-depends:
- sysext/starlit-cli-stack.bst
- sysext/starlit-cli-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
