import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ubsohbet/app_data.dart';
import 'package:ubsohbet/screens/voice_room_screen.dart';
import 'package:ubsohbet/screens/tokens/token_shop_screen.dart';
import 'package:ubsohbet/screens/tokens/premium_screen.dart';

const Color _atlasInk = Color(0xFF121214);
const Color _atlasTeal = Color(0xFF0E6B6B);
const Color _atlasSea = Color(0xFF2E7D6E);
const Color _atlasAmber = Color(0xFFF0A04B);
const Color _atlasCard = Color(0xFFFFFFFF);
const Color _atlasShadow = Color(0x1A121214);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';
  bool _showShuffled = false;
  late final TextEditingController _searchController;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<City> get _filteredCities {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kCities;
    return kCities
        .where((city) => city.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filteredCities = _filteredCities;

    void openPage(Widget page) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
    }

    const totalTokens = 24;
    const friendTokens = 3;
    const skipTokens = 5;

    return StreamBuilder<DatabaseEvent>(
      stream: _database
          .ref('presence')
          .orderByChild('online')
          .equalTo(true)
          .onValue,
      builder: (context, presenceSnapshot) {
        final counts = <String, int>{};
        final rawPresence = presenceSnapshot.data?.snapshot.value;
        if (rawPresence is Map) {
          rawPresence.forEach((_, value) {
            if (value is Map) {
              final city = value['city'];
              if (city is String && city.trim().isNotEmpty) {
                counts[city] = (counts[city] ?? 0) + 1;
              }
            }
          });
        }

        final cities = filteredCities.map((city) {
          final online = counts[city.name] ?? 0;
          return City(
            name: city.name,
            matchKey: city.matchKey,
            tagline: city.tagline,
            onlineCount: online,
            accent: city.accent,
          );
        }).toList();
        final maxOnline = cities.fold<int>(
          0,
          (currentMax, city) =>
              city.onlineCount > currentMax ? city.onlineCount : currentMax,
        );
        if (maxOnline > 0) {
          final maxIndex =
              cities.indexWhere((city) => city.onlineCount == maxOnline);
          if (maxIndex > 0) {
            final topCity = cities.removeAt(maxIndex);
            cities.insert(0, topCity);
          }
        }

        final computedTotal =
            counts.values.fold<int>(0, (sum, value) => sum + value);
        final totalOnline = computedTotal < 0 ? 0 : computedTotal;
        final totalLabel = totalOnline >= 1000
            ? 'Toplam aktif ${(totalOnline / 1000).toStringAsFixed(1)}K'
            : 'Toplam aktif $totalOnline';

        return Stack(
          children: [
            const _AtlasBackground(),
            SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'UB',
                              style: GoogleFonts.bebasNeue(
                                fontSize: 40,
                                letterSpacing: 1.2,
                                color: _atlasInk,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PULSE',
                              style: GoogleFonts.bebasNeue(
                                fontSize: 32,
                                letterSpacing: 3,
                                color: _atlasTeal,
                              ),
                            ),
                            const Spacer(),
                            _AtlasChip(
                              label: totalLabel,
                              icon: Icons.graphic_eq,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sadece ses. Gercek zamanli eslesme.',
                          style: GoogleFonts.spaceGrotesk(
                            textStyle: textTheme.bodyMedium,
                            color: withOpacity(_atlasInk, 0.7),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _TokenPanel(
                          totalTokens: totalTokens,
                          friendTokens: friendTokens,
                          skipTokens: skipTokens,
                          onBuyTokens: () => openPage(const TokenShopScreen(currentTokens: totalTokens)),
                          onPremium: () => openPage(const PremiumScreen()),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [_atlasTeal, _atlasSea],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _atlasShadow,
                                blurRadius: 24,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sesli eslesme',
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 28,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sehir sec ve tek dokunusla baglan.',
                                style: GoogleFonts.spaceGrotesk(
                                  textStyle: textTheme.bodyLarge,
                                  color: withOpacity(Colors.white, 0.85),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _AtlasStat(
                                    label: 'Bekleme',
                                    value: '14 sn',
                                  ),
                                  const SizedBox(width: 12),
                                  _AtlasStat(
                                    label: 'Durum',
                                    value: 'Canli',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SearchField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _query = value;
                              _showShuffled = false;
                            });
                          },
                          onClear: () {
                            setState(() {
                              _query = '';
                              _showShuffled = false;
                              _searchController.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 22),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Sehir haritasi',
                                  style: GoogleFonts.bebasNeue(
                                    fontSize: 24,
                                    letterSpacing: 1.4,
                                    color: _atlasInk,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                _AtlasToggle(
                                  selected: !_showShuffled,
                                  label: 'Sehirler',
                                  icon: Icons.list_alt,
                                  onTap: () {
                                    setState(() {
                                      _showShuffled = false;
                                      _query = '';
                                      _searchController.clear();
                                    });
                                  },
                                ),
                                _AtlasToggle(
                                  selected: _showShuffled,
                                  label: 'Karisik havuz',
                                  icon: Icons.shuffle,
                                  onTap: () {
                                    setState(() {
                                      _showShuffled = true;
                                      _query = '';
                                      _searchController.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_showShuffled)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _atlasCard,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: withOpacity(_atlasTeal, 0.25),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _atlasShadow,
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Karisik havuz',
                                  style: GoogleFonts.bebasNeue(
                                    fontSize: 22,
                                    letterSpacing: 1.2,
                                    color: _atlasInk,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Sehir ayrimi yok. Bu butonda olanlarla esles.',
                                  style: GoogleFonts.spaceGrotesk(
                                    textStyle: textTheme.bodyMedium,
                                    color: withOpacity(_atlasInk, 0.7),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () {
                                      final poolCity = City(
                                        name: 'Karisik',
                                        matchKey: 'karisik',
                                        tagline: 'Karisik havuzda eslesme',
                                        onlineCount: totalOnline,
                                        accent: _atlasAmber,
                                      );
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => VoiceRoomScreen(
                                            city: poolCity,
                                          ),
                                        ),
                                      );
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _atlasAmber,
                                      foregroundColor: _atlasInk,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Ara'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (filteredCities.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _atlasCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: withOpacity(_atlasTeal, 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_off, color: _atlasInk),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Sonuc bulunamadi.',
                                    style: GoogleFonts.spaceGrotesk(
                                      textStyle: textTheme.bodyMedium,
                                      color: withOpacity(_atlasInk, 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: List.generate(
                              cities.length,
                              (index) => CityCard(
                                city: cities[index],
                                index: index,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => VoiceRoomScreen(
                                        city: cities[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
        );
      },
    );
  }
}

class _AtlasBackground extends StatelessWidget {
  const _AtlasBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF7F7F7), Color(0xFFEFEFEF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ],
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

class _AtlasToggle extends StatelessWidget {
  const _AtlasToggle({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? withOpacity(_atlasAmber, 0.25) : _atlasCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _atlasAmber : withOpacity(_atlasTeal, 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _atlasInk),
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
      ),
    );
  }
}

class _AtlasStat extends StatelessWidget {
  const _AtlasStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: withOpacity(Colors.white, 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: withOpacity(Colors.white, 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: withOpacity(Colors.white, 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.bebasNeue(
                fontSize: 20,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.spaceGrotesk(
        color: _atlasInk,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Sehir ara',
        hintStyle: GoogleFonts.spaceGrotesk(
          color: withOpacity(_atlasInk, 0.45),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(Icons.search, color: _atlasInk),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, color: _atlasInk),
                onPressed: onClear,
                tooltip: 'Temizle',
              ),
        filled: true,
        fillColor: _atlasCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: withOpacity(_atlasTeal, 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: withOpacity(_atlasTeal, 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _atlasTeal, width: 1.4),
        ),
      ),
    );
  }
}

class CityCard extends StatelessWidget {
  const CityCard({
    super.key,
    required this.city,
    required this.index,
    required this.onTap,
  });

  final City city;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _atlasCard,
            borderRadius: BorderRadius.circular(26),
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
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: withOpacity(_atlasTeal, 0.12),
                ),
                child: Icon(Icons.place, color: _atlasTeal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.name,
                      style: GoogleFonts.spaceGrotesk(
                        textStyle: textTheme.titleMedium,
                        fontWeight: FontWeight.w700,
                        color: _atlasInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      city.tagline,
                      style: GoogleFonts.spaceGrotesk(
                        textStyle: textTheme.bodyMedium,
                        color: withOpacity(_atlasInk, 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: withOpacity(_atlasAmber, 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: withOpacity(_atlasAmber, 0.4)),
                    ),
                    child: Text(
                      '${city.onlineCount} aktif',
                      style: GoogleFonts.spaceGrotesk(
                        textStyle: textTheme.bodySmall,
                        fontWeight: FontWeight.w600,
                        color: _atlasInk,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _TokenPanel extends StatelessWidget {
  const _TokenPanel({
    required this.totalTokens,
    required this.friendTokens,
    required this.skipTokens,
    required this.onBuyTokens,
    required this.onPremium,
  });

  final int totalTokens;
  final int friendTokens;
  final int skipTokens;
  final VoidCallback onBuyTokens;
  final VoidCallback onPremium;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _atlasCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
        boxShadow: [
          BoxShadow(
            color: _atlasShadow,
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: withOpacity(_atlasTeal, 0.12),
                  border: Border.all(color: withOpacity(_atlasTeal, 0.25)),
                ),
                child: const Icon(
                  Icons.confirmation_num_outlined,
                  color: _atlasTeal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jetonlar',
                  style: GoogleFonts.spaceGrotesk(
                    textStyle: textTheme.bodyLarge,
                    fontWeight: FontWeight.w700,
                    color: _atlasInk,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: withOpacity(_atlasAmber, 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: withOpacity(_atlasAmber, 0.4)),
                ),
                child: Text(
                  '$totalTokens',
                  style: GoogleFonts.spaceGrotesk(
                    textStyle: textTheme.bodyMedium,
                    fontWeight: FontWeight.w700,
                    color: _atlasInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TokenStat(
                  icon: Icons.person_add_alt_1,
                  label: 'Arkadas ekleme',
                  value: friendTokens,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TokenStat(
                  icon: Icons.skip_next,
                  label: 'Pas gecme',
                  value: skipTokens,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onBuyTokens,
                  style: FilledButton.styleFrom(
                    backgroundColor: _atlasAmber,
                    foregroundColor: _atlasInk,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Jeton al'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onPremium,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: withOpacity(_atlasTeal, 0.45)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Premium al',
                    style: GoogleFonts.spaceGrotesk(
                      textStyle: textTheme.bodyMedium,
                      fontWeight: FontWeight.w700,
                      color: _atlasInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TokenStat extends StatelessWidget {
  const _TokenStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: withOpacity(_atlasTeal, 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: withOpacity(_atlasTeal, 0.2)),
      ),
      child: Row(
        children: [
          Container(
            height: 26,
            width: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _atlasCard,
              border: Border.all(color: withOpacity(_atlasTeal, 0.25)),
            ),
            child: Icon(icon, size: 14, color: _atlasTeal),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    textStyle: textTheme.bodySmall,
                    color: withOpacity(_atlasInk, 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: GoogleFonts.spaceGrotesk(
                    textStyle: textTheme.bodyLarge,
                    color: _atlasInk,
                    fontWeight: FontWeight.w700,
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
