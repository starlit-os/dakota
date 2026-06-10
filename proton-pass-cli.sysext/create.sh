#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# Proton Pass CLI sysext.
#
# Adapted from the starlit-os/dakota BuildStream element
# elements/sysext/proton-pass-cli.bst on branch starlit-sysexts.
# Original ID policy (ID=bluefin-dakota) has been relaxed to ID=_any so the
# image is host-agnostic.
#
# Portability caveat: the upstream `pass-cli` Linux binary is dynamically
# linked against the host's libstdc++/glibc. It has only been smoke-tested
# on a Dakota bootc host. Generic ID=_any is the bakery default, but the
# README warns consumers to validate `pass-cli --help` on a non-Dakota
# glibc host before relying on this sysext as fully host-agnostic. See
# starlit-os/dakota docs/sysexts/pangolin.md for the recommended host
# matrix and validation steps.
#
# Copyright (c) 2025 the starlit-os maintainers.
# Use of this source code is governed by the Apache 2.0 license.

RELOAD_SERVICES_ON_MERGE="false"

# Pinned SHA256 sums for the upstream prebuilt binaries.
# These must be updated in lockstep with the version variable below and
# verified by `populate_sysext_root` before the binary is installed.
declare -A PROTON_PASS_CLI_SHAS=(
  ["2.1.2"]="5291edd21d85d222538b91341345ae3b0a1479e254d42920c2bbbd34012c6243:x86_64 0562625812f940bd4b7abd664b3bbcfefdeaf79d2f9b12f2d0a73be1ffc551ff:aarch64"
)

function list_available_versions() {
  list_github_releases "protonpass" "pass-cli"
}
# --

function populate_sysext_root() {
  local sysextroot="$1"
  local arch="$2"
  local version="$3"

  # Upstream uses linux-{x86_64,aarch64} in the asset name.
  local rel_arch="$(arch_transform "x86-64" "x86_64" "$arch")"
  rel_arch="$(arch_transform "arm64" "aarch64" "$rel_arch")"

  local url="https://github.com/protonpass/pass-cli/releases/download/${version}/pass-cli-linux-${rel_arch}"
  local bin="pass-cli-linux-${rel_arch}"

  echo "Downloading ${url}"
  curl --fail --silent --show-error --location --remote-name "${url}"

  # SHA256 verify against the pinned sum for this version + arch.
  local pinned="${PROTON_PASS_CLI_SHAS[${version}]:-}"
  if [[ -z "${pinned}" ]] ; then
    echo "ERROR: no pinned SHA256 for proton-pass-cli version '${version}'." >&2
    echo "Update PROTON_PASS_CLI_SHAS in create.sh and re-run." >&2
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
    echo "ERROR: no pinned SHA256 for proton-pass-cli arch '${rel_arch}'." >&2
    exit 1
  fi
  echo "${expected}  ${bin}" | sha256sum -c -

  mkdir -p "${sysextroot}/usr/bin"
  install -m 0755 "${bin}" "${sysextroot}/usr/bin/pass-cli"
}
# --
