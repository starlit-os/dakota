kind: compose

description: zoxide CLI directory-form sysext

build-depends:
- sysext/starlit-cli-zoxide-cli.bst
- sysext/starlit-cli-zoxide-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
