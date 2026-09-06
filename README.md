# ocaml-features

Dev Container Features maintained by [TheCBaH](https://github.com/TheCBaH),
built on the [Dev Container Feature self-authoring
template](https://github.com/devcontainers/feature-template).

This repository owns only Features intentionally maintained here. It does not
carry a fork or snapshot of `devcontainers/features`, and does not publish
copies of upstream Features.

## Features

### `ocaml`

Installs ocaml/opam toolchains on Alpine (`apk`), Debian/Ubuntu (`apt-get`),
Fedora/RHEL-family (`dnf`), or Gentoo (Portage). See
[`src/ocaml/README.md`](src/ocaml/README.md) for the full option list.

```jsonc
{
    "features": {
        "ghcr.io/thecbah/ocaml-features/ocaml:1": {
            "version": "5.2.1"
        }
    }
}
```

## Development

The root `.devcontainer/devcontainer.json` is a small meta-container with the
Dev Container CLI, Docker access, and `sshd` — it does not itself consume the
`ocaml` Feature. Test the working tree directly:

```sh
devcontainer features test -f ocaml .
```

## Branch and release lifecycle

Push development commits to `devel`. Each push validates Feature metadata,
runs static shell checks, and runs the local Feature test matrix — nothing is
published from `devel`.

`main` is fast-forwarded only from a green `devel`. A push to `main` re-runs
the required checks, publishes to GHCR
(`ghcr.io/thecbah/ocaml-features/<feature>`), and runs a post-publish smoke
test against the exact published version and its floating major tag.

No pull-request workflow is required; `devel` → `main` fast-forward is the
normal promotion path.

## License

[MIT](LICENSE)
