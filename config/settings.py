"""
Base settings for the MutInt assembled project.

Loads aledb-core defaults via importlib (to avoid the `config` namespace clash),
then adds each app submodule to sys.path and extends INSTALLED_APPS.
"""
import importlib.util
import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ── Path setup ────────────────────────────────────────────────────────────────
# Each submodule directory is appended (not inserted) so that `import config`
# continues to resolve to mutint/config/ (which manage.py inserted first).

_SUBMODULE_DIRS = [
    os.path.join(BASE_DIR, 'aledb-core'),
    os.path.join(BASE_DIR, 'mutint-app'),
    # Add further app submodule directories here, e.g.:
    # os.path.join(BASE_DIR, 'another-app'),
]
for _d in _SUBMODULE_DIRS:
    if _d not in sys.path:
        sys.path.append(_d)

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

# ── Assemble INSTALLED_APPS ───────────────────────────────────────────────────
# aledb-core apps are already in INSTALLED_APPS (inherited above).
# Add each additional app below.
INSTALLED_APPS = INSTALLED_APPS + [
    'mutint_app',
    # 'another_app',
]
