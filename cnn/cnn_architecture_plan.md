# CNN Architecture & Training Plan

## Goal

Train the twin CNN to learn **texture statistics** from near/far natural-image labels, so
the rule transfers to Brodatz same/different discrimination. Target: mid-80s–90s.

## Bayesian anchors

Near/far ≈ 73–80%. Texture same/different ≈ 92.7%. These share one decision bound, but
only for order-invariant features (position-agnostic histograms/power spectrum) — that's
why the clean task scores higher despite training on the noisier one.

## Reading the plots

- `NatVal` plateauing ~0.78–0.80 is expected (near/far labels are noisy) — don't chase it.
- **Success = `BrodatzVal` rises above `NatVal`**, toward ~85–90%. Below or declining =
  the network is using non-texture, near/far-specific cues.
- Training accuracy → 100% = memorizing label noise.

## Design principles

1. **No early stopping.** Want a network that transfers well fully trained, not one
   cherry-picked at its Brodatz peak.
2. **No hand-defined Bayesian features.** The Bayesian model is already near-optimal on
   its own features, so feeding those in would teach the CNN nothing new. Constrain the
   *class* of features generically; let the CNN find its own.

## Current state

- **Data:** on-the-fly, non-repeating sampling is implemented and active —
  `+general/nat_image_to_A.m` (per-image processing), `+general/load_nat_A_pool.m` (builds
  the image pool once), `cnn/getTwinBatch_nat_live.m` (cuts fresh pairs each batch).
  `train_cnn.m` splits by **image**, not pair, and samples live.
- **Monitoring:** `NatVal` batch resampled fresh each check; training accuracy measured
  *before* the weight update (fresh-data, comparable to validation).
- **Architecture: C** (tiny pooling, ~9,600 params) is active — testing whether small
  capacity keeps the network confined to texture-like features. Not yet observed.

## Results log

- **Run 1** — arch. B (~600K, pooling) + fixed repeating data: Brodatz peaked ~0.77, fell
  to ~0.66. Didn't fix overfitting.
- **Run 2** — arch. B + on-the-fly data: memorization eliminated (train/NatVal plateau
  together ~0.80), but Brodatz still peaks ~0.78 then declines to ~0.68. Since data never
  repeats, this proves a genuine non-texture shortcut, not memorization.
- **Run 3** — arch. C + on-the-fly data: in progress.

## Lessons learned

- **Order-invariant pooling is necessary but not sufficient** — it removes spatial-layout
  shortcuts but not other non-texture cues (e.g. shared low-frequency shading between
  adjacent patches) that survive pooling because they're in *what's* detected, not *where*.
- **Contrast is not the shortcut.** Verified in source (`dv_spot_hist.m`, `ptch_norm.m`):
  the achromatic histogram keeps contrast; only center-surround/edge features are
  contrast-normalized. The CNN's `img/mean(img(:))` input already matches this.
- **Patches are already local** (64×64 ≈ 1°, matches Bayesian scale) — no need to shrink
  receptive fields further.

## Architecture reference

Conv stack (`conv → relu → pool` ×4) is shared; architectures differ in the embedding.

| arch | channels | embedding | merge | conv params |
|---|---|---|---|---|
| A — large/FC | 64‑128‑128‑256 | `fullyConnectedLayer(4096)` → `sigmoid` | 1×4096 | ~600K (+16.8M FC) |
| B — lean/pooling | 64‑128‑128‑256 | mean+std → 512-d, L2-norm (`poolStats`) | 1×512 | ~600K |
| C — tiny/pooling (**active**) | 8‑16‑16‑32 | mean+std → 64-d, L2-norm (`poolStats`) | 1×64 | ~9,600 |

B/C use `poolStats(forward/predict(net,X))` in `forwardTwin.m`/`predictTwin.m` instead of a
sigmoid on the raw map (sigmoid on all-positive ReLU output saturates). To switch
architectures: layer-stack ending + `fcWeights`/`fcBias` size in `train_cnn.m`, plus the
embedding line in `forwardTwin.m`/`predictTwin.m`.

## Open questions / next experiments

- Does Run 3 (arch. C) stop the Brodatz decline?
- If not: arch. A vs. B at full training — A's FC embedding can read spatial layout; if
  its Brodatz gap is worse, that confirms layout was part of the shortcut.
- Contrast-normalization ablation (empirical only — not expected to be the shipped fix).
- Match near/far pairs on a suspected low-level statistic at sampling time
  (`getTwinBatch_nat_live.m`) to remove that cue from the labels.

## Feature visualization (during training)

Add a live view of what the net is learning, refreshed on the existing every-50-iterations
schedule. Options, cheapest first:
1. **First-layer filter montage (recommended).** conv1 is 8 kernels of 5×5×1 — tiny images.
   Extract them from `net.Learnables` and show as a grid beside the accuracy plot; watch
   oriented edge/bar structure emerge. Near-zero cost. Caveat: only shows input-level
   features — a shortcut built in deeper layers or the pooling won't show here.
2. **Activation maps.** Push one fixed sample patch through the net each update and show
   each layer's channel responses (what fires where). More code and compute; reveals the
   deeper stack. Worth adding if conv1 looks texture-like yet transfer still fails.
3. **Embedding geometry.** Project the 64-d `poolStats` embeddings of a fixed same/diff set
   to 2D and animate how they separate. Shows the decision geometry, not features per se.

## Ruled out

- Fixed Bayesian front-end as feature source — CNN would learn nothing new.
- Shrinking receptive fields below patch size — already local enough.
- Early stopping on the Brodatz peak — hides the shortcut. (Still keep a Brodatz test split
  untouched by any decision, for the final number.)
- Trimming capacity to prevent memorization — moot; on-the-fly data already does that.
  (Arch. C is being tried for a different reason — see Current state.)

## Still open, low priority

Not implemented; expected to tidy the curve, not close the Brodatz gap alone:
1. Data augmentation (flips/rotations) in `getTwinBatch_nat_live.m`.
2. Weight decay on both `adamupdate` calls in `train_cnn.m`.
3. Dropout (~0.2–0.3) on the conv feature map.

## Verification

- Primary: `BrodatzVal` > `NatVal`, toward ~85–90%.
- Sanity: training accuracy stays near the ~78–80% plateau.
- Final number reported on a Brodatz split untouched by any architecture/checkpoint choice.
