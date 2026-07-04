# CLEANUP.md — texture-segmentation

Tracked removals/reconciliations for the vision-commons migration. Per the user's
directive, nothing here has been **deleted** — this file *flags* everything for a
later batch review/approval (like the texture-learning legacy-file removal). Items
marked **DONE** were already applied (they were purely additive or verified-safe).

Verified equivalences were checked headlessly in MATLAB R2024b against the live code.

---

## 1. Legacy duplicate code trees — DELETE after confirming superseded
- `Texture Discrimination Brodatz/` and `Texture Discrimination Fabrics/` — full older,
  self-contained copies of the DV/discrimination code (`Rp.m`, `Rh.m`, `Re.m`, `Rs.m`,
  `otf.m`, `aply_otf.m`, `ptch_norm.m`, `mk_bins.m`, `mk_win.m`, …, plus `_old`/`_old2`/
  `_old3` script variants and `.asv` autosaves) **and** raw Brodatz `B*.gif` / Fabric
  `F*.png` sheets. The texture sheets now live in `global_data/textures/{brodatz,fabric}`;
  the DV code is superseded by `vision-commons` + this repo's `+lib`/root helpers.
  → Recommend deleting both trees wholesale.
- `.asv` MATLAB autosave files (not source): `+experiment/+discriminate/+prep/generate_stimuli.asv`,
  `+experiment/+grouping/+run/runExperiment.asv`, `+grouping/chktlst.asv`, and several inside
  the two legacy trees. → Delete all `.asv`.

## 2. DV / optics reconciliation onto vision-commons

| local call | commons counterpart | status | action |
|---|---|---|---|
| `lib.power_dv(a,b,β)` | `nat_stat_bayes.dv_power(a,b,β,size(a,1))` | **identical** (diff 8.7e-18) | **DONE** — repointed all 4 live calls (`+general/simulate_discrimination.m`). `+lib/power_dv.m` is now dead → delete. |
| `lib.downsample(img,L)` | `vislib.downsample(img,L)` | **identical** for 2-D (diff 0); local's `filter`/`ppd`/… params were dead | **DONE** — repointed live calls (`cnn/getTwinBatch.m`, `+general/nat_near_far_patches_cnn.m`). `+lib/downsample.m` dead → delete. `+lib/downsample_old.m` is **broken** (calls a missing `aply_otf`) → delete. |
| `Rs(a,b,psz)` (root `Rs.m`, `edgecode/Rs.m`) | `nat_stat_bayes.dv_spatial(a,b,psz)` | **identical** (diff 3.5e-15), promoted to commons | repoint `Rs` users, then delete the copies. |
| `lib.hist_dv(a,b,edges)` | — (none; `dv_spot_hist` is a *different*, multi-feature colour-histogram DV) | **not equivalent** | keep `+lib/hist_dv.m` local, OR add a grayscale-histogram DV to commons. Decide with Geisler. |
| `lib.otf_filter(img,ppd,…)` (root `+lib`) | `vislib.otf_filter` | ported; the **root version errors on a 3-channel input** (old bug) | verify `vislib.otf_filter` against real images, then repoint `lib.otf_filter`→`vislib.otf_filter` (deferred — not done, to avoid an unverified behaviour change). |
| `lib.texture_patch`, `lib.find_nat_patch`, `lib.compute_pClipped`, `lib.monitorDegreesToPixels`, `lib.gammaCorrect` | — | repo-specific / utilities | keep local, but move out of `+lib` to resolve the collision (see §3). |

## 3. `+lib` name collisions (lab-root `+lib` vs this repo's `+lib`)
Both merge into the `lib.*` namespace when both are on the path. `setup.m` currently makes
**this repo's `+lib` win** (added last) so behaviour is deterministic, but two names differ:
- `compute_pClipped` — local adds a `>1%` clipping **warning** branch the root lacks.
- `monitorDegreesToPixels` — root handles a **3-D** position array; local does not. Verify no
  caller passes a 3-D array to the local version.

**Proper fix:** rename this repo's *unique* `+lib` code (`texture_patch`, `find_nat_patch`,
`compute_pClipped`, `monitorDegreesToPixels`, `gammaCorrect`, `hist_dv`) into a domain package
(e.g. `+texseg`), update call sites, then drop the root-`+lib` dependency and remove the
`root_parent` `addpath` from `setup.m`. (`monitorDegreesToPixels`/`gammaCorrect` are display-side
utilities → candidates for the shared `+psychexp` framework instead.)

## 4. Dangling references (currently BROKEN — fix or remove)
- `edge_dv.m` calls `lib.edge_contour_props`, which exists nowhere. (Its logic overlaps the
  inline contour tracing in root `Re.m` + `mk_contour.m`.)
- `texture_grouping.m` and `Rs_new.m` call bare `Rp(...)`/`Rh(...)` — no `Rp.m`/`Rh.m` exists at
  the repo root (only `Rp_win.m`, whose function is named `Rp`, and `lib.power_dv`/`lib.hist_dv`).

## 5. Stale hardcoded absolute paths
- `+general/nat_near_far_patches_bayes.m:9-12` — two `addpath('C:\Users\Bill Geisler\…')`. Replace
  with `config.paths` (the `CPS natural images` set is now `cfg.paths.natural_images`).

## 6. `edgecode/` (standalone legacy)
- A 4th copy of `Rp/Rh/Re/Rs` (+ `mk_contour.m`, and `texture_discrimination.m` which references a
  missing `mk_win.m`). `Rs` is now `nat_stat_bayes.dv_spatial`; fold `Rp/Rh/Re` onto
  `nat_stat_bayes.{dv_power,dv_spot_hist,dv_edge_hist}` or delete the tree.

## 7. Experiment harness → `vision-commons/+psychexp` (separate pass, needs PTB testing)
- `+experiment` duplicates its whole harness across `+discriminate` and `+grouping`. There is a
  latent bug: `+grouping/+run/runTrial.m` and `runLevel.m` call `experiment.run.*` (not
  `experiment.grouping.run.*`), so the duplicated packages may not even resolve as-is.
- **DONE:** `vision-commons/+psychexp` (shared session→level→trial loop) added; `runExperiment.m` for
  BOTH the `+grouping` and `+discriminate` experiments now delegates the loop/screen to it, wiring each
  task's interval functions as hooks. The superseded `runLevel.m`/`runTrial.m` in both `+run` packages
  were **deleted** (commit `de7cb3148`), fixing the grouping harness's latent `experiment.run.*` namespace
  bug. Parse-verified; not headless-testable (Psychtoolbox) — PTB validation waived by the user.
- The `+discriminate` and `+grouping` **interval functions** are still near-duplicates of each other
  (fixation/response/feedback/displayLevelStart are effectively identical; only `stimulusInterval` differs
  trivially). They could be merged into one shared set parameterized by task — optional further dedup.

## 8. `img_data/` (~95k derived files)
- `img_data/brodatz/patches/{train,test}` and `img_data/nat/patches/{same,diff}` are **derived**
  artifacts (regenerable from `global_data` via `+general/nat_near_far_patches_cnn.m` and the
  Brodatz patch cutter). Consider moving to `global_data` as a documented derived cache, or
  gitignoring them and regenerating on demand.
