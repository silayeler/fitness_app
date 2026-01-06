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
          customReps: args.customReps,
          customDuration: args.customDuration,
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
    ProgramDetailRoute.name: (routeData) {
      final args = routeData.argsAs<ProgramDetailRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: ProgramDetailScreen(
          key: args.key,
          program: args.program,
        ),
      );
    },
    ProgramsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ProgramsScreen(),
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
    int? customReps,
    int? customDuration,
    List<PageRouteInfo>? children,
  }) : super(
          ExerciseSessionRoute.name,
          args: ExerciseSessionRouteArgs(
            key: key,
            exerciseName: exerciseName,
            customReps: customReps,
            customDuration: customDuration,
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
    this.customReps,
    this.customDuration,
  });

  final Key? key;

  final String exerciseName;

  final int? customReps;

  final int? customDuration;

  @override
  String toString() {
    return 'ExerciseSessionRouteArgs{key: $key, exerciseName: $exerciseName, customReps: $customReps, customDuration: $customDuration}';
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
/// [ProgramDetailScreen]
class ProgramDetailRoute extends PageRouteInfo<ProgramDetailRouteArgs> {
  ProgramDetailRoute({
    Key? key,
    required ProgramModel program,
    List<PageRouteInfo>? children,
  }) : super(
          ProgramDetailRoute.name,
          args: ProgramDetailRouteArgs(
            key: key,
            program: program,
          ),
          initialChildren: children,
        );

  static const String name = 'ProgramDetailRoute';

  static const PageInfo<ProgramDetailRouteArgs> page =
      PageInfo<ProgramDetailRouteArgs>(name);
}

class ProgramDetailRouteArgs {
  const ProgramDetailRouteArgs({
    this.key,
    required this.program,
  });

  final Key? key;

  final ProgramModel program;

  @override
  String toString() {
    return 'ProgramDetailRouteArgs{key: $key, program: $program}';
  }
}

/// generated route for
/// [ProgramsScreen]
class ProgramsRoute extends PageRouteInfo<void> {
  const ProgramsRoute({List<PageRouteInfo>? children})
      : super(
          ProgramsRoute.name,
          initialChildren: children,
        );

  static const String name = 'ProgramsRoute';

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
