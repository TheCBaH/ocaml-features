# Notes

## Package-manager detection

`install.sh` branches on `apt-get` vs. `emerge` at the top of the script; the
rest of the script (opam init/switch/package loop, pin handling, overrides)
is a single shared code path. Adding a third distribution means adding a
`check_packages_<mgr>`/`translate_packages_<mgr>` pair and a branch in
`PKG_MANAGER` detection, not a parallel script.

## Debian → Portage package-name translation

`system-packages` is always spelled with Debian package names, even on
Gentoo. `translate_packages_portage()` maps the ones this feature has
actually needed (`libgmp-dev` → `dev-libs/gmp`, `pkg-config` →
`dev-util/pkgconf`). An unmapped name passes through unchanged with a
warning rather than failing the build — add new entries to that table (not
to a caller's `devcontainer.json`) when a future `system-packages` value
needs a Gentoo-side name that differs from the Debian one.

## `OPAMROOT` ownership

The feature installs opam as root, then `chown -R ${USERNAME}:${USERNAME}
$OPAMROOT` at the end so the container's non-root remote user can use it
without `sudo`. `USERNAME` follows the same "auto" resolution devcontainer
Features conventionally use (`_REMOTE_USER`, then `vscode`/`node`/`codespace`,
then the first uid-1000 account, then `root`).

## Optional vs. required packages

Only `optional-packages` entries may be silently dropped when unsolvable for
the selected switch/platform (checked with `opam install --show-actions`,
not `opam list --installable`, since the latter can still match packages
whose `available:` filter rejects the current architecture). Anything in
`packages` or `pin-packages` that opam cannot install must still fail the
build — that is intentional, not a gap to fix.

## `ocaml-version-overrides` ordering

Version-scoped overrides (`name#version@ocaml-pattern`) are applied after
`packages`/`pin-packages`/`repositories`, so they can override an otherwise
unconditional pin for one specific OCaml switch.
