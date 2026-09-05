"""
URL configuration for the MutInt assembled project.
"""
from django.contrib.staticfiles.urls import staticfiles_urlpatterns
from django.urls import include, path, re_path
from django.conf import settings
from mutint_common.urls import get_core_urlpatterns

urlpatterns = get_core_urlpatterns() + [
    path('mutint/', include('mutint_app.urls')),
]

if settings.DEBUG:
    import debug_toolbar
    urlpatterns += [
        re_path(r'^__debug__/', include(debug_toolbar.urls)),
    ] + staticfiles_urlpatterns()
