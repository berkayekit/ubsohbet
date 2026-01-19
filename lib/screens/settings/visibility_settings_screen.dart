import 'package:flutter/material.dart';

import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/widgets/backgrounds.dart';
import 'package:ubsohbet/screens/settings/settings_widgets.dart';

class VisibilitySettingsScreen extends StatelessWidget {
  const VisibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  title: 'Gorunurluk',
                  subtitle: 'Kimler seni gorur ayarlari.',
                  showBack: true,
                ),
                const SizedBox(height: 16),
                SettingsSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Durum',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sadece eslestigin kisilere gorun.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: withOpacity(kMidnight, 0.65),
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: kSun,
                              foregroundColor: kMidnight,
                            ),
                            child: const Text('Eslestiklerim'),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kMidnight,
                              side: BorderSide(
                                color: withOpacity(kCoral, 0.6),
                              ),
                            ),
                            child: const Text('Herkes'),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kMidnight,
                              side: BorderSide(
                                color: withOpacity(kCoral, 0.6),
                              ),
                            ),
                            child: const Text('Gizli'),
                          ),
                        ],
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
