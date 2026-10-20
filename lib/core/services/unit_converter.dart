/// Unit conversion utilities
class UnitConverter {
  static const kpaToBar = 0.01;
  static const kpaToAtm = 0.0098692;
  static const mpaToMpg = 145.038;
  static const knToLbf = 224.809;

  static double convertPressure(double value, String from, String to) {
    final inKpa = _toPressure(value, from);
    return _fromPressure(inKpa, to);
  }

  static double _toPressure(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'kpa':
        return value;
      case 'bar':
        return value / kpaToBar;
      case 'atm':
        return value / kpaToAtm;
      case 'mpa':
        return value * 1000;
      default:
        return value;
    }
  }

  static double _fromPressure(double kpa, String unit) {
    switch (unit.toLowerCase()) {
      case 'kpa':
        return kpa;
      case 'bar':
        return kpa * kpaToBar;
      case 'atm':
        return kpa * kpaToAtm;
      case 'mpa':
        return kpa / 1000;
      default:
        return kpa;
    }
  }

  static double convertLength(double value, String from, String to) {
    final inMeter = _toLength(value, from);
    return _fromLength(inMeter, to);
  }

  static double _toLength(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'mm':
        return value / 1000;
      case 'cm':
        return value / 100;
      case 'm':
        return value;
      case 'km':
        return value * 1000;
      case 'ft':
        return value * 0.3048;
      case 'in':
        return value * 0.0254;
      default:
        return value;
    }
  }

  static double _fromLength(double meter, String unit) {
    switch (unit.toLowerCase()) {
      case 'mm':
        return meter * 1000;
      case 'cm':
        return meter * 100;
      case 'm':
        return meter;
      case 'km':
        return meter / 1000;
      case 'ft':
        return meter / 0.3048;
      case 'in':
        return meter / 0.0254;
      default:
        return meter;
    }
  }

  static double convertForce(double value, String from, String to) {
    final inKn = _toForce(value, from);
    return _fromForce(inKn, to);
  }

  static double _toForce(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'kn':
        return value;
      case 'n':
        return value / 1000;
      case 'lbf':
        return value / knToLbf;
      case 'tonf':
        return value * 9.81;
      case 'kgf':
        return value * 0.00981;
      default:
        return value;
    }
  }

  static double _fromForce(double kn, String unit) {
    switch (unit.toLowerCase()) {
      case 'kn':
        return kn;
      case 'n':
        return kn * 1000;
      case 'lbf':
        return kn * knToLbf;
      case 'tonf':
        return kn / 9.81;
      case 'kgf':
        return kn / 0.00981;
      default:
        return kn;
    }
  }
}
