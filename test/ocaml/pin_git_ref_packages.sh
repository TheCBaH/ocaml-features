#!/bin/bash
# packages="err_trace#git+https://...#ff50f85" — a name#url pin whose url itself
# contains a "#" (a git ref); only the text up to the first "#" is the name.
set -e

source dev-container-features-test-lib
export OPAMROOT=/opt/opam
eval "$(opam env)"

check "err_trace is installed" bash -c 'opam list --installed -s err_trace | grep -Fx err_trace'
check "err_trace is pinned to the git ref" bash -c 'grep -F "#ff50f85" /opt/opam/*/.opam-switch/overlay/err_trace/opam'

reportResults
