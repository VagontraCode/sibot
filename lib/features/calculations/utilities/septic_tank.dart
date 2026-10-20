import 'dart:math';

class SepticTankDesign {
  static Map<String, dynamic> designSepticTank({
    required int populationServed, // number of people
    required double wasteWaterPerCapita, // L/person/day (typically 150-200)
    String tankType = 'two_chamber',
  }) {
    // Design flow
    final dailyFlow = populationServed * wasteWaterPerCapita;

    // Retention time: 24-48 hours (use 24 for design)
    const retentionTime = 24; // hours

    // Required volume
    final requiredVolume = (dailyFlow * retentionTime) / 1000; // m³

    // Add freeboard (10-15%)
    final totalVolume = requiredVolume * 1.15;

    // Design dimensions (assuming rectangular tank)
    final length = sqrt(totalVolume * 2);
    final width = totalVolume / length;
    final depth = totalVolume / (length * width);

    // Sludge storage (1-3 years for household septic tanks)
    const sludgeStorageYears = 2;
    const sludgeProductionPerCapita = 0.5; // m³ per person per year
    final sludgeVolume =
        populationServed * sludgeProductionPerCapita * sludgeStorageYears;

    return {
      'populationServed': populationServed,
      'dailyWasteWater': dailyFlow,
      'requiredRetentionVolume': requiredVolume,
      'totalTankVolume': totalVolume,
      'sludgeStorageVolume': sludgeVolume,
      'dimensions': {
        'length': (length * 100).round() / 100,
        'width': (width * 100).round() / 100,
        'depth': (depth * 100).round() / 100,
      },
      'numberOfChambers': tankType == 'two_chamber' ? 2 : 1,
      'remarks': 'Design per local sewerage codes',
    };
  }
}
