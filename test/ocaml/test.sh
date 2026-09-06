#!/bin/bash
# Runs against the auto-generated devcontainer.json (default options).
# See: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
set -e

source dev-container-features-test-lib
[ -f /etc/profile.d/ocaml-opam.sh ] && . /etc/profile.d/ocaml-opam.sh
eval "$(opam env)"

check "opam is available" opam --version
check "default OCaml version is 5.4.1" bash -c 'ocamlc -version | grep -Fx 5.4.1'
check "dune (base-packages default) is available" dune --version

reportResults
