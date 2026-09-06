#!/bin/bash
# system-packages="libgmp-dev pkg-config" — additional system packages must
# be installed alongside opam itself.
set -e

source dev-container-features-test-lib
[ -f /etc/profile.d/ocaml-opam.sh ] && . /etc/profile.d/ocaml-opam.sh
eval "$(opam env)"

check "libgmp-dev installed" dpkg -s libgmp-dev
check "pkg-config installed" dpkg -s pkg-config

reportResults
