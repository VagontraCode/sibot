import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'entities.g.dart';

// ============ PROJECT MODELS ============

@HiveType(typeId: 0)
@JsonSerializable()
class Project {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5)
  final String location;

  @HiveField(6)
  final String engineer;

  @HiveField(7)
  final String status; // active, archived, completed

  @HiveField(8)
  final Map<String, dynamic> metadata;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.location,
    required this.engineer,
    required this.status,
    required this.metadata,
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? location,
    String? engineer,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      engineer: engineer ?? this.engineer,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}

// ============ CALCULATION MODELS ============

@HiveType(typeId: 1)
@JsonSerializable()
class FootingCalculation {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String projectId;

  @HiveField(2)
  final String name;

  // Inputs
  @HiveField(3)
  final double columnLoad; // kN

  @HiveField(4)
  final double columnMoment; // kN.m

  @HiveField(5)
  final double soilBearingCapacity; // kPa

  @HiveField(6)
  final double soilDensity; // kN/m3

  @HiveField(7)
  final double concrete; // fck in MPa

  @HiveField(8)
  final double steel; // fy in MPa

  @HiveField(9)
  final String footing; // isolated, combined, raft

  @HiveField(10)
  final String code; // eurocode, bael99

  // Calculated Results
  @HiveField(11)
  final double? requiredArea;

  @HiveField(12)
  final double? footingLength;

  @HiveField(13)
  final double? footingWidth;

  @HiveField(14)
  final double? footingDepth;

  @HiveField(15)
  final double? reinforcementRatio;

  @HiveField(16)
  final DateTime createdAt;

  @HiveField(17)
  final DateTime updatedAt;

  @HiveField(18)
  final bool isValid;

  @HiveField(19)
  final Map<String, dynamic> metadata;

  FootingCalculation({
    required this.id,
    required this.projectId,
    required this.name,
    required this.columnLoad,
    required this.columnMoment,
    required this.soilBearingCapacity,
    required this.soilDensity,
    required this.concrete,
    required this.steel,
    required this.footing,
    required this.code,
    this.requiredArea,
    this.footingLength,
    this.footingWidth,
    this.footingDepth,
    this.reinforcementRatio,
    required this.createdAt,
    required this.updatedAt,
    required this.isValid,
    required this.metadata,
  });

  FootingCalculation copyWith({
    String? id,
    String? projectId,
    String? name,
    double? columnLoad,
    double? columnMoment,
    double? soilBearingCapacity,
    double? soilDensity,
    double? concrete,
    double? steel,
    String? footing,
    String? code,
    double? requiredArea,
    double? footingLength,
    double? footingWidth,
    double? footingDepth,
    double? reinforcementRatio,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isValid,
    Map<String, dynamic>? metadata,
  }) {
    return FootingCalculation(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      columnLoad: columnLoad ?? this.columnLoad,
      columnMoment: columnMoment ?? this.columnMoment,
      soilBearingCapacity: soilBearingCapacity ?? this.soilBearingCapacity,
      soilDensity: soilDensity ?? this.soilDensity,
      concrete: concrete ?? this.concrete,
      steel: steel ?? this.steel,
      footing: footing ?? this.footing,
      code: code ?? this.code,
      requiredArea: requiredArea ?? this.requiredArea,
      footingLength: footingLength ?? this.footingLength,
      footingWidth: footingWidth ?? this.footingWidth,
      footingDepth: footingDepth ?? this.footingDepth,
      reinforcementRatio: reinforcementRatio ?? this.reinforcementRatio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isValid: isValid ?? this.isValid,
      metadata: metadata ?? this.metadata,
    );
  }

  factory FootingCalculation.fromJson(Map<String, dynamic> json) =>
      _$FootingCalculationFromJson(json);
  Map<String, dynamic> toJson() => _$FootingCalculationToJson(this);
}

// ============ FIELD MANAGEMENT MODELS ============

@HiveType(typeId: 2)
@JsonSerializable()
class PhotoLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String projectId;

  @HiveField(2)
  final String imagePath;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String location;

  @HiveField(6)
  final List<String> tags;

  PhotoLog({
    required this.id,
    required this.projectId,
    required this.imagePath,
    required this.description,
    required this.timestamp,
    required this.location,
    required this.tags,
  });

  factory PhotoLog.fromJson(Map<String, dynamic> json) =>
      _$PhotoLogFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoLogToJson(this);
}

@HiveType(typeId: 3)
@JsonSerializable()
class DailyReport {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String projectId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String weather;

  @HiveField(4)
  final int workersCount;

