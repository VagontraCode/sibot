// User combinations and analysis specifications of 3D models.
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  final base = Model3D.empty();

  test('generated combinations until the user sets their own', () {
    final gen = combinationsOf(base, DesignCode.ec2);
    expect(gen.first.name, 'ULS 1.35G + 1.5 Q');
    final own = base.copyWith(
      combinations: const [
        Combination('ELU 1', CombinationKind.uls, {0: 1.35, 1: 1.5}),
        Combination('ELS', CombinationKind.slsCharacteristic, {0: 1, 1: 1}),
      ],
    );
    expect(combinationsOf(own, DesignCode.ec2).map((c) => c.name), [
      'ELU 1',
      'ELS',
    ]);
    // Back to automatic.
    expect(own.copyWith(autoCombinations: true).combinations, isNull);
    // The list survives JSON and the editing operations.
    final back = Model3D.fromJson(own.toJson());
    expect(back.combinations!.first.factors, {0: 1.35, 1: 1.5});
    final (withNode, _) = back.addNode(const Node3D(1, 2, 3));
    expect(withNode.deleteNodes({0}).combinations, hasLength(2));
  });

  test('a combination must use existing cases and at least one factor', () {
    expect(
      combinationValid(base, const Combination('a', CombinationKind.uls, {})),
      isFalse,
    );
    expect(
      combinationValid(
        base,
        const Combination('b', CombinationKind.uls, {0: 1, 5: 1}),
      ),
      isFalse,
    );
    expect(
      combinationValid(
        base,
        const Combination('c', CombinationKind.uls, {1: 1}),
      ),
      isTrue,
    );
  });

  test(
    'analysis specifications: JSON, defaults and the chosen combination',
    () {
      const s = AnalysisSpec(
        id: 'sx',
        kind: AnalysisKind.spectrum,
        name: 'EC8 X',
        agR: 1.1,
        ground: GroundType.c,
        direction: 0,
        modes: 20,
      );
      final back = AnalysisSpec.fromJson(s.toJson());
      expect(back, s);
      expect(back.ground, GroundType.c);
      expect(back.modes, 20);
      expect(defaultAnalyses.map((a) => a.kind), [
        AnalysisKind.static,
        AnalysisKind.modal,
        AnalysisKind.buckling,
      ]);
      final combos = combinationsOf(base, DesignCode.ec2);
      const b = AnalysisSpec(id: 'b', kind: AnalysisKind.buckling);
      expect(b.combinationIn(combos), 0);
      expect(b.copyWith(combinations: [1]).combinationIn(combos), 1);
      // Out of range: back to the first ULS combination.
      expect(b.copyWith(combinations: [99]).combinationIn(combos), 0);
    },
  );
}
