import 'package:flutter/material.dart';

import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/widgets/backgrounds.dart';
import 'package:ubsohbet/screens/settings/settings_widgets.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

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
                  title: 'Engellenenler',
                  subtitle: 'Engelledigin kisileri burada yonet.',
                  showBack: true,
                ),
                const SizedBox(height: 16),
                SettingsSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Henuz engellenen yok.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Birini engellediginde burada gorunur.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: withOpacity(kMidnight, 0.65),
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
