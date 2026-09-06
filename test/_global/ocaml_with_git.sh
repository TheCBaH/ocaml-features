#!/bin/bash
# ocaml installed alongside an independent Feature (git) — neither should
# disturb the other's install, regardless of lifecycle ordering.
set -e

source dev-container-features-test-lib
[ -f /etc/profile.d/ocaml-opam.sh ] && . /etc/profile.d/ocaml-opam.sh
eval "$(opam env)"

check "opam is available" opam --version
check "git is available" git --version

reportResults
