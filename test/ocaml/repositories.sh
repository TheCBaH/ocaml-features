#!/bin/bash
# repositories="extra https://opam.ocaml.org" — an additional named opam
# repository must be registered.
set -e

source dev-container-features-test-lib
export OPAMROOT=/opt/opam
eval "$(opam env)"

check "extra repository registered" bash -c "opam repo list --all | grep -qw '^extra'"

reportResults
