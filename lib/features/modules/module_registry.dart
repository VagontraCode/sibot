import 'package:flutter/material.dart';
import 'package:sibot/l10n/l10n.dart';

enum ModuleStatus {
  /// Usable; exact formulas that need no independent verification
  /// (geometry, quantities).
  available,

  /// Usable, but calculations are not yet verified (Phase 1 rewrite pending).
  beta,

  /// Planned; not reachable yet.
  comingSoon,
}

enum ModuleCategory {
  analysis(Icons.hub_outlined),
  concrete(Icons.view_in_ar_outlined),
  steel(Icons.horizontal_split_outlined),
  timber(Icons.forest_outlined),
  masonry(Icons.grid_view_outlined),
  geotech(Icons.terrain_outlined),
  loads(Icons.air_outlined),
  tools(Icons.handyman_outlined);

  final IconData icon;
  const ModuleCategory(this.icon);

  String label(AppLocalizations l) => switch (this) {
    analysis => l.catAnalysis,
    concrete => l.catConcrete,
    steel => l.catSteel,
    timber => l.catTimber,
    masonry => l.catMasonry,
    geotech => l.catGeotech,
    loads => l.catLoads,
    tools => l.catTools,
  };
}

@immutable
class EngModule {
  final String id;
  final IconData icon;
  final ModuleCategory category;

  /// Sub-route under `/projects/:projectId/`.
  final String? route;
  final ModuleStatus status;

  /// Roadmap phase that delivers this module (for "coming soon" modules).
  final int? phase;

  const EngModule({
    required this.id,
    required this.icon,
    required this.category,
    required this.status,
    this.route,
    this.phase,
  });

  bool get isAvailable => status != ModuleStatus.comingSoon && route != null;

  String title(AppLocalizations l) => switch (id) {
    'frame2d' => l.modFrame2d,
    'frame3d' => l.modFrame3d,
    'beam' => l.modBeam,
    'column' => l.modColumn,
    'slab' => l.modSlab,
    'footing' => l.modFooting,
    'retaining-wall' => l.modRetainingWall,
    'steel-member' => l.modSteelMember,
    'timber-member' => l.modTimberMember,
    'masonry-wall' => l.modMasonryWall,
    'bearing' => l.modBearing,
    'slope' => l.modSlope,
    'wind-snow' => l.modWindSnow,
    'seismic' => l.modSeismic,
    'sections' => l.modSections,
    'quantities' => l.modQuantities,
    'pile-cap' => l.modPileCap,
    'septic' => l.modSeptic,
    _ => id,
  };

  String subtitle(AppLocalizations l) => switch (id) {
    'frame2d' => l.modFrame2dSub,
    'frame3d' => l.modFrame3dSub,
    'beam' => l.modBeamSub,
    'column' => l.modColumnSub,
    'slab' => l.modSlabSub,
    'footing' => l.modFootingSub,
    'retaining-wall' => l.modRetainingWallSub,
    'steel-member' => l.modSteelMemberSub,
    'timber-member' => l.modTimberMemberSub,
    'masonry-wall' => l.modMasonryWallSub,
    'bearing' => l.modBearingSub,
    'slope' => l.modSlopeSub,
    'wind-snow' => l.modWindSnowSub,
    'seismic' => l.modSeismicSub,
    'sections' => l.modSectionsSub,
    'quantities' => l.modQuantitiesSub,
    'pile-cap' => l.modPileCapSub,
    'septic' => l.modSepticSub,
    _ => '',
  };
}

const modules = <EngModule>[
  EngModule(
    id: 'frame2d',
    icon: Icons.hub_outlined,
    category: ModuleCategory.analysis,
    route: 'frame2d',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'frame3d',
    icon: Icons.view_in_ar_outlined,
    category: ModuleCategory.analysis,
    status: ModuleStatus.comingSoon,
    phase: 4,
  ),
  EngModule(
    id: 'beam',
    icon: Icons.straighten,
    category: ModuleCategory.concrete,
    route: 'beam',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'column',
    icon: Icons.view_column_outlined,
    category: ModuleCategory.concrete,
    route: 'column',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'slab',
    icon: Icons.layers_outlined,
    category: ModuleCategory.concrete,
    route: 'slab',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'footing',
    icon: Icons.foundation,
    category: ModuleCategory.concrete,
    route: 'footing',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'retaining-wall',
    icon: Icons.stairs_outlined,
    category: ModuleCategory.concrete,
    route: 'retaining-wall',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'steel-member',
    icon: Icons.horizontal_split_outlined,
    category: ModuleCategory.steel,
    route: 'steel-member',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'timber-member',
    icon: Icons.forest_outlined,
    category: ModuleCategory.timber,
    route: 'timber-member',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'masonry-wall',
    icon: Icons.grid_view_outlined,
    category: ModuleCategory.masonry,
    status: ModuleStatus.comingSoon,
    phase: 3,
  ),
  EngModule(
    id: 'bearing',
    icon: Icons.terrain_outlined,
    category: ModuleCategory.geotech,
    route: 'bearing',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'slope',
    icon: Icons.landscape_outlined,
    category: ModuleCategory.geotech,
    status: ModuleStatus.comingSoon,
    phase: 3,
  ),
  EngModule(
    id: 'wind-snow',
    icon: Icons.air_outlined,
    category: ModuleCategory.loads,
    status: ModuleStatus.comingSoon,
    phase: 3,
  ),
  EngModule(
    id: 'seismic',
    icon: Icons.waves_outlined,
    category: ModuleCategory.loads,
    status: ModuleStatus.comingSoon,
    phase: 3,
  ),
  EngModule(
    id: 'sections',
    icon: Icons.crop_square,
    category: ModuleCategory.tools,
    route: 'sections',
    status: ModuleStatus.available,
  ),
  EngModule(
    id: 'quantities',
    icon: Icons.calculate_outlined,
    category: ModuleCategory.tools,
    route: 'quantities',
    status: ModuleStatus.available,
  ),
  EngModule(
    id: 'pile-cap',
    icon: Icons.view_week_outlined,
    category: ModuleCategory.tools,
    status: ModuleStatus.comingSoon,
    phase: 3,
  ),
  EngModule(
    id: 'septic',
    icon: Icons.water_drop_outlined,
    category: ModuleCategory.tools,
    status: ModuleStatus.comingSoon,
    phase: 3,
  ),
];

EngModule? moduleByRoute(String route) {
  for (final m in modules) {
    if (m.route == route) return m;
  }
  return null;
}

EngModule? moduleById(String id) {
  for (final m in modules) {
    if (m.id == id) return m;
  }
  return null;
}
