#!/bin/bash
# remoteUser=octocat (a non-root user created by common-utils) — OPAMROOT
# must end up owned by that user, not root.
set -e

source dev-container-features-test-lib
[ -f /etc/profile.d/ocaml-opam.sh ] && . /etc/profile.d/ocaml-opam.sh
eval "$(opam env)"

check "running as octocat" bash -c 'test "$(id -un)" = octocat'
check "OPAMROOT owned by octocat" bash -c 'test "$(stat -c %U "$OPAMROOT")" = octocat'

reportResults
