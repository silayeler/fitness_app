import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart';

@RoutePage()
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.router.maybePop(),
        ),
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _SectionHeader(title: 'Görünüm'),
          ValueListenableBuilder(
            valueListenable: UserService().settingsListenable,
            builder: (context, box, _) {
              final isDark = UserService().isDarkMode;
              return SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                ),
                title: const Text('Karanlık Mod'),
                value: isDark,
                onChanged: (val) {
                  UserService().setDarkMode(val);
                },
              );
            },
          ),
          const Divider(),
          _SectionHeader(title: 'Hakkında'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Versiyon'),
            subtitle: Text('1.0.0 - Beta'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Gizlilik Politikası'),
            trailing: Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
