import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/auth/ui/register_screen.dart';
import '../../features/school_admin/ui/admin_dashboard.dart';
import '../../features/school_admin/ui/manage_classes_screen.dart';
import '../../features/school_admin/ui/manage_teachers_screen.dart';
import '../../features/teacher/ui/teacher_dashboard.dart';
import '../../features/teacher/ui/class_detail_screen.dart';
import '../../features/teacher/ui/spelling_sets_screen.dart';
import '../../features/teacher/ui/edit_spelling_set_screen.dart';
import '../../features/parent/ui/parent_dashboard.dart';
import '../../features/parent/ui/child_detail_screen.dart';
import '../../features/parent/ui/child_settings_screen.dart';
import '../../features/parent/ui/personal_lists_screen.dart';
import '../../features/child/ui/child_home_screen.dart';
import '../../features/child/ui/set_list_screen.dart';
import '../../features/child/ui/practice_screen.dart';
import '../../features/child/ui/results_screen.dart';
import '../../shared/models/profile.dart';

// Route name constants
abstract class AppRoutes {
  static const login = '/login';
  static const register = '/register';

  // Admin
  static const adminDashboard = '/admin';
  static const adminClasses = '/admin/classes/:schoolId';
  static const adminTeachers = '/admin/teachers/:schoolId';

  // Teacher
  static const teacherDashboard = '/teacher';
  static const teacherClass = '/teacher/class/:classId';
  static const teacherSets = '/teacher/class/:classId/sets';
  static const teacherEditSet = '/teacher/set/:setId/edit';

  // Parent
  static const parentDashboard = '/parent';
  static const parentChild = '/parent/child/:childId';
  static const parentChildSettings = '/parent/child/:childId/settings';
  static const parentPersonalLists = '/parent/child/:childId/lists';

  // Child
  static const childHome = '/child';
  static const childSetList = '/child/sets';
  static const childPractice = '/child/practice/:setId';
  static const childResults = '/child/results/:sessionId';
}

/// Bridges Riverpod auth state into GoRouter's refreshListenable.
/// The GoRouter instance is created once; this notifier tells it when
/// to re-evaluate the redirect without recreating the router.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(currentProfileProvider, (_, __) => notifyListeners());
  }
}

final _routerNotifierProvider = Provider<_RouterNotifier>(
  (ref) => _RouterNotifier(ref),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: notifier,
    redirect: (context, state) {
      // Use ref.read — we only want the *current* value, not to watch
      final authState = ref.read(authStateProvider);
      final profile = ref.read(currentProfileProvider);

      final isLoggedIn = authState.valueOrNull?.session != null;
      final isOnAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      // Not logged in → always go to login
      if (!isLoggedIn && !isOnAuth) return AppRoutes.login;

      // Logged in but on auth screen → redirect to role home
      if (isLoggedIn && isOnAuth) {
        final p = profile.valueOrNull;
        if (p == null) return null; // profile still loading — wait
        return switch (p.role) {
          UserRole.schoolAdmin => AppRoutes.adminDashboard,
          UserRole.teacher => AppRoutes.teacherDashboard,
          UserRole.parent => AppRoutes.parentDashboard,
          UserRole.child => AppRoutes.childHome,
        };
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),

      // ── Admin ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (_, __) => const AdminDashboard(),
        routes: [
          GoRoute(
            path: 'classes/:schoolId',
            builder: (_, state) =>
                ManageClassesScreen(schoolId: state.pathParameters['schoolId']!),
          ),
          GoRoute(
            path: 'teachers/:schoolId',
            builder: (_, state) => ManageTeachersScreen(
                schoolId: state.pathParameters['schoolId']!),
          ),
        ],
      ),

      // ── Teacher ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.teacherDashboard,
        builder: (_, __) => const TeacherDashboard(),
        routes: [
          GoRoute(
            path: 'class/:classId',
            builder: (_, state) =>
                ClassDetailScreen(classId: state.pathParameters['classId']!),
            routes: [
              GoRoute(
                path: 'sets',
                builder: (_, state) => SpellingSetsScreen(
                    classId: state.pathParameters['classId']!),
              ),
            ],
          ),
          GoRoute(
            path: 'set/:setId/edit',
            builder: (_, state) =>
                EditSpellingSetScreen(setId: state.pathParameters['setId']!),
          ),
        ],
      ),

      // ── Parent ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.parentDashboard,
        builder: (_, __) => const ParentDashboard(),
        routes: [
          GoRoute(
            path: 'child/:childId',
            builder: (_, state) =>
                ChildDetailScreen(childId: state.pathParameters['childId']!),
            routes: [
              GoRoute(
                path: 'settings',
                builder: (_, state) => ChildSettingsScreen(
                    childId: state.pathParameters['childId']!),
              ),
              GoRoute(
                path: 'lists',
                builder: (_, state) => PersonalListsScreen(
                    childId: state.pathParameters['childId']!),
              ),
            ],
          ),
        ],
      ),

      // ── Child ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.childHome,
        builder: (_, __) => const ChildHomeScreen(),
        routes: [
          GoRoute(
            path: 'sets',
            builder: (_, __) => const SetListScreen(),
          ),
          GoRoute(
            path: 'practice/:setId',
            builder: (_, state) =>
                PracticeScreen(setId: state.pathParameters['setId']!),
          ),
          GoRoute(
            path: 'results/:sessionId',
            builder: (_, state) =>
                ResultsScreen(sessionId: state.pathParameters['sessionId']!),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

