import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/ui/ui.dart';

class _Dest {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _Dest(this.label, this.icon, this.selectedIcon);
}

const _destinations = [
  _Dest('Home', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
  _Dest('Projects', Icons.folder_outlined, Icons.folder_rounded),
  _Dest('Field', Icons.construction_outlined, Icons.construction_rounded),
  _Dest('Reports', Icons.description_outlined, Icons.description_rounded),
  _Dest('Library', Icons.menu_book_outlined, Icons.menu_book_rounded),
];

/// Bottom navigation on phones, a rail on tablets, an extended rail on large
/// tablets and desktops.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _go(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the current tab returns to its root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < Breakpoints.medium) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: context.colors.outlineVariant),
            ),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _go,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        ),
      );
    }

    final extended = width >= Breakpoints.large;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 232,
            labelType: extended ? NavigationRailLabelType.none : null,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _go,
            leading: Padding(
              padding: const EdgeInsets.only(top: Gap.md, bottom: Gap.xl),
              child: extended
                  ? SizedBox(
                      width: 200,
                      child: Row(
                        children: [
                          const SizedBox(width: Gap.sm),
                          const BrandMark(size: 34),
                          const SizedBox(width: Gap.md),
                          Text('Sibot', style: context.text.titleLarge),
                          const SizedBox(width: Gap.xs),
                          Text(
                            'Engineering',
                            style: context.text.titleLarge?.copyWith(
                              color: context.colors.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const BrandMark(size: 34),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                ),
            ],
          ),
          VerticalDivider(width: 1, color: context.colors.outlineVariant),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
