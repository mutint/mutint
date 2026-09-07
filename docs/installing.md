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

## Cloning

The submodule URLs are **relative paths**, which git resolves against the parent's remote. That
keeps the assembly working without hardcoded hosts, and it means the clone has to sit where its
siblings can be found.

```bash
git clone --recurse-submodules https://github.com/mutint/mutint.git
cd mutint
```

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
  `./mutint start` in it.
- **`MutInt.app`** — the same launcher with an application's name and icon, so it can sit in
  the Dock. All it does is open the `.command` above in Terminal; the first time, macOS asks
  once for permission to control Terminal.

The Terminal window is the point rather than an artifact. A first launch spends several minutes
installing the venv and the external tools before Django is importable, and the admin
credentials are printed once — a launcher that hid that would make a slow success look like a
hang and a failure look like nothing. **Ctrl-C in that window stops the server**, and closing
the window will offer to.

Double-clicking again while MutInt is already running just opens the browser: the dev server
is fixed to port 8000, so a second one would only collide with the first.

!!! note "Both are plain text, and neither is signed"

    `MutInt.app` is a folder with an `Info.plist`, a shell script and an icon in it — there is
    no build step. The icon is a checked-in `Contents/Resources/MutInt.icns`, composed from the
    same SVGs in `staticfiles/img/mutint/` that the site's favicon comes from; `Info.plist`'s
    comment records how to rebuild it.

    Both rely on their executable bit, which git records. If Finder opens one in a text editor
    instead of running it, `chmod +x` is the fix.

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
