# Sibot Engineering Suite — Roadmap

Goal: a phone- and tablet-first structural engineering suite in the spirit of Robot Structural
Analysis (RSA): model → analyse (FEM) → design members to code → print a calculation note.

Decisions (2026-10-20):
- Codes: Eurocode (EC0, EC1, EC2, EC3, EC5, EC6, EC7, EC8) and BAEL 91/99 + PS92
- Solver: 2D first, then 3D, then plates and modal/seismic analysis
- Materials: reinforced concrete, steel, timber, masonry
- Languages: English + French
- Devices: phones and tablets (Android and iPad)

---

## 1. Assessment of the current app (v0.1.0, ~8,600 lines of Dart)

### What is good
- Clean Flutter setup: feature folders, Riverpod, go_router, Hive, PDF/printing. `flutter analyze` is clean.
- Useful scope: projects, RC modules, field tools (photo log, daily report, punch list), reports, reference.
- Material 3 theme with light and dark mode; EN/FR locales declared.

### Critical problems (fix before anything else)
| # | Problem | Where |
|---|---------|-------|
| 1 | **All saved calculations are deleted on every app start** (`Hive.deleteBoxFromDisk(calculationsBox)`) | `lib/core/services/core_services.dart` |
| 2 | Footing area is ~100× too large: `N·SF / (q/100)`. 500 kN on 200 kPa gives 750 m² | `calculation_engine.dart` `calculateRequiredFootingArea` |
| 3 | Beam bending: K limit is 0.48 (EC2 is 0.167). For K > 0.28 the lever-arm square root goes negative → NaN | `designBeamFlexure` |
| 4 | Beam shear: V_c is in kN but V_Ed is in N, so the shear check is off by 1000× | `designBeamShear` |
| 5 | Bearing capacity: wrong Nc, Nq and Nγ (Nγ is negative for φ < 45°), and the q-term has a stray 0.5 | `advance_analysis.dart` |
| 6 | Column design uses the wrong resistance formula; "slenderness" is height/diameter, not λ = l₀/i | `designColumn` |
| 7 | EC8 spectrum: soil factors S and T_B/T_C/T_D are wrong, the behaviour factor q is missing from the design spectrum, and the interaction diagram is not physically valid | `advance_analysis.dart` |
| 8 | "Structure analysis" is not an analysis: the engine applies simply-supported formulas and the page only shows a snackbar | `structure_analysis/` |
| 9 | 8 module pages are not routed and cannot be reached: structure analysis, seismic, geotechnical, wind/snow, pile slab, section properties, materials, septic tank | `config/router.dart` |
| 10 | No tests. Engineering code without verification tests is unsafe to use for real designs | — |

### Structural/technical debt
- Engineering code is mixed into UI providers (e.g. the moment `wL²/8` is computed in `beams_provider.dart`).
- Results are passed as `Map<String, dynamic>`, which gives no type safety and no units.
- Mixed units (mm/m, N/kN) without a unit system, which caused bugs 2 and 4.
- Riverpod `legacy` StateNotifier API; Hive 2.x is no longer maintained.
- Bottom navigation only, so no tablet layout. `TextScaler.noScaling` disables accessibility text sizing.
- UI strings are hard-coded in English despite the FR locale.
- Not under git version control.

**Verdict:** the app shell is a good start. The engineering core has to be rewritten and verified,
because the current numbers are wrong. They should not be used for real designs.

---

## 2. Target architecture

```
sibot/
├─ packages/
│  ├─ sibot_engine/        Pure Dart, no Flutter. 100% unit-tested.
│  │  ├─ units/            Quantity types (Force, Length, Stress…), SI internally
│  │  ├─ fem/              Model, elements, assembler, sparse solver, results
│  │  ├─ loads/            Load cases, EC0 / BAEL combinations, EC1 wind/snow, EC8 / PS92 spectra
│  │  ├─ design/
│  │  │  ├─ concrete/      EC2 + BAEL (beams, columns, slabs, footings, walls)
│  │  │  ├─ steel/         EC3 (members, buckling, LTB, basic connections)
│  │  │  ├─ timber/        EC5
│  │  │  ├─ masonry/       EC6
│  │  │  └─ geotech/       EC7 (bearing, sliding, settlement, retaining walls)
│  │  └─ library/          Sections (IPE, HEA, HEB, UPN, CHS, RHS…), materials, rebar
│  └─ sibot_report/        Calculation-note builder (PDF): formulas + code clauses
└─ lib/                    Flutter app (UI only: editors, viewers, state)
```

Principles:
- **The engine is pure Dart.** It can be tested, run in an `Isolate` (UI never freezes) and reused later on desktop or web.
- **Code-agnostic interfaces** such as `ConcreteDesignCode`, implemented by `Ec2` and `Bael91`, so each design module supports both codes.
- **Typed results.** Each result carries its value, unit, the check ratio (utilisation) and the code clause, so reports are generated automatically.
- **Verification suite.** Each module is checked against textbook examples and against RSA results you provide.

### FEM solver (the RSA-like core)
- Direct stiffness method. Elements: 2D truss and 2D frame (3 DOF per node), later 3D frame (6 DOF), then plate/shell (DKMQ or MITC4) for slabs.
- Features: end releases (hinges), elastic supports and springs, member loads (UDL, point, trapezoidal, thermal), self-weight, nodal loads, imposed displacements.
- Performance: `Float64List` storage, Reverse Cuthill–McKee renumbering, banded/skyline Cholesky, solver running in an isolate. Target: a 2,000-node 2D model solves in under 1 s on a mid-range phone.
- Results: displacements, reactions, N/V/M (and T and M_y/M_z in 3D) along members, envelopes over combinations, and global equilibrium checks.
- Later: P-Δ (second order), linear buckling, modal analysis (subspace iteration), response spectrum with CQC (EC8 / PS92).

