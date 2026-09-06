#!/bin/bash
# packages="utop ocamlfind#1.9.6" — a plain required package plus a
# name#version pin.
set -e

source dev-container-features-test-lib
export OPAMROOT=/opt/opam
eval "$(opam env)"

check "utop is installed" utop -version
check "ocamlfind is pinned to 1.9.6" bash -c 'opam list --installed --column=version -s ocamlfind | grep -Fx 1.9.6'

reportResults
