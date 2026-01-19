import 'package:flutter/material.dart';

import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/widgets/backgrounds.dart';
import 'package:ubsohbet/screens/settings/settings_widgets.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    void showMessage(String title) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yakinda: $title'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          const SimpleBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const SettingsHeader(
                  title: 'Tercihler',
                  subtitle: 'Gorunum ve deneyim ayarlari.',
                  showBack: true,
                ),
                const SizedBox(height: 16),
                SettingsSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uygulama modu',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () {
                              showMessage('Standart mod');
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: kSun,
                              foregroundColor: kMidnight,
                            ),
                            child: const Text('Standart'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              showMessage('Sessiz mod');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kMidnight,
                              side: BorderSide(
                                color: withOpacity(kCoral, 0.6),
                              ),
                            ),
                            child: const Text('Sessiz'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              showMessage('Odak mod');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kMidnight,
                              side: BorderSide(
                                color: withOpacity(kCoral, 0.6),
                              ),
                            ),
                            child: const Text('Odak'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SettingsSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gizli mod',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Profilini daha az gorunur yap.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: withOpacity(kMidnight, 0.65),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            showMessage('Gizli mod');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: kSun,
                            foregroundColor: kMidnight,
                          ),
                          icon: const Icon(Icons.visibility_off_outlined),
                          label: const Text('Gizli modu ac'),
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
