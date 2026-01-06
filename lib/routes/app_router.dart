import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart'; // Key tipi için



import '../screens/exercise/exercise_select_screen.dart';
import '../screens/exercise/exercise_session_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/main_tab_page.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../services/user_service.dart';

import '../screens/programs/programs_screen.dart';
import '../models/program_model.dart'; // For ProgramModel argument
import '../screens/programs/program_detail_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: MainTabRoute.page, 
          path: '/', 
          initial: true,
          guards: [OnboardingGuard()], // Add Guard
          children: [
            AutoRoute(page: HomeRoute.page, path: 'home', initial: true),
            AutoRoute(page: ExerciseSelectRoute.page, path: 'exercise'),
            AutoRoute(page: HistoryRoute.page, path: 'history'),
            AutoRoute(page: ProfileRoute.page, path: 'profile'),
          ],
        ),
        AutoRoute(page: OnboardingRoute.page, path: '/onboarding'),

        AutoRoute(page: ExerciseSessionRoute.page, path: '/exercise-session'),
        AutoRoute(page: SettingsRoute.page, path: '/settings'),
        
        // Programs
        AutoRoute(page: ProgramsRoute.page, path: '/programs'),
        AutoRoute(page: ProgramDetailRoute.page, path: '/program-detail'),
      ];
}

class OnboardingGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    // Check if onboarding is seen
    if (UserService().onboardingSeen) {
      resolver.next(true);
    } else {
      // Redirect to Onboarding
      // resolver.redirect(const OnboardingRoute()); 
      // But OnboardingRoute might not be generated yet or we need context.
      // AutoRoute usually works with page route consts.
      // Need to make sure imported via app_router.gr.dart.
      resolver.redirect(const OnboardingRoute());
    }
  }
}



