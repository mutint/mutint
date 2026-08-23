"""
Base settings for the MutInt assembled project.

Loads aledb-core defaults via importlib (to avoid the `config` namespace clash),
then auto-discovers submodule directories from .gitmodules and extends
INSTALLED_APPS with any Django app packages found in those directories.

To add a new app submodule, add it to .gitmodules — no edits here needed.
"""
import configparser
import importlib.util
import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ── Auto-discover submodule directories from .gitmodules ──────────────────────
# Each submodule directory is appended (not inserted) so that `import config`
# continues to resolve to mutint/config/ (which manage.py inserted first).

_submodule_paths = []
_gitmodules = os.path.join(BASE_DIR, '.gitmodules')
if os.path.isfile(_gitmodules):
    _cfg = configparser.ConfigParser()
    _cfg.read(_gitmodules)
    for _section in _cfg.sections():
        _path = _cfg.get(_section, 'path', fallback=None)
        if _path:
            _full = os.path.join(BASE_DIR, _path)
            _submodule_paths.append(_full)
            if _full not in sys.path:
                sys.path.append(_full)

# ── Inherit aledb-core base settings ─────────────────────────────────────────
def _load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

_core_defaults = _load_module(
    '_aledb_core_defaults',
    os.path.join(BASE_DIR, 'aledb-core', 'config', 'defaults.py'),
)
globals().update({k: getattr(_core_defaults, k) for k in dir(_core_defaults) if k.isupper()})

# ── Reset settings that depend on project root ────────────────────────────────
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATIC_ROOT = os.path.join(BASE_DIR, 'static')

ROOT_URLCONF = 'config.urls'
WSGI_APPLICATION = 'config.wsgi.application'

# ── Auto-discover INSTALLED_APPS from submodule packages ─────────────────────
# Any immediate subdirectory of a submodule that is a Django app package
# (has __init__.py + apps.py) and is not already in INSTALLED_APPS is added.
# The aledb-core submodule is skipped entirely: all of its apps are provided by
# base settings above, and re-scanning it would pull in packages base settings
# deliberately omits (e.g. aledb_accounts alongside aledb_accounts_noauth).

_core_submodule = os.path.join(BASE_DIR, 'aledb-core')
_core_apps = set(INSTALLED_APPS)
for _subdir_path in _submodule_paths:
    if _subdir_path == _core_submodule:
        continue
    if not os.path.isdir(_subdir_path):
        continue
    for _name in sorted(os.listdir(_subdir_path)):
        _pkg = os.path.join(_subdir_path, _name)
        if (os.path.isdir(_pkg)
                and os.path.isfile(os.path.join(_pkg, '__init__.py'))
                and os.path.isfile(os.path.join(_pkg, 'apps.py'))
                and _name not in _core_apps):
            INSTALLED_APPS = INSTALLED_APPS + [_name]
            _core_apps.add(_name)


# ── MutInt's identity ─────────────────────────────────────────────────────────
# aledb-core is unbranded: without this the sidebar carries no name and `/` is the
# project list. MutInt is a collater and contributes no UI of its own, but it is
# still the thing you are looking at, so it names itself here. No logo and no
# home/splash.html, so there is no icon and `/` stays the project list.
from mutint_app.version import NAME as _MUTINT_NAME, __version__ as _MUTINT_VERSION  # noqa: E402

ALEDB_BRANDING = {
    'name': _MUTINT_NAME,
    'version': 'v%s' % _MUTINT_VERSION,
}
