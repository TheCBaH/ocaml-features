#!/bin/bash
# pin-packages="ocamlfind#1.9.6,dune 3.15.0" — the name#version form and the
# generic "name version" form (a bare name with no target is an invalid
# pin-packages entry: opam treats it as a path-pin against the cwd).
set -e

source dev-container-features-test-lib
[ -f /etc/profile.d/ocaml-opam.sh ] && . /etc/profile.d/ocaml-opam.sh
eval "$(opam env)"

check "ocamlfind pinned to 1.9.6" bash -c 'opam list --installed --column=version -s ocamlfind | grep -Fx 1.9.6'
check "dune pinned to 3.15.0" bash -c 'opam list --installed --column=version -s dune | grep -Fx 3.15.0'

reportResults
