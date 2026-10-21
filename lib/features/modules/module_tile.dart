import 'package:flutter/material.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';

class ModuleTile extends StatelessWidget {
  final EngModule module;
  final VoidCallback? onOpen;

  const ModuleTile({super.key, required this.module, this.onOpen});

  void _tap(BuildContext context) {
    if (module.isAvailable) {
      onOpen?.call();
      return;
    }
    final l = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.modPlannedFor(module.title(l), module.phase ?? 0)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final available = module.isAvailable;
    return Opacity(
      opacity: available ? 1 : 0.62,
      child: SurfaceCard(
        onTap: () => _tap(context),
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(
                  module.icon,
                  tone: available ? Tone.primary : Tone.neutral,
                ),
                const Spacer(),
                if (module.status == ModuleStatus.beta)
                  StatusPill(l.commonBeta, tone: Tone.warning)
                else if (module.status == ModuleStatus.comingSoon)
                  StatusPill(l.commonPhase(module.phase ?? 0)),
              ],
            ),
            const SizedBox(height: Gap.lg),
            Text(
              module.title(l),
              style: context.text.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              module.subtitle(l),
              style: context.text.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