  @HiveField(5)
  final String progressSummary;

  @HiveField(6)
  final List<String> issues;

  @HiveField(7)
  final String safetyNotes;

  DailyReport({
    required this.id,
    required this.projectId,
    required this.date,
    required this.weather,
    required this.workersCount,
    required this.progressSummary,
    required this.issues,
    required this.safetyNotes,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) =>
      _$DailyReportFromJson(json);
  Map<String, dynamic> toJson() => _$DailyReportToJson(this);
}

@HiveType(typeId: 4)
@JsonSerializable()
class PunchListItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String projectId;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String priority; // high, medium, low

  @HiveField(4)
  final String status; // open, in_progress, closed

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime? completedAt;

  @HiveField(7)
  final String assignedTo;

  PunchListItem({
    required this.id,
    required this.projectId,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.assignedTo,
  });

  PunchListItem copyWith({
    String? id,
    String? projectId,
    String? description,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? assignedTo,
  }) {
    return PunchListItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }

  factory PunchListItem.fromJson(Map<String, dynamic> json) =>
      _$PunchListItemFromJson(json);
  Map<String, dynamic> toJson() => _$PunchListItemToJson(this);
}

@HiveType(typeId: 5)
@JsonSerializable()
class BeamCalculation {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String projectId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final double span;
  @HiveField(4)
  final double load;
  @HiveField(5)
  final double width;
  @HiveField(6)
  final double depth;
  @HiveField(7)
  final double concrete;
  @HiveField(8)
  final double steel;
  @HiveField(9)
  final DateTime createdAt;
  @HiveField(10)
  final bool isValid;
  @HiveField(11)
  final Map<String, dynamic> metadata;

  BeamCalculation({
    required this.id,
    required this.projectId,
    required this.name,
    required this.span,
    required this.load,
    required this.width,
    required this.depth,
    required this.concrete,
    required this.steel,
    required this.createdAt,
    required this.isValid,
    required this.metadata,
  });

  factory BeamCalculation.fromJson(Map<String, dynamic> json) =>
      _$BeamCalculationFromJson(json);
  Map<String, dynamic> toJson() => _$BeamCalculationToJson(this);
}

@HiveType(typeId: 6)
@JsonSerializable()
class ColumnCalculation {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String projectId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final double axialLoad;
  @HiveField(4)
  final double height;
  @HiveField(5)
  final double concrete;
  @HiveField(6)
  final double steel;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final bool isValid;
  @HiveField(9)
  final Map<String, dynamic> metadata;

  ColumnCalculation({
    required this.id,
    required this.projectId,
    required this.name,
    required this.axialLoad,
    required this.height,
    required this.concrete,
    required this.steel,
    required this.createdAt,
    required this.isValid,
    required this.metadata,
  });

  factory ColumnCalculation.fromJson(Map<String, dynamic> json) =>
      _$ColumnCalculationFromJson(json);
  Map<String, dynamic> toJson() => _$ColumnCalculationToJson(this);
}

@HiveType(typeId: 7)
@JsonSerializable()
class SlabCalculation {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String projectId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final double span;
  @HiveField(4)
  final double load;
  @HiveField(5)
  final double concrete;
  @HiveField(6)
  final double steel;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final bool isValid;
  @HiveField(9)
  final Map<String, dynamic> metadata;

  SlabCalculation({
    required this.id,
    required this.projectId,
    required this.name,
    required this.span,
    required this.load,
    required this.concrete,
    required this.steel,
    required this.createdAt,
    required this.isValid,
    required this.metadata,
  });

  factory SlabCalculation.fromJson(Map<String, dynamic> json) =>
      _$SlabCalculationFromJson(json);
  Map<String, dynamic> toJson() => _$SlabCalculationToJson(this);
}

@HiveType(typeId: 8)
@JsonSerializable()
class RetainingWallCalculation {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String projectId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final double height;
  @HiveField(4)
  final double soilDensity;
  @HiveField(5)
  final double frictionAngle;
  @HiveField(6)
  final double concrete;
  @HiveField(7)
  final double steel;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final bool isValid;
  @HiveField(10)
  final Map<String, dynamic> metadata;

  RetainingWallCalculation({
    required this.id,
    required this.projectId,
    required this.name,
    required this.height,
    required this.soilDensity,
    required this.frictionAngle,
    required this.concrete,
    required this.steel,
    required this.createdAt,
    required this.isValid,
    required this.metadata,
  });

