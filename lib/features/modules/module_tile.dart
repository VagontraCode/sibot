import 'package:flutter/material.dart';
import 'package:sibot/features/modules/module_registry.dart';
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${module.title} is planned for Phase ${module.phase} of the roadmap.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
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
                  const StatusPill('Beta', tone: Tone.warning)
                else
                  StatusPill('Phase ${module.phase}'),
              ],
            ),
            const SizedBox(height: Gap.lg),
            Text(
              module.title,
              style: context.text.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              module.subtitle,
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

/// Compact row variant used for the roadmap list.
class ModuleRow extends StatelessWidget {
  final EngModule module;
  const ModuleRow({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconBadge(module.icon, tone: Tone.neutral, size: 36),
      title: Text(module.title),
      subtitle: Text(module.subtitle),
      trailing: StatusPill('Phase ${module.phase}'),
      dense: false,
    );
  }
}
