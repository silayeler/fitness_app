
import 'package:flutter/foundation.dart'; // For ValueListenableBuilder
import 'package:flutter/material.dart';

import 'routes/app_router.dart';

import 'services/user_service.dart';
import 'services/notification_service.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await UserService().init();
  await NotificationService().init();
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter();

    return ValueListenableBuilder(
      valueListenable: UserService().settingsListenable,
      builder: (context, box, _) {
        final isDark = UserService().isDarkMode;
        
        return MaterialApp.router(
          title: 'Posturify',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            scaffoldBackgroundColor: const Color(0xFFF4F5F7),
            cardColor: Colors.white,
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E1E), // For containers
              onSurface: const Color(0xFFE0E0E0),
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          routerConfig: appRouter.config(),
        );
      },
    );
  }
}



