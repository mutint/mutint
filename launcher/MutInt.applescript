-- MutInt.app's source. `launcher/build.sh` compiles this into the bundle.
--
-- **Why an AppleScript applet rather than the shell script this used to be.** A bundle whose
-- executable is a plain shell script gets a real Dock tile and can be killed cleanly, but it
-- has no way to answer an Apple Event -- so Dock > Quit was sent, never answered, and left
-- Force Quit as the only way to stop MutInt. `osacompile -s` produces a stay-open applet whose
-- runtime dispatches those events, which is the whole reason for the change. Measured before
-- committing to it: the quit handler runs, the process exits, and the sender returns at once.
--
-- `osacompile` is a real binary on every Mac -- unlike /usr/bin/python3, which is a stub until
-- Apple's Command Line Tools are installed -- so rebuilding the launcher needs no Xcode.
--
-- **What this file does not do is decide anything.** Starting MutInt is still
-- `Start MutInt.command`: the interpreter check, the dialog when the Command Line Tools are
-- missing, the already-running check and the log viewer all live there, and this launches that
-- script exactly as Finder would. The applet is the part that can hold a Dock tile and answer
-- Quit, and nothing more.

-- The `./mutint start` this launched. Set on every run, never trusted from the last one: an
-- applet's properties are written back into the compiled script, so a stale pid would survive
-- a launch and `on quit` would signal whatever now holds that number.
property serverPid : 0

on run
    try
        startServer()
    on error message
        -- An applet's own answer to an unhandled error is a raw AppleScript dialog, which
        -- says something like "Can't set launch to ..." to somebody who double-clicked an
        -- icon. Say what failed and stop, rather than sitting in the Dock doing nothing.
        display dialog "MutInt could not start." & return & return & message ¬
            with title "MutInt" buttons {"OK"} default button "OK" with icon stop
        quit
    end try
end run

-- A click on the Dock icon while MutInt is running. This is what a shell-script bundle could
-- not do at all -- LaunchServices sends the event and nothing answers it, so the click did
-- nothing. Opening the browser is what clicking a running MutInt obviously means.
on reopen
    do shell script "/usr/bin/open http://127.0.0.1:8000"
end reopen

-- **The app is MutInt, so it does not outlive the server.** `Start MutInt.command` exits
-- straight away when one is already running (it opens a browser tab instead), and a server can
-- fail on its own; either way a Dock icon with nothing behind it is worse than no icon.
on idle
    if serverPid is not 0 and not isRunning(serverPid) then quit
    return 5
end idle

on quit
    stopServer()
    continue quit
end quit

-- The checkout this bundle is sitting in. `path to me` rather than a baked path, so a copied
-- or renamed installation still finds its own MutInt.
on projectRoot()
    return do shell script "cd " & quoted form of (POSIX path of (path to me)) & "/.. && pwd"
end projectRoot

on isRunning(thePid)
    try
        do shell script "kill -0 " & thePid
        return true
    on error
        return false
    end try
end isRunning

on startServer()
    set root to projectRoot()
    set logFile to root & "/data/server.log"
    set quotedLog to quoted form of logFile

    do shell script "mkdir -p " & quoted form of (root & "/data")

    -- One rotation, so the log you want is still there after clicking the icon again to see
    -- whether it failed the same way twice. Asked of the port first: a launch that finds MutInt
    -- already running writes nothing, and rotating anyway would push the last real log out.
    try
        do shell script "nc -z 127.0.0.1 8000"
    on error
        do shell script "[ -s " & quotedLog & " ] && mv -f " & quotedLog & " " & quotedLog & ".1 || true"
    end try

    -- How to start MutInt again, for /update/'s Restart button. Core runs whatever this says
    -- and offers the button only where something said it; see mutint_update/restart.py.
    set relaunch to "/usr/bin/open " & quoted form of (POSIX path of (path to me))

    -- Backgrounded, because an applet cannot hold a child process the way a shell can -- which
    -- is the one thing given up by moving off the shell script, and what `deadman` below buys
    -- back. `echo $!` hands back the pid: the .command `exec`s the server, so that number stays
    -- the server's for its whole life.
    -- `launchCommand`, not `launch`: that is a Standard Additions command, and assigning to
    -- it compiles cleanly and then fails at runtime with "Can't set launch to ...", which is
    -- an error dialog on somebody's screen rather than anything a build would catch.
    set launchCommand to "MUTINT_LOG_FILE=" & quotedLog & " " & ¬
        "MUTINT_RELAUNCH_COMMAND=" & quoted form of relaunch & " " & ¬
        quoted form of (root & "/Start MutInt.command") & " >> " & quotedLog & " 2>&1 & echo $!"
    set serverPid to (do shell script launchCommand) as integer

    deadman(serverPid)
end startServer

-- **Force Quit is SIGKILL, so no handler runs**, and the server would go on serving with its
-- Dock icon gone -- the failure the old shell-script bundle could not have, because it *was*
-- the server. This watches the applet's own pid (`$PPID` from inside `do shell script` is the
-- applet) and stops the server when it goes, whatever took it.
on deadman(thePid)
    set appPid to do shell script "echo $PPID"
    do shell script "/bin/sh -c 'while kill -0 " & appPid & " 2>/dev/null; do sleep 1; done; " & ¬
        "kill -TERM " & thePid & " 2>/dev/null' >/dev/null 2>&1 &"
end deadman

-- SIGTERM and wait, because what it is waiting for is `atexit` stopping a PostgreSQL cluster
-- and a background worker. `continue quit` in the caller is what actually ends the app, so this
-- returning early would leave the server being stopped after its Dock icon had gone.
on stopServer()
    if serverPid is 0 then return
    try
        do shell script "kill -TERM " & serverPid
    on error
        return -- already gone
    end try
    repeat 60 times
        if not isRunning(serverPid) then return
        delay 0.5
    end repeat
    -- Past the bound it stops being polite. A MutInt that will not quit is worse than one
    -- stopped abruptly, and `./mutint start` adopts a cluster whose owner was killed outright.
    try
        do shell script "kill -KILL " & serverPid
    end try
end stopServer
