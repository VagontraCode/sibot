import 'package:flutter_riverpod/legacy.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/calculation_engine.dart';
import 'package:sibot/core/services/core_services.dart';

final retainingWallStateProvider =
    StateNotifierProvider.family<
      RetainingWallCalculationStateNotifier,
      RetainingWallCalculationState,
      String
    >((ref, projectId) {
      return RetainingWallCalculationStateNotifier(projectId);
    });

class RetainingWallCalculationState {
  final double? height;
  final double? soilDensity;
  final double? frictionAngle;
  final double? concreteStrength;
  final double? steelStrength;
  final RetainingWallCalculation? lastCalculation;
  final Map<String, dynamic>? suggestions;
  final bool isLoading;
  final String? error;

  const RetainingWallCalculationState({
    this.height,
    this.soilDensity,
    this.frictionAngle,
    this.concreteStrength,
    this.steelStrength,
    this.lastCalculation,
    this.suggestions,
    this.isLoading = false,
    this.error,
  });

  RetainingWallCalculationState copyWith({
    double? height,
    double? soilDensity,
    double? frictionAngle,
    double? concreteStrength,
    double? steelStrength,
    RetainingWallCalculation? lastCalculation,
    Map<String, dynamic>? suggestions,
    bool? isLoading,
    String? error,
  }) {
    return RetainingWallCalculationState(
      height: height ?? this.height,
      soilDensity: soilDensity ?? this.soilDensity,
      frictionAngle: frictionAngle ?? this.frictionAngle,
      concreteStrength: concreteStrength ?? this.concreteStrength,
      steelStrength: steelStrength ?? this.steelStrength,
      lastCalculation: lastCalculation ?? this.lastCalculation,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RetainingWallCalculationStateNotifier
    extends StateNotifier<RetainingWallCalculationState> {
  final String projectId;

  RetainingWallCalculationStateNotifier(this.projectId)
    : super(const RetainingWallCalculationState());

  void updateHeight(double value) {
    final suggestions = SuggestionEngine.suggestRetainingWall(value);
    state = state.copyWith(height: value, suggestions: suggestions);
  }
  void updateSoilDensity(double value) =>
      state = state.copyWith(soilDensity: value);
  void updateFrictionAngle(double value) =>
      state = state.copyWith(frictionAngle: value);
  void updateConcreteStrength(double value) =>
      state = state.copyWith(concreteStrength: value);
  void updateSteelStrength(double value) =>
      state = state.copyWith(steelStrength: value);

  Future<void> calculate() async {
    if (!_validateInputs()) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final ka = CalculationEngine.calculateEarthPressureCoefficient(
        state.frictionAngle!,
      );
      final earthPressure =
          0.5 * ka * state.soilDensity! * state.height! * state.height!;

      // Simplified check for overturning (assuming width = 0.6 * height)
      final width = 0.6 * state.height!;
      final weight = width * state.height! * 24; // Concrete density ~24 kN/m3

      final overturningMoment = earthPressure * (state.height! / 3);
      final resistingMoment = weight * (width / 2);

      final stability = CalculationEngine.checkOverturnStability(
        resistingMoment: resistingMoment,
        overturningMoment: overturningMoment,
      );

      final result = {
        'ka': ka,
        'earthPressure': earthPressure,
        'overturningMoment': overturningMoment,
        'resistingMoment': resistingMoment,
        'fos': stability['fos'],
        'isSafe': stability['isSafe'],
      };

      final calculation = RetainingWallCalculation(
        id: IdService.generateCalculationId(),
        projectId: projectId,
        name: 'Retaining Wall - ${DateTime.now().toString().split(' ')[0]}',
        height: state.height!,
        soilDensity: state.soilDensity!,
        frictionAngle: state.frictionAngle!,
        concrete: state.concreteStrength!,
        steel: state.steelStrength!,
        createdAt: DateTime.now(),
        isValid: stability['isSafe'] as bool,
        metadata: result,
      );

      state = state.copyWith(lastCalculation: calculation, isLoading: false);
      await _saveCalculation(calculation);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Calculation error: $e');
    }
  }

  Future<void> _saveCalculation(RetainingWallCalculation calculation) async {
    final box = HiveService.getBox(HiveService.calculationsBox);
    await box.put(calculation.id, calculation);
  }

  bool _validateInputs() {
    if (state.height == null || state.height! <= 0) {
      state = state.copyWith(error: 'Height must be greater than 0');
      return false;
    }
    if (state.soilDensity == null || state.soilDensity! <= 0) {
      state = state.copyWith(error: 'Soil density must be greater than 0');
      return false;
    }
    return true;
  }
}
