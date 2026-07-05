# CLEANUP.md — texture-segmentation

Tracked removals/reconciliations for the vislab migration. Per the user's
directive, nothing here has been **deleted** — this file *flags* everything for a
later batch review/approval (like the texture-learning legacy-file removal). Items
marked **DONE** were already applied (they were purely additive or verified-safe).

Verified equivalences were checked headlessly in MATLAB R2024b against the live code.

---

## 1. Legacy duplicate code trees
- **DONE (2026-07-05, commit `5e65ec79d`):** deleted `Texture Discrimination Brodatz/` and
  `Texture Discrimination Fabrics/` wholesale (~335 MB, 510 files) — full self-contained legacy copies
  of the DV/discrimination code (`Rp`/`Rh`/`Re`/`Rs`/`otf`/`aply_otf`/`ptch_norm`/`mk_bins`/… + `_old*`
  variants + `.asv`), raw Brodatz `B*.gif` / Fabric `F*.png` sheets, old `.mat`, and `Results_*.xlsx`.
  Verified nothing in the modern repo referenced them (no code path; not on the MATLAB path); the texture
  sheets live in `vislab-common/data/textures/{brodatz,fabric}`. Recoverable from git history.
- `.asv` MATLAB autosave files (not source): `+experiment/+discriminate/+prep/generate_stimuli.asv`,
  `+experiment/+grouping/+run/runExperiment.asv`, `+grouping/chktlst.asv`, and several inside
  the two legacy trees. → Delete all `.asv`.

## 2. DV / optics reconciliation onto vislab

| local call | commons counterpart | status | action |
|---|---|---|---|
| `lib.power_dv(a,b,β)` | `vislab.nat_stat_bayes.dv_power(a,b,β,size(a,1))` | **identical** (diff 8.7e-18) | **DONE** — repointed all 4 live calls (`+general/simulate_discrimination.m`). `+lib/power_dv.m` is now dead → delete. |
| `lib.downsample(img,L)` | `vislab.lib.downsample(img,L)` | **identical** for 2-D (diff 0); local's `filter`/`ppd`/… params were dead | **DONE** — repointed live calls (`cnn/getTwinBatch.m`, `+general/nat_near_far_patches_cnn.m`). `+lib/downsample.m` dead → delete. `+lib/downsample_old.m` is **broken** (calls a missing `aply_otf`) → delete. |
| `Rs(a,b,psz)` (root `Rs.m`, `edgecode/Rs.m`) | `vislab.nat_stat_bayes.dv_spatial(a,b,psz)` | **identical** (diff 3.5e-15), promoted to commons | repoint `Rs` users, then delete the copies. |
| `lib.hist_dv(a,b,edges)` | — (none; `dv_spot_hist` is a *different*, multi-feature colour-histogram DV) | **not equivalent** | keep `+lib/hist_dv.m` local, OR add a grayscale-histogram DV to commons. Decide with Geisler. |
| `lib.otf_filter(img,ppd,…)` (root `+lib`) | `vislab.lib.otf_filter` | verified equivalent for texseg's usage (grayscale / per-channel); vislib's also handles color in one call | **DONE (2026-07-05):** repointed all 4 live calls (`+general/simulate_discrimination.m:34,306,312`, `nat_near_far_patches_cnn.m:41`) and the copies inside `+lib/edge_props_stim.m`. |
| `lib.texture_patch`, `lib.find_nat_patch`, `lib.compute_pClipped`, `lib.monitorDegreesToPixels`, `lib.gammaCorrect` | — | repo-specific / utilities | kept local in `+lib` (§3 collision now moot — root `+lib` no longer on the path). |

## 3. `+lib` name collisions (lab-root `+lib` vs this repo's `+lib`) — RESOLVED (2026-07-05)
**DONE:** made this repo's `+lib` self-contained and dropped the lab-root `+lib` dependency (mirrors
`camouflage_detection`). Copied the reachable root-`+lib` functions this repo needed into `+lib/`
(`edge_props_stim` + its subtree `target_mask`/`steerable_grad`/`steerable_filter`/
`create_pink_noise_line`/`local_sd`), repointed `lib.otf_filter`→`vislab.lib.otf_filter`, and removed the
`root_parent` `addpath` from `setup.m`. Nothing deleted from root `+lib` (it's a loose lab-root folder).
- The two former collisions are now moot — with root `+lib` off the path, `lib.compute_pClipped` and
  `lib.monitorDegreesToPixels` simply resolve to this repo's own local copies (the same resolution as
  before, when this repo's `+lib` was added last and won). Verified no caller depended on the root
  copies' different behaviour (root's 3-D `monitorDegreesToPixels`, root's missing clip-warning branch).
- Chose to keep the package named `+lib` (not rename to `+texseg`) so `lib.*` call sites stay unchanged
  and the structure mirrors `camouflage_detection`'s local `+lib`.

## 4. Dangling references (currently BROKEN — fix or remove)
- `edge_dv.m` calls `lib.edge_contour_props`, which exists nowhere. (Its logic overlaps the
  inline contour tracing in root `Re.m` + `mk_contour.m`.)
- `texture_grouping.m` and `Rs_new.m` call bare `Rp(...)`/`Rh(...)` — no `Rp.m`/`Rh.m` exists at
  the repo root (only `Rp_win.m`, whose function is named `Rp`, and `lib.power_dv`/`lib.hist_dv`).
- `+experiment/+grouping/+run/loadStimuli.m:21` reads `exp_settings.ecc(currentLevel)`, but the
  grouping `exp_settings.mat` has **no `ecc` field** (confirmed by loading the shipped file; grouping's
  blocks are *contrast* levels, not eccentricities). Looks copy-pasted from `+discriminate`'s loadStimuli;
  would error if that fixation-eccentricity path were exercised in grouping. Fix or remove.

## Naming note — eccentricity "level" NOT renamed here
The lab-wide `level`→`ecc` rename (done in texture-learning + vislab, 2026-07-05) was **deliberately
NOT applied to this repo**: texseg's eccentricity concept is the downsample factor (`down_level`/`lev`/`iLevel`
in `+general`/`cnn`/`+lib/downsample`), but `ecc` is already used here for a *different* thing —
`exp_settings.ecc` = fixation eccentricity in **degrees** (`[0 1.6 5 11.5]`), plus `mecc`/`decc` (in-image
spatial eccentricity) in `+grouping`. Renaming the downsample factor to `ecc` would collide. Left as-is per
the owner's call; revisit with a distinct token (e.g. `ecc_ds`) if consistency is wanted later.

