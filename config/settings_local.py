"""Local development overrides."""
from .settings import *  # noqa: F401, F403

DEBUG = True

# **Nothing about the database belongs here any more.**
#
# This block used to name a SQLite file, because each project kept its own. There is nothing
# left to name: the entry script provisions a PostgreSQL cluster per checkout under env/ and
# exports MUTINT_DB_HOST/NAME/USER, and mutint-core's base settings read those -- with the name
# derived from the checkout's own directory, so the three projects differ by default even when
# pointed at one external server.
#
# It is worth knowing what this file used to get wrong, because the shape of the mistake
# outlives the setting. It once spelled out the whole DATABASES dict, silently overriding the
# engine and its options, so this project -- the one people actually import into -- ran a
# configuration mutint-core had moved on from. `check` passes either way; it took a test
# asserting the live connection to find it. That test still exists, in Postgres form.
