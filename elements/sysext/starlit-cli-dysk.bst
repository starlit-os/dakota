kind: compose

description: dysk CLI directory-form sysext

build-depends:
- sysext/starlit-cli-dysk-cli.bst
- sysext/starlit-cli-dysk-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
