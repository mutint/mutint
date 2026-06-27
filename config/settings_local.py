"""Local development overrides — not committed to version control."""
from .settings import *  # noqa: F401, F403

DEBUG = True
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'mutint_local.sqlite3'),
    }
}
