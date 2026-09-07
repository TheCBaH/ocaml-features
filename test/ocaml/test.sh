#!/bin/bash
# Runs against the auto-generated devcontainer.json (default options).
# See: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
set -e

source dev-container-features-test-lib
export OPAMROOT=/opt/opam
eval "$(opam env)"

check "opam is available" opam --version
check "OCaml is available" ocamlc -version
check "dune (base-packages default) is available" dune --version

reportResults
