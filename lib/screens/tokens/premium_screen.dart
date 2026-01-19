import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/widgets/backgrounds.dart';

const Color _atlasInk = Color(0xFF121214);
const Color _atlasTeal = Color(0xFF0E6B6B);
const Color _atlasAmber = Color(0xFFF0A04B);
const Color _atlasCard = Color(0xFFFFFFFF);
const Color _atlasShadow = Color(0x1A121214);

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlan = 0;

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                        'Premium',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 30,
                          letterSpacing: 1.2,
                          color: _atlasInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Daha hizli eslesme, daha fazla kontrol ve rozetlerle one cik.',
                    style: GoogleFonts.spaceGrotesk(
                      textStyle: textTheme.bodyMedium,
                      color: withOpacity(_atlasInk, 0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: withOpacity(_atlasTeal, 0.12),
                                border: Border.all(
                                  color: withOpacity(_atlasTeal, 0.25),
                                ),
                              ),
                              child:
                                  const Icon(Icons.stars, color: _atlasTeal),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Premium avantajlari',
                                style: GoogleFonts.spaceGrotesk(
                                  textStyle: textTheme.bodyLarge,
                                  fontWeight: FontWeight.w700,
                                  color: _atlasInk,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const _FeatureRow(
                          icon: Icons.flash_on,
                          title: 'Oncelikli eslesme',
                          subtitle: 'Yo?un saatlerde once sen baglan.',
                        ),
                        const _FeatureRow(
                          icon: Icons.block_outlined,
                          title: 'Reklamsiz deneyim',
                          subtitle: 'Kesintisiz sohbet akisi.',
                        ),
                        const _FeatureRow(
                          icon: Icons.auto_awesome,
                          title: 'Premium rozet',
                          subtitle: 'Profilinde premium vurgusu.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PlanTile(
                    title: 'Aylik plan',
                    price: '59,90 TL',
                    subtitle: 'Her ay otomatik yenilenir',
                    selected: _selectedPlan == 0,
                    onTap: () => setState(() {
                      _selectedPlan = 0;
                    }),
                  ),
                  const SizedBox(height: 12),
                  _PlanTile(
                    title: 'Yillik plan',
                    price: '499,90 TL',
                    subtitle: '2 ay ucretsiz',
                    selected: _selectedPlan == 1,
                    tag: 'En avantajli',
                    onTap: () => setState(() {
                      _selectedPlan = 1;
                    }),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => showSoon('Premium satin alma'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _atlasAmber,
                        foregroundColor: _atlasInk,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Premium ol'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Iptal edebilirsin. Odeme altyapisi yakinda.',
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: withOpacity(_atlasTeal, 0.12),
              border: Border.all(color: withOpacity(_atlasTeal, 0.25)),
            ),
            child: Icon(icon, size: 18, color: _atlasTeal),
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
                    fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.tag,
  });

  final String title;
  final String price;
  final String subtitle;
  final bool selected;
  final String? tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _atlasCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? withOpacity(_atlasAmber, 0.6)
                : withOpacity(_atlasTeal, 0.2),
            width: selected ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _atlasShadow,
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? withOpacity(_atlasAmber, 0.2)
                    : withOpacity(_atlasTeal, 0.12),
                border: Border.all(
                  color: selected
                      ? withOpacity(_atlasAmber, 0.45)
                      : withOpacity(_atlasTeal, 0.25),
                ),
              ),
              child: Icon(
                selected ? Icons.check : Icons.workspace_premium,
                color: selected ? _atlasAmber : _atlasTeal,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.spaceGrotesk(
                          textStyle: textTheme.bodyLarge,
                          fontWeight: FontWeight.w700,
                          color: _atlasInk,
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: withOpacity(_atlasAmber, 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: withOpacity(_atlasAmber, 0.4),
                            ),
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
                    ],
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
            Text(
              price,
              style: GoogleFonts.bebasNeue(
                fontSize: 26,
                letterSpacing: 1.2,
                color: _atlasInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
