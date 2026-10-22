// Engine timings on a device: flutter drive --profile
//   --driver=test_driver/integration_test.dart
//   --target=integration_test/perf_test.dart -d <device>
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sibot_engine/sibot_engine.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('engine timings', () {
    final timings = <String, int>{};
    int time(String label, void Function() f) {
      final sw = Stopwatch()..start();
      f();
      sw.stop();
      timings[label] = sw.elapsedMilliseconds;
      // ignore: avoid_print
      print('PERF ${label.padRight(44)} ${sw.elapsedMilliseconds} ms');
      return sw.elapsedMilliseconds;
    }

    for (final (bx, by, n) in [(3, 2, 4), (5, 4, 8), (6, 6, 12)]) {
      final params = BuildingParams(
        spansX: List.filled(bx, 6.0),
        spansY: List.filled(by, 5.0),
        storeyHeights: List.filled(n, 3.0),
        column: Section3D.rectangle(400, 400),
        beam: Section3D.rectangle(300, 600),
      );
      final m = buildingFrame(params);
      final tag = '${bx}x${by}x$n';
      late Frame3DAnalysis an;
      time('$tag static', () {
        an = Frame3DAnalysis(m);
        an.solveAll();
      });
      late ModalResult modal;
      time('$tag modal 12', () {
        modal = modalAnalysis(
          m,
          options: ModalOptions(
            modes: 12,
            nodeMasses: buildingNodeMasses(params, m),
          ),
          analysis: an,
        );
      });
      time('$tag spectrum X+torsion', () {
        responseSpectrum(
          modal,
          direction: 0,
          ag: 1.6,
          spectrum: spectrumParams(GroundType.b, type1: false),
          q: 1.5,
          accidentalTorsion: true,
        );
      });
      time('$tag buckling', () {
        final cases = an.solveAll();
        an.bucklingFactorOf(cases[0].scaled(1.35).plus(cases[1].scaled(1.5)));
      });
    }
    for (final n in [16, 30, 40]) {
      time('plate $n', () {
        analysePlateCases(
          PlateInput(lx: 8, ly: 8, t: 250, nx: n, ny: n),
          [(10, const []), (7, const [])],
        );
      });
    }
    time('slope search', () {
      analyseSlope(
        const SlopeInput(height: 8, angle: 33.7, gamma: 19, cohesion: 10, phi: 28),
      );
    });
    time('slope Janbu layered', () {
      analyseSlope(
        const SlopeInput(
          height: 8,
          angle: 60,
          gamma: 19,
          cohesion: 15,
          phi: 25,
          waterLevel: 2,
          layers: [SoilLayer(top: 1, gamma: 18, cohesion: 5, phi: 15)],
        ),
        method: SlopeMethod.janbu,
      );
    });
    time('continuous beam 6 spans', () {
      designContinuousBeam(
        const ContinuousBeamInput(
          code: DesignCode.ec2,
          spans: [5, 6, 6, 6, 6, 5],
          b: 300,
          h: 550,
          g: 20,
          q: 15,
          fck: 30,
          fyk: 500,
        ),
      );
    });
    binding.reportData = {'timings': timings};
  });
}
