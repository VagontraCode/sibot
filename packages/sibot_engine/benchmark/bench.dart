// Timings of the heavy computations: dart run benchmark/bench.dart
import 'package:sibot_engine/sibot_engine.dart';

T time<T>(String label, T Function() f, {int runs = 3}) {
  late T r;
  final sw = Stopwatch()..start();
  for (var i = 0; i < runs; i++) {
    r = f();
  }
  sw.stop();
  print('${label.padRight(48)} ${(sw.elapsedMilliseconds / runs).toStringAsFixed(0).padLeft(6)} ms');
  return r;
}

void main() {
  for (final (bx, by, n) in [(3, 2, 4), (5, 4, 8), (6, 6, 12)]) {
    final params = BuildingParams(
      spansX: List.filled(bx, 6.0),
      spansY: List.filled(by, 5.0),
      storeyHeights: List.filled(n, 3.0),
      column: Section3D.rectangle(400, 400),
      beam: Section3D.rectangle(300, 600),
    );
    final m = buildingFrame(params);
    final tag = '$bx×$by bays × $n storeys (${m.elements.length} members)';
    print('--- 3D $tag');
    final an = time('static: factorise + all cases', () {
      final a = Frame3DAnalysis(m);
      a.solveAll();
      return a;
    });
    print('  equations ${an.equations}');
    final modal = time('modal: 12 modes', () => modalAnalysis(
          m,
          options: ModalOptions(
            modes: 12,
            nodeMasses: buildingNodeMasses(params, m),
          ),
        ));
    print('  modal iterations ${modal.iterations}');
    time('spectrum X with torsion', () => responseSpectrum(
          modal,
          direction: 0,
          ag: 1.6,
          spectrum: spectrumParams(GroundType.b, type1: false),
          q: 1.5,
          accidentalTorsion: true,
        ));
    final combos = combinationsFor(
      [for (final c in m.cases) (c.name, c.type)],
      DesignCode.ec2,
    );
    final withUls = withCase(m, combinedCase(m, combos.first.factors));
    time('buckling factor', () => Frame3DAnalysis(withUls).bucklingFactor(m.cases.length), runs: 1);
    time('P-Δ of the ULS combination', () => Frame3DAnalysis(withUls).pDeltaCase(m.cases.length), runs: 1);
  }
  for (final n in [16, 30, 40]) {
    time('plate $n × $n', () => analysePlate(PlateInput(lx: 8, ly: 8, t: 250, nx: n, ny: n, q: 10)));
  }
}