  factory RetainingWallCalculation.fromJson(Map<String, dynamic> json) =>
      _$RetainingWallCalculationFromJson(json);
  Map<String, dynamic> toJson() => _$RetainingWallCalculationToJson(this);
}

// Hive Adapters
class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 0;

  @override
  Project read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Project(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      location: fields[5] as String,
      engineer: fields[6] as String,
      status: fields[7] as String,
      metadata: (fields[8] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.engineer)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.metadata);
  }
}

class FootingCalculationAdapter extends TypeAdapter<FootingCalculation> {
  @override
  final int typeId = 1;

  @override
  FootingCalculation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FootingCalculation(
      id: fields[0] as String,
      projectId: fields[1] as String,
      name: fields[2] as String,
      columnLoad: fields[3] as double,
      columnMoment: fields[4] as double,
      soilBearingCapacity: fields[5] as double,
      soilDensity: fields[6] as double,
      concrete: fields[7] as double,
      steel: fields[8] as double,
      footing: fields[9] as String,
      code: fields[10] as String,
      requiredArea: fields[11] as double?,
      footingLength: fields[12] as double?,
      footingWidth: fields[13] as double?,
      footingDepth: fields[14] as double?,
      reinforcementRatio: fields[15] as double?,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime,
      isValid: fields[18] as bool,
      metadata: fields[19] as Map<String, dynamic>,
    );
  }

  @override
  void write(BinaryWriter writer, FootingCalculation obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.columnLoad)
      ..writeByte(4)
      ..write(obj.columnMoment)
      ..writeByte(5)
      ..write(obj.soilBearingCapacity)
      ..writeByte(6)
      ..write(obj.soilDensity)
      ..writeByte(7)
      ..write(obj.concrete)
      ..writeByte(8)
      ..write(obj.steel)
      ..writeByte(9)
      ..write(obj.footing)
      ..writeByte(10)
      ..write(obj.code)
      ..writeByte(11)
      ..write(obj.requiredArea)
      ..writeByte(12)
      ..write(obj.footingLength)
      ..writeByte(13)
      ..write(obj.footingWidth)
      ..writeByte(14)
      ..write(obj.footingDepth)
      ..writeByte(15)
      ..write(obj.reinforcementRatio)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt)
      ..writeByte(18)
      ..write(obj.isValid)
      ..writeByte(19)
      ..write(obj.metadata);
  }
}

class PhotoLogAdapter extends TypeAdapter<PhotoLog> {
  @override
  final int typeId = 2;

  @override
  PhotoLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PhotoLog(
      id: fields[0] as String,
      projectId: fields[1] as String,
      imagePath: fields[2] as String,
      description: fields[3] as String,
      timestamp: fields[4] as DateTime,
      location: fields[5] as String,
      tags: fields[6] as List<String>,
    );
  }

  @override
  void write(BinaryWriter writer, PhotoLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.tags);
  }
}

class DailyReportAdapter extends TypeAdapter<DailyReport> {
  @override
  final int typeId = 3;

  @override
  DailyReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyReport(
      id: fields[0] as String,
      projectId: fields[1] as String,
      date: fields[2] as DateTime,
      weather: fields[3] as String,
      workersCount: fields[4] as int,
      progressSummary: fields[5] as String,
      issues: fields[6] as List<String>,
      safetyNotes: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DailyReport obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.weather)
      ..writeByte(4)
      ..write(obj.workersCount)
      ..writeByte(5)
      ..write(obj.progressSummary)
      ..writeByte(6)
      ..write(obj.issues)
      ..writeByte(7)
      ..write(obj.safetyNotes);
  }
}

class PunchListItemAdapter extends TypeAdapter<PunchListItem> {
  @override
  final int typeId = 4;

  @override
  PunchListItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PunchListItem(
      id: fields[0] as String,
      projectId: fields[1] as String,
      description: fields[2] as String,
      priority: fields[3] as String,
      status: fields[4] as String,
      createdAt: fields[5] as DateTime,
      completedAt: fields[6] as DateTime?,
      assignedTo: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PunchListItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.completedAt)
      ..writeByte(7)
      ..write(obj.assignedTo);
  }
}

class BeamCalculationAdapter extends TypeAdapter<BeamCalculation> {
  @override
  final int typeId = 5;

