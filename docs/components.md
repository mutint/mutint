# What is inside it

MutInt installs aledb-core plus four analysis plugins. Each is a separate repository, pinned
here as a submodule, and each contributes its own pages to this manual — so the sections beside
this one are an inventory of what this deployment actually has.

| component | what it adds |
|---|---|
| **aledb-core** | the platform: experiments, samples, mutations, import, export, the genome browser |
| **aledb-compare** | the cross-sample mutation table at `/compare/` |
| **aledb-fixation** | mutations that have fixed in a lineage, at `/fixation` |
| **aledb-converge** | genes hit independently in more than one lineage, at `/converge` |
| **aledb-phylogeny** | a maximum-parsimony tree over an experiment's samples |
| **mutint-app** | MutInt's own app — no UI, by design |

`/about` in a running instance is the live version of this table: it reports every installed
component with its version and git revision, so it is accurate for *your* checkout in a way
this page cannot be.

## Adding one

```bash
git -c protocol.file.allow=always submodule add ../aledb-yourthing aledb-yourthing
git add -A && git commit -m "feat: add aledb-yourthing submodule"
```

That is the whole installation — no edit to `config/settings.py` or `config/urls.py`. The app
is discovered, its URLs arrive through the plugin registry, its sidebar entry through the nav
registry, and its documentation through this manual.

A plugin's position in the sidebar, in rebuild order, and in this manual all follow its
position in `.gitmodules`, because that determines `INSTALLED_APPS` order.

Writing one is documented under **Extending ALEdb**.
