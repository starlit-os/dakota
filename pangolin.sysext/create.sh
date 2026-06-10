#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# Pangolin CLI sysext.
#
# Adapted from the starlit-os/dakota BuildStream element
# elements/sysext/pangolin.bst on branch starlit-sysexts.
# Original ID policy (ID=bluefin-dakota) has been relaxed to ID=_any so the
# image is host-agnostic. The pangolin binary is a CGO_ENABLED=0 Go static
# binary, so it is safe to ship as a generic sysext.
#
# Copyright (c) 2025 the starlit-os maintainers.
# Use of this source code is governed by the Apache 2.0 license.

RELOAD_SERVICES_ON_MERGE="false"

# Pinned SHA256 sums for the upstream prebuilt binaries.
# These must be updated in lockstep with the version variable below and
# verified by `populate_sysext_root` before the binary is installed.
declare -A PANGOLIN_SHAS=(
  ["0.9.0"]="6056da7b3cea8a9ebc36c0ef9e003bf505f8957a38d11f445d070a0a56e46764:amd64 39427a82db6f77d5ba6e61c11e0b1c022aa93542efbf606a2723b5198ceb9f3e:arm64"
)

function list_available_versions() {
  list_github_releases "fosrl" "cli"
}
# --

function populate_sysext_root() {
  local sysextroot="$1"
  local arch="$2"
  local version="$3"

  local rel_arch="$(arch_transform "x86-64" "amd64" "$arch")"
  rel_arch="$(arch_transform "arm64" "arm64" "$rel_arch")"

  local url="https://github.com/fosrl/cli/releases/download/${version}/pangolin-cli_linux_${rel_arch}"
  local bin="pangolin-cli_linux_${rel_arch}"

  echo "Downloading ${url}"
  curl --fail --silent --show-error --location --remote-name "${url}"

  # SHA256 verify against the pinned sum for this version + arch.
  local pinned="${PANGOLIN_SHAS[${version}]:-}"
  if [[ -z "${pinned}" ]] ; then
    echo "ERROR: no pinned SHA256 for pangolin version '${version}'." >&2
    echo "Update PANGOLIN_SHAS in create.sh and re-run." >&2
    exit 1
  fi
  local expected=""
  for entry in ${pinned} ; do
    local entry_sha="${entry%%:*}"
    local entry_arch="${entry##*:}"
    if [[ "${entry_arch}" == "${rel_arch}" ]] ; then
      expected="${entry_sha}"
      break
    fi
  done
  if [[ -z "${expected}" ]] ; then
    echo "ERROR: no pinned SHA256 for pangolin arch '${rel_arch}'." >&2
    exit 1
  fi
  echo "${expected}  ${bin}" | sha256sum -c -

  mkdir -p "${sysextroot}/usr/bin"
  install -m 0755 "${bin}" "${sysextroot}/usr/bin/pangolin"
}
# --
