import 'package:sibot_engine/sibot_engine.dart';

/// Concrete rectangle b × h (mm) with Ecm from EN 1992-1-1 Table 3.1.
FrameSection concreteRectangle(double b, double h, {double fck = 25}) {
  final e = Concrete(DesignCode.ec2, fck.clamp(12, 50).toDouble()).ecm;
  final s = FrameSection.rectangle(b, h, e: e);
  return FrameSection(
    name: '${b.round()}×${h.round()} C${fck.round()}',
    area: s.area,
    inertia: s.inertia,
    youngModulus: e,
    unitWeight: 25,
  );
}

/// IPE profiles: area (cm²) and Iy (cm⁴) from the Euronorm 19-57 tables.
const ipeProfiles = <String, (double, double)>{
  'IPE 100': (10.3, 171),
  'IPE 120': (13.2, 318),
  'IPE 140': (16.4, 541),
  'IPE 160': (20.1, 869),
  'IPE 180': (23.9, 1317),
  'IPE 200': (28.5, 1943),
  'IPE 220': (33.4, 2772),
  'IPE 240': (39.1, 3892),
  'IPE 270': (45.9, 5790),
  'IPE 300': (53.8, 8356),
  'IPE 330': (62.6, 11770),
  'IPE 360': (72.7, 16270),
  'IPE 400': (84.5, 23130),
  'IPE 450': (98.8, 33740),
  'IPE 500': (116, 48200),
  'IPE 550': (134, 67120),
  'IPE 600': (156, 92080),
};

FrameSection steelProfile(String name) {
  final (a, i) = ipeProfiles[name]!;
  return FrameSection(
    name: name,
    area: a * 1e-4,
    inertia: i * 1e-8,
    youngModulus: 210000,
    unitWeight: 78.5,
  );
}
