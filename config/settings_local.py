"""Local development overrides."""
from .settings import *  # noqa: F401, F403

DEBUG = True

# Only the file name. **Do not restate ENGINE or OPTIONS here.**
#
# This block used to spell out `'ENGINE': 'django.db.backends.sqlite3'` and no OPTIONS,
# which silently overrode both. The effect was that this project -- the one people
# actually import into -- ran on the stock backend with a 5s busy timeout while
# aledb-core had moved to `aledb_common.db.sqlite_immediate` and 30s, so it did not
# get the fix for imports losing samples to `database is locked` at all. Nothing
# reported that; `./mutint check` cannot see it, and it took a test asserting the
# engine to find it.
#
# Overriding one key of the inherited dict is what keeps this from happening again:
# whatever aledb-core decides the backend should be, this follows.
DATABASES['default']['NAME'] = os.path.join(BASE_DIR, 'mutint_local.sqlite3')  # noqa: F405
