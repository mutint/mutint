# MutInt

MutInt is an **assembled project**: it collects aledb-core and a set of plugins into one
runnable Django application. It is the reference assembly, and the one the ALEdb suite is
developed against.

## It deliberately adds nothing

Worth stating plainly, because the absence looks like an oversight and is not.

MutInt exists to *collate*. It contributes no features and no pages of its own — its
`mutint_app` registers no sidebar entry, so the sidebar you see is entirely aledb-core's plus
the plugins'. When something needs to appear in MutInt's UI, the question is which core app or
plugin should own it, never whether `mutint_app` should grow an entry.

So this section of the manual is short by design. Everything you actually do with MutInt is
under **Using ALEdb**, and everything about writing code for it under **Extending ALEdb** —
both contributed by the components listed in [what is inside it](components.md).

## Where things live

```
mutint/
├── config/          settings and URLs for this assembly
├── mutint-app/      MutInt's own Django app
├── aledb-core/      the platform
├── aledb-compare/   ┐
├── aledb-fixation/  ├─ plugins, each its own repository
├── aledb-converge/  │
├── aledb-phylogeny/ ┘
└── mutint           the entry script
```

Each is a git submodule pinned to a commit. Nothing in `config/` names a plugin: settings read
`.gitmodules`, put each submodule directory on `sys.path`, and discover installed apps by
scanning for packages that have both `__init__.py` and `apps.py`.
