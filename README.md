# texture-segmentation

Code for **"Principles of local and global grouping that underlie segmentation of natural texture images"**
(W. S. Geisler & A. Das, [bioRxiv 2026](https://www.biorxiv.org/content/10.64898/2026.05.06.723304v1.abstract)) —
the Bayesian model, the human psychophysics that tests it, and the texture-region stimuli both
are run on.

## What it does

Given two patches of an image, is it the *same* texture or a *different* one? This repo builds a
**Hierarchical Bayesian Observer (HBO)**: each low-level image statistic — the Fourier power
spectrum, the gray-level histogram, the distribution of oriented edges, the energy along the
border between the patches — contributes a log-likelihood ratio, and those *decision variables*
are combined into one same/different judgement. Applying that judgement to every pair of patches
in an image, and then grouping the patches that agree, **segments** the image into texture regions.

The same repo holds the **Psychtoolbox experiments** that measure human observers on exactly these
tasks (discrimination of patch pairs, and grouping of patches in a texture-region image), so model
and human can be compared on the same stimuli.

The sibling [texture-learning](https://github.com/Bill-Geisler/texture-learning) repo
([proximity paper](https://www.biorxiv.org/content/10.64898/2026.05.12.724620v1.abstract)) builds
on this model, showing it can be *trained* from unlabelled natural images by using spatial
proximity as a ground-truth proxy. The learned twin/Siamese-network comparison lives there too.

## Dependencies

- **[vislab-common](https://github.com/abhranildas/vislab-common)** — the lab's shared MATLAB library
  (the `+vislab` package inside the sibling `vislab-common` folder; `setup.m` clones it automatically if
  it's missing). Provides `vislab.lib.*` (optics, filters, normalization, downsampling),
  `vislab.nat_stat_bayes.*` (the decision-variable toolkit) and `vislab.psychframework.*` (the shared
  Psychtoolbox experiment harness).
- **[IntClassNorm](https://www.mathworks.com/matlabcentral/fileexchange/84973-integrate-and-classify-normal-distributions)** and
  **[gx2](https://www.mathworks.com/matlabcentral/fileexchange/85028-generalized-chi-square-distribution)** —
  MATLAB **add-on toolboxes** (`classify_normals`, `quad2fun`, `gx2*`). If either is missing, `setup.m`
  downloads the `.mltbx` from its latest GitHub release and installs it automatically (needs network);
  if that fails it opens the File Exchange page and warns.
- **vislab-common/data** — the shared data store, a sibling folder alongside this repo. Its **texture
  sheets** (Brodatz, Fabric, Pertex, VisTex, …) and colour transforms ship inside the `vislab-common`
  repo, so `setup.m`'s auto-clone brings them along, and that is all the model and the demo need. Only
  the large calibrated **natural-image** set (~19 GB), used by the `+general` analyses, is too large for
  GitHub and must be obtained separately. `setup.m` warns if the store is missing; edit
  `cfg.paths.data_root` if you keep it elsewhere.
- **[Psychtoolbox-3](http://psychtoolbox.org/)** — required only to *run* the human experiments
  (`+experiment`). Nothing else in the repo needs it.
- MATLAB with the Image Processing and Statistics & Machine Learning toolboxes.

## Installation and setup

- Download or git clone this repository to your local machine.
- Install git (so that the `setup` script can automatically git clone the `vislab-common` dependency).
- Within MATLAB, navigate to the repo folder and run:

```matlab
setup            % adds this repo + vislab to the path; auto-installs the gx2/IntClassNorm toolboxes if missing
cfg = config;    % data paths + shared constants; edit cfg.paths.data_root if vislab-common/data isn't a sibling
```

`setup` only changes the path for the current session, so re-run it in every new MATLAB session. It is
safe to re-run: every step is a no-op once the thing it provides already resolves.

## Quick demo

`run_demo.m` is a short, self-contained tour of the model. It takes no arguments, asks no questions,
runs in a few seconds, and needs **no large downloads** — everything it uses comes from the Brodatz
texture sheets inside `vislab-common`, which `setup` clones for you.

```matlab
run_demo      % four figures and a printed summary
```

It walks through four things:

1. **Texture patches.** Pairs of 64×64 Brodatz patches drawn by `lib.texture_patch` — some pairs from
   the same sheet, some from two different sheets.
2. **Decision variables.** Two of the model's same/different decision variables, `lib.power_dv` (Fourier
   power spectrum) and `lib.hist_dv` (gray-level histogram log-likelihood ratio), scored on those pairs.
   It prints each one's mean for same- and different-texture pairs plus the area under the ROC curve, and
   plots the two distributions — so you can see the model actually discriminating.
3. **A grouping stimulus.** A patch grid grown into contiguous texture regions with `grouping.mk_masks`,
   textured by `grouping.mk_texs`, and filled patch by patch: the ground-truth region map next to the
   image a subject (or the model) actually sees.
4. **Pair binning.** The distance / eccentricity geometry the grouping experiment pools its patch pairs
   into (`grouping.mk_dist`, `mk_mecc`, `mk_decc`, `mk_bindex`, `find_bin`), shown around one reference
   patch.

The demo is fully reproducible: every draw is made under `rng(cfg.seed)` and every patch is given an
explicit seed, so repeated runs give identical numbers and identical images. It deliberately does *not*
launch the Psychtoolbox experiments (those need a live display and a subject) or the natural-image
analyses (those need the ~19 GB image set).

## Repository layout

```
texture-segmentation/
├── setup.m, config.m     path bootstrap + central configuration
├── run_demo.m            the quick demo above
├── +lib/                 decision variables and patch tools (power_dv, hist_dv,
│                           edge_props_stim, steerable_grad/filter, texture_patch, ...)
├── +grouping/            texture-region stimulus generation + grouping geometry
├── +experiment/          Psychtoolbox experiments: +discriminate and +grouping,
│                           each with +prep (session setup) and +run (trial loop)
├── +general/             patch-pair generators, simulations, analysis scripts
│                           (these are the parts that need the natural-image set)
├── data/                 model/ (fitted discrimination boundaries)
│                           + stimuli/ (derived patch sets, git-ignored where large)
├── exp_files/            human-subject experiment settings and output
├── docs/                 repo-cleanup.md — the cleanup/refactor plan and bug register
├── notes/                papers, posters, and talk slides for the project
└── tools/                repo-maintenance checks (style check, golden-output harness)
```

A handful of older analysis scripts also sit at the root (`re.m`, `rp.m`, `rs.m`, `edge_dv.m`,
`mk_win.m`, `mk_contour.m`, `thresh.m`, `nlsame.m`, `texture_grouping.m`).

Shared low-level code lives in `vislab` (not here), so it isn't duplicated across the lab's repos.

## Known issues

The repo is mid-way through a documented cleanup (`docs/repo-cleanup.md`, section 0.4 is the full bug
register). Two things a new user will notice:

- **The Psychtoolbox experiments do not currently launch.** Both `+experiment` trees read an
  `exp_settings.monitorSizePix` field that nothing in the repo ever assigns (bug B2.10), and the
  `+grouping` tree has several further gaps behind it (B2.8, B2.9, B2.11). The stimulus generation and
  analysis code around them is fine; it is the session-setup plumbing that is incomplete.
- **Several higher-level `+grouping` stimulus scripts are broken as written** — `mk_texseg_stim_points`,
  `mk_texseg_stim_shape`, `tex_regions`, `demo_mk_trl_points`, `s_gtr_img` (bugs B2.5–B2.7, B3.11).
  Most call their own package's helpers unqualified (`mk_texs(...)` instead of `grouping.mk_texs(...)`),
  which does not resolve. The **low-level** `+grouping` helpers they build on are verified working and
  covered by the golden-output harness in `tools/` — `run_demo.m` composes a texture-region stimulus out
  of them directly.

Everything the quick demo touches runs.

## Documentation

- `docs/repo-cleanup.md` — the cleanup plan: conventions, the stage-by-stage log, and the register of
  known bugs and structural issues.
- `../vislab-common/ARCHITECTURE.md` — how the repos, the shared library, the add-on toolboxes and
  `vislab-common/data` fit together.
- `notes/` — the papers, posters and slides behind the project.

## License & citation

Code released under the MIT License (see `LICENSE`). If you use it, please cite the paper above
(`CITATION.cff`).
