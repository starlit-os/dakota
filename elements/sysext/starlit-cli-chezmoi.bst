kind: compose

description: Chezmoi CLI directory-form sysext

build-depends:
- sysext/starlit-cli-chezmoi-cli.bst
- sysext/starlit-cli-chezmoi-metadata.bst

config:
  exclude:
    - devel
    - debug
    - static-blocklist
