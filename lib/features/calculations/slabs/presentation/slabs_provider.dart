import 'package:flutter_riverpod/legacy.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/calculation_engine.dart';
import 'package:sibot/core/services/core_services.dart';

final slabStateProvider =
    StateNotifierProvider.family<
      SlabCalculationStateNotifier,
      SlabCalculationState,
      String
    >((ref, projectId) {
      return SlabCalculationStateNotifier(projectId);
    });

class SlabCalculationState {
  final double? span;
  final double? load;
  final double? concreteStrength;
  final double? steelStrength;
  final SlabCalculation? lastCalculation;
  final bool isLoading;
  final String? error;

  const SlabCalculationState({
    this.span,
    this.load,
    this.concreteStrength,
    this.steelStrength,
    this.lastCalculation,
    this.isLoading = false,
    this.error,
  });

  SlabCalculationState copyWith({
    double? span,
    double? load,
    double? concreteStrength,
    double? steelStrength,
    SlabCalculation? lastCalculation,
    bool? isLoading,
    String? error,
  }) {
    return SlabCalculationState(
      span: span ?? this.span,
      load: load ?? this.load,
      concreteStrength: concreteStrength ?? this.concreteStrength,
      steelStrength: steelStrength ?? this.steelStrength,
      lastCalculation: lastCalculation ?? this.lastCalculation,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SlabCalculationStateNotifier extends StateNotifier<SlabCalculationState> {
  final String projectId;

  SlabCalculationStateNotifier(this.projectId)
    : super(const SlabCalculationState());

  void updateSpan(double value) => state = state.copyWith(span: value);
  void updateLoad(double value) => state = state.copyWith(load: value);
  void updateConcreteStrength(double value) =>
      state = state.copyWith(concreteStrength: value);
  void updateSteelStrength(double value) =>
      state = state.copyWith(steelStrength: value);

  Future<void> calculate() async {
    if (!_validateInputs()) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = CalculationEngine.designOneWaySlab(
        span: state.span!,
        loadPerM2: state.load!,
        concreteStrength: state.concreteStrength!,
        steelStrength: state.steelStrength!,
      );

      final calculation = SlabCalculation(
        id: IdService.generateCalculationId(),
        projectId: projectId,
        name: 'Slab Design - ${DateTime.now().toString().split(' ')[0]}',
        span: state.span!,
        load: state.load!,
        concrete: state.concreteStrength!,
        steel: state.steelStrength!,
        createdAt: DateTime.now(),
        isValid: true,
        metadata: result,
      );

      state = state.copyWith(lastCalculation: calculation, isLoading: false);
      await _saveCalculation(calculation);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Calculation error: $e');
    }
  }

  Future<void> _saveCalculation(SlabCalculation calculation) async {
    final box = HiveService.getBox(HiveService.calculationsBox);
    await box.put(calculation.id, calculation);
  }

  bool _validateInputs() {
    if (state.span == null || state.span! <= 0) {
      state = state.copyWith(error: 'Span must be greater than 0');
      return false;
    }
    return true;
  }
}
