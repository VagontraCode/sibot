import 'package:flutter_riverpod/legacy.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/calculation_engine.dart';
import 'package:sibot/core/services/core_services.dart';

final columnStateProvider =
    StateNotifierProvider.family<
      ColumnCalculationStateNotifier,
      ColumnCalculationState,
      String
    >((ref, projectId) {
      return ColumnCalculationStateNotifier(projectId);
    });

class ColumnCalculationState {
  final double? axialLoad;
  final double? height;
  final double? concreteStrength;
  final double? steelStrength;
  final ColumnCalculation? lastCalculation;
  final bool isLoading;
  final String? error;

  const ColumnCalculationState({
    this.axialLoad,
    this.height,
    this.concreteStrength,
    this.steelStrength,
    this.lastCalculation,
    this.isLoading = false,
    this.error,
  });

  ColumnCalculationState copyWith({
    double? axialLoad,
    double? height,
    double? concreteStrength,
    double? steelStrength,
    ColumnCalculation? lastCalculation,
    bool? isLoading,
    String? error,
  }) {
    return ColumnCalculationState(
      axialLoad: axialLoad ?? this.axialLoad,
      height: height ?? this.height,
      concreteStrength: concreteStrength ?? this.concreteStrength,
      steelStrength: steelStrength ?? this.steelStrength,
      lastCalculation: lastCalculation ?? this.lastCalculation,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ColumnCalculationStateNotifier
    extends StateNotifier<ColumnCalculationState> {
  final String projectId;

  ColumnCalculationStateNotifier(this.projectId)
    : super(const ColumnCalculationState());

  void updateAxialLoad(double value) =>
      state = state.copyWith(axialLoad: value);
  void updateHeight(double value) => state = state.copyWith(height: value);
  void updateConcreteStrength(double value) =>
      state = state.copyWith(concreteStrength: value);
  void updateSteelStrength(double value) =>
      state = state.copyWith(steelStrength: value);

  Future<void> calculate() async {
    if (!_validateInputs()) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = CalculationEngine.designColumn(
        axialLoad: state.axialLoad!,
        concreteStrength: state.concreteStrength!,
        steelStrength: state.steelStrength!,
        height: state.height!,
        assumedPercentSteel: 1.0, // default 1%
      );

      final calculation = ColumnCalculation(
        id: IdService.generateCalculationId(),
        projectId: projectId,
        name: 'Column Design - ${DateTime.now().toString().split(' ')[0]}',
        axialLoad: state.axialLoad!,
        height: state.height!,
        concrete: state.concreteStrength!,
        steel: state.steelStrength!,
        createdAt: DateTime.now(),
        isValid: !result['isSlender'], // Simplified check
        metadata: result,
      );

      state = state.copyWith(lastCalculation: calculation, isLoading: false);
      await _saveCalculation(calculation);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Calculation error: $e');
    }
  }

  Future<void> _saveCalculation(ColumnCalculation calculation) async {
    final box = HiveService.getBox(HiveService.calculationsBox);
    await box.put(calculation.id, calculation);
  }

  bool _validateInputs() {
    if (state.axialLoad == null || state.axialLoad! <= 0) {
      state = state.copyWith(error: 'Axial load must be greater than 0');
      return false;
    }
    return true;
  }
}