### Mobile and tablet UX
- Adaptive shell based on screen width:
  - under 600 dp: bottom navigation, single pane
  - 600–840 dp: navigation rail
  - over 840 dp: navigation rail plus two panes (model canvas | properties and results)
- Model editor: canvas with pan/zoom, grid snapping, node and bar drawing by touch, multi-select, undo/redo, and stylus/mouse/keyboard support on tablets.
- Structured wizards ("portal frame", "continuous beam", "truss") to build models fast on a phone.
- Results views: deformed shape, N/V/M diagrams, colour maps, tap on a member to see values, tables.
- Text scaling enabled; all strings in ARB files (EN/FR).

### Data
- Migrate from Hive 2.x to **drift (SQLite)**: projects, models stored as versioned JSON, calculations, field data.
- Model files can be exported and imported as `.sibot` (JSON) so they can be shared between phone and tablet.

---

## 3. Phased plan

Each phase ends with a usable app, passing tests, and a git tag.

### Phase 0 — Fix and foundation
- [x] `git init`, first commit of the current state
- [x] Remove the start-up deletion of all calculations (problem #1)
- [ ] Create `packages/sibot_engine` with the unit system and a test setup
- [x] Adaptive shell (bottom nav / rail / two panes) and allow text scaling
- [x] New design system: Inter + JetBrains Mono, light/dark theme, shared page, form and result components
- [x] Screen smoke test at phone and tablet sizes (`test/screens_smoke_test.dart`)
- [x] i18n with ARB files (EN/FR) and move existing strings into them (provider validation messages and number formatting move with the Phase 1 rewrite)
- [ ] Migrate Riverpod legacy APIs to `Notifier`/`AsyncNotifier`
- [x] Route or hide the 8 unreachable pages, with one entry point per module (hidden as "Phase N": they showed made-up results)
- [x] Settings: language, theme, default design code (national annex and units in Phase 1)

### Phase 1 — Correct RC design (EC2 and BAEL), with tests
Engine: `packages/sibot_engine` (pure Dart), 53 tests against hand calculations.
- [x] Materials: concrete and steel design values per code (EC2 αcc = 1.0, γc = 1.5; BAEL fbu, ft28)
- [x] Beam: ULS bending (singly and doubly reinforced), shear (EC2 variable strut; BAEL τu), deflection by span/depth (EC2 7.4.2, BAEL B.6.5.1), bar and link selection
- [ ] Beam: crack-width control, continuous beams (comes with Phase 2 analysis)
- [x] Column: N–M interaction (strain compatibility), EC2 nominal curvature, BAEL α method and A.4.4 second order
- [ ] Column: biaxial bending, circular sections
- [x] Slabs: one-way and two-way (BAEL Annexe E3), simple or continuous (A.8.2.32), shear without links, deflection
- [ ] Slabs: punching under point loads
- [x] Footings: isolated pad, eccentric load, BAEL struts and ties, EC2 bending and punching (6.4 with β)
- [ ] Footings: strip and combined footings; EC7 bearing resistance from soil parameters
- [x] Retaining wall: overturning, sliding, eccentricity, bearing (global FS 1.5), stem design, iterative pre-design
- [ ] Retaining wall: EC7 DA1/DA2 partial factors, heel and toe design
- [ ] Each module checked against at least 2 published worked examples per code (and the user's RSA models) → then remove the Beta banner

### Phase 2 — 2D FEM analysis (core RSA feature)
- [ ] Engine: 2D truss and frame elements, releases, supports and springs, member loads, sparse solver in an isolate
- [ ] Load cases, EC0 and BAEL combinations, envelopes
- [ ] Model editor (canvas, grid, snapping, undo) and the wizards
- [ ] Results: deformed shape, N/V/M diagrams, reactions, tables
- [ ] Verification: cantilever, fixed beam, continuous beam, portal frame and Pratt truss against closed-form solutions and RSA

### Phase 3 — Analysis-to-design link and the other materials
- [ ] Send members from the FEM model straight to RC design, which designs from the envelopes automatically
- [ ] Section library: IPE, HEA, HEB, HEM, UPN, L, CHS, RHS, SHS (JSON assets)
- [ ] Steel EC3: cross-section classification, resistances, flexural and lateral-torsional buckling, interaction checks, utilisation colour map
- [ ] Timber EC5: service classes, k_mod, members in bending and compression
- [ ] Masonry EC6: vertical load capacity of walls, slenderness
- [ ] EC1 wind and snow, EC8 / PS92 equivalent lateral force method

### Phase 4 — 3D frames and dynamics
- [ ] 3D frame element (6 DOF), rigid diaphragms, 3D viewer (orbit, pan, zoom)
- [ ] Modal analysis, then response spectrum (EC8 / PS92) with CQC combination
- [ ] P-Δ and linear buckling

### Phase 5 — Plates, polish and performance
- [ ] Plate elements for slabs and rafts, contour maps, and reinforcement from Wood–Armer moments
- [ ] Full calculation notes in PDF (EN/FR) with diagrams and code clauses
- [ ] `.sibot` and DXF geometry import/export
- [ ] Performance profiling on low-end Android, and battery and memory budgets

---

## 4. Important note
This is engineering software. Each module must pass its verification tests before it is shown
as validated in the app. Until then the UI marks it **"Beta — verify independently"**.
