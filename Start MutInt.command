#!/bin/sh
# Double-clickable launcher for `./mutint start`. Finder runs a .command file inside
# Terminal, which is the point: a first run spends minutes installing the venv and the
# tools before Django exists, and prints the admin credentials once. An .app on its own
# would swallow all of it, and swallow a failure with it.
cd "$(dirname "$0")" || exit 1

# `start` hardcodes port 8000 and does no pre-flight bind check, so a second double-click
# would migrate, print a success banner, open a browser tab pointed at the server that is
# already running, and only then die with "That port is already in use" -- the error
# arriving after the success. Getting there first turns that into the obvious thing.
if nc -z 127.0.0.1 8000 2>/dev/null; then
    echo "MutInt is already running at http://127.0.0.1:8000"
    open http://127.0.0.1:8000
    exit 0
fi

exec ./mutint start
