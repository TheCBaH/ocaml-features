#!/bin/bash
# pin-packages="ocamlfind#1.9.6,dune" — a name#version pin form and a bare
# name pin-add form.
set -e

source dev-container-features-test-lib
[ -f /etc/profile.d/ocaml-opam.sh ] && . /etc/profile.d/ocaml-opam.sh
eval "$(opam env)"

check "ocamlfind pinned to 1.9.6" bash -c 'opam list --installed --column=version -s ocamlfind | grep -Fx 1.9.6'
check "dune is installed" dune --version

reportResults
