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
# ocaml-option-static only makes the switch's C compiler musl-gcc
# (no -static baked in); a static link of the user's own code still
# needs -ccopt -static explicitly, same as any other ocamlopt build.
ocamlopt -ccopt -static /tmp/variant_hello.ml -o /tmp/variant_hello

check "binary runs" bash -c '/tmp/variant_hello | grep -qx hi'
check "binary is statically linked" bash -c 'ldd /tmp/variant_hello 2>&1 | grep -qi "not a dynamic executable"'

reportResults
