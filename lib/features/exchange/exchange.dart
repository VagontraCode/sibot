import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/frame/frame_repository.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// Content of a .sibot exchange file.
sealed class SibotFile {
  final String name;
  const SibotFile(this.name);
}

class Sibot2D extends SibotFile {
  final Model2D model;
  const Sibot2D(super.name, this.model);
}

class Sibot3D extends SibotFile {
  final BuildingParams params;
  final Model3D? custom;
  const Sibot3D(super.name, this.params, this.custom);
}

const sibotFormat = 'sibot';
const sibotVersion = 1;

String encodeFrame2d(FrameModelRecord r) =>
    const JsonEncoder.withIndent(' ').convert({
      'format': sibotFormat,
      'version': sibotVersion,
      'kind': 'frame2d',
      'name': r.name,
      'model': r.model.toJson(),
    });

String encodeFrame3d(Frame3DRecord r) =>
    const JsonEncoder.withIndent(' ').convert({
      'format': sibotFormat,
      'version': sibotVersion,
      'kind': 'frame3d',
      'name': r.name,
      'params': r.params.toJson(),
      if (r.custom != null) 'model': r.custom!.toJson(),
    });

/// Reads a .sibot file; throws [FormatException] when it is not one.
SibotFile decodeSibot(String text) {
  final Object? j;
  try {
    j = jsonDecode(text);
  } catch (_) {
    throw const FormatException('not JSON');
  }
  if (j is! Map || j['format'] != sibotFormat) {
    throw const FormatException('not a Sibot file');
  }
  final version = j['version'];
  if (version is! int || version > sibotVersion) {
    throw const FormatException('unsupported version');
  }
  final name = j['name'] as String? ?? 'Model';
  Map<String, dynamic> map(Object? v) => Map<String, dynamic>.from(v as Map);
  switch (j['kind']) {
    case 'frame2d':
      return Sibot2D(name, Model2D.fromJson(map(j['model'])));
    case 'frame3d':
      return Sibot3D(
        name,
        BuildingParams.fromJson(map(j['params'])),
        j['model'] == null ? null : Model3D.fromJson(map(j['model'])),
      );
    default:
      throw const FormatException('unknown model kind');
  }
}

/// Writes [text] to a temporary file and opens the share sheet.
Future<void> shareTextFile(String fileName, String text) async {
  final dir = await getTemporaryDirectory();
  final safe = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final file = File(p.join(dir.path, safe));
  await file.writeAsString(text);
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
}

/// Picked file name and text, or null when cancelled.
Future<(String, String)?> pickTextFile() async {
  final f = await FilePicker.pickFile();
  if (f == null) return null;
  final bytes = await f.readAsBytes();
  return (f.name, utf8.decode(bytes, allowMalformed: true));
}

/// Placeholder generator parameters for an imported model (the model
/// itself is kept as the edited model).
BuildingParams importedParams(Model3D m) {
  double extent(double Function(Node3D) f) {
    final v = m.nodes.map(f);
    return (v.reduce((a, b) => a > b ? a : b) -
            v.reduce((a, b) => a < b ? a : b))
        .clamp(1.0, 1e4);
  }

  return BuildingParams(
    spansX: [extent((n) => n.x)],
    spansY: [extent((n) => n.y)],
    storeyHeights: [extent((n) => n.z)],
    column: m.sections.first,
    beam: m.sections.length > 1 ? m.sections[1] : m.sections.first,
    g: 0,
    q: 0,
  );
}

/// Imports a picked .sibot or .dxf file into a project as a 3D model;
/// returns the new record id.
Future<String> importFrame3d(
  String projectId,
  String fileName,
  String text, {
  double dxfUnit = 1,
}) async {
  final id = IdService.generateCalculationId();
  final now = DateTime.now();
  final Frame3DRecord record;
  if (fileName.toLowerCase().endsWith('.dxf')) {
    final model = model3dFromLines(
      parseDxf(text, unit: dxfUnit),
      section: Section3D.rectangle(300, 300),
    );
    record = Frame3DRecord(
      id: id,
      projectId: projectId,
      name: p.basenameWithoutExtension(fileName),
      updatedAt: now,
      params: importedParams(model),
      custom: model,
    );
  } else {
    final f = decodeSibot(text);
    if (f is! Sibot3D) throw const FormatException('not a 3D model');
    record = Frame3DRecord(
      id: id,
      projectId: projectId,
      name: f.name,
      updatedAt: now,
      params: f.params,
      custom: f.custom,
    );
  }
  await Frame3DRepository.save(record);
  return id;
}

/// Imports a picked .sibot or .dxf file into a project as a 2D model.
Future<String> importFrame2d(
  String projectId,
  String fileName,
  String text, {
  double dxfUnit = 1,
}) async {
  final id = IdService.generateCalculationId();
  final Model2D model;
  final String name;
  if (fileName.toLowerCase().endsWith('.dxf')) {
    model = model2dFromLines(
      parseDxf(text, unit: dxfUnit),
      section: FrameSection.rectangle(300, 300),
    );
    name = p.basenameWithoutExtension(fileName);
  } else {
    final f = decodeSibot(text);
    if (f is! Sibot2D) throw const FormatException('not a 2D model');
    model = f.model;
    name = f.name;
  }
  await FrameRepository.save(
    FrameModelRecord(
      id: id,
      projectId: projectId,
      name: name,
      updatedAt: DateTime.now(),
      model: model,
    ),
  );
  return id;
}
