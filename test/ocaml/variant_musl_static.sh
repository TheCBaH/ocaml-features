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

check "binary runs" bash -c '/tmp/variant_hello | grep -qx hi'
check "binary is statically linked" bash -c 'file /tmp/variant_hello | grep -qi "statically linked"'

reportResults
