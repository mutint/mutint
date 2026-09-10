# Installing MutInt

**MutInt is installed as a git checkout, and that is not incidental.** It upgrades itself in
place -- see [Upgrading](upgrading.md) -- and it can only do that from a repository it can
fetch into. There is no tarball, on purpose: unpacking one over an installation that already
holds data has no safe answer, since the database in `data/db` and the file store in
`data/store` live inside the directory you would be replacing.

Note also that GitHub's own **source archive of this repository will not work**. The components
are submodules, so the archive contains six *empty* directories, and `config/settings.py`
discovers `INSTALLED_APPS` by scanning them -- it would find nothing and fail in a way that
says nothing about submodules. (If you have already ended up in that state,
`./mutint upgrade --adopt` turns such a tree into a real checkout without touching your data.)

## The install script

```bash
curl -LO https://raw.githubusercontent.com/mutint/mutint/main/install.sh
sh install.sh
```

It clones MutInt with all of its components and runs `./mutint start`.

**It will fetch its own `git` if the machine has none.** The same micromamba the entry script
uses for Python, the external tools and PostgreSQL can install git too, so a machine without
developer tools is not turned away at the first step. That copy is temporary: `git` is in
mutint-core's `tools.txt`, so the checkout installs its own into `env/tools` on first run like
any other tool.

It is downloaded and then run, rather than piped into a shell, so you can read it first.

### Which version it installs

**The latest release, not the tip of `main`.** The script asks the remote for its `v*` tags
the same way [Upgrading](upgrading.md) does -- `git ls-remote`, no API and no token -- and
clones the highest one, leaving `HEAD` detached on it. Name a version to override that:

```bash
sh install.sh v0.0.1       # that release
sh install.sh main         # the development branch
```

`MUTINT_VERSION` does the same thing for a script being run non-interactively, beside the
`MUTINT_REPO` and `MUTINT_DIR` it already reads.

Asking for `main` also writes the `main` channel into `data/upgrade.json`, so the installation
goes on following the branch it was installed from. Without that it would sit on the default
`stable` channel and be offered the newest *release tag* -- which is behind the development
branch, so the offer would be a downgrade.

## Cloning

The submodule URLs are **relative paths**, which git resolves against the parent's remote. That
keeps the assembly working without hardcoded hosts, and it means the clone has to sit where its
siblings can be found.

```bash
git clone --recurse-submodules --branch v0.0.1 https://github.com/mutint/mutint.git
cd mutint
```

Without `--branch` a clone takes the tip of `main`, which is the development branch rather
than a release; `./mutint upgrade --check` would then offer you an older tag.

An existing clone that predates a submodule:

```bash
git submodule update --init --recursive
```

## First run

```bash
./mutint start
```

That installs a shared virtualenv at `env/main/` from every component's `requirements.txt`,
installs any non-Python tools declared in a `tools.txt` into `env/tools/`, migrates, creates an
admin user, opens a browser (via macOS `open`, so on Linux you go to the URL yourself) and runs
the server.

The entry script discovers submodules from `.gitmodules` and re-execs under the venv, so there
is nothing to activate.

## Starting it from the Finder

Two files in the checkout do the same thing without a terminal:

- **`Start MutInt.command`** — double-click it and macOS opens a Terminal window and runs
  `./mutint start` in it. The server runs *in* that window, so Ctrl-C stops it and closing the
  window will offer to.
- **`MutInt.app`** — the same launcher with an application's name and icon, so it can sit in
  the Dock. **The app is MutInt**, not a shortcut to it: it runs the server itself, its icon
  stays in the Dock for as long as MutInt is up, **Quit stops the server**, and clicking the
  icon while it is running opens the browser.

Both run the same script; the app just tells it there is no terminal to print to.

### The window the app opens is a log viewer

A first launch spends several minutes installing the venv and the external tools before Django
is importable, and the admin credentials are printed once — a launcher that hid all that would
make a slow success look like a hang and a failure look like nothing. So the app writes
everything to **`data/server.log`** and opens a Terminal window showing it as it is written.

That window is opened by handing the file `launcher/view-log.command` to Terminal, which asks
macOS to open a document and so needs no permission. Double-click that file yourself any time
to watch the log, whether or not MutInt started it for you.

