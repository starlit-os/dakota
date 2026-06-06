# Sysext recipe dispatcher.
#
# Keep one small top-level sysext dispatcher and import the shared helper file
# plus per-extension justfiles here as new extensions are added.

import 'sysext.just'
import 'sysext-pangolin.just'
import 'sysext-proton-pass-cli.just'
import 'sysext-starlit-cli.just'
