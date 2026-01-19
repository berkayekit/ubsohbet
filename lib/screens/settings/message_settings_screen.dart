import 'package:flutter/material.dart';

import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/widgets/backgrounds.dart';
import 'package:ubsohbet/screens/settings/settings_widgets.dart';

class MessageSettingsScreen extends StatefulWidget {
  const MessageSettingsScreen({super.key});

  @override
  State<MessageSettingsScreen> createState() => _MessageSettingsScreenState();
}

class _MessageSettingsScreenState extends State<MessageSettingsScreen> {
  bool _messagePreview = true;
  bool _readReceipts = true;
  bool _typingIndicator = true;
  bool _mentions = true;

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
                  title: 'Mesajlar',
                  subtitle: 'Sohbet bildirim ayarlari.',
                  showBack: true,
                ),
                const SizedBox(height: 16),
                SettingsSectionCard(
                  child: Column(
                    children: [
                      SettingsToggleRow(
                        title: 'Mesaj onizleme',
                        subtitle: 'Bildirimde icerik goster',
                        value: _messagePreview,
                        onChanged: (value) {
                          setState(() {
                            _messagePreview = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Divider(color: withOpacity(kMist, 0.8)),
                      const SizedBox(height: 12),
                      SettingsToggleRow(
                        title: 'Goruldu bilgisi',
                        subtitle: 'Okundu bildirimi gonder',
                        value: _readReceipts,
                        onChanged: (value) {
                          setState(() {
                            _readReceipts = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Divider(color: withOpacity(kMist, 0.8)),
                      const SizedBox(height: 12),
                      SettingsToggleRow(
                        title: 'Yaziyor gostergesi',
                        subtitle: 'Karsi tarafa yaziyor goster',
                        value: _typingIndicator,
                        onChanged: (value) {
                          setState(() {
                            _typingIndicator = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Divider(color: withOpacity(kMist, 0.8)),
                      const SizedBox(height: 12),
                      SettingsToggleRow(
                        title: 'Bahsetmeler',
                        subtitle: 'Etiketlenince bildirim al',
                        value: _mentions,
                        onChanged: (value) {
                          setState(() {
                            _mentions = value;
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
