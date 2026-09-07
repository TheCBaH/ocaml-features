#!/bin/bash
# remoteUser=octocat (a non-root user created by common-utils) — OPAMROOT
# must end up owned by that user, not root.
set -e

source dev-container-features-test-lib
export OPAMROOT=/opt/opam
eval "$(opam env)"

check "running as octocat" bash -c 'test "$(id -un)" = octocat'
check "OPAMROOT owned by octocat" bash -c 'test "$(stat -c %U "$OPAMROOT")" = octocat'

reportResults
