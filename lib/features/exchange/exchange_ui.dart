import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/exchange/exchange.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';

/// Asks the drawing unit of a DXF file (factor to metres).
Future<double?> askDxfUnit(BuildContext context) {
  final l = context.l10n;
  return showDialog<double>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(l.exchangeDxfUnit),
      children: [
        for (final (label, f) in [
          (l.exchangeMetres, 1.0),
          (l.exchangeCentimetres, 0.01),
          (l.exchangeMillimetres, 0.001),
        ])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, f),
            child: Text(label),
          ),
      ],
    ),
  );
}

/// Picks a .sibot or .dxf file and imports it as a 2D or 3D model of the
/// project, then opens it.
Future<void> importModel(
  BuildContext context, {
  required String projectId,
  required bool threeD,
}) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  try {
    final picked = await pickTextFile();
    if (picked == null) return;
    final (name, text) = picked;
    var unit = 1.0;
    if (name.toLowerCase().endsWith('.dxf')) {
      if (!context.mounted) return;
      final u = await askDxfUnit(context);
      if (u == null) return;
      unit = u;
    }
    final id = threeD
        ? await importFrame3d(projectId, name, text, dxfUnit: unit)
        : await importFrame2d(projectId, name, text, dxfUnit: unit);
    router.push('/projects/$projectId/${threeD ? 'frame3d' : 'frame2d'}/$id');
  } catch (e, st) {
    LoggerService.w('Import failed: $e\n$st');
    messenger.showSnackBar(SnackBar(content: Text(l.exchangeImportFailed)));
  }
}

/// App-bar menu exporting a model as .sibot or DXF.
class ExportMenu extends StatelessWidget {
  final String name;
  final String Function() sibot;
  final String Function() dxf;
  const ExportMenu({
    super.key,
    required this.name,
    required this.sibot,
    required this.dxf,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l.exchangeExport,
      icon: const Icon(Icons.ios_share_rounded),
      onSelected: (v) async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          if (v == 'sibot') {
            await shareTextFile('$name.sibot', sibot());
          } else {
            await shareTextFile('$name.dxf', dxf());
          }
        } catch (e) {
          LoggerService.w('Export failed: $e');
          messenger.showSnackBar(
            SnackBar(content: Text(l.exchangeExportFailed)),
          );
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'sibot',
          child: ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l.exchangeSibot),
            subtitle: Text(l.exchangeSibotHelp),
          ),
        ),
        PopupMenuItem(
          value: 'dxf',
          child: ListTile(
            leading: const Icon(Icons.architecture_rounded),
            title: Text(l.exchangeDxf),
            subtitle: Text(l.exchangeDxfHelp),
          ),
        ),
      ],
    );
  }
}

/// Import button for the model lists.
class ImportButton extends StatelessWidget {
  final String projectId;
  final bool threeD;
  const ImportButton({
    super.key,
    required this.projectId,
    required this.threeD,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return IconButton(
      tooltip: l.exchangeImport,
      icon: const Icon(Icons.file_open_outlined),
      onPressed: () =>
          importModel(context, projectId: projectId, threeD: threeD),
    );
  }
}

/// Explains the import formats under a list.
class ImportHint extends StatelessWidget {
  const ImportHint({super.key});

  @override
  Widget build(BuildContext context) =>
      Text(context.l10n.exchangeImportHint, style: context.text.bodySmall);
}
