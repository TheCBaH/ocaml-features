#!/bin/bash
# system-packages="libgmp-dev pkg-config" — additional system packages must
# be installed alongside opam itself.
set -e

source dev-container-features-test-lib
export OPAMROOT=/opt/opam
eval "$(opam env)"

check "libgmp-dev installed" dpkg -s libgmp-dev
check "pkg-config installed" dpkg -s pkg-config

reportResults
