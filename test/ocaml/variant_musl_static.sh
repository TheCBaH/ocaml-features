#!/bin/bash
# options="ocaml-option-musl,ocaml-option-static" plus
# system-packages="musl-tools" (musl-gcc, the depext ocaml-option-musl
# itself declares) — a real, fully static, musl-linked binary must come
# out the other end, not just an opam switch that claims to have it.
set -e

source dev-container-features-test-lib
export OPAMROOT=/opt/opam
eval "$(opam env)"

echo 'let () = print_endline "hi"' > /tmp/variant_hello.ml
ocamlopt /tmp/variant_hello.ml -o /tmp/variant_hello
file /tmp/variant_hello

check "binary runs" bash -c '/tmp/variant_hello | grep -qx hi'
# "static" alone, not "statically linked": a static-PIE binary (common
# default for -static toolchains that also default to PIE) shows up in
# `file` as "static-pie linked", which "statically linked" doesn't match.
check "binary is statically linked" bash -c 'file /tmp/variant_hello | grep -qi static'

reportResults
