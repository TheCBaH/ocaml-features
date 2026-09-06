#!/bin/bash
# repositories="extra https://opam.ocaml.org" — an additional named opam
# repository must be registered.
set -e

source dev-container-features-test-lib
[ -f /etc/profile.d/ocaml-opam.sh ] && . /etc/profile.d/ocaml-opam.sh
eval "$(opam env)"

check "extra repository registered" bash -c 'opam repo list | grep -q "^extra "'

reportResults
