#!/bin/bash
# version=4.14.3 with ocaml-version-overrides="ocamlfind#1.9.6@4.14.*" — the
# glob matches the selected version, so the override pin must apply.
set -e

source dev-container-features-test-lib
export OPAMROOT=/opt/opam
eval "$(opam env)"

check "OCaml version is 4.14.3" bash -c 'ocamlc -version | grep -Fx 4.14.3'
check "matching override applied" bash -c 'opam list --installed --column=version -s ocamlfind | grep -Fx 1.9.6'

reportResults
