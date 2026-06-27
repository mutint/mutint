"""
URL configuration for the MutInt assembled project.

Includes all aledb-core URL patterns plus each app's routes.
Keep the core section in sync with aledb-core/config/urls.py.
"""
from django.contrib.staticfiles.urls import staticfiles_urlpatterns
from django.urls import include, re_path, path
from django.conf import settings
from django.contrib import admin
from django.apps import apps as django_apps
from config.views import protected_file_serve

_auth_cfg = next(
    (cfg for cfg in django_apps.get_app_configs() if getattr(cfg, 'auth_app', False)),
    None,
)

# ── Core aledb patterns (mirrors aledb-core/config/urls.py) ──────────────────
urlpatterns = [
    re_path(r'^', include('aledb_home.urls')),
    re_path(r'^dashboard', include('aledb_dashboard.urls')),
    re_path(r'^admin/', admin.site.urls),
]

if _auth_cfg:
    urlpatterns += [re_path(r'^accounts/', include(f'{_auth_cfg.name}.urls', namespace='accounts'))]

urlpatterns += [
    re_path(r'^about', include('aledb_about.urls')),
    re_path(r'^ale/', include('aledb_experiment.urls')),
    re_path(r'^bibliome/', include('aledb_bibliome.urls')),
    re_path(r'^converge/', include('aledb_converge.urls')),
    re_path(r'^export', include('aledb_export.urls')),
    re_path(r'^filter/', include('aledb_filter.urls')),
    re_path(r'^fixation/', include('aledb_fixation.urls')),
    re_path(r'^interop-query/', include('aledb_interop_query.urls')),
    re_path(r'^metadata/', include('aledb_metadata.urls')),
    re_path(r'^mutations/', include('aledb_seq.urls')),
    re_path(r'^search/', include('aledb_search.urls')),
    re_path(r'^stats/', include('aledb_stats.urls')),
    re_path(r'^aledata/(?P<page_name>.*)$', protected_file_serve),
]

# ── Additional app patterns ───────────────────────────────────────────────────
urlpatterns += [
    path('mutint/', include('mutint_app.urls')),
    # path('another/', include('another_app.urls')),
]

if settings.DEBUG:
    import debug_toolbar
    urlpatterns += [
        re_path(r'^__debug__/', include(debug_toolbar.urls)),
    ] + staticfiles_urlpatterns()
