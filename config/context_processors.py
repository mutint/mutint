"""
Required by mutint-core's TEMPLATES config.
`config.context_processors` resolves here at runtime because mutint/ is first
on sys.path.
"""
from django.conf import settings


def global_settings(request):
    return {
        'GOOGLE_ANALYTICS_TAG': settings.GOOGLE_ANALYTICS_TAG,
    }