That window holds nothing but `tail`, which is the whole point: **closing it does not stop
MutInt**. Quit the app to do that. The log is a file you can reopen later, or attach to a bug
report, and the previous run is kept beside it as `data/server.log.1`.

Clicking the icon again while MutInt is already running opens the browser rather than starting
a second server — the dev server is fixed to port 8000, so a second one would only collide with
the first. (macOS will not run two copies of an application anyway; the check is there because
the `.command` and the app can be used against each other.)

### Upgrading from the Dock

`/upgrade/` stages a new version, and the upgrade itself happens on the next launch, before
the server comes up — a running MutInt cannot safely replace its own code. Started from the
app, the page offers **Restart MutInt**, which is that launch: it stops the server, waits for
it to finish shutting down, and opens the app again. The page reloads itself when MutInt is
back.

Started from a terminal instead, there is no Restart button. Nothing there can start MutInt
again once it has been stopped — the shell that would do it is the one being killed — so the
page says to quit and start it again, which is the same two steps by hand.

### If macOS asks for the Command Line Tools

`./mutint` is a Python script, so *something* has to be a Python before the checkout has
installed its own — and on a Mac that has never had Xcode, `/usr/bin/python3` is not a Python
at all. It is a stub whose only job is to offer to install Apple's Command Line Tools.

MutInt checks for that before it starts and offers the installer in a dialog rather than
failing silently. It is a one-time cost: after MutInt has run once it has a Python of its own
in `env/python`, uses that from then on, and never asks again.

!!! note "How the app is built, and why it is not just a script"

    `MutInt.app` is an **AppleScript applet**, compiled from `launcher/MutInt.applescript` by
    `sh launcher/build.sh`. It was a plain shell script for a while, which was simpler and
    could not be quit: a bundle whose executable is a script has no way to answer the Quit
    event macOS sends it, so Force Quit was the only way to stop MutInt. An applet's runtime
    answers that event, and answers a click on the Dock icon too.

    Everything about *starting* MutInt is still `Start MutInt.command`, in plain shell. The
    applet holds the Dock tile, answers Quit and Reopen, and launches that script exactly as
    Finder would.

    The compiled bundle is committed, so a clone needs no build. `build.sh` regenerates it —
    `osacompile` ships with macOS, so unlike the rest of MutInt this needs no Python and no
    Command Line Tools. The icon master is `launcher/MutInt.icns`, composed from the same SVGs
    in `staticfiles/img/mutint/` the site's favicon comes from; `build.sh` records how to
    rebuild it and copies it in, since `osacompile` writes the bundle from scratch every time.

    It asks for no permissions. An earlier version opened its log window by telling Terminal,
    through AppleScript, to run a command — an Apple Event, so macOS asked *"MutInt wants to
    control Terminal"* on the first launch. That is an alarming question to put to somebody who
    double-clicked an icon, and refusing it left them with no window; opening a document with
    `open -a` does the same job through LaunchServices and asks nothing.

    Nothing is signed beyond an ad-hoc signature. A clone carries no quarantine attribute, so
    Gatekeeper lets it run; a copy downloaded through a browser would not be so lucky.

    `Start MutInt.command` relies on its executable bit, which git records. If Finder opens it
    in a text editor instead of running it, `chmod +x` is the fix.

## Everyday commands

```bash
./mutint check
./mutint test              # core's suite and every plugin's
./mutint test mutint_compare
./mutint migrate
./mutint shell
./mutint docs --serve      # this manual
```

`./mutint` inherits every mutint-core command — both entry scripts end at the same dispatcher —
plus any a plugin ships. `./mutint help` lists them.

## Updating a component

A submodule is pinned to a commit, so committing in a component does not change what MutInt
runs until the pointer moves:

```bash
git -c protocol.file.allow=always submodule update --remote mutint-core
git submodule status mutint-core        # the SHA must equal that repo's HEAD
./mutint check
git add mutint-core && git commit -m "chore: bump mutint-core"
```

!!! warning "Check the SHA, and never commit inside a submodule"

    `--remote` follows each submodule's `origin/HEAD`, which is not always the branch being
    developed — it has silently rolled a pointer backwards here.

    And the submodule directories are **detached-HEAD clones**. A commit made inside one is
    reachable only by SHA within that clone, and is discarded the next time the pointer moves.
    `cd mutint-core` from here lands in one, looks identical, and passes its tests. Check
    `git branch --show-current` before committing: an empty answer means the wrong checkout.
