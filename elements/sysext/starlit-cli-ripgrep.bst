kind: compose

description: ripgrep CLI directory-form sysext

build-depends:
- sysext/starlit-cli-ripgrep-cli.bst
- sysext/starlit-cli-ripgrep-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
