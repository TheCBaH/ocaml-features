#!/bin/bash
# base-packages="" — only opam itself should be present; dune/ocamlformat
# (the normal defaults) must be absent.
set -e

source dev-container-features-test-lib
export OPAMROOT=/opt/opam
eval "$(opam env)"

check "opam is available" opam --version
check "dune is not installed" bash -c '! command -v dune'
check "ocamlformat is not installed" bash -c '! command -v ocamlformat'

reportResults
