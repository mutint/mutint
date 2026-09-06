"""
URL configuration for the MutInt assembled project.
"""
from django.contrib.staticfiles.urls import staticfiles_urlpatterns
from django.conf import settings
from mutint_common.urls import get_core_urlpatterns

# Core's routes and every installed plugin's, through the plugin registry. MutInt adds none
# of its own.
urlpatterns = get_core_urlpatterns()

if settings.DEBUG:
    urlpatterns += staticfiles_urlpatterns()
