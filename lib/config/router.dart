import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/features/calculations/footings/presentation/footings_page.dart';
import 'package:sibot/features/calculations/beams/presentation/beams_page.dart';
import 'package:sibot/features/calculations/columns/presentation/columns_page.dart';
import 'package:sibot/features/calculations/slabs/presentation/slabs_page.dart';
import 'package:sibot/features/calculations/retaining_walls/presentation/retaining_wall_page.dart';
import 'package:sibot/features/field/presentation/pages/field_hub.dart';
import 'package:sibot/features/field/presentation/pages/field.dart';
import 'package:sibot/features/projects/presentation/pages/project_detail.dart';
import 'package:sibot/features/projects/presentation/pages/project_page.dart';
import 'package:sibot/features/report/presentation/pages/report_page.dart';
import 'package:sibot/features/shared/presentation/pages/reference_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => _MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/projects',
          name: 'projects',
          builder: (context, state) => const ProjectsPage(),
          routes: [
            GoRoute(
              path: ':projectId',
              name: 'project-detail',
              builder: (context, state) => ProjectDetailPage(
                projectId: state.pathParameters['projectId']!,
              ),
              routes: [
                GoRoute(
                  path: 'footing',
                  name: 'footing',
                  builder: (context, state) => FootingPage(
                    projectId: state.pathParameters['projectId']!,
                  ),
                ),
                GoRoute(
                  path: 'beam',
                  name: 'beam',
                  builder: (context, state) =>
                      BeamPage(projectId: state.pathParameters['projectId']!),
                ),
                GoRoute(
                  path: 'column',
                  name: 'column',
                  builder: (context, state) =>
                      ColumnPage(projectId: state.pathParameters['projectId']!),
                ),
                GoRoute(
                  path: 'slab',
                  name: 'slab',
                  builder: (context, state) =>
                      SlabPage(projectId: state.pathParameters['projectId']!),
                ),
                GoRoute(
                  path: 'retaining-wall',
                  name: 'retaining-wall',
                  builder: (context, state) => RetainingWallPage(
                    projectId: state.pathParameters['projectId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/field',
          name: 'field',
          builder: (context, state) => const FieldHubPage(),
          routes: [
            GoRoute(
              path: 'photo-log/:projectId',
              name: 'photo-log',
              builder: (context, state) => PhotoLogPage(
                projectId: state.pathParameters['projectId']!,
              ),
            ),
            GoRoute(
              path: 'daily-report/:projectId',
              name: 'daily-report',
              builder: (context, state) => DailyReportPage(
                projectId: state.pathParameters['projectId']!,
              ),
            ),
            GoRoute(
              path: 'punch-list/:projectId',
              name: 'punch-list',
              builder: (context, state) => PunchListPage(
                projectId: state.pathParameters['projectId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/reports',
          name: 'reports',
          builder: (context, state) => const ReportsPage(),
        ),
        GoRoute(
          path: '/reference',
          name: 'reference',
          builder: (context, state) => const ReferencePage(),
        ),
      ],
    ),
  ],
);

class _MainScaffold extends StatelessWidget {
  final Widget child;

  const _MainScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          switch (index) {
            case 0:
              context.goNamed('dashboard');
              break;
            case 1:
              context.goNamed('projects');
              break;
            case 2:
              context.goNamed('field');
              break;
            case 3:
              context.goNamed('reports');
              break;
            case 4:
              context.goNamed('reference');
              break;
          }
        },
        selectedIndex: _calculateSelectedIndex(context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Projects'),
          NavigationDestination(icon: Icon(Icons.construction), label: 'Field'),
          NavigationDestination(
            icon: Icon(Icons.description),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'Reference',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/projects')) return 1;
    if (location.startsWith('/field')) return 2;
    if (location.startsWith('/reports')) return 3;
    if (location.startsWith('/reference')) return 4;
    return 0;
  }
}
