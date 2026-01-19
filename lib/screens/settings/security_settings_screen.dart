import 'package:flutter/material.dart';

import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/widgets/backgrounds.dart';
import 'package:ubsohbet/screens/settings/settings_widgets.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _twoFactor = true;
  bool _deviceAlerts = true;
  bool _screenLock = false;

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
                  title: 'Guvenlik',
                  subtitle: 'Hesap ve oturum guvenligi.',
                  showBack: true,
                ),
                const SizedBox(height: 16),
                SettingsSectionCard(
                  child: Column(
                    children: [
                      SettingsToggleRow(
                        title: 'Iki adimli dogrulama',
                        subtitle: 'Ek guvenlik katmani',
                        value: _twoFactor,
                        onChanged: (value) {
                          setState(() {
                            _twoFactor = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Divider(color: withOpacity(kMist, 0.8)),
                      const SizedBox(height: 12),
                      SettingsToggleRow(
                        title: 'Yeni cihaz uyarisi',
                        subtitle: 'Oturum acilinca bildirim al',
                        value: _deviceAlerts,
                        onChanged: (value) {
                          setState(() {
                            _deviceAlerts = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Divider(color: withOpacity(kMist, 0.8)),
                      const SizedBox(height: 12),
                      SettingsToggleRow(
                        title: 'Ekran kilidi',
                        subtitle: 'Uygulama acilisinda kilit',
                        value: _screenLock,
                        onChanged: (value) {
                          setState(() {
                            _screenLock = value;
                          });
                        },
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
                        'Oturumlar',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Son girisler ve aktif cihazlar burada listelenecek.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: withOpacity(kMidnight, 0.65),
                            ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Yakinda: Oturum yonetimi'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kMidnight,
                            side: BorderSide(
                              color: withOpacity(kCoral, 0.6),
                            ),
                          ),
                          icon: const Icon(Icons.devices),
                          label: const Text('Cihazlari gor'),
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
