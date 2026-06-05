kind: script

description: Starlit CLI squashfs raw sysext image

build-depends:
- freedesktop-sdk.bst:bootstrap/bash.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst
- freedesktop-sdk.bst:components/squashfs-tools.bst
- filename: sysext/starlit-cli.bst
  config:
    location: /sysroot

variables:
  raw-filename: starlit-cli.raw

config:
  commands:
    - mkdir -p "%{install-root}"
    - |
      mksquashfs /sysroot "%{install-root}/%{raw-filename}" \
        -noappend \
        -all-root \
        -no-progress
