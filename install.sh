#!/bin/sh
#
# Install MutInt.
#
#   curl -LO https://raw.githubusercontent.com/mutint/mutint/main/install.sh
#   sh install.sh
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

# ── the clone ────────────────────────────────────────────────────────────────────────────

# --recurse-submodules is not optional: the six components are submodules, and without their
# contents config/settings.py discovers no apps at all and fails saying nothing about it.
echo "Cloning MutInt..."
"${GIT}" clone --recurse-submodules "${REPO}" "${TARGET}"

cleanup
BOOTSTRAP=""

cd "${TARGET}"

echo ""
echo "Starting MutInt. The first run installs Python, the external tools and PostgreSQL"
echo "into env/, which takes a few minutes; after that it starts immediately."
echo ""

exec ./mutint start
