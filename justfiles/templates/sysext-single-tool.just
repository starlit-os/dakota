# Template: single-tool sysext helper workflow
#
# Copy the recipes you need from this file into `justfiles/sysext-<name>.just`
# and replace the placeholders below.
#
# Assumes the shared helpers in `justfiles/sysext.just` are imported by the
# dispatcher.
#
# Placeholders:
# - <name>        short sysext name, also used in /var/lib/extensions/<name>
# - <element>     top-level BuildStream sysext element, e.g. sysext/<name>.bst
# - <source-dir>  default checkout directory under the repo, e.g. .build-sysext/<name>
# - <binary>      expected command on PATH after merge
# - <display>     human-readable name for PASS messages

[group('sysext')]
sysext-<name>:
    #!/usr/bin/env bash
    set -euo pipefail
    just sysext-<name>-build
    just sysext-<name>-checkout

[group('sysext')]
sysext-<name>-build:
    just bst build <element>

[group('sysext')]
sysext-<name>-checkout out_dir="<source-dir>":
    just _sysext-checkout <element> "{{out_dir}}"

[group('sysext')]
sysext-<name>-archive source_dir="<source-dir>" archive_path=".build-sysext/<name>.tar.gz":
    just _sysext-archive "{{source_dir}}" "{{archive_path}}"

[group('sysext')]
sysext-<name>-host source="<source-dir>":
    #!/usr/bin/env bash
    set -euo pipefail
    just sysext-<name>-host-install "{{source}}"
    just sysext-<name>-host-smoke

[group('sysext')]
sysext-<name>-host-install source="<source-dir>":
    just _sysext-host-install <name> "{{source}}" <binary>

[group('sysext')]
sysext-<name>-host-smoke:
    just _sysext-host-smoke <binary> <display>

[group('sysext')]
sysext-<name>-host-remove:
    just _sysext-host-remove <name>
