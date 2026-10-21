import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/features/calculations/beams/presentation/beams_page.dart';
import 'package:sibot/features/calculations/columns/presentation/columns_page.dart';
import 'package:sibot/features/calculations/footings/presentation/footings_page.dart';
import 'package:sibot/features/calculations/retaining_walls/presentation/retaining_wall_page.dart';
import 'package:sibot/features/calculations/slabs/presentation/slabs_page.dart';
import 'package:sibot/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:sibot/features/field/presentation/pages/field.dart';
import 'package:sibot/features/field/presentation/pages/field_hub.dart';
import 'package:sibot/features/projects/presentation/pages/project_detail.dart';
import 'package:sibot/features/projects/presentation/pages/project_page.dart';
import 'package:sibot/features/report/presentation/pages/report_page.dart';
import 'package:sibot/features/shared/presentation/pages/reference_page.dart';
import 'package:sibot/features/settings/settings_page.dart';
import 'package:sibot/features/shell/app_shell.dart';
import 'package:sibot/features/tools/tools_pages.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

String _pid(GoRouterState s) => s.pathParameters['projectId']!;

/// Field tool routes; mounted under both `/field` (as `photo-log/:projectId`)
/// and `/projects/:projectId` (as `photo-log`) so that "back" returns to
/// where the user came from.
List<GoRoute> _fieldRoutes(String prefix, {String suffix = ''}) => [
  GoRoute(
    path: 'photo-log$suffix',
    name: '$prefix-photo-log',
    builder: (context, state) => PhotoLogPage(projectId: _pid(state)),
  ),
  GoRoute(
    path: 'daily-report$suffix',
    name: '$prefix-daily-report',
    builder: (context, state) => DailyReportPage(projectId: _pid(state)),
  ),
  GoRoute(
    path: 'punch-list$suffix',
    name: '$prefix-punch-list',
    builder: (context, state) => PunchListPage(projectId: _pid(state)),
  ),
];

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (context, state) => const DashboardPage(),
              routes: [
                GoRoute(
                  path: 'settings',
                  name: 'settings',
                  builder: (context, state) => const SettingsPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/projects',
              name: 'projects',
              builder: (context, state) => const ProjectsPage(),
              routes: [
                GoRoute(
                  path: ':projectId',
                  name: 'project-detail',
                  builder: (context, state) =>
                      ProjectDetailPage(projectId: _pid(state)),
                  routes: [
                    GoRoute(
                      path: 'footing',
                      name: 'footing',
                      builder: (context, state) =>
                          FootingPage(projectId: _pid(state)),
                    ),
                    GoRoute(
                      path: 'beam',
                      name: 'beam',
                      builder: (context, state) =>
                          BeamPage(projectId: _pid(state)),
                    ),
                    GoRoute(
                      path: 'column',
                      name: 'column',
                      builder: (context, state) =>
                          ColumnPage(projectId: _pid(state)),
                    ),
                    GoRoute(
                      path: 'slab',
                      name: 'slab',
                      builder: (context, state) =>
                          SlabPage(projectId: _pid(state)),
                    ),
                    GoRoute(
                      path: 'retaining-wall',
                      name: 'retaining-wall',
                      builder: (context, state) =>
                          RetainingWallPage(projectId: _pid(state)),
                    ),
                    GoRoute(
                      path: 'bearing',
                      name: 'bearing',
                      builder: (context, state) =>
                          BearingPage(projectId: _pid(state)),
                    ),
                    GoRoute(
                      path: 'sections',
                      name: 'sections',
                      builder: (context, state) =>
                          SectionsPage(projectId: _pid(state)),
                    ),
                    GoRoute(
                      path: 'quantities',
                      name: 'quantities',
                      builder: (context, state) =>
                          QuantitiesPage(projectId: _pid(state)),
                    ),
                    ..._fieldRoutes('project'),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/field',
              name: 'field',
              builder: (context, state) => const FieldHubPage(),
              routes: _fieldRoutes('field', suffix: '/:projectId'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              name: 'reports',
              builder: (context, state) => const ReportsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reference',
              name: 'reference',
              builder: (context, state) => const ReferencePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