  @override
  BeamCalculation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BeamCalculation(
      id: fields[0] as String,
      projectId: fields[1] as String,
      name: fields[2] as String,
      span: fields[3] as double,
      load: fields[4] as double,
      width: fields[5] as double,
      depth: fields[6] as double,
      concrete: fields[7] as double,
      steel: fields[8] as double,
      createdAt: fields[9] as DateTime,
      isValid: fields[10] as bool,
      metadata: fields[11] as Map<String, dynamic>,
    );
  }

  @override
  void write(BinaryWriter writer, BeamCalculation obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.span)
      ..writeByte(4)
      ..write(obj.load)
      ..writeByte(5)
      ..write(obj.width)
      ..writeByte(6)
      ..write(obj.depth)
      ..writeByte(7)
      ..write(obj.concrete)
      ..writeByte(8)
      ..write(obj.steel)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.isValid)
      ..writeByte(11)
      ..write(obj.metadata);
  }
}

class ColumnCalculationAdapter extends TypeAdapter<ColumnCalculation> {
  @override
  final int typeId = 6;

  @override
  ColumnCalculation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ColumnCalculation(
      id: fields[0] as String,
      projectId: fields[1] as String,
      name: fields[2] as String,
      axialLoad: fields[3] as double,
      height: fields[4] as double,
      concrete: fields[5] as double,
      steel: fields[6] as double,
      createdAt: fields[7] as DateTime,
      isValid: fields[8] as bool,
      metadata: fields[9] as Map<String, dynamic>,
    );
  }

  @override
  void write(BinaryWriter writer, ColumnCalculation obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.axialLoad)
      ..writeByte(4)
      ..write(obj.height)
      ..writeByte(5)
      ..write(obj.concrete)
      ..writeByte(6)
      ..write(obj.steel)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.isValid)
      ..writeByte(9)
      ..write(obj.metadata);
  }
}

class SlabCalculationAdapter extends TypeAdapter<SlabCalculation> {
  @override
  final int typeId = 7;

  @override
  SlabCalculation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SlabCalculation(
      id: fields[0] as String,
      projectId: fields[1] as String,
      name: fields[2] as String,
      span: fields[3] as double,
      load: fields[4] as double,
      concrete: fields[5] as double,
      steel: fields[6] as double,
      createdAt: fields[7] as DateTime,
      isValid: fields[8] as bool,
      metadata: fields[9] as Map<String, dynamic>,
    );
  }

  @override
  void write(BinaryWriter writer, SlabCalculation obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.span)
      ..writeByte(4)
      ..write(obj.load)
      ..writeByte(5)
      ..write(obj.concrete)
      ..writeByte(6)
      ..write(obj.steel)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.isValid)
      ..writeByte(9)
      ..write(obj.metadata);
  }
}

class RetainingWallCalculationAdapter
    extends TypeAdapter<RetainingWallCalculation> {
  @override
  final int typeId = 8;

  @override
  RetainingWallCalculation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RetainingWallCalculation(
      id: fields[0] as String,
      projectId: fields[1] as String,
      name: fields[2] as String,
      height: fields[3] as double,
      soilDensity: fields[4] as double,
      frictionAngle: fields[5] as double,
      concrete: fields[6] as double,
      steel: fields[7] as double,
      createdAt: fields[8] as DateTime,
      isValid: fields[9] as bool,
      metadata: fields[10] as Map<String, dynamic>,
    );
  }

  @override
  void write(BinaryWriter writer, RetainingWallCalculation obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.soilDensity)
      ..writeByte(5)
      ..write(obj.frictionAngle)
      ..writeByte(6)
      ..write(obj.concrete)
      ..writeByte(7)
      ..write(obj.steel)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.isValid)
      ..writeByte(10)
      ..write(obj.metadata);
  }
}

/// Saved result of any module without a dedicated entity (steel, timber,
/// masonry, loads…). Inputs and key results live in [metadata].
class ModuleCalculation {
  final String id;
  final String projectId;

  /// Id in the module registry, e.g. 'steel-member'.
  final String moduleId;
  final String name;
  final DateTime createdAt;
  final bool isValid;
  final Map<String, dynamic> metadata;

  ModuleCalculation({
    required this.id,
    required this.projectId,
    required this.moduleId,
    required this.name,
    required this.createdAt,
    required this.isValid,
    required this.metadata,
  });
}

class ModuleCalculationAdapter extends TypeAdapter<ModuleCalculation> {
  @override
  final int typeId = 9;

  @override
  ModuleCalculation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ModuleCalculation(
      id: fields[0] as String,
      projectId: fields[1] as String,
      moduleId: fields[2] as String,
      name: fields[3] as String,
      createdAt: fields[4] as DateTime,
      isValid: fields[5] as bool,
      metadata: (fields[6] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ModuleCalculation obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.moduleId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.isValid)
      ..writeByte(6)
      ..write(obj.metadata);
  }
}
