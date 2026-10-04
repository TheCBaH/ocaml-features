#!/bin/bash
# pin-packages="err_trace git+https://...#ff50f85" — the generic "name target" form
# with a git ref in the target.
set -e

source dev-container-features-test-lib
export OPAMROOT=/opt/opam
eval "$(opam env)"

check "err_trace is installed" bash -c 'opam list --installed -s err_trace | grep -Fx err_trace'
check "err_trace is pinned to the git ref" bash -c 'grep -F "#ff50f85" /opt/opam/*/.opam-switch/overlay/err_trace/opam'

reportResults
