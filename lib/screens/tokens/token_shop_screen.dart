import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/widgets/backgrounds.dart';

const Color _atlasInk = Color(0xFF121214);
const Color _atlasTeal = Color(0xFF0E6B6B);
const Color _atlasAmber = Color(0xFFF0A04B);
const Color _atlasCard = Color(0xFFFFFFFF);
const Color _atlasShadow = Color(0x1A121214);

class TokenShopScreen extends StatelessWidget {
  const TokenShopScreen({
    super.key,
    required this.currentTokens,
  });

  final int currentTokens;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    void showSoon(String label) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label yakinda.'),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: _atlasInk),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Jeton al',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 26,
                          letterSpacing: 1.1,
                          color: _atlasInk,
                        ),
                      ),
                      const Spacer(),
                      _CountChip(value: currentTokens.toString()),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sohbeti hizlandir, daha fazla eslesme icin jeton kullan.',
                    style: GoogleFonts.spaceGrotesk(
                      textStyle: textTheme.bodyMedium,
                      color: withOpacity(_atlasInk, 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      _UsageChip(
                        icon: Icons.person_add_alt_1,
                        label: 'Arkadas ekleme',
                      ),
                      SizedBox(width: 8),
                      _UsageChip(
                        icon: Icons.skip_next,
                        label: 'Pas gecme',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TokenPackCard(
                    title: 'Mini paket',
                    tokens: 5,
                    price: '7 TL',
                    onTap: () => showSoon('Mini paket'),
                  ),
                  const SizedBox(height: 10),
                  _TokenPackCard(
                    title: 'Baslangic paket',
                    tokens: 10,
                    price: '12 TL',
                    onTap: () => showSoon('Baslangic paket'),
                  ),
                  const SizedBox(height: 10),
                  _TokenPackCard(
                    title: 'Orta paket',
                    tokens: 15,
                    price: '17 TL',
                    onTap: () => showSoon('Orta paket'),
                  ),
                  const SizedBox(height: 10),
                  _TokenPackCard(
                    title: 'Avantaj paket',
                    tokens: 20,
                    price: '22 TL',
                    tag: 'Populer',
                    onTap: () => showSoon('Avantaj paket'),
                  ),
                  const SizedBox(height: 10),
                  _TokenPackCard(
                    title: 'Mega paket',
                    tokens: 50,
                    price: '50 TL',
                    onTap: () => showSoon('Mega paket'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Odeme islemleri yakinda aktif edilecek.',
                    style: GoogleFonts.spaceGrotesk(
                      textStyle: textTheme.bodySmall,
                      color: withOpacity(_atlasInk, 0.6),
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

class _TokenPackCard extends StatelessWidget {
  const _TokenPackCard({
    required this.title,
    required this.tokens,
    required this.price,
    required this.onTap,
    this.tag,
  });

  final String title;
  final int tokens;
  final String price;
  final String? tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _atlasCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
        boxShadow: [
          BoxShadow(
            color: _atlasShadow,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: withOpacity(_atlasTeal, 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jeton',
                  style: GoogleFonts.spaceGrotesk(
                    textStyle: textTheme.bodySmall,
                    color: withOpacity(_atlasInk, 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tokens.toString(),
                  style: GoogleFonts.spaceGrotesk(
                    textStyle: textTheme.bodyLarge,
                    color: _atlasInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.spaceGrotesk(
                          textStyle: textTheme.bodyMedium,
                          fontWeight: FontWeight.w700,
                          color: _atlasInk,
                        ),
                      ),
                    ),
                    if (tag != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: withOpacity(_atlasAmber, 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: withOpacity(_atlasAmber, 0.4)),
                        ),
                        child: Text(
                          tag!,
                          style: GoogleFonts.spaceGrotesk(
                            textStyle: textTheme.bodySmall,
                            fontWeight: FontWeight.w700,
                            color: _atlasInk,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  price,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    letterSpacing: 1.1,
                    color: _atlasInk,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: _atlasAmber,
              foregroundColor: _atlasInk,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Al'),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _atlasCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: withOpacity(_atlasTeal, 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.confirmation_num_outlined,
              size: 14, color: _atlasTeal),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              textStyle: textTheme.bodyMedium,
              fontWeight: FontWeight.w700,
              color: _atlasInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageChip extends StatelessWidget {
  const _UsageChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: withOpacity(_atlasTeal, 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _atlasTeal),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              textStyle: textTheme.bodySmall,
              color: withOpacity(_atlasInk, 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
