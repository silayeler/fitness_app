import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart'; // Key tipi için


import '../screens/exercise/exercise_preview_screen.dart';
import '../screens/exercise/exercise_select_screen.dart';
import '../screens/exercise/exercise_session_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/main_tab_page.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
        // Uygulamanın ana tab yapısı.
        AutoRoute(page: MainTabRoute.page, path: '/', initial: true,
          children: [
            AutoRoute(page: HomeRoute.page, path: 'home', initial: true),
            AutoRoute(page: ExerciseSelectRoute.page, path: 'exercise'),
            AutoRoute(page: HistoryRoute.page, path: 'history'),
            AutoRoute(page: ProfileRoute.page, path: 'profile'),
          ],
        ),
        AutoRoute(page: OnboardingRoute.page, path: '/onboarding'),
        AutoRoute(page: ExercisePreviewRoute.page, path: '/exercise-preview'),
        AutoRoute(page: ExerciseSessionRoute.page, path: '/exercise-session'),
        AutoRoute(page: SettingsRoute.page, path: '/settings'),
      ];
}



