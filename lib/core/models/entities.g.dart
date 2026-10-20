// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) => Project(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  location: json['location'] as String,
  engineer: json['engineer'] as String,
  status: json['status'] as String,
  metadata: json['metadata'] as Map<String, dynamic>,
);

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'location': instance.location,
  'engineer': instance.engineer,
  'status': instance.status,
  'metadata': instance.metadata,
};

FootingCalculation _$FootingCalculationFromJson(Map<String, dynamic> json) =>
    FootingCalculation(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      columnLoad: (json['columnLoad'] as num).toDouble(),
      columnMoment: (json['columnMoment'] as num).toDouble(),
      soilBearingCapacity: (json['soilBearingCapacity'] as num).toDouble(),
      soilDensity: (json['soilDensity'] as num).toDouble(),
      concrete: (json['concrete'] as num).toDouble(),
      steel: (json['steel'] as num).toDouble(),
      footing: json['footing'] as String,
      code: json['code'] as String,
      requiredArea: (json['requiredArea'] as num?)?.toDouble(),
      footingLength: (json['footingLength'] as num?)?.toDouble(),
      footingWidth: (json['footingWidth'] as num?)?.toDouble(),
      footingDepth: (json['footingDepth'] as num?)?.toDouble(),
      reinforcementRatio: (json['reinforcementRatio'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isValid: json['isValid'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$FootingCalculationToJson(FootingCalculation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'name': instance.name,
      'columnLoad': instance.columnLoad,
      'columnMoment': instance.columnMoment,
      'soilBearingCapacity': instance.soilBearingCapacity,
      'soilDensity': instance.soilDensity,
      'concrete': instance.concrete,
      'steel': instance.steel,
      'footing': instance.footing,
      'code': instance.code,
      'requiredArea': instance.requiredArea,
      'footingLength': instance.footingLength,
      'footingWidth': instance.footingWidth,
      'footingDepth': instance.footingDepth,
      'reinforcementRatio': instance.reinforcementRatio,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isValid': instance.isValid,
      'metadata': instance.metadata,
    };

PhotoLog _$PhotoLogFromJson(Map<String, dynamic> json) => PhotoLog(
  id: json['id'] as String,
  projectId: json['projectId'] as String,
  imagePath: json['imagePath'] as String,
  description: json['description'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  location: json['location'] as String,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$PhotoLogToJson(PhotoLog instance) => <String, dynamic>{
  'id': instance.id,
  'projectId': instance.projectId,
  'imagePath': instance.imagePath,
  'description': instance.description,
  'timestamp': instance.timestamp.toIso8601String(),
  'location': instance.location,
  'tags': instance.tags,
};

DailyReport _$DailyReportFromJson(Map<String, dynamic> json) => DailyReport(
  id: json['id'] as String,
  projectId: json['projectId'] as String,
  date: DateTime.parse(json['date'] as String),
  weather: json['weather'] as String,
  workersCount: (json['workersCount'] as num).toInt(),
  progressSummary: json['progressSummary'] as String,
  issues: (json['issues'] as List<dynamic>).map((e) => e as String).toList(),
  safetyNotes: json['safetyNotes'] as String,
);

Map<String, dynamic> _$DailyReportToJson(DailyReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'date': instance.date.toIso8601String(),
      'weather': instance.weather,
      'workersCount': instance.workersCount,
      'progressSummary': instance.progressSummary,
      'issues': instance.issues,
      'safetyNotes': instance.safetyNotes,
    };

PunchListItem _$PunchListItemFromJson(Map<String, dynamic> json) =>
    PunchListItem(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      assignedTo: json['assignedTo'] as String,
    );

Map<String, dynamic> _$PunchListItemToJson(PunchListItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'description': instance.description,
      'priority': instance.priority,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'assignedTo': instance.assignedTo,
    };

BeamCalculation _$BeamCalculationFromJson(Map<String, dynamic> json) =>
    BeamCalculation(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      span: (json['span'] as num).toDouble(),
      load: (json['load'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
      concrete: (json['concrete'] as num).toDouble(),
      steel: (json['steel'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isValid: json['isValid'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$BeamCalculationToJson(BeamCalculation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'name': instance.name,
      'span': instance.span,
      'load': instance.load,
      'width': instance.width,
      'depth': instance.depth,
      'concrete': instance.concrete,
      'steel': instance.steel,
      'createdAt': instance.createdAt.toIso8601String(),
      'isValid': instance.isValid,
      'metadata': instance.metadata,
    };

ColumnCalculation _$ColumnCalculationFromJson(Map<String, dynamic> json) =>
    ColumnCalculation(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      axialLoad: (json['axialLoad'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      concrete: (json['concrete'] as num).toDouble(),
      steel: (json['steel'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isValid: json['isValid'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$ColumnCalculationToJson(ColumnCalculation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'name': instance.name,
      'axialLoad': instance.axialLoad,
      'height': instance.height,
      'concrete': instance.concrete,
      'steel': instance.steel,
      'createdAt': instance.createdAt.toIso8601String(),
      'isValid': instance.isValid,
      'metadata': instance.metadata,
    };

SlabCalculation _$SlabCalculationFromJson(Map<String, dynamic> json) =>
    SlabCalculation(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      span: (json['span'] as num).toDouble(),
      load: (json['load'] as num).toDouble(),
      concrete: (json['concrete'] as num).toDouble(),
      steel: (json['steel'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isValid: json['isValid'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$SlabCalculationToJson(SlabCalculation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'name': instance.name,
      'span': instance.span,
      'load': instance.load,
      'concrete': instance.concrete,
      'steel': instance.steel,
      'createdAt': instance.createdAt.toIso8601String(),
      'isValid': instance.isValid,
      'metadata': instance.metadata,
    };

RetainingWallCalculation _$RetainingWallCalculationFromJson(
  Map<String, dynamic> json,
) => RetainingWallCalculation(
  id: json['id'] as String,
  projectId: json['projectId'] as String,
  name: json['name'] as String,
  height: (json['height'] as num).toDouble(),
  soilDensity: (json['soilDensity'] as num).toDouble(),
  frictionAngle: (json['frictionAngle'] as num).toDouble(),
  concrete: (json['concrete'] as num).toDouble(),
  steel: (json['steel'] as num).toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  isValid: json['isValid'] as bool,
  metadata: json['metadata'] as Map<String, dynamic>,
);

Map<String, dynamic> _$RetainingWallCalculationToJson(
  RetainingWallCalculation instance,
) => <String, dynamic>{
  'id': instance.id,
  'projectId': instance.projectId,
  'name': instance.name,
  'height': instance.height,
  'soilDensity': instance.soilDensity,
  'frictionAngle': instance.frictionAngle,
  'concrete': instance.concrete,
  'steel': instance.steel,
  'createdAt': instance.createdAt.toIso8601String(),
  'isValid': instance.isValid,
  'metadata': instance.metadata,
};
