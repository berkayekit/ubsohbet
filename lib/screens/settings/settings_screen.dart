import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/screens/settings/alert_settings_screen.dart';
import 'package:ubsohbet/screens/settings/blocked_users_screen.dart';
import 'package:ubsohbet/screens/settings/message_settings_screen.dart';
import 'package:ubsohbet/screens/settings/preferences_screen.dart';
import 'package:ubsohbet/screens/settings/profile_settings_screen.dart';
import 'package:ubsohbet/screens/settings/security_settings_screen.dart';
import 'package:ubsohbet/screens/settings/settings_widgets.dart';

const Color _atlasInk = Color(0xFF121214);
const Color _atlasTeal = Color(0xFF0E6B6B);
const Color _atlasCard = Color(0xFFFFFFFF);
const Color _atlasShadow = Color(0x1A121214);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    void openPage(Widget page) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => page),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          const _AtlasBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                      Text(
                        'Ayarlar',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 30,
                          letterSpacing: 1.2,
                          color: _atlasInk,
                        ),
                      ),
                      const Spacer(),
                      const _AtlasChip(
                        label: 'V1',
                        icon: Icons.info_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bildirim, gizlilik ve hesap ayarlarini buradan yonet.',
                    style: GoogleFonts.spaceGrotesk(
                      textStyle: textTheme.bodyMedium,
                      color: withOpacity(_atlasInk, 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: _atlasCard,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      onTap: () {
                        openPage(const PreferencesScreen());
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Ink(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: _atlasCard,
                          border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: _atlasShadow,
                              blurRadius: 18,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: withOpacity(_atlasTeal, 0.15),
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: _atlasTeal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tercihlerini guncelle, deneyimini ozellestir.',
                                style: GoogleFonts.spaceGrotesk(
                                  textStyle: textTheme.bodyMedium,
                                  color: withOpacity(_atlasInk, 0.78),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SettingsGroup(
                    title: 'Hesap',
                    items: [
                      SettingsItem(
                        icon: Icons.person_outline,
                        title: 'Profil',
                        subtitle: 'Gorunurluk ve profil bilgileri',
                        onTap: () {
                          openPage(const ProfileSettingsScreen());
                        },
                      ),
                      SettingsItem(
                        icon: Icons.verified_user_outlined,
                        title: 'Guvenlik',
                        subtitle: 'Sifre ve oturumlar',
                        onTap: () {
                          openPage(const SecuritySettingsScreen());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SettingsGroup(
                    title: 'Bildirimler',
                    items: [
                      SettingsItem(
                        icon: Icons.notifications_none,
                        title: 'Uyari tercihleri',
                        subtitle: 'Sessiz saatler ve sesler',
                        onTap: () {
                          openPage(const AlertSettingsScreen());
                        },
                      ),
                      SettingsItem(
                        icon: Icons.mark_email_unread_outlined,
                        title: 'Mesajlar',
                        subtitle: 'Yeni sohbet bildirimleri',
                        onTap: () {
                          openPage(const MessageSettingsScreen());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SettingsGroup(
                    title: 'Gizlilik',
                    items: [
                      SettingsItem(
                        icon: Icons.block_outlined,
                        title: 'Engellenenler',
                        subtitle: 'Engelledigin kisiler',
                        onTap: () {
                          openPage(const BlockedUsersScreen());
                        },
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AtlasBackground extends StatelessWidget {
  const _AtlasBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7F7F7), Color(0xFFEFEFEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _AtlasChip extends StatelessWidget {
  const _AtlasChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _atlasCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: withOpacity(_atlasTeal, 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _atlasTeal),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600,
              color: _atlasInk,
            ),
          ),
        ],
      ),
    );
  }
}
