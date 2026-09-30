# What is inside it

MutInt installs mutint-core plus the plugins below. Each is a separate repository, pinned
here as a submodule, and each contributes its own pages to this manual — so the sections beside
this one are an inventory of what this deployment actually has.

| component | what it adds |
|---|---|
| **mutint-core** | the platform: experiments, samples, mutations, import, export, the genome browser |
| **mutint-compare** | the cross-sample mutation table at `/compare/`, with its Show menu of convergent and fixed mutations |
| **mutint-phylogeny** | a maximum-parsimony tree over an experiment's samples |
| **mutint-needle** | the needle plot, as a panel on the Overview |
| **mutint-breseq** | breseq runs on uploaded reads, queued for the background worker |
| **mutint-api** | the public read API at `/api/`, for another MutInt to pull public data from |
| **mutint-isescan** | ISEScan on the reference genome, merging the IS elements it predicts into the annotation |
| **mutint-refsniff** | identifying the reference genome from a sample of reads, before an experiment has one |
| **mutint-fastqc** | FastQC reports on the reads a breseq run is made from, linked from each sample |
| **mutint-specificity** | the Specificity page: whether evolution was specific to each treatment |

`/about` in a running instance is the live version of this table: it reports every installed
component with its version and git revision, so it is accurate for *your* checkout in a way
this page cannot be.

## Adding one

```bash
git -c protocol.file.allow=always submodule add ../mutint-yourthing mutint-yourthing
git add -A && git commit -m "feat: add mutint-yourthing submodule"
```

That is the whole installation — no edit to `config/settings.py` or `config/urls.py`. The app
is discovered, its URLs arrive through the plugin registry, its sidebar entry through the nav
registry, and its documentation through this manual.

A plugin's position in the sidebar, in rebuild order, and in this manual all follow its
position in `.gitmodules`, because that determines `INSTALLED_APPS` order.

Writing one is documented under **Extending MutInt**.
