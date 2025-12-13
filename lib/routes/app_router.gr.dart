// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    ExercisePreviewRoute.name: (routeData) {
      final args = routeData.argsAs<ExercisePreviewRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: ExercisePreviewScreen(
          key: args.key,
          exerciseName: args.exerciseName,
        ),
      );
    },
    ExerciseSelectRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ExerciseSelectScreen(),
      );
    },
    ExerciseSessionRoute.name: (routeData) {
      final args = routeData.argsAs<ExerciseSessionRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: ExerciseSessionScreen(
          key: args.key,
          exerciseName: args.exerciseName,
        ),
      );
    },
    HistoryRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const HistoryScreen(),
      );
    },
    HomeRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const HomeScreen(),
      );
    },
    MainTabRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const MainTabPage(),
      );
    },
    OnboardingRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const OnboardingScreen(),
      );
    },
    ProfileRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ProfileScreen(),
      );
    },
    SettingsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SettingsScreen(),
      );
    },
  };
}

/// generated route for
/// [ExercisePreviewScreen]
class ExercisePreviewRoute extends PageRouteInfo<ExercisePreviewRouteArgs> {
  ExercisePreviewRoute({
    Key? key,
    required String exerciseName,
    List<PageRouteInfo>? children,
  }) : super(
          ExercisePreviewRoute.name,
          args: ExercisePreviewRouteArgs(
            key: key,
            exerciseName: exerciseName,
          ),
          initialChildren: children,
        );

  static const String name = 'ExercisePreviewRoute';

  static const PageInfo<ExercisePreviewRouteArgs> page =
      PageInfo<ExercisePreviewRouteArgs>(name);
}

class ExercisePreviewRouteArgs {
  const ExercisePreviewRouteArgs({
    this.key,
    required this.exerciseName,
  });

  final Key? key;

  final String exerciseName;

  @override
  String toString() {
    return 'ExercisePreviewRouteArgs{key: $key, exerciseName: $exerciseName}';
  }
}

/// generated route for
/// [ExerciseSelectScreen]
class ExerciseSelectRoute extends PageRouteInfo<void> {
  const ExerciseSelectRoute({List<PageRouteInfo>? children})
      : super(
          ExerciseSelectRoute.name,
          initialChildren: children,
        );

  static const String name = 'ExerciseSelectRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ExerciseSessionScreen]
class ExerciseSessionRoute extends PageRouteInfo<ExerciseSessionRouteArgs> {
  ExerciseSessionRoute({
    Key? key,
    required String exerciseName,
    List<PageRouteInfo>? children,
  }) : super(
          ExerciseSessionRoute.name,
          args: ExerciseSessionRouteArgs(
            key: key,
            exerciseName: exerciseName,
          ),
          initialChildren: children,
        );

  static const String name = 'ExerciseSessionRoute';

  static const PageInfo<ExerciseSessionRouteArgs> page =
      PageInfo<ExerciseSessionRouteArgs>(name);
}

class ExerciseSessionRouteArgs {
  const ExerciseSessionRouteArgs({
    this.key,
    required this.exerciseName,
  });

  final Key? key;

  final String exerciseName;

  @override
  String toString() {
    return 'ExerciseSessionRouteArgs{key: $key, exerciseName: $exerciseName}';
  }
}

/// generated route for
/// [HistoryScreen]
class HistoryRoute extends PageRouteInfo<void> {
  const HistoryRoute({List<PageRouteInfo>? children})
      : super(
          HistoryRoute.name,
          initialChildren: children,
        );

  static const String name = 'HistoryRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [MainTabPage]
class MainTabRoute extends PageRouteInfo<void> {
  const MainTabRoute({List<PageRouteInfo>? children})
      : super(
          MainTabRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainTabRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [OnboardingScreen]
class OnboardingRoute extends PageRouteInfo<void> {
  const OnboardingRoute({List<PageRouteInfo>? children})
      : super(
          OnboardingRoute.name,
          initialChildren: children,
        );

  static const String name = 'OnboardingRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ProfileScreen]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
      : super(
          ProfileRoute.name,
          initialChildren: children,
        );

  static const String name = 'ProfileRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SettingsScreen]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
