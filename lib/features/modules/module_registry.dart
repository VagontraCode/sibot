import 'package:flutter/material.dart';

enum ModuleStatus {
  /// Usable, but calculations are not yet verified (Phase 1 rewrite pending).
  beta,

  /// Planned; not reachable yet.
  comingSoon,
}

enum ModuleCategory {
  analysis('Structural analysis', Icons.hub_outlined),
  concrete('Reinforced concrete', Icons.view_in_ar_outlined),
  steel('Steel', Icons.horizontal_split_outlined),
  timber('Timber', Icons.forest_outlined),
  masonry('Masonry', Icons.grid_view_outlined),
  geotech('Geotechnics', Icons.terrain_outlined),
  loads('Loads', Icons.air_outlined),
  tools('Tools', Icons.handyman_outlined);

  final String label;
  final IconData icon;
  const ModuleCategory(this.label, this.icon);
}

@immutable
class EngModule {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final ModuleCategory category;

  /// Sub-route under `/projects/:projectId/`.
  final String? route;
  final ModuleStatus status;

  /// Roadmap phase that delivers this module (for "coming soon" modules).
  final int? phase;

  const EngModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.status,
    this.route,
    this.phase,
  });

  bool get isAvailable => status != ModuleStatus.comingSoon && route != null;
}

const modules = <EngModule>[
  EngModule(
    id: 'frame2d',
    title: '2D Frame Analysis',
    subtitle: 'Frames, trusses, continuous beams',
    icon: Icons.hub_outlined,
    category: ModuleCategory.analysis,
    status: ModuleStatus.comingSoon,
    phase: 2,
  ),
  EngModule(
    id: 'frame3d',
    title: '3D Frame Analysis',
    subtitle: 'Space frames, modal analysis',
    icon: Icons.view_in_ar_outlined,
    category: ModuleCategory.analysis,
    status: ModuleStatus.comingSoon,
    phase: 4,
  ),
  EngModule(
    id: 'beam',
    title: 'Beam',
    subtitle: 'Bending, shear',
    icon: Icons.straighten,
    category: ModuleCategory.concrete,
    route: 'beam',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'column',
    title: 'Column',
    subtitle: 'Axial, slenderness',
    icon: Icons.view_column_outlined,
    category: ModuleCategory.concrete,
    route: 'column',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'slab',
    title: 'Slab',
    subtitle: 'One-way slab',
    icon: Icons.layers_outlined,
    category: ModuleCategory.concrete,
    route: 'slab',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'footing',
    title: 'Footing',
    subtitle: 'Isolated, combined',
    icon: Icons.foundation,
    category: ModuleCategory.concrete,
    route: 'footing',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'retaining-wall',
    title: 'Retaining Wall',
    subtitle: 'Stability, pre-sizing',
    icon: Icons.stairs_outlined,
    category: ModuleCategory.concrete,
    route: 'retaining-wall',
    status: ModuleStatus.beta,
  ),
  EngModule(
    id: 'steel-member',
    title: 'Steel Member',
    subtitle: 'EC3 checks, buckling',
    icon: Icons.horizontal_split_outlined,
    category: ModuleCategory.steel,
    status: ModuleStatus.comingSoon,
    phase: 3,
  ),
  EngModule(
    id: 'timber-member',
    title: 'Timber Member',
    subtitle: 'EC5 checks',
    icon: Icons.forest_outlined,
    category: ModuleCategory.timber,
    status: ModuleStatus.comingSoon,
    phase: 3,
  ),
  EngModule(
    id: 'masonry-wall',
    title: 'Masonry Wall',
    subtitle: 'EC6 vertical capacity',
    icon: Icons.grid_view_outlined,
    category: ModuleCategory.masonry,
    status: ModuleStatus.comingSoon,
    phase: 3,
  ),
  EngModule(
    id: 'bearing',
    title: 'Bearing & Settlement',
    subtitle: 'EC7 soil checks',
    icon: Icons.terrain_outlined,
    category: ModuleCategory.geotech,
    status: ModuleStatus.comingSoon,
    phase: 1,
  ),
  EngModule(
    id: 'slope',
    title: 'Slope Stability',
    subtitle: 'Factor of safety',
    icon: Icons.landscape_outlined,
    category: ModuleCategory.geotech,
    status: ModuleStatus.comingSoon,
    phase: 3,
  ),
  EngModule(
    id: 'wind-snow',
    title: 'Wind & Snow',
    subtitle: 'EC1 actions',
    icon: Icons.air_outlined,
    category: ModuleCategory.loads,
    status: ModuleStatus.comingSoon,
    phase: 3,
  ),
  EngModule(
    id: 'seismic',
    title: 'Seismic',
    subtitle: 'EC8 / PS92 spectra',
    icon: Icons.waves_outlined,
    category: ModuleCategory.loads,
    status: ModuleStatus.comingSoon,
    phase: 3,
  ),
  EngModule(
    id: 'sections',
    title: 'Section Properties',
    subtitle: 'A, I, W, i',
    icon: Icons.crop_square,
    category: ModuleCategory.tools,
    status: ModuleStatus.comingSoon,
    phase: 1,
  ),
  EngModule(
    id: 'quantities',
    title: 'Quantities',
    subtitle: 'Concrete, rebar take-off',
    icon: Icons.calculate_outlined,
    category: ModuleCategory.tools,
    status: ModuleStatus.comingSoon,
    phase: 1,
  ),
  EngModule(
    id: 'pile-cap',
    title: 'Pile Cap',
    subtitle: 'Pile group, cap design',
    icon: Icons.view_week_outlined,
    category: ModuleCategory.tools,
    status: ModuleStatus.comingSoon,
    phase: 3,
  ),
  EngModule(
    id: 'septic',
    title: 'Septic Tank',
    subtitle: 'Volume sizing',
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
