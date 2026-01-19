import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:ubsohbet/app_data.dart';

const Color _atlasInk = Color(0xFF121214);
const Color _atlasTeal = Color(0xFF0E6B6B);
const Color _atlasAmber = Color(0xFFF0A04B);
const Color _atlasCard = Color(0xFFFFFFFF);
const Color _atlasShadow = Color(0x1A121214);

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(items[i]);
      if (i < items.length - 1) {
        children.add(const SizedBox(height: 12));
        children.add(Divider(color: withOpacity(_atlasTeal, 0.2)));
        children.add(const SizedBox(height: 12));
      }
    }
    return Material(
      color: _atlasCard,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
          boxShadow: [
            BoxShadow(
              color: _atlasShadow,
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                textStyle: textTheme.bodyLarge,
                fontWeight: FontWeight.w700,
                color: _atlasInk,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class SettingsItem extends StatelessWidget {
  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: withOpacity(_atlasTeal, 0.12),
                border: Border.all(color: withOpacity(_atlasTeal, 0.25)),
              ),
              child: Icon(icon, color: withOpacity(_atlasTeal, 0.8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      textStyle: textTheme.bodyLarge,
                      fontWeight: FontWeight.w600,
                      color: _atlasInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      textStyle: textTheme.bodyMedium,
                      color: withOpacity(_atlasInk, 0.65),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: withOpacity(_atlasInk, 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: _atlasInk),
                tooltip: 'Geri',
              ),
            if (showBack) const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.bebasNeue(
                fontSize: 28,
                letterSpacing: 1.1,
                color: _atlasInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.spaceGrotesk(
            textStyle: textTheme.bodyMedium,
            color: withOpacity(_atlasInk, 0.65),
          ),
        ),
      ],
    );
  }
}

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _atlasCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
        boxShadow: [
          BoxShadow(
            color: _atlasShadow,
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  textStyle: textTheme.bodyLarge,
                  fontWeight: FontWeight.w600,
                  color: _atlasInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
                  textStyle: textTheme.bodyMedium,
                  color: withOpacity(_atlasInk, 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: _atlasAmber,
        ),
      ],
    );
  }
}
