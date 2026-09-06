#!/bin/bash
# version="5.2.1" (not the Feature default) — the requested OCaml version,
# not the default, must be the one actually built.
set -e

source dev-container-features-test-lib
[ -f /etc/profile.d/ocaml-opam.sh ] && . /etc/profile.d/ocaml-opam.sh
eval "$(opam env)"

check "requested OCaml version 5.2.1 is installed" bash -c 'ocamlc -version | grep -Fx 5.2.1'

reportResults
