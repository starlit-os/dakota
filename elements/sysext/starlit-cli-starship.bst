kind: compose

description: starship CLI directory-form sysext

build-depends:
- sysext/starlit-cli-starship-cli.bst
- sysext/starlit-cli-starship-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
