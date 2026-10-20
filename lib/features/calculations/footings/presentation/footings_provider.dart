import 'package:flutter_riverpod/legacy.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/calculation_engine.dart';
import 'package:sibot/core/services/core_services.dart';

final footingStateProvider =
    StateNotifierProvider.family<
      FootingCalculationStateNotifier,
      FootingCalculationState,
      String
    >((ref, projectId) {
      return FootingCalculationStateNotifier(projectId);
    });

class FootingCalculationState {
  final double? columnLoad;
  final double? columnMoment;
  final double? soilBearingCapacity;
  final double? soilDensity;
  final double? concreteStrength;
  final double? steelStrength;
  final String footingType;
  final String code;
  final FootingCalculation? lastCalculation;
  final bool isLoading;
  final String? error;

  const FootingCalculationState({
    this.columnLoad,
    this.columnMoment,
    this.soilBearingCapacity,
    this.soilDensity,
    this.concreteStrength,
    this.steelStrength,
    this.footingType = 'isolated',
    this.code = 'eurocode',
    this.lastCalculation,
    this.isLoading = false,
    this.error,
  });

  FootingCalculationState copyWith({
    double? columnLoad,
    double? columnMoment,
    double? soilBearingCapacity,
    double? soilDensity,
    double? concreteStrength,
    double? steelStrength,
    String? footingType,
    String? code,
    FootingCalculation? lastCalculation,
    bool? isLoading,
    String? error,
  }) {
    return FootingCalculationState(
      columnLoad: columnLoad ?? this.columnLoad,
      columnMoment: columnMoment ?? this.columnMoment,
      soilBearingCapacity: soilBearingCapacity ?? this.soilBearingCapacity,
      soilDensity: soilDensity ?? this.soilDensity,
      concreteStrength: concreteStrength ?? this.concreteStrength,
      steelStrength: steelStrength ?? this.steelStrength,
      footingType: footingType ?? this.footingType,
      code: code ?? this.code,
      lastCalculation: lastCalculation ?? this.lastCalculation,
      isLoading: isLoading ?? this.isLoading,
      error: error, // cleared by any update unless set
    );
  }
}

class FootingCalculationStateNotifier
    extends StateNotifier<FootingCalculationState> {
  final String projectId;

  FootingCalculationStateNotifier(this.projectId)
    : super(FootingCalculationState(code: SettingsService.getDefaultCode()));

  void updateColumnLoad(double value) {
    state = state.copyWith(columnLoad: value);
  }

  void updateColumnMoment(double value) {
    state = state.copyWith(columnMoment: value);
  }

  void updateSoilBearingCapacity(double value) {
    state = state.copyWith(soilBearingCapacity: value);
  }

  void updateSoilDensity(double value) {
    state = state.copyWith(soilDensity: value);
  }

  void updateConcreteStrength(double value) {
    state = state.copyWith(concreteStrength: value);
  }

  void updateSteelStrength(double value) {
    state = state.copyWith(steelStrength: value);
  }

  void updateFootingType(String type) {
    state = state.copyWith(footingType: type);
  }

  void updateCode(String code) {
    state = state.copyWith(code: code);
  }

  Future<void> calculate() async {
    if (!_validateInputs()) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final totalLoad = state.columnLoad! + (state.columnMoment ?? 0) * 0.1;

      // Calculate required area
      final safetyFactor = state.code == 'eurocode' ? 3.0 : 2.5;
      final requiredArea = CalculationEngine.calculateRequiredFootingArea(
        totalLoad: totalLoad,
        soilBearingCapacity: state.soilBearingCapacity!,
        safetyFactor: safetyFactor,
      );

      // Calculate dimensions
      final dimensions = CalculationEngine.calculateFootingDimensions(
        requiredArea: requiredArea,
        lengthWidthRatio: 1.5,
      );

      // Design reinforcement
      final reinforcement = CalculationEngine.designFootingReinforcement(
        bendingMoment: state.columnMoment ?? 0,
        concreteStrength: state.concreteStrength!,
        steelStrength: state.steelStrength!,
        effectiveDepth: 450,
        width: dimensions['length']!,
      );

      final calculation = FootingCalculation(
        id: IdService.generateCalculationId(),
        projectId: projectId,
        name: 'Footing Design - ${DateTime.now().toString().split(' ')[0]}',
        columnLoad: state.columnLoad!,
        columnMoment: state.columnMoment ?? 0,
        soilBearingCapacity: state.soilBearingCapacity!,
        soilDensity: state.soilDensity!,
        concrete: state.concreteStrength!,
        steel: state.steelStrength!,
        footing: state.footingType,
        code: state.code,
        requiredArea: requiredArea,
        footingLength: dimensions['length'],
        footingWidth: dimensions['width'],
        footingDepth: 450,
        reinforcementRatio:
            (reinforcement['ast'] as double) /
            ((dimensions['area'] as double) * 1000),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isValid: reinforcement['isValid'] as bool,
        metadata: {'dimensions': dimensions, 'reinforcement': reinforcement},
      );

      state = state.copyWith(lastCalculation: calculation, isLoading: false);

      // Save to database
      await _saveCalculation(calculation);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Calculation error: $e');
      LoggerService.e('Footing calculation failed: $e');
    }
  }

  Future<void> _saveCalculation(FootingCalculation calculation) async {
    try {
      final box = HiveService.getBox(HiveService.calculationsBox);
      await box.put(calculation.id, calculation);
      LoggerService.i('Calculation saved: ${calculation.id}');
    } catch (e) {
      LoggerService.e('Failed to save calculation: $e');
    }
  }

  bool _validateInputs() {
    if (state.columnLoad == null || state.columnLoad! <= 0) {
      state = state.copyWith(error: 'Column load must be greater than 0');
      return false;
    }
    if (state.soilBearingCapacity == null || state.soilBearingCapacity! <= 0) {
      state = state.copyWith(
        error: 'Soil bearing capacity must be greater than 0',
      );
      return false;
    }
    if (state.concreteStrength == null || state.concreteStrength! <= 0) {
      state = state.copyWith(error: 'Concrete strength must be greater than 0');
      return false;
    }
    if (state.steelStrength == null || state.steelStrength! <= 0) {
      state = state.copyWith(error: 'Steel strength must be greater than 0');
      return false;
    }
    return true;
  }
}
