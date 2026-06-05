kind: compose

description: Starlit CLI directory-form sysext

build-depends:
- sysext/starlit-cli-fish.bst
- sysext/starlit-cli-bat.bst
- sysext/starlit-cli-eza.bst
- sysext/starlit-cli-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
