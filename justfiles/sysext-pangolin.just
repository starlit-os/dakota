# Pangolin sysext helper workflows.

[group('sysext')]
sysext-pangolin:
    #!/usr/bin/env bash
    set -euo pipefail
    just sysext-pangolin-build
    just sysext-pangolin-checkout

[group('sysext')]
sysext-pangolin-build:
    just bst build sysext/pangolin.bst

[group('sysext')]
sysext-pangolin-checkout out_dir=".build-sysext/pangolin":
    just _sysext-checkout sysext/pangolin.bst "{{out_dir}}"

[group('sysext')]
sysext-pangolin-archive source_dir=".build-sysext/pangolin" archive_path=".build-sysext/pangolin.tar.gz":
    just _sysext-archive "{{source_dir}}" "{{archive_path}}"

[group('sysext')]
sysext-pangolin-host source=".build-sysext/pangolin":
    #!/usr/bin/env bash
    set -euo pipefail
    just sysext-pangolin-host-install "{{source}}"
    just sysext-pangolin-host-smoke

[group('sysext')]
sysext-pangolin-host-install source=".build-sysext/pangolin":
    just _sysext-host-install pangolin "{{source}}"

[group('sysext')]
sysext-pangolin-host-smoke:
    just _sysext-host-smoke pangolin Pangolin

[group('sysext')]
sysext-pangolin-host-remove:
    just _sysext-host-remove pangolin
