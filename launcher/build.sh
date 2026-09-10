#!/bin/sh
# Rebuild MutInt.app from MutInt.applescript.
#
# The bundle is committed, and this is what regenerates it -- the same arrangement
# Contents/Resources/MutInt.icns already has, whose recipe is recorded in the Info.plist it
# ends up in. `osacompile` is a real binary on every Mac (unlike /usr/bin/python3, which is a
# stub until the Command Line Tools are installed), so this needs no Xcode and no toolchain.
#
# Run it from anywhere:  sh launcher/build.sh
set -e

here="$(cd "$(dirname "$0")/.." && pwd)"
app="$here/MutInt.app"
icon="$here/launcher/MutInt.icns"

# The icon is *this* file's input, not the bundle's: `osacompile` writes the bundle from
# scratch, so anything left inside it is destroyed on every rebuild. Keeping the master here
# and copying it in is what makes the build repeatable rather than a one-way door.
[ -f "$icon" ] || { echo "launcher/MutInt.icns is missing." >&2; exit 1; }

# **Rebuilding the icon**, since nothing here does it and the recipe would otherwise be
# lost with the Info.plist osacompile overwrites:
#
#   Resources/MutInt.icns, named without its extension, which is what this key
#   expects. Rebuilding it, since nothing in the repo does: compose each slot on
#   Apple's 1024pt grid -- an 824x824 plate, corner radius 185.4, centred, filled
#   #ffffff -- with the mark from staticfiles/img/mutint/ centred on its own ink
#   bounding box at an extent of 660, i.e. 82pt of plate showing on every side.
#   Render every one of the ten standard slots at its native size from that SVG
#   rather than resampling a master, then `iconutil -c icns`.
#
#   The 16 and 32 physical-pixel slots use icon-16.svg, the simplified mark: three
#   shapes where the full icon has fifteen. That is the same rule favicon.ico
#   follows, so the tab icon and the bundle icon agree about where detail stops
#   being legible. Everything from 64px up uses icon.svg.
#
#   Rasterize with a browser engine, not ImageMagick: its built-in SVG renderer
#   flattens circles to a fixed segment count in user units, and the mark's rings
#   come out visibly polygonal once the composing transform magnifies them.
#   Supersampling does not hide it. Headless Chrome writes the screenshot and then
#   hangs on shutdown, so poll for the file and kill it.

rm -rf "$app"
# -s is stay-open: without it the applet runs `on run` and quits, taking the Dock tile with it
# and leaving MutInt with no way to be quit -- which is the whole point of the applet.
osacompile -s -o "$app" "$here/launcher/MutInt.applescript"

plist="$app/Contents/Info.plist"
set_key() {
    /usr/libexec/PlistBuddy -c "Delete :$1" "$plist" >/dev/null 2>&1 || true
    /usr/libexec/PlistBuddy -c "Add :$1 $2 $3" "$plist"
}

# **CFBundleIdentifier is the one osacompile does not write, and it is load-bearing.**
# LaunchServices keys single-instance behaviour on it -- without one, a second click can start
# a second MutInt -- and so does the Automation permission, so a bundle that loses its
# identifier asks again for control of Terminal and forgets it was ever granted.
set_key CFBundleIdentifier string edu.utexas.barricklab.mutint.launcher
set_key CFBundleName string MutInt
set_key CFBundleDisplayName string MutInt
set_key CFBundleShortVersionString string 0.0.1
set_key LSMinimumSystemVersion string 10.13

# The sentence macOS shows in the "MutInt wants to control Terminal" prompt. The app drives
# Terminal to show the server's log; see docs/installing.md.
set_key NSAppleEventsUsageDescription string "MutInt opens a Terminal window showing its log while it starts."

# osacompile drops its own stock applet icon in; ours is the one CFBundleIconFile names,
# so that is one binary the repo does not need to carry.
rm -f "$app/Contents/Resources/applet.icns"
cp "$icon" "$app/Contents/Resources/MutInt.icns"
set_key CFBundleIconFile string MutInt

# osacompile signs the bundle ad-hoc as it writes it, and every edit above invalidates that.
# An invalid signature is worse than none: Gatekeeper refuses the app outright, where an
# unsigned one launched from a git clone (no quarantine attribute) simply runs.
codesign --force --sign - "$app" >/dev/null 2>&1 || true

echo "Built $app"
