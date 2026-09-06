# Notes

## Package-manager detection

`install.sh` branches on `apt-get`/`emerge`/`dnf`(or `yum`/`tdnf`)/`apk` at
the top of the script; the rest of the script (opam init/switch/package
loop, pin handling, overrides) is a single shared code path. Adding another
package manager means adding a `check_packages_<mgr>`/`translate_packages_<mgr>`
pair and a branch in `PKG_MANAGER` detection (plus `opam_available()` and the
final-cleanup `case`), not a parallel script.

## Debian → other package-manager name translation

`system-packages` is always spelled with Debian package names, even on
non-Debian package managers. `translate_packages_<mgr>()` maps the ones this
feature has actually needed (`libgmp-dev`, `pkg-config`) to each target's
name. An unmapped name passes through unchanged with a warning rather than
failing the build — add new entries to the relevant table (not to a caller's
`devcontainer.json`) when a future `system-packages` value needs a
non-Debian name that differs from the Debian one.

## opam: distro package vs. the upstream binary installer

`common-utils` (the devcontainers/features one, not TheCBaH's Gentoo fork)
supports three OS families: debian, rhel (RHEL/Fedora/CentOS/Rocky/Alma/Azure
Linux/Mariner), and alpine. Checked against real package indexes (not just
opam's own generic install docs, which list `apk add opam` without
qualification and are misleading here): opam is a real package on
Debian/Ubuntu, Fedora, and Gentoo, but **not** on RHEL-clones (no EPEL build)
or any stable Alpine release (only Alpine's `edge`/`community` branch has
it — verified via pkgs.alpinelinux.org, not just the docs page). `dnf`/`apk`
therefore probe availability first (`opam_available()`) and fall back to
`opam.ocaml.org/install.sh --download-only` plus a manual `install -m 0755`
into `/usr/local/bin` when there's no distro package — this also means the
fallback path must install the build toolchain (gcc/make, or Alpine's
`build-base`) itself, since a raw binary has no package dependencies to pull
it in the way the distro-packaged opam does.

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
