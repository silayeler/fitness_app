import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../routes/app_router.dart';

@RoutePage()
class MainTabPage extends StatelessWidget {
  const MainTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: const [
        HomeRoute(),
        ExerciseSelectRoute(),
        HistoryRoute(),
        ProfileRoute(),
      ],
      appBarBuilder: (context, tabsRouter) {
        return AppBar(
          title: const Text('Mobil Fitness Asistanı'),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                context.router.push(const SettingsRoute());
              },
            ),
          ],
        );
      },
      bottomNavigationBuilder: (context, tabsRouter) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              currentIndex: tabsRouter.activeIndex,
              onTap: tabsRouter.setActiveIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFF00C853),
              unselectedItemColor: Colors.grey[600],
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  label: 'Ana Sayfa',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center_outlined),
                  label: 'Egzersiz',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Geçmiş',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


