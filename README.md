# MutInt

An assembled Django project: [mutint-core](mutint-core/README.md) and a set of plugins, each
a git submodule, collected by the `config/` package here. MutInt has no app of its own.

---

## Installing

### The install script

```bash
curl -LO https://raw.githubusercontent.com/mutint/mutint/main/install.sh
sh install.sh
```

It clones MutInt with its components and starts it. If the machine has no `git`, it fetches
one for itself rather than asking you to install developer tools first.

Downloaded and then run, rather than piped straight into a shell, so you can read it before
it does anything.

**It installs the latest release**, not the tip of `main`. Name a version to get a different
one:

```bash
sh install.sh v0.0.1       # that release
sh install.sh main         # the development branch, and follow it thereafter
```

### Or clone it yourself

```bash
git clone --recurse-submodules --branch v0.0.1 https://github.com/mutint/mutint.git
```

Without `--branch` you get the tip of `main`, which is a development branch rather than a
release.

The `--recurse-submodules` is not optional -- without it the component directories are empty
and `config/settings.py` finds no apps to install. If you already cloned without it:

```bash
git submodule update --init
```

Either way you end up with a git checkout, which is what lets MutInt **upgrade itself in
place** later, keeping the data in `data/`.

---

## Quick start

**Requirements:** any `python3`, 3.9 or newer. That is the whole list -- the entry script
provisions its own Python 3.13, and everything else, into `env/`.

```bash
./mutint start
```

On first run, `./mutint start` will automatically:
1. Provision a pinned Python 3.13 and build a virtual environment (`env/main/`)
2. Install every component's `requirements.txt` into it
3. Install the external tools components ask for (`env/tools/`)
4. Provision PostgreSQL, start a cluster in `data/db/` and migrate it -- no external
   database to install or configure, and nothing listens on the network
5. Create a default admin user (`admin` / `admin`)
6. Open your browser to `http://127.0.0.1:8000`

Expect the first run to take several minutes; later ones start immediately.

The admin interface is at `http://127.0.0.1:8000/admin/`. Change the default password immediately.

---

## Upgrading

MutInt upgrades itself in place, keeping your data. Sign in as a superuser, click your
username in the sidebar, then **Upgrade** &mdash; it lists what is installed, checks for a
newer version, and stages it. Quit MutInt and start it again to apply it.

From a terminal:

```bash
./mutint upgrade --check    # what is available
./mutint upgrade            # move onto it, then run ./mutint start
```

See `docs/using/upgrading.md` (or `./mutint docs --serve`) for the two channels, the backup it
takes first, and what it refuses to do to a checkout somebody is working in.

---

## Management commands

The `./mutint` script works like `./mutint` in mutint-core — no manual venv activation needed:

```bash
./mutint migrate
./mutint runserver
./mutint shell
./mutint createsuperuser
./mutint import /path/to/data --project P --experiment E --person alice
./mutint install                      # reinstall/update all dependencies
```

See [mutint-core/README.md](mutint-core/README.md) for data loading, environment variables,
and the full list of management commands.
