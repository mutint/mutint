#!/bin/sh
# Starting MutInt, from Finder or from MutInt.app -- one implementation for both.
#
# Double-clicked in Finder, this runs in a Terminal window and prints to it, which is what
# it has always done. Launched by MutInt.app, there is no window: the app redirects this
# script's output to a log and sets MUTINT_LOG_FILE, and the log is what the viewer window
# opened below is reading. `[ -t 1 ]` is the whole of the difference and needs no flag --
# an app launched by LaunchServices has no controlling terminal (verified: `ps -o tty=`
# answers `??`).
#
# **This script execs the server**, and so does the app that execs this script, so the
# process that ends up serving is the one macOS started and its pid never changes. That is
# what makes the Dock tile last as long as MutInt does.
cd "$(dirname "$0")" || exit 1

# LaunchServices hands an app a minimal PATH, so a Python installed by Homebrew or from
# python.org is not on it -- without this, a machine with no Command Line Tools would work
# from Terminal and fail from the Dock, which is the worst way for this to break.
PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
export PATH

# Says what went wrong, wherever there is to say it: the terminal if we have one, a dialog
# if we do not. Exits; there is nothing after this worth trying.
fail() {
    if [ -t 1 ]; then
        printf '\n%s\n\n' "$1" >&2
    else
        osascript - "$1" >/dev/null 2>&1 <<'APPLESCRIPT'
on run argv
    display dialog (item 1 of argv) with title "MutInt" with icon stop ¬
        buttons {"Cancel", "Install Developer Tools"} default button "Install Developer Tools"
    if button returned of result is "Install Developer Tools" then
        try
            do shell script "xcode-select --install"
        end try
    end if
end run
APPLESCRIPT
    fi
    exit 1
}

# Which Python starts the entry script.
#
# `./mutint` is `#!/usr/bin/env python3`, so something has to be a Python before the
# checkout has installed its own. On a Mac with no Command Line Tools **/usr/bin/python3 is
# not a Python at all**: it is a stub whose only job is to pop "requires the command line
# developer tools". /usr/bin/{python3,git,clang,make} are all hard links to that one binary.
#
# So it cannot be probed by running it -- running it *is* the prompt. `xcode-select -p`
# answers the same question and pops nothing.
if [ -x "env/python/bin/python3" ]; then
    # What the checkout installed for itself. After one successful run this is always the
    # answer, and no host Python is needed again -- including on a machine that only ever
    # had the stub, because `install.sh` got that far with micromamba.
    PYTHON="env/python/bin/python3"
else
    PYTHON="$(command -v python3 2>/dev/null)"
    if [ "$PYTHON" = "/usr/bin/python3" ] && ! xcode-select -p >/dev/null 2>&1; then
        PYTHON=""
    fi
fi
[ -n "$PYTHON" ] || fail "MutInt needs Apple's Command Line Tools before it can start for the first time.

They include the Python that gets MutInt going, and installing them takes a few minutes and no decisions. Once MutInt has run once it installs a Python of its own and never needs these again."

# `start` hardcodes port 8000 and does no pre-flight bind check, so without this a launch
# while one is already up would migrate, print a success banner, open a browser tab pointed
# at the server that is already running, and only then die with "That port is already in
# use" -- the error arriving after the success.
#
# Clicking the Dock icon cannot cause that (LaunchServices runs one instance per bundle id
# and drops the second launch; verified), but the two entry points can: a server started
# from Terminal, then the app, or the reverse.
if nc -z 127.0.0.1 8000 2>/dev/null; then
    [ -t 1 ] && echo "MutInt is already running at http://127.0.0.1:8000"
    open http://127.0.0.1:8000
    exit 0
fi

# The window, when we are the app: a *viewer* on the log, holding nothing but `tail`.
# Closing it costs nothing, which is the entire point of the arrangement -- the window used
# to be the server, so closing it was how people killed MutInt by accident.
if [ -n "$MUTINT_LOG_FILE" ]; then
    osascript - "$MUTINT_LOG_FILE" >/dev/null 2>&1 <<'APPLESCRIPT'
on run argv
    tell application "Terminal"
        activate
        do script "clear; echo 'MutInt server log. Closing this window does NOT stop MutInt --'; echo 'quit MutInt from the Dock to do that.'; echo; exec tail -n +1 -f " & quoted form of (item 1 of argv)
    end tell
end run
APPLESCRIPT
fi

exec "$PYTHON" ./mutint start
