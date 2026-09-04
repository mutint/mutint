# MutInt

An assembled Django project combining [aledb-core](aledb-core/README.md) with the MutInt app
(`mutint_app`). Core ALEdb functionality is provided via the `aledb-core` git submodule;
`mutint-app` adds the MutInt-specific views and models.

---

## Cloning

```bash
git clone --recurse-submodules <repo-url>
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init
```

---

## Quick start

**Requirements:** Python 3.10+

```bash
./mutint start
```

On first run, `./mutint start` will automatically:
1. Create a Python virtual environment (`env/main/`)
2. Install all dependencies from submodule requirements files
3. Run database migrations (SQLite, no external database needed)
4. Create a default admin user (`admin` / `admin`)
5. Open your browser to `http://127.0.0.1:8000`

The admin interface is at `http://127.0.0.1:8000/admin/`. Change the default password immediately.

---

## Management commands

The `./mutint` script works like `./aledb` in aledb-core — no manual venv activation needed:

```bash
./mutint migrate
./mutint runserver
./mutint shell
./mutint createsuperuser
./mutint import /path/to/data --project P --experiment E --person alice
./mutint install                      # reinstall/update all dependencies
```

See [aledb-core/README.md](aledb-core/README.md) for data loading, environment variables,
and the full list of management commands.
