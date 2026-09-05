"""
Thin shim — re-exports mutint-core's config/views.py contents.
Required because `config.views` in urls.py resolves to this package.
"""
import importlib.util
import os

_spec = importlib.util.spec_from_file_location(
    '_mutint_core_views',
    os.path.join(os.path.dirname(os.path.dirname(__file__)), 'mutint-core', 'config', 'views.py'),
)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

protected_file_serve = _mod.protected_file_serve
show_amplifiction_data = _mod.show_amplifiction_data
