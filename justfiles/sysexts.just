# Sysext recipe dispatcher.
#
# Keep one small top-level sysext dispatcher and import the shared helper file
# plus per-extension justfiles here as new extensions are added.

import 'sysext.just'
import 'sysext-pangolin.just'
import 'sysext-proton-pass-cli.just'
import 'sysext-starlit-cli.just'
import 'sysext-starlit-niri.just'

[group('sysext')]
sysext-all:
    #!/usr/bin/env bash
    set -euo pipefail
    just sysext-pangolin
    just sysext-pangolin-archive
    just sysext-proton-pass-cli
    just sysext-proton-pass-cli-archive
    just sysext-starlit-cli
    just sysext-starlit-cli-archive
    just sysext-starlit-niri
    just sysext-starlit-niri-archive
