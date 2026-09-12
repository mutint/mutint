#!/bin/sh
#
# Install MutInt.
#
#   curl -LO https://raw.githubusercontent.com/mutint/mutint/main/install.sh
#   sh install.sh              # the latest release
#   sh install.sh v0.0.1       # that release
#   sh install.sh main         # the development branch
#
# **It installs a release, not whatever `main` happens to be.** A plain clone takes the tip of
# the default branch, which is a moving target and is not what anybody means by "install
# MutInt"; worse, it lands a fresh installation on an untagged commit while `data/update.json`
# defaults to the `stable` channel, so /update/ immediately offers the newest *tag* -- which
# may be behind the commit just installed. So this asks the remote for its release tags the
# same way `mutint_common/update.py` does (`git ls-remote --tags`, no API, no token) and
# clones the highest one. Asking for `main` writes the channel to match, so the installation
# goes on following the branch it was installed from.
#
# Documented as download-then-run rather than `curl | sh`, so this can be read before it does
# anything. It is short on purpose: its only job is to get far enough to clone. Everything
# after that -- a pinned Python, the virtualenv, the external tools, PostgreSQL, the database
# -- is `./mutint start`, which already does all of it and is the same code an existing
# installation runs every day.
#
# **It will fetch its own git if the machine has none.** That is the one thing this script
# does that a `git clone` line in the README does not: on a Mac with no developer tools, `git`
# prints a dialog inviting you to install Xcode, which is not a first step to ask of somebody
# who wants to look at some mutations. The same micromamba the entry script uses for Python
# and the bioinformatics tools can install git, so it does.
#
# That copy is temporary and is thrown away at the end. `git` is a line in mutint-core's
# tools.txt, so the checkout provisions its own into env/tools on first run, through the path
# every other tool takes -- and conda prefixes are not relocatable, so moving the bootstrap
# one into the clone would produce a prefix that works until it does not.

set -eu

REPO="${MUTINT_REPO:-https://github.com/mutint/mutint.git}"
TARGET="${MUTINT_DIR:-mutint}"

# The version to install: the first argument, else MUTINT_VERSION, else the latest release tag
# once there is a git to ask with. `main` is named rather than inferred from the default
# branch, so what gets installed never depends on where the remote points HEAD.
MAIN_BRANCH=main
VERSION="${MUTINT_VERSION:-}"
if [ $# -gt 0 ]; then
    VERSION="$1"
fi

if [ -e "${TARGET}" ]; then
    echo "'${TARGET}' already exists here." >&2
    echo "Move it aside, or set MUTINT_DIR to install somewhere else." >&2
    exit 1
fi

# ── git, or a temporary one ──────────────────────────────────────────────────────────────

BOOTSTRAP=""
cleanup() {
    if [ -n "${BOOTSTRAP}" ] && [ -d "${BOOTSTRAP}" ]; then
        rm -rf "${BOOTSTRAP}"
    fi
}
trap cleanup EXIT INT TERM

if command -v git >/dev/null 2>&1; then
    GIT=git
else
    echo "No git found. Fetching a temporary one..."

    # The same mapping the entry script's _MICROMAMBA_PLATFORMS holds. Kept in step by hand,
    # which is tolerable because it is four lines that change when micromamba adds a platform.
    case "$(uname -s)/$(uname -m)" in
        Darwin/arm64)   PLATFORM=osx-arm64 ;;
        Darwin/x86_64)  PLATFORM=osx-64 ;;
        Linux/x86_64)   PLATFORM=linux-64 ;;
        Linux/aarch64)  PLATFORM=linux-aarch64 ;;
        *)
            echo "No micromamba build is known for $(uname -s)/$(uname -m)." >&2
            echo "Install git yourself and run this again." >&2
            exit 1 ;;
    esac

    BOOTSTRAP="$(mktemp -d)"
    curl -fsSL "https://micro.mamba.pm/api/micromamba/${PLATFORM}/latest" \
        | tar -xj -C "${BOOTSTRAP}" bin/micromamba
    "${BOOTSTRAP}/bin/micromamba" create -y -q -p "${BOOTSTRAP}/git" \
        -c conda-forge git >/dev/null
    GIT="${BOOTSTRAP}/git/bin/git"
fi

# ── which version ────────────────────────────────────────────────────────────────────────

# The highest `v<numbers>` tag on the remote, or nothing if it has none. The pattern is as
# strict as update.py's TAG_RE on purpose: a tag namespace accumulates release candidates and
# `testdata-*` assets, and an install should land on a reviewed point or not at all. Versions
# are compared component-wise rather than as strings, so v0.10.0 beats v0.2.0; `sort -V` would
# do it in one word and is not on every host this has to run on.
highest_tag() {
    sed -e 's|^.*refs/tags/||' \
        | awk '
            /^v[0-9]+(\.[0-9]+)*$/ {
                n = split(substr($0, 2), part, ".")
                key = ""
                for (i = 1; i <= 4; i++)
                    key = key sprintf("%010d", (i <= n) ? part[i] : 0)
                if (key > best_key) { best_key = key; best = $0 }
            }
            END { if (best != "") print best }'
}

if [ -z "${VERSION}" ]; then
    echo "Asking ${REPO} which versions it has..."
    # "could not ask" and "there is nothing to install" are kept apart here, the same way
    # update.py keeps Unreachable apart from an empty answer: falling back to the branch
    # because the network was busy would install something nobody chose.
    if ! TAGS="$("${GIT}" ls-remote --tags --refs "${REPO}" 'v*')"; then
        echo "Could not reach ${REPO}." >&2
        exit 1
    fi
    VERSION="$(printf '%s\n' "${TAGS}" | highest_tag)"
    if [ -z "${VERSION}" ]; then
        echo "It has no release tags yet; installing the tip of ${MAIN_BRANCH} instead."
        VERSION="${MAIN_BRANCH}"
    fi
fi

# ── the clone ────────────────────────────────────────────────────────────────────────────

# --recurse-submodules is not optional: the six components are submodules, and without their
# contents config/settings.py discovers no apps at all and fails saying nothing about it.
#
# --branch takes a tag as happily as a branch, and leaves HEAD detached on one -- which is
# where an installation belongs, and is what makes `./mutint update` see a version rather
# than a bare SHA.
echo "Cloning MutInt ${VERSION}..."
"${GIT}" clone --recurse-submodules --branch "${VERSION}" "${REPO}" "${TARGET}"

cleanup
BOOTSTRAP=""

cd "${TARGET}"

# Installing the development branch means following it. The update state defaults to the
# `stable` channel, which would otherwise offer the newest release tag to a checkout that is
# deliberately ahead of it. `data/` is the directory the entry script would create anyway.
if [ "${VERSION}" = "${MAIN_BRANCH}" ]; then
    mkdir -p data
    printf '{\n  "channel": "main"\n}\n' > data/update.json
fi

echo ""
echo "Starting MutInt. The first run installs Python, the external tools and PostgreSQL"
echo "into env/, which takes a few minutes; after that it starts immediately."
echo ""

exec ./mutint start
