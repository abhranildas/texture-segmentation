# texture-segmentation

Code for the Geisler-lab texture discrimination & segmentation project — the
Hierarchical Bayesian Observer (HBO) model of texture segmentation, the human
psychophysics experiments that test it, and a twin-CNN comparison. This is the
foundational model that the sibling [texture-learning](https://github.com/Bill-Geisler/texture-learning)
repo (the "proximity" paper) builds on. See the
[bioRxiv paper](https://www.biorxiv.org/content/10.64898/2026.05.06.723304v1.abstract) and `notes/`
for details.

## What's here

- **Bayesian decision-variable model** — power / colour-histogram / edge / spatial
  decision variables between texture patches, combined into same-vs-different and
  grouping decisions (`+lib`, root DV helpers, `edgecode/`).
- **Human experiments (Psychtoolbox)** — discrimination and grouping tasks with
  session/level/trial structure and per-subject output (`+experiment`, `exp_files/`).
- **Grouping / segmentation** — grow texture-region stimuli and segment them
  (`+grouping`).
- **Twin/Siamese CNN** — a learned baseline trained on Brodatz / natural patches
  (`cnn/`), with patch-pair generators in `+general`.
- **Analysis** — psychometric fitting and statistics (`+general`, `+stats`).

## Dependencies

- **[vislab-common](https://github.com/abhranildas/vislab-common)** — the lab's shared MATLAB library
  (the `+vislab` package inside the sibling `vislab-common` folder; `setup.m` clones it automatically if
  it's missing). Provides `vislab.lib.*` (optics, filters, normalization, downsampling) and
  `vislab.nat_stat_bayes.*` (the decision-variable toolkit, incl. `dv_power`, `dv_spot_hist`, `dv_edge_hist`, `dv_spatial`).
- **[IntClassNorm](https://github.com/abhranildas/IntClassNorm)** and
  **[gx2](https://github.com/abhranildas/gx2)** — installed MATLAB **add-on toolboxes**
  (`classify_normals`, `quad2fun`). `setup.m` verifies/self-heals them; they are *not*
  bundled or fetched as source.
- **vislab-common/data** — the shared data store, a sibling folder alongside this repo. Its texture sheets
  and colour transforms ship inside the `vislab-common` repo (so the auto-clone brings them along); only the
  large calibrated **natural-image** set (~19 GB) is **too large for GitHub** and must be obtained separately
  (`setup.m` warns if the store is missing; edit `cfg.paths.data_root` if it's elsewhere).
- **Psychtoolbox-3** — required only to *run* the experiments (`+experiment`).
- MATLAB with the Image Processing and Statistics & Machine Learning toolboxes
  (and Deep Learning Toolbox for `cnn/`).

## Setup

```matlab
setup            % adds this repo + vislab to the path; self-heals the toolboxes
cfg = config;    % data paths + shared constants; edit cfg.paths.data_root if needed
```

## Repository layout

```
texture-segmentation/
├── setup.m, config.m     path bootstrap + central configuration
├── +experiment/          Psychtoolbox experiments (discrimination, grouping) + analysis
├── +grouping/            texture-region stimulus generation + segmentation
├── +general/             patch-pair generators, simulations, analysis scripts
├── +stats/               natural-scene statistics infrastructure
├── +lib/                 repo-specific helpers (texture_patch, find_nat_patch, ...)
├── cnn/                  twin/Siamese network baseline
├── data/                 stimuli/ (derived patch sets, git-ignored where large) + model/ (analysis artifacts)
├── exp_files/            human-subject experiment output
└── notes/                paper + code documentation
```

Shared low-level code lives in `vislab` (not here), so it isn't duplicated
across the lab's repos.

## Status & caveats — reorganization in progress

This repo is mid-migration onto `vislab` (aligning it with the
texture-learning / camouflage_detection repos; see `../REORGANIZATION_PLAN.md`).

- **Done:** `setup.m` + `config.m` added (previously the repo relied on the ambient
  MATLAB path and hardcoded absolute paths); the verified-identical decision-variable
  and downsampling calls now use `vislab` (`dv_power`, `dv_spatial`,
  `vislab.lib.downsample`); the Psychtoolbox harness unified onto the shared
  `vislab/+psychframework`; the legacy duplicate trees
  (`Texture Discrimination Brodatz/Fabrics/`) removed; and the repo made **self-contained** —
  its `+lib` now holds everything it needs (the few remaining lab-root functions were copied
  in, `otf_filter` repointed to `vislab.lib.otf_filter`), so it no longer depends on the shared
  lab-root `+lib`.
- **Pending (see `CLEANUP.md`):** removing `edgecode/` and `.asv` autosaves, fixing the
  pre-existing dangling references (`edge_contour_props`, bare `Rp`/`Rh`), and the stale
  hardcoded `addpath` in the legacy `nat_near_far_patches_bayes.m`. Per request, those are
  flagged in `CLEANUP.md` rather than deleted.

## Documentation

- `CLEANUP.md` — the full migration/cleanup checklist and old→new mapping.
- `../vislab/ARCHITECTURE.md` — how the repos, the shared library, the
  toolboxes, and `vislab-common/data` fit together.

## License

MIT License (see `LICENSE`).
