#!/bin/sh
set -eu
set -x

echo "Activating feature 'OCaml'"
PACKAGES=${PACKAGES:-$@}
BASE_PACKAGES=${BASE_PACKAGES-"dune ocaml-lsp-server ocamlformat ocamlformat-rpc"}
OPTIONAL_PACKAGES=${OPTIONAL_PACKAGES:-}
SYSTEM_PACKAGES=${SYSTEM_PACKAGES:-}
PIN_PACKAGES=${PIN_PACKAGES:-}
REPOSITORIES=${REPOSITORIES:-}
OCAML_VERSION=${VERSION:-4.14.3}
OCAML_VERSION_OVERRIDES=${OCAML_VERSION_OVERRIDES:-}
OPAM_OPTIONS=''
if [ -n "${OPTIONS:-}" ]; then
    OPAM_OPTIONS="--packages=ocaml-variants.${OCAML_VERSION}+options,${OPTIONS}"
fi
echo "Selected OCaml:$OCAML_VERSION base packages: ${BASE_PACKAGES} packages: $PACKAGES optional: ${OPTIONAL_PACKAGES} with ${OPAM_OPTIONS} ${SYSTEM_PACKAGES}"

# Package-manager detection. apt (Debian/Ubuntu) keeps the original,
# unmodified behavior below; emerge (Gentoo), dnf/yum/tdnf (Fedora/RHEL
# family) and apk (Alpine) are additional paths. Everything distro-specific
# is isolated into the helpers this selects, so the rest of the script (opam
# init/switch/package loop, pin handling, ...) stays a single copy.
if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER=apt
elif command -v emerge >/dev/null 2>&1; then
    PKG_MANAGER=portage
elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER=dnf
    DNF_CMD=dnf
elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER=dnf
    DNF_CMD=yum
elif command -v tdnf >/dev/null 2>&1; then
    PKG_MANAGER=dnf
    DNF_CMD=tdnf
elif command -v apk >/dev/null 2>&1; then
    PKG_MANAGER=apk
else
    echo "Unsupported base image: none of apt-get, emerge, dnf/yum/tdnf, apk found" >&2
    exit 1
fi

# From https://github.com/devcontainers/features/blob/main/src/git/install.sh
apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Mirrors apt_get_update(): re-sync only when the tree looks empty, so a
# Dockerfile that already ran emerge-webrsync (as this repo's does) doesn't
# pay for a second sync here.
portage_sync()
{
    tree="${PORTDIR:-/var/db/repos/gentoo}"
    if [ ! -d "$tree" ] || [ -z "$(ls -A "$tree" 2>/dev/null)" ]; then
        echo "Running emerge-webrsync..."
        emerge-webrsync
    fi
}

# Checks if packages are installed and installs them if not
check_packages_apt() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        if ! apt-get -o Acquire::Retries=3 -y install --no-install-recommends "$@"; then
            apt-get update -y
            apt-get -o Acquire::Retries=3 -y install --no-install-recommends "$@"
        fi
    fi
}

check_packages_portage() {
    [ "$#" -eq 0 ] && return 0
    portage_sync
    emerge --quiet --noreplace "$@"
}

check_packages_dnf() {
    [ "$#" -eq 0 ] && return 0
    "$DNF_CMD" install -y "$@"
}

# Alpine's index sync is cheap (a small compressed file per repo, no
# webrsync-style full-tree mirror like Gentoo's), so unlike apt/portage this
# always re-syncs rather than trying to detect a stale/missing cache.
apk_update() {
    apk update
}

check_packages_apk() {
    [ "$#" -eq 0 ] && return 0
    apk_update
    apk add --no-cache "$@"
}

check_packages() {
    case "$PKG_MANAGER" in
        apt) check_packages_apt "$@" ;;
        portage) check_packages_portage "$@" ;;
        dnf) check_packages_dnf "$@" ;;
        apk) check_packages_apk "$@" ;;
    esac
}

