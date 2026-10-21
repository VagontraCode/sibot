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

### Phase 1 — Correct RC design (EC2 and BAEL), with tests ✅
Engine: `packages/sibot_engine` (pure Dart), 106 tests against hand calculations.
- [x] Materials: concrete and steel design values per code (EC2 αcc = 1.0, γc = 1.5; BAEL fbu, ft28)
- [x] Beam: ULS bending (singly and doubly reinforced), shear (EC2 variable strut; BAEL τu), deflection by span/depth, bar and link selection
- [x] Beam SLS: cracked-section stresses, EC2 crack width (7.3.4) and σs ≤ 0.8 fyk; BAEL σbc and cracking classes (A.4.5)
- [x] Column: N–M interaction (strain compatibility, any section), EC2 nominal curvature, BAEL α method and A.4.4 second order
- [x] Column: biaxial bending (EC2 5.8.9(4)), circular sections
- [x] Slabs: one-way and two-way (BAEL Annexe E3), simple or continuous (A.8.2.32), shear without links, deflection
- [x] Slabs: punching under columns / point loads (EC2 6.4 incl. reinforcement, BAEL A.5.2.42)
- [x] Footings: isolated (eccentric), strip, combined two-column footing with V/M diagrams; punching
- [x] Footings: EC7 Annex D bearing resistance from soil parameters (drained / undrained, DA2)
- [x] Retaining wall: EC7 EQU overturning and DA2 sliding (EC2 code) or global FS 1.5 (BAEL); stem, toe and heel design; iterative pre-design
- [x] Tools: bearing & settlement (EC7), section properties (rect, circle, hollow, I, T), quantities (concrete, formwork, rebar)
- [ ] Each module checked against at least 2 published worked examples per code (and the user's RSA models) → then remove the Beta banner
- [ ] Later: continuous beams (with Phase 2 analysis), edge/corner punching, combined footing widening optimisation

### Phase 2 — 2D FEM analysis (core RSA feature) ✅ (Beta)
- [x] Engine: 2D beam and truss elements, hinges (static condensation), supports and springs, banded Cholesky with RCM renumbering; analysis in a background isolate
- [x] Loads: nodal, uniform / trapezoidal / partial distributed (global, local, projected), point loads on members, self-weight
- [x] Load cases (G, Q, snow, wind), automatic EN 1990 and BAEL combinations, ULS envelopes
- [x] Model editor: touch canvas with pan/zoom, grid snapping, node / member / support / load tools, undo/redo, autosave, properties panel (side panel on tablets)
- [x] Wizards: continuous beam, multi-bay multi-storey frame, Pratt / Howe / Warren trusses
- [x] Results: deformed shape, N/V/M diagrams drawn on the tension side, reactions, per-member values and diagrams, envelope
- [x] Verification: 19 closed-form benchmarks (cantilever, simple / fixed / continuous beams, propped cantilever, Kleinlogel portal, truss, hinge, spring, inclined member, equilibrium) + template tests; 2091-node frame in ~0.55 s
- [ ] Compare with the user's RSA models, then remove the Beta banner
- [ ] Editor: point loads and partial / trapezoidal loads in the UI (engine supports them), node dragging, copy / array tools
- [x] Send member forces to the RC design modules (Phase 3)

### Phase 3 — Analysis-to-design link and the other materials
- [x] Send members from the FEM model straight to RC and steel design, which designs from the envelopes automatically
- [x] Section library: IPE, HEA, HEB, with properties computed from the dimensions and checked against the tables (A, Iy, Wpl,y within 1 %)
- [ ] Section library: HEM, UPN, L, CHS, RHS, SHS
- [x] Steel EC3 (Beta): classification, resistances with M+V+N, flexural buckling, LTB (6.3.2.3), Annex B interaction, lightest-section search
- [ ] Steel EC3: minor-axis bending, utilisation colour map on the frame
- [x] Timber EC5 (Beta): C16–C30 and GL24h–GL32h, kmod/kh/kdef, bending with kcrit, shear, column buckling, 6.23/6.24/6.35 interaction, deflection with creep
- [ ] Timber EC5: bearing perpendicular to grain, notches, connections
- [x] Masonry EC6 (Beta): fk = K fb^0.7 fm^0.3, effective height, slenderness ≤ 27, end and mid-height reduction (Annex G) with creep
- [ ] Masonry EC6: lateral load, concentrated loads, cavity walls
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
