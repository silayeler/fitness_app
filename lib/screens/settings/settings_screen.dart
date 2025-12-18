import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';

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
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Bildirimler'),
          ValueListenableBuilder(
            valueListenable: UserService().settingsListenable,
            builder: (context, box, _) {
              final enabled = UserService().notificationsEnabled;
              final hour = UserService().reminderHour;
              final minute = UserService().reminderMinute;
              final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

              return Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_rounded),
                    title: const Text('Günlük Hatırlatıcı'),
                    value: enabled,
                    onChanged: (val) {
                      UserService().setNotificationsEnabled(val);
                    },
                  ),
                  if (enabled)
                    ListTile(
                      leading: const Icon(Icons.access_time_rounded),
                      title: const Text('Hatırlatma Zamanı'),
                      subtitle: Text(timeStr),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        final now = TimeOfDay(hour: hour, minute: minute);
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: now,
                        );
                        if (picked != null) {
                          UserService().setReminderTime(picked.hour, picked.minute);
                        }
                      },
                    ),
                  if (enabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            NotificationService().showInstantNotification();
                          },
                          icon: const Icon(Icons.notifications_active, size: 16),
                          label: const Text('Test Bildirimi Gönder'),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'Ses ve Geri Bildirim'),
          ValueListenableBuilder(
            valueListenable: UserService().settingsListenable,
            builder: (context, box, _) {
              final sound = UserService().soundEnabled;
              final vibration = UserService().vibrationEnabled;
              return Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    ),
                    title: const Text('Ses Efektleri'),
                    value: sound,
                    onChanged: (val) {
                      UserService().setSoundEnabled(val);
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.vibration_rounded),
                    title: const Text('Titreşim'),
                    value: vibration,
                    onChanged: (val) {
                      UserService().setVibrationEnabled(val);
                    },
                  ),
                ],
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'Görünüm'),
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
          const _SectionHeader(title: 'Hesap ve Veri Yönetimi'),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Profili Güncelle'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const _UpdateProfileDialog(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            title: const Text('Verileri Sıfırla', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Verileri Sıfırla'),
                  content: const Text('Tüm egzersiz geçmişiniz kalıcı olarak silinecek. Bu işlem geri alınamaz. Emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Sıfırla'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await UserService().clearAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tüm veriler sıfırlandı.')),
                  );
                }
              }
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'Hakkında'),
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

class _UpdateProfileDialog extends StatefulWidget {
  const _UpdateProfileDialog();

  @override
  State<_UpdateProfileDialog> createState() => _UpdateProfileDialogState();
}

class _UpdateProfileDialogState extends State<_UpdateProfileDialog> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  String? _selectedGoal;

  final List<String> _goals = [
    'Kilo Verme',
    'Kas Yapma',
    'Form Koruma',
    'Dayanıklılık',
  ];

  @override
  void initState() {
    super.initState();
    final user = UserService().user;
    _nameController.text = user.name == 'Misafir' ? '' : user.name;
    if (user.weight != null) {
      _weightController.text = user.weight.toString();
    }
    _selectedGoal = user.goal;
    // Default if not set or not in list
    if (_selectedGoal == null || !_goals.contains(_selectedGoal)) {
      _selectedGoal = _goals.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profili Güncelle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Adınız',
                hintText: 'Örn: Elif',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Güncel Kilo (kg)',
                suffixText: 'kg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGoal,
              decoration: const InputDecoration(
                labelText: 'Ana Hedef',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.track_changes_outlined),
              ),
              items: _goals.map((goal) {
                return DropdownMenuItem(
                  value: goal,
                  child: Text(goal),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedGoal = val;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
             final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
             final name = _nameController.text.trim();
             
             if (name.isNotEmpty && weight != null && _selectedGoal != null) {
               UserService().updateProfile(
                 name: name,
                 weight: weight, 
                 goal: _selectedGoal
               );
               Navigator.pop(context);
               
               // Show simple feedback
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Profil güncellendi!')),
               );
             } else {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
               );
             }
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
