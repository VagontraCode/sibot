import 'package:flutter_riverpod/legacy.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/calculation_engine.dart';
import 'package:sibot/core/services/core_services.dart';

final beamStateProvider =
    StateNotifierProvider.family<
      BeamCalculationStateNotifier,
      BeamCalculationState,
      String
    >((ref, projectId) {
      return BeamCalculationStateNotifier(projectId);
    });

class BeamCalculationState {
  final double? span;
  final double? load;
  final double? width;
  final double? depth;
  final double? concreteStrength;
  final double? steelStrength;
  final BeamCalculation? lastCalculation;
  final bool isLoading;
  final String? error;

  const BeamCalculationState({
    this.span,
    this.load,
    this.width,
    this.depth,
    this.concreteStrength,
    this.steelStrength,
    this.lastCalculation,
    this.isLoading = false,
    this.error,
  });

  BeamCalculationState copyWith({
    double? span,
    double? load,
    double? width,
    double? depth,
    double? concreteStrength,
    double? steelStrength,
    BeamCalculation? lastCalculation,
    bool? isLoading,
    String? error,
  }) {
    return BeamCalculationState(
      span: span ?? this.span,
      load: load ?? this.load,
      width: width ?? this.width,
      depth: depth ?? this.depth,
      concreteStrength: concreteStrength ?? this.concreteStrength,
      steelStrength: steelStrength ?? this.steelStrength,
      lastCalculation: lastCalculation ?? this.lastCalculation,
      isLoading: isLoading ?? this.isLoading,
      error: error, // cleared by any update unless set
    );
  }
}

class BeamCalculationStateNotifier extends StateNotifier<BeamCalculationState> {
  final String projectId;

  BeamCalculationStateNotifier(this.projectId)
    : super(const BeamCalculationState());

  void updateSpan(double value) => state = state.copyWith(span: value);
  void updateLoad(double value) => state = state.copyWith(load: value);
  void updateWidth(double value) => state = state.copyWith(width: value);
  void updateDepth(double value) => state = state.copyWith(depth: value);
  void updateConcreteStrength(double value) =>
      state = state.copyWith(concreteStrength: value);
  void updateSteelStrength(double value) =>
      state = state.copyWith(steelStrength: value);

  Future<void> calculate() async {
    if (!_validateInputs()) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final moment =
          (state.load! * state.span! * state.span!) / 8; // Simple span moment

      final result = CalculationEngine.designBeamFlexure(
        bendingMoment: moment,
        concreteStrength: state.concreteStrength!,
        steelStrength: state.steelStrength!,
        effectiveDepth: state.depth! - 50, // assume 50mm cover
        width: state.width!,
      );

      if (result.containsKey('error')) {
        state = state.copyWith(isLoading: false, error: result['error']);
        return;
      }

      final calculation = BeamCalculation(
        id: IdService.generateCalculationId(),
        projectId: projectId,
        name: 'Beam Design - ${DateTime.now().toString().split(' ')[0]}',
        span: state.span!,
        load: state.load!,
        width: state.width!,
        depth: state.depth!,
        concrete: state.concreteStrength!,
        steel: state.steelStrength!,
        createdAt: DateTime.now(),
        isValid: result['isValid'] as bool,
        metadata: result,
      );

      state = state.copyWith(lastCalculation: calculation, isLoading: false);
      await _saveCalculation(calculation);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Calculation error: $e');
    }
  }

  Future<void> _saveCalculation(BeamCalculation calculation) async {
    final box = HiveService.getBox(HiveService.calculationsBox);
    await box.put(calculation.id, calculation);
  }

  bool _validateInputs() {
    if (state.span == null || state.span! <= 0) {
      state = state.copyWith(error: 'Span must be greater than 0');
      return false;
    }
    if (state.load == null || state.load! <= 0) {
      state = state.copyWith(error: 'Load must be greater than 0');
      return false;
    }
    return true;
  }
}
