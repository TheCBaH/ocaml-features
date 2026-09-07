#!/bin/bash
# options="ocaml-option-flambda" — the requested compiler variant must
# actually be the one built, not silently ignored.
set -e

source dev-container-features-test-lib
export OPAMROOT=/opt/opam
eval "$(opam env)"

check "flambda is enabled" bash -c 'ocamlopt -config | grep -qx "flambda: true"'

reportResults