## Colour transforms — NOT yet on the shared auto-loading vislab functions (flagged 2026-07-05)
The lab now centralizes the two colour transforms in `vislab-common/data` behind auto-loading functions:
`vislab.lib.rgb2lms(img)` (RGB→LMS, from `cps_rgb2lms.mat`) and
`vislab.nat_stat_bayes.apply_color_rotation(patch)` (LMS→ABR, from `cps_lms2abr_otf.mat`). texture-learning
was migrated to call these. texseg was **left as-is** because its two consumers aren't clean drop-ins:
- `+general/nat_near_far_patches_bayes.m` — legacy script still on the **old unqualified names** (`aply_otf`,
  `rgb2lms`, `dsmp`) and `ppd=60`; it's effectively broken already. Migrate the whole script (→ `vislab.lib.*`)
  or retire it.
- `+general/nat_near_far_patches_cnn.m` — computes RGB→LMS **inline with the WRONG matrix orientation**
  (`lms * rgb_col`, A-channel only, no negative clip). **RESOLVED (2026-07-05, from `Bill's old code/`):**
  Bill's original `rgb2lms.m` uses `rgb_row * M` and clips negatives (identical to `vislab.lib.rgb2lms`), and
  his `mk_rot_mtrx.m:148-149` explicitly comments `coeff*lms'` as "incorrect multiplication" and `lms*coeff`
  (row × matrix) as "correct". So this cnn script is transposed/wrong; converting it to
  `vislab.lib.rgb2lms(img)` is a **correctness fix** that will change the CNN-patch numbers to the right ones.
  (texture-learning already matches Bill exactly, so it needs no change.)

## 5. Stale hardcoded absolute paths
- `+general/nat_near_far_patches_bayes.m:9-12` — two `addpath('C:\Users\Bill Geisler\…')`. Replace
  with `config.paths` (the `CPS natural images` set is now `cfg.paths.natural_images`).

## 6. `edgecode/` (standalone legacy)
- A 4th copy of `Rp/Rh/Re/Rs` (+ `mk_contour.m`, and `texture_discrimination.m` which references a
  missing `mk_win.m`). `Rs` is now `vislab.nat_stat_bayes.dv_spatial`; fold `Rp/Rh/Re` onto
  `vislab.nat_stat_bayes.{dv_power,dv_spot_hist,dv_edge_hist}` or delete the tree.

## 7. Experiment harness → `vislab/+psychframework` (separate pass, needs PTB testing)
- `+experiment` duplicates its whole harness across `+discriminate` and `+grouping`. There is a
  latent bug: `+grouping/+run/runTrial.m` and `runLevel.m` call `experiment.run.*` (not
  `experiment.grouping.run.*`), so the duplicated packages may not even resolve as-is.
- **DONE:** `vislab/+psychframework` (shared session→level→trial loop) added; `runExperiment.m` for
  BOTH the `+grouping` and `+discriminate` experiments now delegates the loop/screen to it, wiring each
  task's interval functions as hooks. The superseded `runLevel.m`/`runTrial.m` in both `+run` packages
  were **deleted** (commit `de7cb3148`), fixing the grouping harness's latent `experiment.run.*` namespace
  bug. Parse-verified; not headless-testable (Psychtoolbox) — PTB validation waived by the user.
- The `+discriminate` and `+grouping` **interval functions** are still near-duplicates of each other
  (fixation/response/feedback/displayLevelStart are effectively identical; only `stimulusInterval` differs
  trivially). They could be merged into one shared set parameterized by task — optional further dedup.

## 8. Repo size / large files — DROPPED (2026-07-05, user's call: keep large files in git)
The history rewrite is **not** happening. For the record, the bloat is `img_data/brodatz/patches/{train,test}`
(17,700 tracked PNGs) + `img_data/nat/patches/{same,diff}` (derived/regenerable), plus large `.mat`
(`cnn/cnn_on_{brodatz,nat}.mat` ~62 MB each, `exp_files/*/exp_settings.mat` 18–53 MB, `+grouping/test.mat`
17 MB). Left as-is. Revisit only if repo size matters at publication.
