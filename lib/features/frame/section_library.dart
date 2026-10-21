import 'package:sibot_engine/sibot_engine.dart';

/// Concrete rectangle b × h (mm) with Ecm from EN 1992-1-1 Table 3.1.
FrameSection concreteRectangle(double b, double h, {double fck = 25}) {
  final f = fck.clamp(12, 50).toDouble();
  final e = Concrete(DesignCode.ec2, f).ecm;
  final s = FrameSection.rectangle(b, h, e: e, fck: f);
  return FrameSection(
    name: '${b.round()}×${h.round()} C${f.round()}',
    area: s.area,
    inertia: s.inertia,
    youngModulus: e,
    unitWeight: 25,
    material: SectionMaterial.concrete,
    b: b,
    h: h,
    fck: f,
  );
}

/// Rolled IPE / HEA / HEB profile from the engine library (major axis).
FrameSection steelProfile(String name) {
  final p = steelSections[name]!;
  return FrameSection(
    name: name,
    area: p.area * 1e-6,
    inertia: p.iy * 1e-12,
    youngModulus: 210000,
    unitWeight: 78.5,
    material: SectionMaterial.steel,
    profile: name,
  );
}