# devcontainer.json spells system-packages using Debian package names (this
# repo passes "libgmp-dev pkg-config"); on other package managers those names
# don't exist, so translate the ones this feature actually sees. An unmapped
# name passes through unchanged with a warning rather than failing, so a
# future Debian-only addition here doesn't hard-break the other paths.
translate_packages_portage() {
    for pkg in "$@"; do
        case "$pkg" in
            libgmp-dev) echo dev-libs/gmp ;;
            pkg-config) echo dev-util/pkgconf ;;
            */*) echo "$pkg" ;;
            *)
                echo "no portage atom mapping for '$pkg', passing through as-is" >&2
                echo "$pkg"
                ;;
        esac
    done
}

translate_packages_dnf() {
    for pkg in "$@"; do
        case "$pkg" in
            libgmp-dev) echo gmp-devel ;;
            pkg-config) echo pkgconf-pkg-config ;;
            *)
                echo "no dnf package mapping for '$pkg', passing through as-is" >&2
                echo "$pkg"
                ;;
        esac
    done
}

translate_packages_apk() {
    for pkg in "$@"; do
        case "$pkg" in
            libgmp-dev) echo gmp-dev ;;
            pkg-config) echo pkgconf ;;
            *)
                echo "no apk package mapping for '$pkg', passing through as-is" >&2
                echo "$pkg"
                ;;
        esac
    done
}

# devcontainer.json's system-packages is always Debian-spelled; translate for
# whichever package manager this image actually uses.
translate_packages() {
    case "$PKG_MANAGER" in
        apt) printf '%s\n' "$@" ;;
        portage) translate_packages_portage "$@" ;;
        dnf) translate_packages_dnf "$@" ;;
        apk) translate_packages_apk "$@" ;;
    esac
}

export DEBIAN_FRONTEND=noninteractive

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
UPDATE_RC="${UPDATE_RC:-"true"}"

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS="vscode node codespace $(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)"
    for CURRENT_USER in $POSSIBLE_USERS; do
        if id -u "${CURRENT_USER}" > /dev/null 2>&1; then
            USERNAME="${CURRENT_USER}"
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

updaterc() {
    if [ "${UPDATE_RC}" = "true" ]; then
        echo "Updating /etc/bash.bashrc, /etc/zsh/zshrc and /etc/profile.d..."
        # Debian/Ubuntu vs. Gentoo spell the system-wide bash rc file
        # differently; each is a no-op if absent on this distro.
        if [ -f /etc/bash.bashrc ]; then
            /bin/echo -e "$1" >> /etc/bash.bashrc
        fi
        if [ -f /etc/bash/bashrc ]; then
            /bin/echo -e "$1" >> /etc/bash/bashrc
        fi
        if [ -f "/etc/zsh/zshrc" ]; then
            /bin/echo -e "$1" >> /etc/zsh/zshrc
        fi
        # Gentoo's /etc/bash/bashrc opts out for non-interactive shells
        # ("Proceed no further in the case of a non-interactive shell"), so
        # a login-but-non-interactive invocation (e.g. `devcontainer exec
        # bash -lc ...`, or any script/CI use of `bash -c`) never sees the
        # export above there. /etc/profile.d/*.sh has no such guard and is
        # sourced by /etc/profile for every login shell regardless of
        # interactivity, on both Debian and Gentoo, so mirror the snippet
        # there too as the reliable path.
        if [ -d /etc/profile.d ]; then
            /bin/echo -e "$1" >> /etc/profile.d/ocaml-opam.sh
        fi
    fi
}

export OPAMROOT="/opt/opam"
export OPAMYES="true"
export OPAMCONFIRMLEVEL="unsafe-yes"

rc="$(cat << EOF
# >>> OCaml >>>
export OPAMROOT="$OPAMROOT"
# <<< OCaml <<<
EOF
)"
updaterc "$rc"

# ca-certificates first and on its own: opam's own repository fetch (or, on
# the binary-installer fallback below, curl's fetch of the installer itself)
# is the very next network access, and a bare (non-devcontainer-base) image
# such as plain debian/ubuntu has no CA trust store at all, which fails HTTPS
# downloads with a certificate-issuer error rather than a missing-package one.
case "$PKG_MANAGER" in
    portage) check_packages app-misc/ca-certificates ;;
    *) check_packages ca-certificates ;;
esac

# shellcheck disable=SC2046
check_packages $(translate_packages ${SYSTEM_PACKAGES})

# Prefer the distro-packaged opam: it pulls in the OCaml build toolchain as a
# transitive dependency. Only Debian/Ubuntu, Gentoo and Fedora actually
# package opam -- RHEL clones (no EPEL build) and stable Alpine (opam only
# exists in Alpine's edge/community branch, not any release) don't. Fall back
# to opam's own prebuilt-binary installer there, installing the build
# toolchain ourselves first since a raw binary has no dependencies to pull it in.
opam_available() {
    case "$PKG_MANAGER" in
        apt|portage) return 0 ;;
        dnf) "$DNF_CMD" list opam >/dev/null 2>&1 ;;
        apk) apk_update; apk add --simulate --no-cache opam >/dev/null 2>&1 ;;
    esac
}

install_opam_binary() {
    echo "No distro package for opam on this image; installing the upstream prebuilt binary from opam.ocaml.org"
    case "$PKG_MANAGER" in
        dnf) check_packages curl gcc make unzip bubblewrap patch ;;
        apk) check_packages curl build-base ;;
    esac
    tmp_dir=$(mktemp -d)
    (cd "$tmp_dir" && curl -fsSL https://opam.ocaml.org/install.sh | sh -s -- --download-only)
    bin=$(find "$tmp_dir" -maxdepth 1 -name 'opam-*' -type f | head -n 1)
    if [ -z "$bin" ]; then
        echo "opam installer did not produce a binary in $tmp_dir" >&2
        exit 1
    fi
    install -m 0755 "$bin" /usr/local/bin/opam
    rm -rf "$tmp_dir"
}

if opam_available; then
    case "$PKG_MANAGER" in
        portage) check_packages dev-ml/opam ;;
        *) check_packages opam ;;
    esac
else
    install_opam_binary
fi

export OPAMJOBS="$(getconf _NPROCESSORS_ONLN)"
opam init --no-setup --disable-sandboxing --bare
eval $(opam env)
opam switch create $OCAML_VERSION ${OPAM_OPTIONS}

if [ -n "${REPOSITORIES}" ]; then
    OLDIFS="$IFS"
    IFS=','
    for entry in ${REPOSITORIES}; do
        IFS="$OLDIFS"
        entry=$(echo "$entry" | xargs)
        if [ -n "$entry" ]; then
            repo_name=$(echo "$entry" | awk '{print $1}')
            repo_url=$(echo "$entry" | awk '{print $2}')
            opam repo add "$repo_name" "$repo_url"
        fi
    done
    IFS="$OLDIFS"
    opam update
fi

OPAM_PACKAGES=""
for pkg in ${BASE_PACKAGES} ${PACKAGES}; do
    case "$pkg" in
        *#*)
            pkg_name=$(echo "$pkg" | cut -d'#' -f1)
            pkg_ver=$(echo "$pkg" | cut -d'#' -f2)
            opam pin add --no-action "$pkg_name" "$pkg_ver"
            OPAM_PACKAGES="${OPAM_PACKAGES} ${pkg_name}"
            ;;
        *)
            OPAM_PACKAGES="${OPAM_PACKAGES} ${pkg}"
            ;;
    esac
done

OPTIONAL_OPAM_PACKAGES=""
for pkg in ${OPTIONAL_PACKAGES}; do
    case "$pkg" in
        *#*)
            pkg_name=$(echo "$pkg" | cut -d'#' -f1)
            pkg_ver=$(echo "$pkg" | cut -d'#' -f2)
            # Unlike packages/pin-packages, a pin failure here (e.g. the
            # package name doesn't exist at all, not just an unsolvable
            # version) must not abort the build: "optional" means skip it,
            # the same as the not-installable case the dry-run below catches.
            if opam pin add --no-action "$pkg_name" "$pkg_ver"; then
                OPTIONAL_OPAM_PACKAGES="${OPTIONAL_OPAM_PACKAGES} ${pkg_name}"
            else
                echo "Skipping optional package '$pkg': could not pin" >&2
            fi
            ;;
        *)
            OPTIONAL_OPAM_PACKAGES="${OPTIONAL_OPAM_PACKAGES} ${pkg}"
            ;;
    esac
done

if [ -n "${PIN_PACKAGES}" ]; then
    OLDIFS="$IFS"
    IFS=','
    for entry in ${PIN_PACKAGES}; do
        IFS="$OLDIFS"
        entry=$(echo "$entry" | xargs)
        if [ -n "$entry" ]; then
            case "$entry" in
                *#*)
                    pkg_name=$(echo "$entry" | cut -d'#' -f1)
                    pkg_ver=$(echo "$entry" | cut -d'#' -f2)
                    opam pin add --no-action "$pkg_name" "$pkg_ver"
                    ;;
                *)
                    pkg_name=$(echo "$entry" | awk '{print $1}')
                    opam pin add --no-action $entry
                    ;;
            esac
            OPAM_PACKAGES="${OPAM_PACKAGES} ${pkg_name}"
        fi
    done
    IFS="$OLDIFS"
fi

# A version override is a release pin qualified by an OCaml-version shell glob,
# e.g. "yojson#2.2.2@4.12.*". Apply these after generic pins so a devcontainer
# author can override an otherwise unconditional package choice for one switch.
for entry in ${OCAML_VERSION_OVERRIDES}; do
    case "$entry" in
        *@*)
            pin_spec=${entry%@*}
            ocaml_pattern=${entry##*@}
            ;;
        *)
            echo "Invalid ocaml-version-overrides entry '$entry': expected name#version@ocaml-pattern" >&2
            exit 1
            ;;
    esac
    case "$pin_spec" in
        *#*)
            pkg_name=$(echo "$pin_spec" | cut -d'#' -f1)
            pkg_ver=$(echo "$pin_spec" | cut -d'#' -f2)
            ;;
        *)
            echo "Invalid ocaml-version-overrides entry '$entry': expected name#version@ocaml-pattern" >&2
            exit 1
            ;;
    esac
    case "$OCAML_VERSION" in
        $ocaml_pattern)
            echo "Applying OCaml-version override '$pin_spec' for $OCAML_VERSION (pattern: $ocaml_pattern)"
            opam pin add --no-action "$pkg_name" "$pkg_ver"
            ;;
    esac
done

# Only the packages declared optional may be dropped; anything in PACKAGES or
# PIN_PACKAGES that opam cannot install must still fail the build.
for pkg in ${OPTIONAL_OPAM_PACKAGES}; do
    # A solver dry run is required here: `opam list --installable` can still
    # match packages whose `available:` filter rejects the current architecture.
    if opam install --show-actions "$pkg" > /dev/null 2>&1; then
        OPAM_PACKAGES="${OPAM_PACKAGES} ${pkg}"
    else
        echo "Skipping optional package '$pkg': not installable for this switch/platform" >&2
    fi
done

if [ -n "${OPAM_PACKAGES}" ]; then
    opam install ${OPAM_PACKAGES}
fi

opam clean --repo-cache
opam list
chown -R ${USERNAME}:${USERNAME} $OPAMROOT

case "$PKG_MANAGER" in
    apt)
        apt-get autoremove -y
        apt-get clean -y
        rm -rf /var/lib/apt/lists/*
        ;;
    portage)
        rm -rf /var/cache/distfiles/* /var/cache/binpkgs/*
        ;;
    dnf)
        "$DNF_CMD" clean all
        ;;
    apk)
        rm -rf /var/cache/apk/*
        ;;
esac
