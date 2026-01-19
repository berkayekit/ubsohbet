import 'package:flutter/material.dart';

import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/widgets/backgrounds.dart';
import 'package:ubsohbet/screens/settings/settings_widgets.dart';

class AlertSettingsScreen extends StatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> {
  bool _pushAlerts = true;
  bool _soundAlerts = true;
  bool _vibration = true;
  bool _quietHours = false;

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
                  title: 'Uyari tercihleri',
                  subtitle: 'Bildirim ses ve zaman ayarlari.',
                  showBack: true,
                ),
                const SizedBox(height: 16),
                SettingsSectionCard(
                  child: Column(
                    children: [
                      SettingsToggleRow(
                        title: 'Anlik bildirim',
                        subtitle: 'Push bildirimi al',
                        value: _pushAlerts,
                        onChanged: (value) {
                          setState(() {
                            _pushAlerts = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Divider(color: withOpacity(kMist, 0.8)),
                      const SizedBox(height: 12),
                      SettingsToggleRow(
                        title: 'Ses',
                        subtitle: 'Bildirim seslerini ac',
                        value: _soundAlerts,
                        onChanged: (value) {
                          setState(() {
                            _soundAlerts = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Divider(color: withOpacity(kMist, 0.8)),
                      const SizedBox(height: 12),
                      SettingsToggleRow(
                        title: 'Titresim',
                        subtitle: 'Bildirimlerde titresim',
                        value: _vibration,
                        onChanged: (value) {
                          setState(() {
                            _vibration = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Divider(color: withOpacity(kMist, 0.8)),
                      const SizedBox(height: 12),
                      SettingsToggleRow(
                        title: 'Sessiz saatler',
                        subtitle: '22:00 - 08:00 arasi',
                        value: _quietHours,
                        onChanged: (value) {
                          setState(() {
                            _quietHours = value;
                          });
                        },
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
