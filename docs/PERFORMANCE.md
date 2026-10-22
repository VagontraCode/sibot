# Performance

How heavy computations are kept off the UI thread, what they cost, and the
budgets we aim for on phones. Re-run the measurements with:

```
cd packages/sibot_engine
dart run benchmark/bench.dart
```

## Measured timings (desktop, Dart 3.13, JIT, 2026-10-22)

| Model | Static (all cases) | Modal, 12 modes | Spectrum X + torsion | Buckling αcr | P-Δ (ULS) |
|---|---|---|---|---|---|
| 3×2 bays × 4 storeys, 116 members, 156 equations | 31 ms | 67 ms | 44 ms | 145 ms | 9 ms |
| 5×4 bays × 8 storeys, 632 members, 744 equations | 52 ms | 158 ms | 145 ms | 250 ms | 86 ms |
| 6×6 bays × 12 storeys, 1 596 members, 1 800 equations | 167 ms | 707 ms | 338 ms | 719 ms | 519 ms |

| Plate (ACM elements) | Time (ULS + SLS share one factorisation) |
|---|---|
| 16 × 16 | 20 ms |
| 30 × 30 | 38 ms |
| 40 × 40 (largest allowed) | 81 ms |

These timings were measured on the development PC, not on a phone. Expect a
low-end Android phone (4 efficiency cores, release build, AOT) to be roughly
3–8 times slower. **Measuring on real low-end devices is still to do**
(see the roadmap).

## Budgets

| Action | Target on a low-end phone | Status from the desktop timings |
|---|---|---|
| Open a 3D model (static results) | < 1 s | 0.17 s desktop for 1 800 equations → within budget |
| Modes tab | < 4 s | 0.7 s desktop for the largest building |
| Seismic run (X + Y, torsion) | < 6 s | 2 × (modal + spectrum) ≈ 2.1 s desktop |
| Buckling tab | < 5 s | 0.7 s desktop |
| Plate 40 × 40 | < 1 s | 0.08 s desktop |
| UI thread | no frame longer than 16 ms during a calculation | all heavy work runs in isolates |

## What keeps the app fast and light on battery

- **Isolates.** The 2D and 3D frame analyses, modes, spectra, P-Δ, buckling,
  plates and slope stability run in `Isolate.run`; the UI keeps animating and
  the calculate button shows a spinner (`DesignFormNotifier.computeAsync`).
- **On demand.** A 3D model opens with its static results only; modes are
  computed when the Modes tab (or the seismic mass) needs them, buckling when
  its tab is opened, and both when a PDF note is exported. Results are cached
  by Riverpod per model and code, and recomputed only when the model changes
  (provider keys are the model's JSON).
- **One factorisation.** The banded Cholesky factor of K (RCM numbering) is
  reused for every load case, the modes (subspace iteration), the spectrum
  responses, the buckling power iteration and the two plate load sets.
- **Tolerances matched to engineering needs.** Modal eigenvalues converge to
  1e-8 (frequencies to ~5e-9), αcr to 1e-7. Tightening them changed nothing
  visible but cost up to 3× more iterations.
- **Animation only when useful.** The 3D view repaints on interaction; the
  only continuous animation is the mode shape in the Modes tab, stopped as
  soon as another tab is shown.

## Memory

- Banded storage: `n × (bandwidth + 1)` doubles. For the 1 800-equation
  building, about 2.6 MB (bandwidth ≈ 180 with rigid floors).
- Each result stores 11 stations per member (10 doubles each): about
  0.15 MB per combination for 1 600 members. A model with 6 combinations and
  12 modes stays below 10 MB.
- Plates: 40 × 40 mesh, 5 043 equations, bandwidth ≈ 125 → 5 MB for the
  factor.

## Known limits

- Plates are limited to 40 × 40 elements and frames are best kept under
  ~2 000 equations on phones; larger models work but are slower.
- The buckling power iteration slows down when several buckling modes have
  almost the same load factor (typical of symmetric buildings); a subspace
  method would help.
