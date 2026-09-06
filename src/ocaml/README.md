# ocaml/opam toolchains (ocaml)

Install ocaml/opam toolchains (Debian/Ubuntu apt or Gentoo portage)

## Example Usage

```jsonc
{
    "features": {
        "ghcr.io/thecbah/ocaml-features/ocaml:1": {
            "version": "5.2.1",
            "packages": "utop ocamlformat#0.28.0"
        }
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| base-packages | space-separated packages installed by default; override this list for minimal or specialized toolchains | string | dune ocaml-lsp-server ocamlformat ocamlformat-rpc |
| packages | additional space-separated packages to install; use 'name#version' to pin a specific version (e.g. 'utop ocamlformat#0.28.0'). Installation fails if a package is unavailable | string | - |
| optional-packages | space-separated packages to install only when opam can solve them for the selected switch and platform; same 'name#version' pin syntax as 'packages' (e.g. 'melange') | string | - |
| version | OCaml version | string | 4.14.3 |
| options | OPAM switch options | string | - |
| system-packages | additional system packages | string | - |
| repositories | comma-separated extra opam repositories to add before installing packages: 'name url' pairs (e.g. 'rocq-released https://rocq-prover.org/opam/released') | string | - |
| pin-packages | comma-separated packages to pin: use 'name#version' to pin a specific version, 'name url' or 'name version' to pin via opam pin add (e.g. 'pkg1#1.0.0,pkg2 https://repo.git#branch') | string | - |
| ocaml-version-overrides | space-separated package pins applied only to matching OCaml versions: use 'name#version@ocaml-pattern', where the pattern is a shell glob (e.g. 'yojson#2.2.2@4.12.*'). Matching overrides are applied after other pins. | string | - |

## Supported distributions

- Debian/Ubuntu, via `apt-get` and opam.
- Gentoo, via Portage (`emerge`) and opam. `system-packages` is still spelled
  with Debian package names; unmapped names are translated to Portage atoms
  where known (see `NOTES.md`) and passed through unchanged otherwise.

See `NOTES.md` for behavior notes that aren't obvious from the option list.
