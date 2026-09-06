#!/bin/bash
# version=4.14.3 with ocaml-version-overrides="ocamlfind#1.9.6@5.*" — the
# glob does not match the selected version, so the override must not apply
# (ocamlfind must not be pinned).
set -e

source dev-container-features-test-lib
export OPAMROOT=/opt/opam
eval "$(opam env)"

check "OCaml version is 4.14.3" bash -c 'ocamlc -version | grep -Fx 4.14.3'
check "non-matching override not applied" bash -c '! opam list --pinned -s ocamlfind | grep -q .'

reportResults
