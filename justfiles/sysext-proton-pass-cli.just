# Proton Pass CLI sysext helper workflows.

[group('sysext')]
sysext-proton-pass-cli:
    #!/usr/bin/env bash
    set -euo pipefail
    just sysext-proton-pass-cli-build
    just sysext-proton-pass-cli-checkout

[group('sysext')]
sysext-proton-pass-cli-build:
    just bst build sysext/proton-pass-cli.bst

[group('sysext')]
sysext-proton-pass-cli-checkout out_dir=".build-sysext/proton-pass-cli":
    just _sysext-checkout sysext/proton-pass-cli.bst "{{out_dir}}"

[group('sysext')]
sysext-proton-pass-cli-archive source_dir=".build-sysext/proton-pass-cli" archive_path=".build-sysext/proton-pass-cli.tar.gz":
    just _sysext-archive "{{source_dir}}" "{{archive_path}}"

[group('sysext')]
sysext-proton-pass-cli-host source=".build-sysext/proton-pass-cli":
    #!/usr/bin/env bash
    set -euo pipefail
    just sysext-proton-pass-cli-host-install "{{source}}"
    just sysext-proton-pass-cli-host-smoke

[group('sysext')]
sysext-proton-pass-cli-host-install source=".build-sysext/proton-pass-cli":
    just _sysext-host-install proton-pass-cli "{{source}}" pass-cli

[group('sysext')]
sysext-proton-pass-cli-host-smoke:
    just _sysext-host-smoke pass-cli "Proton Pass CLI"

[group('sysext')]
sysext-proton-pass-cli-host-remove:
    just _sysext-host-remove proton-pass-cli
