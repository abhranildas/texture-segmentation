# texture-segmentation

Code for the Geisler-lab texture discrimination & segmentation project — the
Hierarchical Bayesian Observer (HBO) model of texture segmentation, the human
psychophysics experiments that test it, and a twin-CNN comparison. This is the
foundational model that the sibling [texture-learning](../texture-learning) repo
(the "proximity" paper) builds on. See `notes/` for the paper and code docs.

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

- **[vision-commons](../vision-commons)** — the lab's shared MATLAB library (git
  submodule, or a sibling folder during local dev). Provides `vislib.*` (optics,
  filters, normalization, downsampling) and `nat_stat_bayes.*` (the decision-variable
  toolkit, incl. `dv_power`, `dv_spot_hist`, `dv_edge_hist`, `dv_spatial`).
- **[IntClassNorm](https://github.com/abhranildas/IntClassNorm)** and
  **[gx2](https://github.com/abhranildas/gx2)** — installed MATLAB **add-on toolboxes**
  (`classify_normals`, `quad2fun`). `setup.m` verifies/self-heals them; they are *not*
  bundled or fetched as source.
- **global_data** — the shared data store (natural images, texture sheets). Point
  `config.m` at it if it isn't a sibling folder.
- **Psychtoolbox-3** — required only to *run* the experiments (`+experiment`).
- MATLAB with the Image Processing and Statistics & Machine Learning toolboxes
  (and Deep Learning Toolbox for `cnn/`).

## Setup

```matlab
setup            % adds this repo + vision-commons to the path; self-heals the toolboxes
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
├── data/, exp_files/     analysis artifacts + human-subject experiment output
├── img_data/             derived patch sets (git-ignored where large)
└── notes/                paper + code documentation
```

Shared low-level code lives in `vision-commons` (not here), so it isn't duplicated
across the lab's repos.

## Status & caveats — reorganization in progress

This repo is mid-migration onto `vision-commons` (aligning it with the
texture-learning / camouflage_detection repos; see `../REORGANIZATION_PLAN.md`).

- **Done:** `setup.m` + `config.m` added (previously the repo relied on the ambient
  MATLAB path and hardcoded absolute paths); the verified-identical decision-variable
  and downsampling calls now use `vision-commons` (`dv_power`, `dv_spatial`,
  `vislib.downsample`).
- **Pending (see `CLEANUP.md`):** removing legacy duplicate trees
  (`Texture Discrimination Brodatz/Fabrics/`, `edgecode/`), resolving the two `+lib`
  name collisions with the lab-root `+lib`, fixing dangling references, and unifying
  the Psychtoolbox harness onto a shared `vision-commons/+psychexp` framework. Per
  request, none of that has been deleted yet — `CLEANUP.md` is the reviewed hit-list.

## Documentation

- `CLEANUP.md` — the full migration/cleanup checklist and old→new mapping.
- `../vision-commons/ARCHITECTURE.md` — how the repos, the shared library, the
  toolboxes, and `global_data` fit together.

## License

MIT License (see `LICENSE`).
