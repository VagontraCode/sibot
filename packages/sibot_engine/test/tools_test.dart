// Section properties, quantities and shallow foundation tools.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  group('section properties', () {
    test('rectangle', () {
      final p = sectionProperties(const RectangleSection(300, 600));
      expect(p.area, 180000);
      expect(p.iy, closeTo(300 * math.pow(600, 3) / 12, 1e-3));
      expect(p.iz, closeTo(600 * math.pow(300, 3) / 12, 1e-3));
      expect(p.welTop, closeTo(300 * 600 * 600 / 6, 1e-3));
      expect(p.wpl, closeTo(300 * 600 * 600 / 4, 1e-3));
    });
    test('circle', () {
      final p = sectionProperties(const CircleSection(400));
      expect(p.iy, closeTo(math.pi * math.pow(400, 4) / 64, 1e-3));
      expect(p.wpl, closeTo(math.pow(400, 3) / 6, 1e-6));
    });
    test('IPE 300 (b 150, h 300, tf 10.7, tw 7.1)', () {
      // Without root radii: A = 2·150·10.7 + 278.6·7.1 = 5188 mm²
      // Iy = (150·300³ − 142.9·278.6³)/12 = 8.0007e7 mm⁴ (tables 8.356e7
      // include the root fillets)
      final p = sectionProperties(
        const ISection(b: 150, h: 300, tf: 10.7, tw: 7.1),
      );
      expect(p.area, closeTo(2 * 150 * 10.7 + 278.6 * 7.1, 1e-6));
      expect(
        p.iy,
        closeTo((150 * math.pow(300, 3) - 142.9 * math.pow(278.6, 3)) / 12, 1),
      );
      expect(p.centroid, closeTo(150, 1e-9));
      // Wpl = b·tf·(h − tf) + tw·(h − 2tf)²/4
      expect(
        p.wpl,
        closeTo(150 * 10.7 * 289.3 + 7.1 * 278.6 * 278.6 / 4, 1e-3),
      );
    });
    test('T-section centroid and plastic axis', () {
      // Flange 600 × 100, web 200 × 400: A = 140 000 mm²
      // centroid = (60000·50 + 80000·300)/140000 = 192.86 mm
      final p = sectionProperties(
        const TSection(b: 600, h: 500, tf: 100, tw: 200),
      );
      expect(p.area, 140000);
      expect(p.centroid, closeTo(192.857, 1e-3));
      // PNA at 70000 mm² from the top: in the web at 100 + 10000/200 = 150
      // Wpl = 60000·100 + 200·50·25 + 200·350·175 = 18.5e6 mm³
      expect(p.wpl, closeTo(6e6 + 0.25e6 + 12.25e6, 1));
    });
    test('hollow rectangle', () {
      final p = sectionProperties(const HollowRectangleSection(200, 300, 10));
      expect(p.area, closeTo(200 * 300 - 180 * 280, 1e-9));
      expect(
        p.iy,
        closeTo((200 * math.pow(300, 3) - 180 * math.pow(280, 3)) / 12, 1e-3),
      );
    });
  });

  group('quantities', () {
    test('concrete materials', () {
      // 4 footings 1.5 × 1.5 × 0.4 = 3.6 m³ + 5 % = 3.78 m³
      final q = concreteQuantity(
        length: 1.5,
        width: 1.5,
        height: 0.4,
        count: 4,
      );
      expect(q.volume, closeTo(3.78, 1e-9));
      expect(q.cementKg, closeTo(1323, 1e-9));
      expect(q.cementBags, 27);
      expect(q.sandM3, closeTo(1.512, 1e-9));
      expect(q.gravelM3, closeTo(3.024, 1e-9));
    });
    test('rebar mass', () {
      // 10 Ø12 × 6 m + 10 % = 66 m × 0.888 kg/m
      final r = rebarQuantity(diameter: 12, count: 10, barLength: 6);
      expect(r.length, closeTo(66, 1e-9));
      expect(r.mass, closeTo(66 * math.pi * 36 * 7850e-6, 1e-9));
      expect(r.stockBars, 5); // two 6 m bars per 12 m stock bar
    });
    test('formwork', () {
      expect(
        formworkArea(length: 5, width: 0.3, height: 0.6, includeSoffit: true),
        closeTo(2 * 5 * 0.6 + 2 * 0.3 * 0.6 + 5 * 0.3, 1e-12),
      );
    });
  });

  group('shallow foundation', () {
    final r = designShallowFoundation(
      const ShallowFoundationInput(
        b: 2,
        l: 2,
        depth: 1,
        g: 600,
        q: 200,
        soil: Soil(phi: 30, gamma: 18),
        youngModulus: 30,
      ),
    );
    test('design pressures', () {
      expect(r.qEd, closeTo((1.35 * 600 + 1.5 * 200) / 4, 1e-9));
      expect(r.qRd, closeTo(r.qUlt / 1.4, 1e-9));
    });
    test('settlement of a rigid footing (equivalent circle)', () {
      final a = math.sqrt(4 / math.pi);
      final s = math.pi / 2 * 200 * a * (1 - 0.09) / 30e3 * 1000;
      expect(r.settlement, closeTo(s, 1e-9));
    });
  });
}
