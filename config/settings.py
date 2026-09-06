"""
Base settings for the MutInt assembled project.

Inherits mutint-core's base settings by calling get_base_settings() directly, then
auto-discovers submodule directories from .gitmodules and extends INSTALLED_APPS with
any Django app packages found in those directories.

To add a new app submodule, add it to .gitmodules — no edits here needed.
"""
import configparser
import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Named once: it is both what base settings need in order to find mutint_common's static
# assets, and the one submodule the INSTALLED_APPS scan below skips.
_core_submodule = os.path.join(BASE_DIR, 'mutint-core')

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

# ── Inherit mutint-core base settings ─────────────────────────────────────────
# Called directly, rather than through mutint-core's config/defaults.py, which is how this
# read before. That module passes *its own* directory as base_dir, so every setting derived
# from the project root -- STATIC_ROOT, TEMPLATES' DIRS, STATICFILES_DIRS and MUTINT_STORE_DIR
# -- came back pointing inside the submodule and had to be re-pointed by hand afterwards.
# Three of those four re-pointings had been missed at least once across the two assembled
# projects, and one of the misses put uploaded .gd files, BAMs and references somewhere
# `submodule update` is entitled to churn. Passing BASE_DIR makes all four right by
# construction, which is why nothing is re-pointed further down any more.
#
# Nothing is lost by skipping defaults.py: all it adds on top of get_base_settings() is
# ROOT_URLCONF and WSGI_APPLICATION, and this project sets both itself. It must be imported
# after the loop above, which is what puts mutint-core on sys.path.
from mutint_common.base_settings import get_base_settings  # noqa: E402

globals().update(get_base_settings(BASE_DIR, mutint_core_dir=_core_submodule))

ROOT_URLCONF = 'config.urls'
WSGI_APPLICATION = 'config.wsgi.application'

# ── Auto-discover INSTALLED_APPS from submodule packages ─────────────────────
# Any immediate subdirectory of a submodule that is a Django app package
# (has __init__.py + apps.py) and is not already in INSTALLED_APPS is added.
# The mutint-core submodule is skipped entirely: all of its apps are provided by
# base settings above, and re-scanning it would pull in packages base settings
# deliberately omits (e.g. mutint_accounts alongside mutint_accounts_noauth).

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
# mutint-core is unbranded: without this the sidebar carries no name and `/` is the
# project list. MutInt is a collater and contributes no UI of its own, but it is
# still the thing you are looking at, so it names itself here -- from its own
# config/version.py, since it has no app of its own. No logo and no
# home/splash.html, so there is no icon and `/` stays the project list.
from config.version import NAME as _MUTINT_NAME, __version__ as _MUTINT_VERSION  # noqa: E402

MUTINT_BRANDING = {
    'name': _MUTINT_NAME,
    'version': 'v%s' % _MUTINT_VERSION,
}
