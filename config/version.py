"""MutInt's own name and version, for the sidebar.

MutInt is the assembled project and has no Django app of its own -- it used to have one,
`mutint-app`, whose only real job was to carry these two values, and which is the example
plugin `mutint-example` now. So they live here, in the one package the project does own.
`./mutint version` reports the components; this is the assembly's own number, bumped by hand.
"""

NAME = "MutInt"

__version__ = "0.0.1"
