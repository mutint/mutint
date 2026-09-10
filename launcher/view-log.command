#!/bin/sh
# Shows MutInt's server log as it is written. Double-click it any time, or let MutInt.app
# open it for you at launch.
#
# **This file exists to avoid a permission prompt.** The app used to open its log window by
# telling Terminal, through AppleScript, to run a command -- which is an Apple Event, so the
# first launch put up *"MutInt wants to control Terminal"*. That is a frightening question to
# ask somebody who has just double-clicked an icon to look at some mutations, and refusing it
# left them with no window at all. `open -a Terminal <this file>` asks LaunchServices to open a
# document instead, which needs no permission and produces the same window.
#
# Nothing runs in this window but `tail`, so closing it does not stop MutInt.
cd "$(dirname "$0")/.." || exit 1
log="data/server.log"

clear
if [ ! -f "$log" ]; then
    echo "No log yet: $(pwd)/$log"
    echo
    echo "MutInt writes it when the app starts it. Start MutInt and open this again."
    echo
    exit 0
fi

echo "MutInt server log — $(pwd)/$log"
echo "Closing this window does NOT stop MutInt; quit MutInt from the Dock to do that."
echo "The previous run is kept beside it as data/server.log.1."
echo
# -n +1 from the beginning of this run, since the log is rotated at each launch: what somebody
# opening this wants is the whole story, not whatever has happened since they opened it.
exec tail -n +1 -f "$log"
