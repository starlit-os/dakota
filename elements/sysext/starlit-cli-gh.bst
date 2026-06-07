kind: compose

description: GitHub CLI directory-form sysext

build-depends:
- sysext/starlit-cli-gh-cli.bst
- sysext/starlit-cli-gh-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
