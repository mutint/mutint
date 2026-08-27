# Installing MutInt

## Cloning

The submodule URLs are **relative paths**, which git resolves against the parent's remote. That
keeps the assembly working without hardcoded hosts, and it means the clone has to sit where its
siblings can be found.

```bash
git clone --recurse-submodules <mutint-url>
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
admin user, opens a browser and runs the server.

The entry script discovers submodules from `.gitmodules` and re-execs under the venv, so there
is nothing to activate.

## Everyday commands

```bash
./mutint check
./mutint test              # core's suite and every plugin's
./mutint test aledb_compare
./mutint migrate
./mutint shell
./mutint docs --serve      # this manual
```

`./mutint` inherits every aledb-core command — both entry scripts end at the same dispatcher —
plus any a plugin ships. `./mutint help` lists them.

## Updating a component

A submodule is pinned to a commit, so committing in a component does not change what MutInt
runs until the pointer moves:

```bash
git -c protocol.file.allow=always submodule update --remote aledb-core
git submodule status aledb-core        # the SHA must equal that repo's HEAD
./mutint check
git add aledb-core && git commit -m "chore: bump aledb-core"
```

!!! warning "Check the SHA, and never commit inside a submodule"

    `--remote` follows each submodule's `origin/HEAD`, which is not always the branch being
    developed — it has silently rolled a pointer backwards here.

    And the submodule directories are **detached-HEAD clones**. A commit made inside one is
    reachable only by SHA within that clone, and is discarded the next time the pointer moves.
    `cd aledb-core` from here lands in one, looks identical, and passes its tests. Check
    `git branch --show-current` before committing: an empty answer means the wrong checkout.
