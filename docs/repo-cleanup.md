# Repo-wide cleanup plan

✅ done · 🚧 in progress · ⬜ not started

---

<details open>
<summary><h2 style="display:inline; margin:0; font-size:1.15em">0. Status</h2></summary>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h3 style="display:inline; margin:0; font-size:1.05em">🚧 0.1 · Stage 1 · Style</h3></summary>

<div style="margin-left:1.5em">

**Description.** Comments, header docs, whitespace, operator and bracket spacing, indentation, reflow, blank-line grouping, renames — file-local identifiers to snake_case, plus function and file names repo-wide in their own tranche — and triaging any commented-out code found in each tranche's files (verdict only, nothing deleted). Checked by `isequal` on a canonical AST fingerprint — no execution needed.

**To-do.**

- [x] **0.1.0.** Tooling: `canon`/`check_stage1`/`assert_rename_bijection`, golden-output harness, housekeeping (drop the tracked `.asv` autosaves from git — they're already gitignored).
- [x] **0.1.1.** Function and file renames, repo-wide — the map in section 3.1.1, verified over every file.
- [ ] **0.1.2.** `+lib` (14 files, 1103 lines) — sets the in-file naming/header conventions for cluster B (the already-mostly-snake_case directories).
- [ ] **0.1.3.** `+grouping` part 1 — the pure geometry/bin helpers (`mk_dist`, `mk_decc`, `mk_mecc`, `mk_bindex`, `mk_masks`, `mk_texs`, `find_bin`, `find_xy`, `check_xy`, `check_tlst`, `effective_distance`, `find_tex_regions`; ~11 files) — sets the terse-abbreviation vocabulary for cluster C.
- [ ] **0.1.4.** `+grouping` part 2 — the stimulus-generation scripts (`mk_texseg_session`, `mk_texseg_stim_points`, `mk_texseg_stim_shape`, `mk_texseg_stim_shape_old`, `mk_trl_points`, `tex_regions`, `s_gtr_img`, `demo_mk_trl_points`; ~10 files) — applies 0.1.3's vocabulary.
- [ ] **0.1.5.** Root cluster-C files (`re.m`, `rs.m`, `rs_new.m`, `rp.m`, `thresh.m`, `nlsame.m`, `mk_contour.m`, `mk_win.m`, `edge_dv.m`, `contour_blur_estimation.m`; 10 files) — applies the same vocabulary.
- [ ] **0.1.6.** `+experiment/+discriminate/+run` + `+experiment/+grouping/+run` (18 files, 779 lines) — one camelCase→snake_case decision applied to both near-duplicate trees at once.
- [ ] **0.1.7.** `+experiment/+discriminate/+prep` + `+experiment/+grouping/+prep` (5 files, 270 lines) — same decision, smaller trees.
- [ ] **0.1.8.** `+general` (3 files, 700 lines: `compute_exp_error_mat`, `nat_near_far_patches_bayes`, `simulate_discrimination`) — the messiest file in the repo (`simulate_discrimination.m`) lives here; no other tranche's conventions bind it, so it goes late rather than early.
- [ ] **0.1.9.** `config.m`, `setup.m`, `texture_grouping.m` — the config file and the user-facing driver, done last.

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h3 style="display:inline; margin:0; font-size:1.05em">⬜ 0.2 · Stage 2 · Tidying</h3></summary>

<div style="margin-left:1.5em">

**Description.** Semicolon insertion, preallocation, `find`→logical indexing, deleting a provably unused assignment. Checked by a whitelisted-pattern diff **plus** a runtime golden-output match. A closed list of four: anything bigger is a Speed item (0.5), not a widening of this stage.

**Status.** Most of the repo has no real entry point that runs without Psychtoolbox or the ~19 GB natural-image set this machine doesn't have, so most Stage 2 tranches will be pattern-check-only — see section 1's harness-coverage note.

**To-do.**

- [ ] **0.2.0.** Extend the golden harness to cover every tranche that has a runnable entry point.
- [ ] **0.2.1.** Same tranche boundaries as Stage 1 (0.1.2–0.1.9), run in the same order.

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h3 style="display:inline; margin:0; font-size:1.05em">⬜ 0.3 · Stage 3 · Structure</h3></summary>

<div style="margin-left:1.5em">

**Description.** Signature changes, `arguments` blocks, merging duplicate functions, reordering statements, float/RNG-order changes, renaming a config struct field or a frozen `save`/`load` name, acting on the Stage 1 commented-out-code triage — not behaviour-preserving, done after Stage 1/2, and not Bugs (0.4) or Speed (0.5) even if a fix here happens to speed something up. **Rating:** 🔴 clear win, low risk · 🟠 real cost (design decision or wide call-site surface) · 🟡 marginal, defer — a joint call, not a formula, say which factor drove it. Id `S<tier>.<n>`, a flat sequence sorted by tier then discovery order, never renumbered.

**To-do.**

- [ ] 🔴 **S1.1.** Merge the byte-identical duplicate files across `+experiment/+discriminate/+run/` and `+experiment/+grouping/+run/` (`display_level_start.m`/`give_feedback.m`/`save_current_level.m`/`stimulus_interval.m`) into one shared implementation.
- [ ] 🟠 **S2.1.** Merge the near-duplicate files in the same two trees that differ by a handful of lines (`response_interval.m`, `load_current_session.m`, `fixation_interval.m`, `+prep/setup_subject.m`, `run_experiment.m`, `load_stimuli.m`), deciding how to parametrize the discriminate-vs-grouping difference.
- [ ] 🟠 **S2.2.** Repoint `+lib/downsample.m`/`downsample_old.m` to `vislab.lib.downsample` and delete the local copies (both also currently shadow the Signal Processing Toolbox's `downsample` builtin).
- [ ] 🟠 **S2.3.** Repoint `+lib/power_dv.m` and `rp.m` (formerly `Rp_win.m`) to `vislab.nat_stat_bayes.dv_power`, which `simulate_discrimination.m` already calls directly; update the remaining callers (`texture_grouping.m:72`, `rs_new.m:49-50`).
- [ ] 🟠 **S2.4.** Unify the two paths used for the same Brodatz texture set (`'img_data/brodatz/'` vs `'vislab-common/data/textures/brodatz/'`) onto `config.m`'s `cfg.paths.textures`.
- [ ] 🟠 **S2.5.** Convert the `+grouping`/`+general` script files with no callable entry point (`mk_texseg_stim_points.m`, `mk_texseg_stim_shape.m`, `mk_texseg_stim_shape_old.m`, `find_tex_regions.m`, `tex_regions.m`, `demo_mk_trl_points.m`, `compute_exp_error_mat.m`, `nat_near_far_patches_bayes.m`, `simulate_discrimination.m`) into proper functions, callable through their package.
- [ ] 🟠 **S2.6.** Deduplicate the three call sites that each independently build the same `mk_dist`/`mk_mecc`/`mk_decc`/`mk_bindex` grid for the same `sz` (`mk_texseg_session.m:37,40`, `mk_texseg_stim_points.m:36,39`, `mk_texseg_stim_shape_old.m:29,32`) into one shared setup call.
- [ ] 🟡 **S3.1.** Decide whether `mk_texseg_stim_shape_old.m` — a third variant alongside `mk_texseg_stim_shape.m`/`mk_texseg_stim_points.m` with no recorded reason it's still kept — should be deleted, once its Stage 1 commented-out-code triage and S2.5/S2.6 have landed.

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h3 style="display:inline; margin:0; font-size:1.05em">⬜ 0.4 · Stage 4 · Bugs</h3></summary>

<div style="margin-left:1.5em">

**Description.** Bugs found anywhere during Stage 1/2/3, fixed here after Structure so a later structural change can't clobber or duplicate a fix. **Rating:** 🔴 severity 1, silently wrong results on a path that has actually been run · 🟠 severity 2, reachable but not silent — errors out, or touches only plots/logging/display · 🟡 severity 3, latent, not reachable with the current config but a hazard for plausible future use. Id `B<severity>.<n>`, a flat sequence sorted by severity then discovery order, never renumbered.

**Status.** Three of these (B2.1, B2.2, B2.3) are pre-existing and already acknowledged in the README's "Status & caveats" section, which used to track them in a now-deleted `CLEANUP.md`; they're re-filed here rather than left undocumented.

**To-do.**

- [ ] 🔴 **B1.1.** `+lib/edge_props_stim.m:30` — a bare `randi(10)` with no semicolon, on the per-trial call path from `simulate_discrimination.m` (called `nchoosek(n_tex,2)*n_samp` times), prints to the console and silently consumes an extra draw from the RNG stream on every call, shifting every later random draw in the simulation.
- [ ] 🔴 **B1.2.** `re.m:103` — `for k = 1:nc1` inside the "patch 2" block (lines 85-119, mirroring "patch 1" at 48-82) almost certainly should be `for k = 1:nc2`; as written it iterates the wrong count for patch 2's labelled regions whenever `nc1 ≠ nc2`, on a live decision-variable function actually used in analysis.
- [ ] 🟠 **B2.1.** `edge_dv.m:2-3` calls `lib.edge_contour_props(...)`, which does not exist anywhere in `+lib` — errors if reached.
- [ ] 🟠 **B2.2.** `texture_grouping.m:72-73` calls bare `Rp(...)` and `Rh(...)`; `Rp` will resolve once the Stage 1 rename below lands (`rp.m`), but `Rh` is not defined as a callable function anywhere — it only exists as an output-variable name inside `+lib/hist_dv.m`.
- [ ] 🟠 **B2.3.** `+general/nat_near_far_patches_bayes.m:9,11` hardcodes `addpath('C:\Users\Bill Geisler\Documents\...')` — breaks on any machine other than the original author's.
- [ ] 🟡 **B3.1.** `+general/simulate_discrimination.m:245-246` loads `exp_files/norm/exp_settings.mat` and `exp_files/norm/subject_out/neel.mat`, but no `norm` subdirectory exists under `exp_files/` (only `grouping`, `joined`, `sep`) — latent, only reachable if some code path selects an experiment type of `'norm'`.
- [ ] 🟡 **B3.2.** `+grouping/find_bin.m:5-29` — only `id` is initialized (`id = 0`); `ime` and `ide` are not. If `mecc`/`decc` fall outside their bin bounds the function throws `Unrecognized function or variable 'ime'` rather than reporting a bin-lookup failure. The `id == 0` branch is no better: it assigns a dead local `err = 1` that is never returned or checked, then falls straight through to `bindex(0, ime, ide)`, which errors on the zero index. Latent with the current bounds (`bbdist = [1,2,4,8,16,32]` etc. cover every pair on a 16×16 grid), but any larger `sz` or narrower bounds hits it. Found while building the golden harness — the harness's `find_bin` sweep had to be sized so this could not trigger.
- [ ] 🟡 **B3.3.** `+grouping/mk_masks.m:11` preallocates `masks = zeros(np, np, np*ntr)`, but the array is written at `(t-1)*ntr+i` for `t = 1:ntrl`, so the third dimension should be `ntrl*ntr`. With `ntrl < np` the result carries trailing all-zero slices and a wrong `size(masks, 3)`; with `ntrl > np` MATLAB silently grows the array instead (correct values, defeated preallocation). Latent only because the first output is currently dead: all four call sites (`mk_texseg_session.m:34` discards it with `~`; `mk_texseg_stim_points.m:31`, `mk_texseg_stim_shape.m:19`, `mk_texseg_stim_shape_old.m:26` assign `masks` and never read it) use only `maps`.

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h3 style="display:inline; margin:0; font-size:1.05em">⬜ 0.5 · Stage 5 · Speed</h3></summary>

<div style="margin-left:1.5em">

**Description.** Optimization candidates found during the survey (section 2) or anywhere in Stage 1–4, never made at the time — done last, once the code is structurally settled and correct. Every item needs a before timing, golden-output equality, and an after timing; if the speedup isn't worth the diff, the change is reverted and the null result recorded. **Rating:** 🔴 large win, low risk · 🟠 real cost (moderate gain, or a large one that perturbs float/RNG/`parfor`-reduction order and needs a tolerance decision) · 🟡 small, speculative, or unverified — most items start here. Id `O<tier>.<n>`, same non-renumbering rule as 0.4. Separate axis, **verification status** — Proven, Perturbing, or Unprofiled (not implementable as recorded until profiled).

**Status.** No timing data exists anywhere in this repo — no `tic`/`toc`, no logged runtimes, no README note — so every item below starts life Unprofiled; nobody currently knows where this repo's wall-clock actually goes.

**To-do.**

- [ ] 🔴 **O1.1.** `+lib/steerable_filter.m:12-18` and `+lib/local_sd.m:18-24` rebuild their kernel/mask from a double loop on every call, for the same handful of `kernel_sd`/size values reused across the whole trial loop (`edge_props_stim.m:106-107` alone calls `steerable_grad`→`steerable_filter` 10 times per trial for 5 fixed scales, plus 10 more `local_sd` calls); `steerable_grad` already accepts an unused `'filter'` parameter (line 8) built for exactly this hoist. Unprofiled.
- [ ] 🔴 **O1.2.** `+experiment/+discriminate/+prep/generate_stimuli.m` → `+lib/texture_patch.m:31` re-`imread`s a Brodatz `.gif` on every patch draw — roughly 2400 calls over only 60 distinct files, each also rebuilding a fresh `inputParser`. Unprofiled.
- [ ] 🔴 **O1.3.** The `+grouping` texture-region pipeline (`mk_trl_points.m:37,40,43`, `mk_texseg_stim_points.m:202`, `mk_texseg_stim_shape.m:77`, `mk_texseg_stim_shape_old.m:205`, `tex_regions.m:100`, `texture_grouping.m:30`) re-`imread`s the same Brodatz files every trial instead of once — same pattern as O1.2, different call path. Unprofiled.
- [ ] 🟠 **O2.1.** `+lib/edge_props_stim.m:152-153,188-249` unconditionally opens/redraws figures and plots on every call (1 `figure`/`imshow` + 15 `subplot`/`bar` calls across 5 scales); removing this, along with B1.1's stray `randi(10)`, changes the RNG draw sequence for the rest of the run, so it needs an explicit tolerance decision before it can be verified. Unprofiled.
- [ ] 🟠 **O2.2.** `+grouping/mk_texseg_stim_points.m:169-178,219-228,233-242` calls `figure; image; set(gcf); pause; close all` three times inside the triple trial loop, blocking on `pause` every trial; gating behind a debug flag changes interactive behaviour, not a pure no-behaviour-change win. Unprofiled.
- [ ] 🟡 **O3.1.** `+grouping/mk_dist.m:6-16`, `mk_decc.m:6-18`, `mk_mecc.m:6-18` are 4-deep loops over `sz²×sz²` of pure arithmetic on `x1,y1,x2,y2` (vectorizable via `meshgrid`), and `mk_bindex.m:12-19`'s 3-deep loop is exactly `reshape(1:N,...)` with a permute — tangled with S2.6, since the same rebuild currently happens at three call sites. Unprofiled.
- [ ] 🟡 **O3.2.** `+grouping/find_bin.m:11-25` does three linear-scan loops to find one bin, called `sz⁴` times from three call sites — replacing the whole pattern with one `discretize` call over the full matrices at once is a large potential win, entirely unmeasured, and also tangled with S2.6. Unprofiled.
- [ ] 🟡 **O3.3.** Remaining small vectorizable loops: `thresh.m:3-12`, `nlsame.m:5-11`, `mk_win.m:6-15,25-30`, `re.m:32-45,55-64,92-101` (tangled with B1.2 — fix the bug first), `+grouping/mk_masks.m:75-88`, `tex_regions.m:66-76`, `mk_trl_points.m:18-28`'s block-mask construction. Unprofiled.
- [ ] 🟡 **O3.4.** `parfor` candidates: `+general/simulate_discrimination.m:30-36`'s image-load/OTF-filter loop is cleanly sliced with no reduction variable; `generate_stimuli.m:13-46`'s first loop is similarly sliceable; `+general/nat_near_far_patches_bayes.m`'s three per-image loops carry `pcnt9/10/12` counters and `while dflg==0` rejection sampling, needing restructuring first. Unprofiled.

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h3 style="display:inline; margin:0; font-size:1.05em">⬜ 0.6 · Stage 6 · Closing</h3></summary>

<div style="margin-left:1.5em">

**Description.** A single fixed gate, run once 0.1 through 0.5 are all done — not a findings list, so no rating legend and no items beyond the four below.

**To-do.**

- [ ] **0.6.1.** `check_stage1` re-run across every in-scope file against current HEAD.
- [ ] **0.6.2.** `golden_harness('replay', ...)` clean, end to end.
- [ ] **0.6.3.** Every item in 0.3, 0.4, and 0.5 ticked, or explicitly closed with a reason.
- [ ] **0.6.4.** Section 2 re-checked against the repo as it now stands.

</div>

</details>

</details>

---

<details>
<summary><h2 style="display:inline; margin:0; font-size:1.15em">1. How an agent should execute this cleanup plan</h2></summary>

<div style="margin-left:1.5em">

`mtree` parses a `.m` file into MATLAB's own syntax tree, and `tree2str` prints it back in canonical form: comments stripped, whitespace/bracket spacing normalised, missing `end` supplied.

```matlab
canon = @(f) tree2str(mtree(f,'-file'));
```

This gives a fingerprint blind to exactly what stage 1 is allowed to change, sensitive to everything else. Verify it succeeds on all 74 in-scope files before relying on it in a tranche.

Reverse-rename check: clean a file (renames, header, reflow), then undo the rename map on the canonical form of the new file and assert it's identical to the canonical form of the old one:

```matlab
c_new = canon(new_file);
for k = 1:size(renames,1)   % renames = {new_name, old_name}
    c_new = regexprep(c_new, ['(?<![A-Za-z0-9_.])' renames{k,1} '(?![A-Za-z0-9_])'], renames{k,2});
end
isequal(canon(old_file), c_new)   % must be true
```

The lookahead `(?![A-Za-z0-9_])` matters: without it a short name (`patch`) can wrongly match inside a longer one (`patch_size`). The rename map itself must be a bijection with disjoint domain/range — assert this before using it:

```matlab
dom = renames(:,1); ran = renames(:,2);
assert(numel(unique(dom)) == numel(dom));
assert(numel(unique(ran)) == numel(ran));
assert(isempty(intersect(dom, ran)));
```

Caveat: `mtree`/`tree2str` are undocumented MATLAB APIs — pin the MATLAB version (R2024b, per the survey) in every commit that depends on this check.

**Stage 2's extra requirement: runtime golden output — and this repo's coverage is narrow.** This repo has no single runnable pipeline: `+experiment` needs Psychtoolbox and a display, and `+general`'s three files need either the ~19 GB natural-image set or the Brodatz/`exp_files` data, neither of which is confirmed present on the machine doing the cleanup. The golden harness therefore covers only the pure, self-contained functions callable with small synthetic inputs: `config()`, and the `+grouping` geometry helpers (`mk_dist`, `mk_decc`, `mk_mecc`, `mk_bindex`, `mk_masks`, `find_bin`, `check_xy`, `check_tlst`) and the `+lib`/root utilities that don't require real image files (`steerable_filter`, `steerable_grad`, `local_sd`, `mk_win`, `mk_contour`, `thresh`, `nlsame`) — call these directly with small synthetic arrays, seeded explicitly, never through `texture_grouping.m` or any Psychtoolbox launcher. Everything touching real Brodatz/natural-image data or Psychtoolbox (all of `+experiment`, `+general`, `+lib/texture_patch.m`, `+lib/edge_props_stim.m`, `re.m`/`rs.m`/`rs_new.m`/`rp.m`/`edge_dv.m`/`contour_blur_estimation.m`/`texture_grouping.m`) is pattern-check-only for Stage 2 — state this explicitly in each such tranche's findings-log entry rather than skipping the question. No `parfor` loops exist anywhere in the repo yet, so there's nothing to check for sliced-vs-reduction safety.

Semicolon insertion is stage 2, not stage 1: `tree2str` preserves display-vs-suppress, so the canonical diff is exactly `X` → `X;` — trivially whitelisted, but not invisible. One thing to watch here specifically: `+general/simulate_discrimination.m:69,114` and `+lib/edge_props_stim.m:30` have *missing* semicolons that are almost certainly leftover debug prints rather than deliberate interactive output (all three are deep inside per-trial loops, not top-level script lines) — ask before "fixing" if in doubt, per the skill's rule, but the loop-nesting context here argues they're accidental.

Speed is its own stage rather than a corner of Structure because the verification differs: a Structure item is reviewed and reasoned about, a Speed item is not done until a stopwatch says it worked. Being last also makes it the one stage that can be dropped entirely without touching anything else.

Stage 3 matters most. The tempting changes are all stage 3 (see section 0.3's list) — merging the near-duplicate `+experiment/+discriminate` / `+experiment/+grouping` trees is the single largest one here. Every one of them changes output, call sites, or validation behaviour, so none of them belong in the behaviour-preserving pass — keeping them out is what makes that pass's diff skimmable instead of line-by-line.

**All three of Structure, Bugs, and Speed rate their items on the same three-colour scale** — 🔴 highest, 🟠 middle, 🟡 lowest — though what the tier means differs by list: how bad a bug is if left unfixed, versus overall cost/benefit for a structural item, versus overall risk/benefit for an optimization. See sections 0.3, 0.4, and 0.5 for each list's specific criteria.

When the pass uncovers a *structural opportunity* — record it in 0.3 with its tier emoji and do not make the change. When it uncovers an *optimization* — record it in 0.5 and do not make it, however small it looks. When it uncovers a *bug* — record it in 0.4 first, marked with its severity emoji; the fix comes later, as a stage 4 item.

Statement reordering is kept out of stage 1/2 even though it looks cosmetic, purely because the check cannot distinguish a safe reorder from an unsafe one.

**Before working section 0.3, check whether section 2 is still current.** If meaningful time has passed since it was measured, or the file set has changed, re-measure it.

**Golden-reference maintenance, Stage 3 and Stage 4.** Run `golden_harness('replay', ...)` after every Stage 3 or Stage 4 item that touches a file the harness actually covers (see the coverage note above — most `+experiment`/`+general` items have no harness to run against, so their log entries say so explicitly instead). If the item was meant to be output-preserving and replay still passes, nothing to do. If replay fails, decide which happened before touching the reference: the item was *expected* to change output — recapture deliberately and log what changed — or it was supposed to be output-preserving and something moved that shouldn't have, which is a new bug for section 0.4, not a reason to recapture.

**Stage 6 (Closing), once Stages 1 through 5 are done:** re-run the full check suite end to end (section 0.6's checklist) rather than trusting the sum of the per-item checks.

</div>

</details>

---

<details>
<summary><h2 style="display:inline; margin:0; font-size:1.15em">2. Scope and measurements</h2></summary>

<div style="margin-left:1.5em">

Every number in this section was measured on the repo as it stands (MATLAB R2024b), on 2026-09-20 — re-measure before trusting any of it after substantial changes, or if real time has passed since this section was last touched.

**Scope, precisely.** Out of scope: `notes/` (21 `.pptx`/`.pdf`/`.docx` files, pure documents); `exp_files/` (17 `.mat` files — real collected human-subject data, frozen); `data/model/texture discrimination boundaries.mat` and the root `.mat`/`.fig`/`.pptx` artifacts (`acc_mod.mat`, `all_cues.mat`, `fabric_bd.mat`, `+grouping/session1.mat`, `+grouping/test.mat`, `discrim_all_cues.fig`, `+grouping/Grouping Experiment 1.pptx`); and 3-4 tracked `.asv` autosave files that `.gitignore` also lists (a stale tracked/ignored mismatch, removed as housekeeping in the tooling tranche rather than treated as an in-scope file). No vendored or ancestral-copy directory exists. The README's own layout section is stale — it still describes an `edgecode/` and a `+stats/` directory and a `CLEANUP.md` file, none of which exist on disk; fixing that description is Stage 1 material once the driver/config tranche (0.1.9) touches `README.md`-adjacent context, or can be done as a small standalone doc fix. That leaves **74 files, 5182 lines** in scope:

| Directory | Files | Lines |
|---|---|---|
| `+experiment/+discriminate/+prep` | 3 | 139 |
| `+experiment/+discriminate/+run` | 9 | 408 |
| `+experiment/+grouping/+prep` | 2 | 131 |
| `+experiment/+grouping/+run` | 9 | 371 |
| `+general` | 3 | 700 |
| `+grouping` | 21 | 1548 |
| `+lib` | 14 | 1103 |
| root (loose) | 13 | 782 |
| **Total** | **74** | **5182** |

**What is actually wrong with the files**, measured, not assumed:

- **Lint.** `checkcode` (R2024b defaults): 59 messages total, 51 of 74 files clean (69%). Worst files: `+lib/edge_props_stim.m` (18), `+lib/downsample.m` (5), `+grouping/s_gtr_img.m` (4). Most common: `STOUT` (18, unset return values, mostly `edge_props_stim.m`'s disabled contour-property outputs), `NASGU` (16, unused assignment), `LOAD` (6, `load` without naming variables), `ASGLU` (4). Two `FNDEF` hits (function name disagrees with filename) name the two mismatches the rename map fixes below.
- **Formatting.** No tab-indented files — the whole repo is space-indented, but inconsistently (1-2 spaces in `+grouping/*`, 4 elsewhere). 19 of 74 files have a line over 100 characters (66 lines total); worst offender `+general/simulate_discrimination.m:229` at 330 characters, runner-up `+experiment/+grouping/+prep/setup_experiment.m:58` at 160.
- **Spacing consistency.** 32 of 74 files (43%) use unspaced `x=y` assignments, 622 occurrences total — this splits cleanly along the three authorial clusters described below (cluster A and cluster B files are unspaced; cluster C files, and `config.m`/`setup.m`, are already spaced). Every Stage 1 tranche in clusters A/B carries real spacing work; clusters C's tranches (0.1.3-0.1.5) mostly don't.
- **Header docs.** 4 files have no header comment at all (`generate_stimuli.m`, `+lib/target_mask.m`, `edge_dv.m`, `thresh.m`). Only 3 files have a labelled `Inputs`/`Output` block (`edge_props_stim.m`, `local_sd.m`, `steerable_grad.m`); many `+grouping` files have the same information as an unlabelled `% name = description` list instead. Zero files have a `See also` line. No `Contents.m` exists anywhere. 14 files carry a stale copy-pasted header naming the wrong function or file (full list in section 3.1.1) — these get fixed as ordinary Stage 1 header edits by whichever tranche touches that file, not treated as bugs.
- **Names, inside files.** Heavy load-bearing abbreviations reused across dozens of files: `sz` (196 occurrences, grid side length in patches), `psz` (126, patch size in pixels), `trl`/`ntrl` (98/40, trial), `ptch`/`ptch1`/`ptch2` (72/31/31, patch), `imw` (79, image width in pixels), `pw` (57, patch width in pixels), `np` (49, number of patches per side), `cuelocs` (50, cue locations), `mecc`/`decc`/`bindex`/`bintbl` (14/14/14/27, min-eccentricity / delta-eccentricity / bin index / bin table), `bbdist`/`bbmecc`/`bbdecc` (21 each, bin bounds), `tlst` (25, tile list), `flg`/`chkflg`/`dflg`/`sflg` (a family of boolean flags). Function names themselves are cryptic in cluster C: `Re`, `Rs`, `Rp`, `Rh`, `fnd_bin`, `chktlst`, `mk_decc`, `s_gtr_img`, `nlsame`.
- **Names, of files.** See section 3.1.1 for the full family analysis and the resulting rename map; the headline findings are two function/file mismatches (`FNDEF` lint hits), a repo-wide camelCase/snake_case split concentrated entirely in `+experiment` plus two `+lib` files, two spellings of "find" in the same directory (`find_tex_regions.m` vs `fnd_bin.m`/`fnd_xy.m`), an inconsistent `_old`/`_new` versioning scheme (two `_old`, one `_new`, no shared convention), and a `test_mk_trl_points.m` that is actually a demo script, not a test.
- **Casing census.** Filenames: 49 snake_case, 20 camelCase (all in `+experiment` plus `+lib/gammaCorrect.m`/`monitorDegreesToPixels.m`), 5 other (`Re`, `Rs`, `Rs_new`, `Rp_win` — TitleCase-style single/short identifiers — and `compute_pClipped`, mixed within one name). Variables: 195 camelCase assignment targets repo-wide, 163 of them inside `+experiment`; only 3 leak outside it (`+lib/texture_patch.m`, `+lib/compute_pClipped.m`, `+general/simulate_discrimination.m`, one each). `+experiment` also has a third casing bucket, TitleCase structs (`SessionSettings`, `SubjectExpFile`, `SessionData`, `SettingsOut`). **The target is snake_case everywhere** — this makes `+experiment` (28 files, ~1200 lines) the size of that specific job; the rest of the repo is already close to compliant.
- **Convention splits.** Three clean authorial clusters, one per directory group: **A** — `+experiment/` + `+lib/gammaCorrect.m`/`monitorDegreesToPixels.m` — camelCase, spaced `=`, 4-space indent, `%FUNCTIONNAME Description` headers (often stale, see above). **B** — `+lib/`, `+general/`, `+experiment/+*/+prep/` — snake_case, `i_`-prefixed loop counters, **unspaced** `=`, 4-space indent, bare `%`/`%%` headers. **C** — `+grouping/` + root `R*`/`mk_*`/`thresh`/`nlsame` — snake_case with `mk_`/`fnd_`/`chk_` truncations, spaced `=`, 1-2 space indent, `%`/`% name = desc` headers. `config.m` and `setup.m` are a fourth, evidently newer style (full block header, aligned `=`, 4-space indent) — the closest thing this repo has to a target already.
- **Builtin shadows.** Only 3 distinct builtins shadowed, 10 sites: `filter` (8 sites, including as an output-argument name in `+lib/steerable_filter.m:1`), `diff` (1, `+experiment/+grouping/+prep/setup_experiment.m:24`), `contour` (2, `Re.m:67,104`). Also worth a note during cleanup though not a strict shadow: `i`/`j` assigned as ordinary loop-index variables at 18 sites across `+grouping/mk_*.m` files, which shadows the imaginary unit and is worth avoiding in any file being touched anyway.
- **Commented-out code.** ~375 lines across roughly 20 distinct blocks. By far the largest is `+lib/edge_props_stim.m:275-534`, ~210 lines across ~35 blocks — an entire disabled contour-property computation, which is also why 15 of that file's 18 lint messages are `STOUT`. Other notable blocks: `Re.m:122-154` (~23 lines, a disabled `eps2` contour-stats section plus 6 figure calls), `Rs_new.m:22-59` (~10 lines across 7 blocks, an entire alternative implementation), `+grouping/mk_texseg_stim_points.m:130-146` and the identical block in `mk_texseg_stim_shape_old.m:123-139` (13 lines each, a disabled display loop), `+grouping/tex_regions.m:78-89` (11 lines). A recurring motif — at least 10 separate disabled `figure`/`image`/`axis`/`close all` debug-display blocks scattered across `+grouping/` and `Re.m`. None of this is judged here; each block gets a verdict (section 3.1.4) only when the Stage 1 tranche that owns its file actually reads it.
- **Argument validation.** No `arguments` blocks anywhere. `inputParser` is used in 7 files, all inside `+lib` (`downsample`, `downsample_old`, `edge_props_stim`, `local_sd`, `steerable_grad`, `target_mask`, `texture_patch`), all with `KeepUnmatched=true`; zero usage outside `+lib`.
- **Performance shape.** Recorded as `O<tier>.<n>` items in section 0.5, not acted on here: loop-invariant filter/mask construction rebuilt on every call (steerable filter, local-SD disk mask); repeated `imread` of the same small set of Brodatz files inside per-trial loops, in both `+experiment` and `+grouping`; several 3-4-deep loops over `sz²`/`sz⁴` that are plainly vectorizable (`mk_dist`/`mk_decc`/`mk_mecc`/`mk_bindex`/`fnd_bin` and smaller ones in `thresh`/`nlsame`/`mk_win`/`Re`); unconditional debug plotting and an interactive `pause` inside hot loops; a handful of cleanly-sliceable `parfor` candidates with no reduction variable. No `inv`/`pinv`/`det` usage anywhere, and no unpreallocated array growth anywhere — clean on both of those axes. No `parfor` loops exist yet, so there's nothing to check for reduction-variable safety.
- **Is there any timing data at all?** None — no `tic`/`toc`, no `timeit`, no logged runtime, no README note. Nobody currently knows where this repo's wall-clock actually goes; every Speed item in section 0.5 starts Unprofiled for exactly this reason.

**The style target already exists in a sibling repo** — `vislab-common/+vislab/+lib/watson_otf.m` (summary line, fully-qualified signature, labelled `Inputs`/`Output` with units, `See also`). No file in this repo has that full shape: the closest are `config.m` (best prose header in the repo, but no Inputs/Output or See also, and zero-argument) and the 3 `+lib` files with a labelled Inputs/Output block but no See also. `config.m` is the reasonable in-repo anchor to extend toward once the driver/config tranche (0.1.9) reaches it. No in-scope file shares a name with a sibling-repo function; the closest overlaps are `+lib/downsample*.m` and `+lib/power_dv.m`/`rp.m`, which the README already says have vislab-common equivalents in active use elsewhere in this repo (see S2.2/S2.3).

</div>

</details>

---

<details>
<summary><h2 style="display:inline; margin:0; font-size:1.15em">3. Stage-by-stage details and work log</h2></summary>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h3 style="display:inline; margin:0; font-size:1.05em">3.1 · Stage 1 · Style</h3></summary>

<div style="margin-left:1.5em">

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h4 style="display:inline; margin:0; font-size:0.98em">3.1.1 Renaming: the three zones, and the function/file map</h4></summary>

<div style="margin-left:1.5em">

**Casing: snake_case for everything this repo owns.** Not camelCase (all of `+experiment` plus `+lib/gammaCorrect.m`/`monitorDegreesToPixels.m`/`compute_pClipped.m`), not TitleCase-style short identifiers (`Re`, `Rs`, `Rs_new`, `Rp_win` — single/short words, so snake_case is just lowercasing them). Not ours to rename: MATLAB/toolbox builtins, Psychtoolbox name-value strings, fields of structs returned by external code, zone-3 frozen names below.

1. **File-local variables — free.** Every camelCase variable and TitleCase struct inside `+experiment` (163 of the repo's 195 camelCase assignment targets) converts to snake_case as its tranche (0.1.6/0.1.7) reads the file; loop-index `i`/`j` shadowing the imaginary unit gets renamed to something index-like wherever a tranche touches that file anyway. The heavily-reused abbreviations in section 2 (`sz`, `psz`, `trl`, `ptch`, `imw`, `pw`, `np`, `cuelocs`, `mecc`/`decc`/`bindex`/`bintbl`, `bbdist`/`bbmecc`/`bbdecc`, `tlst`, `flg`-family) are **cross-file vocabulary** (zone 2, not zone 1) because they recur as function arguments across many `+grouping` files with the same meaning every time — a half-expansion would be worse than none, so the tranche that first reads each family (0.1.2 for `+lib`, 0.1.3 for `+grouping`'s pure helpers) fixes the expansion for that vocabulary once, and every later tranche in the same cluster reuses it rather than re-deciding. Proposed expansions, to be confirmed against each function's actual signature when its tranche reads it: `sz`→`grid_size` (side length of the patch grid, in patches — not pixels), `psz`→`patch_size` (pixels), `imw`→`image_width` (pixels), `pw`→`patch_width` (pixels), `trl`/`ntrl`→`trial`/`n_trials`, `ptch`/`ptch1`/`ptch2`→`patch`/`patch1`/`patch2`, `np`→`n_patches`, `ntexr`/`ntex`/`ntr`→`n_tex_regions`/`n_tex`/`n_regions`, `cuelocs`→`cue_locations`, `mecc`/`decc`→`min_ecc`/`delta_ecc`, `bindex`/`bintbl`→`bin_index`/`bin_table`, `bbdist`/`bbmecc`/`bbdecc`→`bin_bounds_dist`/`bin_bounds_mecc`/`bin_bounds_decc`, `tlst`→`tile_list`, `msks`→`masks`, `imgin`/`pimg`/`cimg`/`timg`/`fimg`→`img_in`/`patch_img`/`cue_img`/`tex_img`/`feedback_img`. Single-purpose one-word names that are already clear (`sigma`, `gain`, `contrast`, etc., where present) are left alone — expansion is for names that are actually unreadable, not padding to fit the convention.
2. **Cross-file vocabulary — repo-wide, or not at all.** Function and file names: the map below, its own tranche (0.1.1), before anything else. Function arguments named consistently across the repo: the abbreviation table above, applied per-cluster as each cluster's tranche runs. The config struct (`config.m`'s `cfg.*` field paths): the survey found no specific bad field name inside `config.m` itself, so there is no rename queued here — if the driver/config tranche (0.1.9) finds one worth renaming when it reads the file closely, it's dot-qualified and therefore **deferred to Stage 3**, not done in Stage 1.
3. **Serialised variable names — frozen.** `exp_settings` and `subject_file` (both `save`d/`load`ed in `+experiment/+{discriminate,grouping}/+{prep,run}/*.m`, and read by real files under `exp_files/`), `lms` (`+general/nat_near_far_patches_bayes.m:35`), `ptchn9/10/12`, `ptchf9/10/12`, `pcnt9/10/12` (same file, three `save` sites), `tx_discrim_bd` (`+general/simulate_discrimination.m:242`, currently inside a commented-out block — still frozen if that block is ever reactivated). None of these names, or any field inside the `exp_settings`/`subject_file` structs, may be renamed even though a local variable holding one of them can be. `+grouping/mk_texseg_session.m:160`'s commented-out `save` (`session<N>.mat`, writing `texset`, `m0`, `sz`, `pw`, `tperm`, `cntrst`, `cuelocs`, ...) is likewise frozen if it's ever un-commented — a reason to lean toward *unfinished*/*alternative* rather than *superseded* when that block gets its Stage 1 triage verdict in 0.1.4.

**Function and file rename map** (skill step 2a), run first as tranche 0.1.1, over the whole repo. Family rules applied: `fnd_`/`chk_` are truncations no shorter than `find_`/`check_` and buy nothing, so cluster C standardizes on the full spelling, matching `find_tex_regions.m`'s existing spelling rather than the other way; `mk_` is kept as-is (11 files) because it's already the dominant, internally-consistent convention for this cluster and renaming 11 files plus every call site would be a wide, low-benefit tranche of its own — flagged here rather than done, in case the user disagrees; every camelCase `+experiment` filename becomes its literal snake_case form (no wording changes, since the words themselves are already fine); the two function/file mismatches are fixed by changing whichever side is less risky to move.

| old file | new file | why |
|---|---|---|
| `+lib/downsample_old.m` | `+lib/downsample_old.m` (function line only: `function img_out = downsample(...)` → `function img_out = downsample_old(...)`) | `FNDEF` — function name disagreed with filename; fixing the function line rather than the filename, since "old" in the filename is the more meaningful, intentional part |
| `Rp_win.m` | `rp.m` | `FNDEF` — function is named `Rp`; the file's `_win` suffix just described that it takes a `win` argument (confirmed by reading the file), not a meaningful variant name, so the file is renamed to agree with the function, then lowercased |
| `Re.m` | `re.m` | snake_case (case-only rename — needs a two-step `git mv` through a temp name on Windows) |
| `Rs.m` | `rs.m` | snake_case (case-only) |
| `Rs_new.m` | `rs_new.m` | snake_case (case-only; keeping the `_new` suffix as-is — resolving it against `rs.m` is a Stage 3 decision, not a rename) |
| `+grouping/chktlst.m` | `+grouping/check_tlst.m` | spell out `chk_`→`check_` to match `check_xy.m`'s existing pattern, and add the missing underscore |
| `+grouping/chk_xy.m` | `+grouping/check_xy.m` | spell out `chk_`→`check_` |
| `+grouping/fnd_bin.m` | `+grouping/find_bin.m` | spell out `fnd_`→`find_` to match `find_tex_regions.m`'s existing spelling — two spellings of "find" in one directory otherwise |
| `+grouping/fnd_xy.m` | `+grouping/find_xy.m` | spell out `fnd_`→`find_` |
| `+grouping/test_mk_trl_points.m` | `+grouping/demo_mk_trl_points.m` | the file's own header says it "demonstrates one call" — it's a demo script, not a test, and the misleading name is the whole finding |
| `+experiment/+{discriminate,grouping}/+run/displayLevelStart.m` | `.../display_level_start.m` | snake_case (×2, one per experiment tree) |
| `+experiment/+{discriminate,grouping}/+run/fixationInterval.m` | `.../fixation_interval.m` | snake_case (×2) |
| `+experiment/+{discriminate,grouping}/+run/giveFeedback.m` | `.../give_feedback.m` | snake_case (×2) |
| `+experiment/+{discriminate,grouping}/+run/loadCurrentSession.m` | `.../load_current_session.m` | snake_case (×2) |
| `+experiment/+{discriminate,grouping}/+run/loadStimuli.m` | `.../load_stimuli.m` | snake_case (×2) |
| `+experiment/+{discriminate,grouping}/+run/responseInterval.m` | `.../response_interval.m` | snake_case (×2) |
| `+experiment/+{discriminate,grouping}/+run/runExperiment.m` | `.../run_experiment.m` | snake_case (×2) |
| `+experiment/+{discriminate,grouping}/+run/saveCurrentLevel.m` | `.../save_current_level.m` | snake_case (×2) |
| `+experiment/+{discriminate,grouping}/+run/stimulusInterval.m` | `.../stimulus_interval.m` | snake_case (×2) |
| `+lib/gammaCorrect.m` | `+lib/gamma_correct.m` | snake_case |
| `+lib/monitorDegreesToPixels.m` | `+lib/monitor_degrees_to_pixels.m` | snake_case |
| `+lib/compute_pClipped.m` | `+lib/compute_p_clipped.m` | snake_case (mixed casing within one name) |

Every new name in this table was checked against `which('<new>', '-all')` before being finalized here; none collide with a builtin or a name found in the sibling `vislab-common` repo. Not renamed here, deliberately: `mk_*` files (11, see above); `+lib/downsample.m`/`downsample_old.m` and `Rp`/`power_dv.m` (their names are fine — whether they should be *deleted* in favour of the `vislab` equivalents is S2.2/S2.3, a Stage 3 question, not a Stage 1 rename); the config struct's field paths (dot-qualified, Stage 3 per zone 2 above).

**The four sweeps the check cannot do for you**, to be answered explicitly in tranche 0.1.1's findings-log entry once it runs:

- Package-qualified call sites (`grouping.find_bin(...)`, `lib.gamma_correct(...)`, etc.) — excluded by `check_stage1`'s lookbehind, so verify these specific files by reading the diff, not by trusting a passing check.
- Old names referenced outside `.m` files — grep `README.md` and this plan document itself for every renamed name (the README's layout section already needs a separate fix for stale directory names, per section 2, so do both in the same pass).
- Dynamic references (`feval`/`str2func`/`exist`/`which`/`help` with the name as a string) — grep each old name as a quoted string, separately from the identifier grep. `chktlst`/`chk_xy`/`fnd_bin`/`fnd_xy` and the camelCase `+experiment` names are the ones most likely to appear this way in a Psychtoolbox launcher.
- Case-only renames on Windows (`Re.m`→`re.m`, `Rs.m`→`rs.m`, `Rs_new.m`→`rs_new.m`) — each needs `git mv foo.m tmp_foo.m && git mv tmp_foo.m Foo.m`, since a direct case-only `git mv` is a no-op on Windows' case-insensitive filesystem.

**Units, stated once here so every header can just cite them:** `sz` is a patch-grid side length, an integer count of patches, not pixels or degrees; `psz`/`imw`/`pw` are pixel counts; `ppd` is pixels per degree; `pd` (pupil diameter) is millimetres; `w` (wavelength, in `downsample`/`gammaCorrect`-family functions) is nanometres; angular/eccentricity quantities in `+grouping` (`mecc`, `decc`) are in the same patch-grid units as `sz`, not degrees, unless a specific function's header says otherwise once read.

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h4 style="display:inline; margin:0; font-size:0.98em">3.1.2 Tranches, sequencing, and model assignment</h4></summary>

<div style="margin-left:1.5em">

The repo is small (74 files, 5182 lines) and cleanly separable into three authorial clusters (section 2), so tranches follow those clusters rather than being cut purely by line-count budget. The **Agent** column is what the orchestrator dispatches to. Tranches run in order, one at a time — none of these are independent enough to parallelize, since 0.1.2/0.1.3 each set a vocabulary the rest of their cluster depends on.

| # | Tranche | Files / lines | Agent | Why |
|---|---|---|---|---|
| 0 | Rename map + `canon`/checker + golden harness + `.asv` housekeeping | — | `matlab-cleanup-lead` | Every other step trusts this being right |
| 1 | Function and file renames, repo-wide (section 3.1.1) | all 74 files | `matlab-cleanup-lead` | Must land before any header or comment names a file, or they all get rewritten twice; repo-wide, never parallel with anything |
| 2 | `+lib` | 14 files / 1103 lines | `matlab-cleanup-lead` | Sets in-file naming/header conventions for cluster B (already close to snake_case, but needs the abbreviation vocabulary fixed and the header shape decided against the `vislab` exemplar); also the only cluster with existing `inputParser` usage to harmonize |
| 3 | `+grouping` pure helpers (`mk_dist`, `mk_decc`, `mk_mecc`, `mk_bindex`, `mk_masks`, `mk_texs`, `find_bin`, `find_xy`, `check_xy`, `check_tlst`, `effective_distance`, `find_tex_regions`) | ~11 files / ~750 lines | `matlab-cleanup-lead` | Sets cluster C's terse-abbreviation vocabulary (`sz`/`psz`/`trl`/`mecc`/`decc`/`bindex`/... — see 3.1.1); these are the smallest, most self-contained files in the cluster, so the vocabulary gets fixed cheaply before it's needed by the larger files in tranche 4 |
| 4 | `+grouping` stimulus scripts (`mk_texseg_session`, `mk_texseg_stim_points`, `mk_texseg_stim_shape`, `mk_texseg_stim_shape_old`, `mk_trl_points`, `tex_regions`, `s_gtr_img`, `demo_mk_trl_points`) | ~10 files / ~800 lines | `matlab-cleanup-mechanical` | Applies tranche 3's vocabulary; these call the tranche-3 helpers directly, so cleaning helpers first avoids relitigating names |
| 5 | Root cluster-C files (`re.m`, `rs.m`, `rs_new.m`, `rp.m`, `thresh.m`, `nlsame.m`, `mk_contour.m`, `mk_win.m`, `edge_dv.m`, `contour_blur_estimation.m`) | 10 files | `matlab-cleanup-mechanical` | Same cluster-C vocabulary, smaller and more scattered files; `Re.m`'s commented-out block and the `nc1`/`nc2` suspect line get logged, not touched |
| 6 | `+experiment/+{discriminate,grouping}/+run` | 18 files / 779 lines | `matlab-cleanup-mechanical` | The near-duplicate pair makes this a single camelCase→snake_case decision applied twice — cheap regardless of file count |
| 7 | `+experiment/+{discriminate,grouping}/+prep` | 5 files / 270 lines | `matlab-cleanup-mechanical` | Same decision, the smaller half of `+experiment` |
| 8 | `+general` | 3 files / 700 lines | `matlab-cleanup-lead` | `simulate_discrimination.m` is the single messiest file in the repo (330-char lines, camelCase leak, console prints in a hot loop, RNG-perturbing `randi`) and has no caller in any other tranche — large and exploratory, so it goes near the end rather than being batched with something smaller |
| 9 | `config.m`, `setup.m`, `texture_grouping.m` | 3 files / ~300 lines | `matlab-cleanup-lead` | The config file and the user-facing driver, done last per the skill's standing rule; `config.m` is also this repo's best-available style anchor (section 2), so its own header is worth getting exactly right |

**Escalation rule, any tranche:** if `check_stage1` fails and the cause isn't obvious from the diff — stop, don't retry with a bigger prompt, hand that one file to `matlab-cleanup-escalation`. Don't loosen the check instead.

**"Done" checklist for a stage 1 tranche:**

- [ ] `check_stage1(old, new, renames)` true for every file.
- [ ] Every file has a header matching the exemplar's shape: summary, signature, `Inputs`/`Output` with units, `See also`.
- [ ] Every identifier the repo owns is snake_case — no camelCase variable, argument, or filename left except the external-API and frozen names listed in section 3.1.1 — and no name padded out just to fit the convention.
- [ ] Each file's `function` line agrees with its filename.
- [ ] Formatting harmonized: spacing around `=` and binary operators, space after commas, no space inside brackets, 4-space indent, no tabs, no trailing whitespace.
- [ ] No line exceeds 100 characters except the documented string-literal exceptions (listed per tranche in section 3.1.3).
- [ ] No zone-3 frozen identifier renamed, no `save`/`load` string literal changed.
- [ ] Each package touched has a `Contents.m`.
- [ ] Every commented-out block in the tranche's files has a verdict in section 3.1.4, and nothing was deleted or converted on the strength of it.
- [ ] Bugs found are written down with a severity tag and not fixed (section 0.4, and section 3.1.3 per-tranche).
- [ ] Optimizations spotted are written down with a tier tag and not made (section 0.5).

One commit per tranche, each stating the checker result and the MATLAB version (R2024b).

**Housekeeping done first, in the tooling commit:** run `git ls-files '*.asv'` and `git rm --cached` whatever's still tracked (the survey found 3-4 such files, all already listed in `.gitignore` — get the exact count and paths at execution time rather than trusting the survey's approximate figure).

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h4 style="display:inline; margin:0; font-size:0.98em">3.1.3 Findings log</h4></summary>

<div style="margin-left:1.5em">

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h5 style="display:inline; margin:0; font-size:0.92em">Step 0 — tooling</h5></summary>

<div style="margin-left:1.5em">

Run 2026-09-20. **MATLAB R2024b**, at `C:\Program Files\MATLAB\R2024b\bin\matlab.exe` — the only MATLAB installed on this machine, and the version every later tranche must pin, since `mtree`/`tree2str` are undocumented.

**What was built.** `tools/canon.m`, `tools/check_stage1.m`, `tools/assert_rename_bijection.m` copied verbatim from the skill (repo-agnostic, unmodified), plus `tools/golden_harness.m` and its captured reference `tools/golden_ref.mat`. `tools/` was created by this step; nothing in it is gitignored, so the reference is committed and every later tranche replays against the same bytes.

**`canon` succeeds on all 74 in-scope files — zero failures, zero empty results.** Verbatim output of the sweep (all `.m` under `+experiment`, `+grouping`, `+lib`, `+general`, plus the loose root `.m` files; `tools/` itself excluded):

```
in-scope .m files found: 74
canon OK: 74 / 74, failures: 0
```

The count matches section 2's independently-measured 74 exactly, so no file needs an alternative verification route and `check_stage1` is trustworthy repo-wide.

**Golden harness.** 15 entry points, all called directly with small synthetic inputs, each preceded by its own `rng(cfg.seed)` so the blocks are order-independent. Entry points and captured reference values:

| entry point | call | captured |
|---|---|---|
| `config` | `config()` | path **field names** only (8, sorted); optics `[60 4 550]`; `rgb_to_lms` checksum `24.3120`, size `[3 3]`; norm `[128 0.25]`; seed `0` |
| `mk_dist` | `grouping.mk_dist(8)` | checksum `1.6943e+04`, size `[64 64]` |
| `mk_mecc` | `grouping.mk_mecc(8)` | checksum `9.9057e+03`, size `[64 64]` |
| `mk_decc` | `grouping.mk_decc(8)` | checksum `5.5339e+03`, size `[64 64]` |
| `mk_bindex` | `grouping.mk_bindex(bb_dist, bb_mecc, bb_decc)` | checksum `7875`, size `[5 5 5]` |
| `find_bin` (now `fnd_bin`) | swept over all 4032 ordered distinct pairs on the 8×8 grid | checksum `190418`, `21` distinct bins, max bin `91` |
| `mk_masks` | `grouping.mk_masks(8, 2, 2, 0.8, 0.25)` | masks checksum `32` size `[8 8 16]`; maps checksum `48` size `[8 8 2]` |
| `check_xy` (now `chk_xy`) | swept over an 8×8 two-region map and its transpose | checksum `32`, size `[8 8 2]` |
| `check_tlst` (now `chktlst`) | swept over all 4 sides × all 64 locations of a map with a 4×4 unfilled block | checksum `2368`, flag sum `64`, size `[4 8 8 3]` |
| `steerable_filter` | `lib.steerable_filter([2 3])` | signed checksum `3.1225e-17`, **abs** checksum `19.0390`, size `[13 13 2]` |
| `local_sd` | `lib.local_sd(stim, [2 3])` | checksum `2.0249e+04`, size `[32 32]` |
| `steerable_grad` | `lib.steerable_grad(stim, 'kernel_size', [2 3])` | omitnan checksum `-152.2962`, NaN count `1248`, size `[32 32 2]` |
| `mk_win` | `mk_win(16, 4, 1)` and `mk_win(16, 4, 2)` | radial checksum `115.4341`; separable checksum `144`; both size `[16 16]` |
| `mk_contour` | `mk_contour(10, ones(1,10), 1:10)` | contour checksum `55`, `lnks` checksum `0`, `ncon` `10` |
| `thresh` | `thresh(rand(8), 8, 0.5)` | checksum `39`, size `[8 8]` |
| `nlsame` | `nlsame([1 3 5 7 9], 5, [2 3 5 8], 4)` | value `2` |

Capture and replay both verified in the same MATLAB session; `golden_harness('replay', 'tools/golden_ref.mat')` returns clean.

**Decisions made here that bind later tranches.**

1. **The golden struct's field names use the POST-rename function names** — `find_bin_*`, `check_xy_*`, `check_tlst_*` — even though tranche 0.1.1 has not run and the harness still calls `grouping.fnd_bin`, `grouping.chk_xy`, `grouping.chktlst`. Reason: struct fields are dot-qualified, and `check_stage1.m:30`'s negative lookbehind deliberately refuses to reverse-rename anything preceded by a `.`. Had the fields been named `fnd_bin_*`, tranche 0.1.1 would face a choice between leaving them stale or renaming them and making `check_stage1` fail on a correct edit — and renaming them would also invalidate the captured reference. **Tranche 0.1.1 must change only the three call expressions in `tools/golden_harness.m`, not the `golden.*` field names.** The comment block at the top of the harness says the same thing in-file.
2. **`config()`'s path fields are recorded by name, never by value.** `cfg.paths.*` are absolute paths built from `mfilename('fullpath')`, so checksumming them would make `golden_ref.mat` machine-specific and unreplayable anywhere else. Only the eight field names (sorted) plus the numeric constants go in. Tranche 0.1.9 should keep it that way.
3. **`steerable_filter` gets both a signed and an absolute checksum.** The filter is antisymmetric, so its signed sum is `3.1e-17` — numerically zero, and therefore blind to almost any change. The `abs` checksum (`19.0390`) is the one that actually has discriminating power. Any later entry point over an antisymmetric or zero-mean quantity should do the same.
4. **`steerable_grad` is reduced with `'omitnan'` plus a separate NaN count.** It preallocates `nan(M,N,2)` and pastes only the `'valid'` filter region, so a plain `sum` is `NaN` and compares useless. The NaN count (`1248`) is what pins the border geometry.
5. **`local_sd` and `steerable_grad` are gated on `exist('stdfilt')` and `exist('padarray')`** (Image Processing Toolbox) and warn rather than error. Both are present on this machine, so their reference values are real, not empty — a machine without IPT would replay the empty placeholders and mismatch. Note that for a later tranche.
6. **All reductions use an explicit `'all'`.**

**Subtleties found while building the harness.**

- `mk_contour`'s `lnks` output checksums to `0` by design, not by accident: the contour walk destructively zeroes each link as it traverses it, so `0` is the "fully traversed" invariant for an open chain. It is a weak checksum on its own, which is why `contour` (`55` = `sum(1:10)`) and `ncon` (`10`) are recorded alongside it.
- `mk_contour` needs an **open** chain. It scans for the first row of the link map with exactly one link and uses it as the start; a closed loop has no such row and the scan runs off the end of the array. The synthetic input is a straight 10-pixel line for that reason.
- `mk_masks`'s region-growing `while sum(tlst(:,1)) < pixp*np^2` loop has no iteration cap, so its parameters were chosen conservatively (`np = 8`, `ntr = 2`, `pixp = 0.25` — 16 of 64 patches) to leave the regions plenty of room to grow. A later tranche should not raise `pixp` toward 1 in the harness without checking termination.
- `find_bin`'s synthetic bin bounds are copied from the real call site (`mk_texseg_session.m:23-25`) rather than invented, and `grid_size = 8` keeps every pair inside them — deliberately, because falling outside them triggers B3.2 below rather than a clean failure.
- Two latent bugs found and **recorded, not fixed**: 🟡 **B3.2** (`fnd_bin`'s uninitialized `ime`/`ide` and its dead `err = 1` out-of-range branch) and 🟡 **B3.3** (`mk_masks` preallocating its third dimension as `np*ntr` where the write pattern needs `ntrl*ntr`). No optimizations or structural items beyond those already in sections 0.5 and 0.3 were found at this step.

**Housekeeping.** `git ls-files '*.asv'` returned exactly 3 tracked autosave files, not the survey's approximate 3-4:

```
+experiment/+discriminate/+prep/generate_stimuli.asv
+experiment/+grouping/+run/runExperiment.asv
+grouping/chktlst.asv
```

`.gitignore:4` already lists `*.asv`, so these were a stale tracked/ignored mismatch. All three were `git rm --cached`'d — untracked, left untouched on disk (confirmed present afterwards). No working-tree content was deleted.

**`parfor`.** Re-confirmed: no `parfor` loop exists anywhere in the repo, so there is nothing to check for sliced-vs-reduction safety. Documented negative.

**Baseline note for later tranches.** At the start of this step the working tree was clean apart from the untracked `docs/` directory, so **HEAD is a valid `check_stage1` baseline for every in-scope `.m` file** — no file carries uncommitted work-in-progress. Re-check `git status` before each tranche rather than assuming this still holds.

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h5 style="display:inline; margin:0; font-size:0.92em">Step 1 — function and file renames</h5></summary>

<div style="margin-left:1.5em">

Run 2026-09-20, **MATLAB R2024b**. Baseline: HEAD (`f35debf48`), working tree clean at the start, so `git show HEAD:<path>` gave the pre-move `old` copy for every file — taken for all 78 tracked `.m` files *before* the first `git mv`. Scope was the whole repo; the only edits made were `git mv`, `function` lines, call sites, and name references in comments and docs.

**What moved.** All 30 file renames in section 3.1.1's map, plus `+lib/downsample_old.m`'s `function` line (no move). 22 identifier renames in total (the 30 files collapse to 22 distinct names, since the nine `+experiment/+run` names each exist in both trees).

**Collision check, re-run at execution time** (`which('<new>', '-all')`, R2024b, before any move). Every new name came back empty except the three case-only renames, which resolved only to the file being renamed itself — Windows' case-insensitive `which` finding `Re.m` for `re` and so on. No name shadows a builtin, a toolbox function, or anything reachable on the path:

```
rp:0  re:1(Re.m)  rs:1(Rs.m)  rs_new:1(Rs_new.m)  check_tlst:0  check_xy:0
find_bin:0  find_xy:0  demo_mk_trl_points:0  display_level_start:0
fixation_interval:0  give_feedback:0  load_current_session:0  load_stimuli:0
response_interval:0  run_experiment:0  save_current_level:0  stimulus_interval:0
gamma_correct:0  monitor_degrees_to_pixels:0  compute_p_clipped:0  downsample_old:0
```

**`check_stage1` over all 74 in-scope files — verbatim:**

```
rename bijection: OK (22 entries)
in-scope .m files found: 74

FAIL  +experiment/+discriminate/+prep/setup_experiment.m
FAIL  +experiment/+discriminate/+run/load_current_session.m
FAIL  +experiment/+discriminate/+run/load_stimuli.m
FAIL  +experiment/+discriminate/+run/run_experiment.m
FAIL  +experiment/+grouping/+prep/setup_experiment.m
FAIL  +experiment/+grouping/+run/load_current_session.m
FAIL  +experiment/+grouping/+run/load_stimuli.m
FAIL  +experiment/+grouping/+run/run_experiment.m
FAIL  +grouping/mk_masks.m
FAIL  +grouping/mk_texseg_session.m
FAIL  +lib/texture_patch.m

check_stage1: 63 / 74 pass, 11 fail

-- auxiliary check on the 11 failures: reverse-rename including
   dot-qualified occurrences (lookbehind dropped only for these files)
  +experiment/+discriminate/+prep/setup_experiment.m      true
  +experiment/+discriminate/+run/load_current_session.m   true
  +experiment/+discriminate/+run/load_stimuli.m           true
  +experiment/+discriminate/+run/run_experiment.m         false
  +experiment/+grouping/+prep/setup_experiment.m          true
  +experiment/+grouping/+run/load_current_session.m       true
  +experiment/+grouping/+run/load_stimuli.m               true
  +experiment/+grouping/+run/run_experiment.m             false
  +grouping/mk_masks.m                                    true
  +grouping/mk_texseg_session.m                           true
  +lib/texture_patch.m                                    true
auxiliary: 9 / 11 pass
```

**All 11 failures are the documented package-qualified case, and the check was not loosened.** `check_stage1.m:30`'s lookbehind `(?<![A-Za-z0-9_.])` refuses to reverse-rename a name preceded by a `.`, so a file whose only rename sites are `lib.gamma_correct(...)`, `grouping.find_bin(...)`, `@experiment.grouping.run.load_stimuli` etc. fails on a correct edit, by design. Each of the 11 was verified two ways instead: by reading its diff line by line (all 11 contain nothing but the expected `old.name` → `new.name` substitution — no other token on any changed line), and by a separate auxiliary script that reverse-renames with the lookbehind dropped. The auxiliary script is a one-off in the scratch directory; `tools/check_stage1.m` is untouched.

**The two auxiliary-check "false" results are the auxiliary script's own artefact, not a real diff.** Both `run_experiment.m` files call the external `vislab.psychframework.run_experiment(ExpSettings, hooks)` — a name that is *already* `run_experiment` and has nothing to do with our rename. Dropping the lookbehind reverse-renames that external call to `vislab.psychframework.runExperiment` too, which the old file never had. Re-running the same comparison with that one fully-qualified external call masked out returns `1` for both files. This is worth remembering: **`run_experiment` is now the name of both this repo's `experiment.{discriminate,grouping}.run.run_experiment` and the shared `vislab.psychframework.run_experiment` it delegates to.** They live in different packages so MATLAB dispatch is unambiguous, but any future text-level rename tooling has to distinguish them.

**Golden-harness replay: passes unchanged.** `golden_harness('replay', 'tools/golden_ref.mat')` asserts clean and prints `REPLAY PASSED`. Expected — these are pure renames — and it confirms the three call expressions changed in `tools/golden_harness.m` (`grouping.fnd_bin`→`find_bin`, `chk_xy`→`check_xy`, `chktlst`→`check_tlst`) still reach the same functions. Per step 0's decision 1, the `golden.*` struct **field names were left untouched**; they already used the post-rename spelling, so `golden_ref.mat` is still valid and was not recaptured.

**The four sweeps `check_stage1` cannot do.**

1. **Package-qualified call sites.** 11 files, listed above; all verified by reading the diff, plus the auxiliary reverse-rename. The complete set of package-qualified sites touched: `lib.gamma_correct` (×9), `lib.monitor_degrees_to_pixels` (×5), `lib.compute_p_clipped` (×1), `grouping.find_bin` (×2), `grouping.find_xy` (×2), `grouping.check_xy` (×2), `grouping.check_tlst` (×1), `@experiment.{discriminate,grouping}.run.load_stimuli` (×2), and the 16 `experiment.{discriminate,grouping}.run.*` hook assignments plus 4 `load_current_session` calls inside the two `run_experiment.m` files.
2. **References outside `.m` files.** One real hit: `README.md:82` named the dangling reference as `Rp`; updated to `rp`. Nothing in `CITATION.cff`, `.gitignore`, or `.claude/settings.json`. In this plan document, the six *current-state* pointers that named a renamed file were updated (S1.1, S2.1, B1.2, B3.2, O3.2, O3.3); the rename map in 3.1.1, S2.3's "(formerly `Rp_win.m`)", and the section 2 survey measurements were deliberately **left naming the old files**, because those are a historical record of what was found, not pointers to current files — section 2 already carries its own "re-measure before trusting this" caveat and Stage 6's 0.6.4 re-checks it. `.mat`/`.fig`/`.pptx` binaries match `Rp` on a byte scan, but they are frozen out-of-scope artifacts and no `save`/`load` string literal was touched.
3. **Dynamic references — documented negative.** Grepping every `.m` file for `feval`, `str2func`, `which(`, `exist(`, and `help <name>` returns only three sites, none of which names a renamed function: `+lib/create_pink_noise_line.m:4` (`exist('alpha','var')`), and `setup.m:98,110,131`, which probe external add-on functions (`gx2cdf`/`gx2pdf`/`gx2inv`) by string. No renamed name appears as a quoted string anywhere in the repo.
4. **Case-only renames on Windows.** `Re.m`→`re.m`, `Rs.m`→`rs.m`, `Rs_new.m`→`rs_new.m` each went through a temp name (`git mv Re.m tmp_re.m && git mv tmp_re.m re.m`). The nine `+experiment/+run` renames and the three `+lib` camelCase renames technically differ by more than case, but were put through the same two-step to be safe, since a case-insensitive filesystem can still collide on an intermediate state. `git ls-files` and the on-disk listing both show `re.m`, `rp.m`, `rs.m`, `rs_new.m` in lowercase, and `git status` records all 30 as `R` (rename), so history follows every file.

**Decisions made here that bind later tranches.**

1. **A header's uppercase self-name follows the file.** Four files carried a MATLAB-style `%FUNCTIONNAME ...` first comment line naming themselves in caps; those were updated in step with the rename (`%LOADCURRENTSESSION`→`%LOAD_CURRENT_SESSION` in both trees, `%GAMMACORRECT`→`%GAMMA_CORRECT`, `%MONITORDEGREESTOPIXELS`→`%MONITOR_DEGREES_TO_PIXELS` twice). Whether to keep that shout-caps convention at all is a header-shape question for tranche 0.1.2, not a rename question — this step only kept the existing convention *correct*.
2. **Historical mentions of deleted code keep their old names.** `run_experiment.m:9-10` in both trees says "The old runExperiment + runLevel + runTrial were retired in favour of this shared harness". `runLevel` and `runTrial` no longer exist anywhere, so this sentence names *deleted legacy functions*, not current files; renaming `runExperiment` inside it would falsely imply the retired thing was called `run_experiment`. Left as written. Later tranches rewriting these headers should keep that distinction: rename a reference to a file that still exists, leave a reference to one that doesn't.
3. **Prose uses of a word that happens to be a function name are not renamed.** `+lib/downsample_old.m` lines 3, 29, 31 say "downsample" as an English verb describing the operation. Only the `function` line changed. The same rule applies wherever a later tranche meets `filter`, `contour`, or `patch` in a sentence.
4. **`mk_*` stays, and this is now settled.** The 11 `mk_*` files were re-confirmed untouched, per section 3.1.1. Later tranches treat `mk_` as the cluster-C verb prefix and do not relitigate it.
5. **No file-local variable was renamed, even where it was obviously wrong.** `+lib/texture_patch.m:41` still reads `pClipped = lib.compute_p_clipped(ptch);` — the camelCase *variable* is tranche 0.1.2's job. `re.m`/`rs.m`/`rs_new.m`/`rp.m` still return `Reout`/`Rsout`/`Rpout`; those are tranche 0.1.5's. Leaving them creates a deliberate, temporary mismatch between a lowercase function and a TitleCase output variable.

**Deliberately left alone.**

- The README's stale layout section (`edgecode/`, `+stats/`, `CLEANUP.md`, and the two `CLEANUP.md` links under "Documentation") — none of those exist on disk. Pre-existing and unrelated to any rename, already recorded in section 2; still awaiting tranche 0.1.9 or a standalone doc fix.
- `README.md:82` still lists `bare rp`/`Rh` as a *pending dangling reference*. After this rename `rp` resolves (that half of B2.2 is now moot); only `Rh` is still dangling. Rewording that bullet is a content edit, not a rename, so only the name was changed.
- Every `save`/`load` string literal and every zone-3 frozen name (section 3.1.1) — untouched, confirmed by the diff containing no changed line inside a string literal.

**Bugs, optimizations, structure.** Nothing new found. This step read only `function` lines and call sites, not function bodies, so it is not a meaningful negative on bug-hunting — the tranches that actually read these files will say. No commented-out block was reached (none of this step's edits touched one), so section 3.1.4 gains no rows here.

**Baseline note for later tranches.** The working tree is clean again after this step's commit, so **HEAD remains a valid `check_stage1` baseline** — but the file *paths* have changed, so a later tranche must take its baseline from the post-rename HEAD, not from `f35debf48`.

</div>

</details>

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h4 style="display:inline; margin:0; font-size:0.98em">3.1.4 Commented-out code — triage verdicts</h4></summary>

<div style="margin-left:1.5em">

One row per block, added as each stage 1 tranche reaches the file it's in. The rough inventory from the survey (section 2) — filled in with real verdicts only once each tranche runs:

| block | file:lines | tranche | what the surrounding code says it was for | verdict |
|---|---|---|---|---|
| disabled contour-property computation | `+lib/edge_props_stim.m:275-534` | 2 (`+lib`) | not yet triaged | — |
| old grads loop | `+lib/edge_props_stim.m:75-94` | 2 (`+lib`) | not yet triaged | — |
| two dead PCA variants | `+lib/edge_props_stim.m:113-117,135-138` | 2 (`+lib`) | not yet triaged | — |
| disabled `eps2` contour-stats section + figure calls | `re.m:122-154` | 5 (root cluster C) | not yet triaged | — |
| entire alternative implementation | `rs_new.m:22-59` | 5 (root cluster C) | not yet triaged | — |
| disabled display loop | `+grouping/mk_texseg_stim_points.m:130-146` | 4 (`+grouping` scripts) | not yet triaged | — |
| disabled display loop (duplicate) | `+grouping/mk_texseg_stim_shape_old.m:123-139,166-173` | 4 (`+grouping` scripts) | not yet triaged | — |
| disabled loop | `+grouping/tex_regions.m:78-89` | 4 (`+grouping` scripts) | not yet triaged | — |
| figure blocks | `+grouping/mk_masks.m:68-72,83-87` | 3 (`+grouping` helpers) | not yet triaged | — |
| disabled sections | `+lib/target_mask.m:52-92` | 2 (`+lib`) | not yet triaged | — |
| disabled block | `edge_dv.m:16-22` | 5 (root cluster C) | not yet triaged | — |
| normalization + display | `+lib/steerable_filter.m:23-30` | 2 (`+lib`) | not yet triaged | — |
| small blocks | `+general/simulate_discrimination.m:16-18,307-317` | 8 (`+general`) | not yet triaged | — |
| duplicated small blocks | `+experiment/+grouping/+run/fixationInterval.m:24-27`, `+experiment/+{discriminate,grouping}/+run/giveFeedback.m,displayLevelStart.m,loadCurrentSession.m` (1-4 lines each) | 6 (`+experiment/+run`) | not yet triaged | — |
| small block | `+experiment/+grouping/+prep/setup_subject.m:10-15` | 7 (`+experiment/+prep`) | not yet triaged | — |

</div>

</details>

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h3 style="display:inline; margin:0; font-size:1.05em">3.2 · Stage 2 · Tidying</h3></summary>

<div style="margin-left:1.5em">

**Coverage gaps found while extending the golden harness, and their resolutions:**

- All of `+experiment` (tranches 6-7) requires Psychtoolbox and a live display — no headless golden harness is possible; every file in these tranches gets pattern-check-only verification for Stage 2.
- `+general` (tranche 8) requires either the ~19 GB natural-image set or `exp_files`/Brodatz data whose presence on the execution machine isn't confirmed — pattern-check-only unless that data turns out to be available, in which case revisit.
- `+lib/texture_patch.m`, `+lib/edge_props_stim.m`, and the root cluster-C files that consume real images (`re.m`, `rs.m`, `rs_new.m`, `rp.m`, `edge_dv.m`, `contour_blur_estimation.m`, `texture_grouping.m`) — pattern-check-only for the same reason, unless a small synthetic-image stand-in turns out to exercise them faithfully enough (decide this when tranches 2 and 5 actually run).
- Everything else — `config()`, and the pure `+grouping`/`+lib` functions listed in section 1's harness-coverage note — gets both pattern-check and golden-output verification.

**Per-tranche work log:** not yet run.

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h3 style="display:inline; margin:0; font-size:1.05em">3.3 · Stage 3 · Structure</h3></summary>

<div style="margin-left:1.5em">

Not yet run.

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h3 style="display:inline; margin:0; font-size:1.05em">3.4 · Stage 4 · Bugs</h3></summary>

<div style="margin-left:1.5em">

Not yet run.

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h3 style="display:inline; margin:0; font-size:1.05em">3.5 · Stage 5 · Speed</h3></summary>

<div style="margin-left:1.5em">

Not yet run.

| item | re-triage | before | after | output check | kept? |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

</div>

</details>

<details style="margin:0.7em 0 0.7em 1.5em">
<summary><h3 style="display:inline; margin:0; font-size:1.05em">3.6 · Stage 6 · Closing</h3></summary>

<div style="margin-left:1.5em">

Not yet run.

</div>

</details>

</details>
