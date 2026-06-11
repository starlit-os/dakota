#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# Newt sysext.
#
# Newt is the Pangolin tunnel client, published by the same maintainer
# (fosrl) and built as a CGO_ENABLED=0 Go static binary. Adapted from
# the upstream release artifacts; safe to ship as ID=_any because the
# binary is statically linked and has no host-library dependency chain.
#
# Copyright (c) 2025 the starlit-os maintainers.
# Use of this source code is governed by the Apache 2.0 license.

RELOAD_SERVICES_ON_MERGE="false"

# Pinned SHA256 sums for the upstream prebuilt binaries.
# These must be updated in lockstep with the version variable below and
# verified by `populate_sysext_root` before the binary is installed.
declare -A NEWT_SHAS=(
  ["1.13.0"]="81db0bc6e303d78419f7be23bc87ce0fdef064758f84e3223f3c3d3f588f1a1c:amd64 161f2b4893ffcdcc563ff5d43812c94df2064b0b210520277e513f5f04a2ff55:arm64"
)

function list_available_versions() {
  list_github_releases "fosrl" "newt"
}
# --

function populate_sysext_root() {
  local sysextroot="$1"
  local arch="$2"
  local version="$3"

  local rel_arch="$(arch_transform "x86-64" "amd64" "$arch")"
  rel_arch="$(arch_transform "arm64" "arm64" "$rel_arch")"

  local url="https://github.com/fosrl/newt/releases/download/${version}/newt_linux_${rel_arch}"
  local bin="newt_linux_${rel_arch}"

  echo "Downloading ${url}"
  curl --fail --silent --show-error --location --remote-name "${url}"

  # SHA256 verify against the pinned sum for this version + arch.
  local pinned="${NEWT_SHAS[${version}]:-}"
  if [[ -z "${pinned}" ]] ; then
    echo "ERROR: no pinned SHA256 for newt version '${version}'." >&2
    echo "Update NEWT_SHAS in create.sh and re-run." >&2
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
    echo "ERROR: no pinned SHA256 for newt arch '${rel_arch}'." >&2
    exit 1
  fi
  echo "${expected}  ${bin}" | sha256sum -c -

  mkdir -p "${sysextroot}/usr/bin"
  install -m 0755 "${bin}" "${sysextroot}/usr/bin/newt"
}
# --
