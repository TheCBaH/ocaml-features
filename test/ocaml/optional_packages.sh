#!/bin/bash
# optional-packages="utop this-package-does-not-exist#0.0.0" — the
# installable one must be present; the unsatisfiable one must be silently
# skipped rather than failing the build.
set -e

source dev-container-features-test-lib
[ -f /etc/profile.d/ocaml-opam.sh ] && . /etc/profile.d/ocaml-opam.sh
eval "$(opam env)"

check "installable optional package present" utop -version
check "unsatisfiable optional package skipped" bash -c '! opam list --installed -s this-package-does-not-exist | grep -q .'

reportResults
