import 'package:flutter/material.dart';

Color withOpacity(Color color, double opacity) {
  final clamped = opacity.clamp(0.0, 1.0);
  return color.withValues(alpha: clamped);
}

const Color kMidnight = Color(0xFF111111);
const Color kDeepSea = kSun;
const Color kSand = Color(0xFFF5F5F5);
const Color kMist = kSand;
const Color kSun = Color(0xFF0F766E);
const Color kCoral = kSun;
const Color kLime = kSun;

final ValueNotifier<List<String>> kFriends = ValueNotifier<List<String>>([]);
final ValueNotifier<int> kNavIndex = ValueNotifier<int>(0);
final ValueNotifier<String?> kActiveChat = ValueNotifier<String?>(null);
final ValueNotifier<String?> kActiveChatName = ValueNotifier<String?>(null);

class City {
  const City({
    required this.name,
    required this.matchKey,
    required this.tagline,
    required this.onlineCount,
    required this.accent,
  });

  final String name;
  final String matchKey;
  final String tagline;
  final int onlineCount;
  final Color accent;
}

const List<String> kCityNames = [
  'Adana',
  'Adıyaman',
  'Afyonkarahisar',
  'Ağrı',
  'Amasya',
  'Ankara',
  'Antalya',
  'Artvin',
  'Aydın',
  'Balıkesir',
  'Bilecik',
  'Bingöl',
  'Bitlis',
  'Bolu',
  'Burdur',
  'Bursa',
  'Çanakkale',
  'Çankırı',
  'Çorum',
  'Denizli',
  'Diyarbakır',
  'Edirne',
  'Elazığ',
  'Erzincan',
  'Erzurum',
  'Eskişehir',
  'Gaziantep',
  'Giresun',
  'Gümüşhane',
  'Hakkâri',
  'Hatay',
  'Isparta',
  'Mersin',
  'İstanbul',
  'İzmir',
  'Kars',
  'Kastamonu',
  'Kayseri',
  'Kırklareli',
  'Kırşehir',
  'Kocaeli',
  'Konya',
  'Kütahya',
  'Malatya',
  'Manisa',
  'Kahramanmaraş',
  'Mardin',
  'Muğla',
  'Muş',
  'Nevşehir',
  'Niğde',
  'Ordu',
  'Rize',
  'Sakarya',
  'Samsun',
  'Siirt',
  'Sinop',
  'Sivas',
  'Tekirdağ',
  'Tokat',
  'Trabzon',
  'Tunceli',
  'Şanlıurfa',
  'Uşak',
  'Van',
  'Yozgat',
  'Zonguldak',
  'Aksaray',
  'Bayburt',
  'Karaman',
  'Kırıkkale',
  'Batman',
  'Şırnak',
  'Bartın',
  'Ardahan',
  'Iğdır',
  'Yalova',
  'Karabük',
  'Kilis',
  'Osmaniye',
  'Düzce',
];

const List<String> kCityMatchKeys = [
  'adana',
  'adiyaman',
  'afyonkarahisar',
  'agri',
  'amasya',
  'ankara',
  'antalya',
  'artvin',
  'aydin',
  'balikesir',
  'bilecik',
  'bingol',
  'bitlis',
  'bolu',
  'burdur',
  'bursa',
  'canakkale',
  'cankiri',
  'corum',
  'denizli',
  'diyarbakir',
  'edirne',
  'elazig',
  'erzincan',
  'erzurum',
  'eskisehir',
  'gaziantep',
  'giresun',
  'gumushane',
  'hakkari',
  'hatay',
  'isparta',
  'mersin',
  'istanbul',
  'izmir',
  'kars',
  'kastamonu',
  'kayseri',
  'kirklareli',
  'kirsehir',
  'kocaeli',
  'konya',
  'kutahya',
  'malatya',
  'manisa',
  'kahramanmaras',
  'mardin',
  'mugla',
  'mus',
  'nevsehir',
  'nigde',
  'ordu',
  'rize',
  'sakarya',
  'samsun',
  'siirt',
  'sinop',
  'sivas',
  'tekirdag',
  'tokat',
  'trabzon',
  'tunceli',
  'sanliurfa',
  'usak',
  'van',
  'yozgat',
  'zonguldak',
  'aksaray',
  'bayburt',
  'karaman',
  'kirikkale',
  'batman',
  'sirnak',
  'bartin',
  'ardahan',
  'igdir',
  'yalova',
  'karabuk',
  'kilis',
  'osmaniye',
  'duzce',
];


const List<Color> kAccentPalette = [
  kSun,
];

final List<City> kCities = List.generate(
  kCityNames.length,
  (index) {
    final name = kCityNames[index];
    final key = kCityMatchKeys[index];
    return City(
      name: name,
      matchKey: key,
      tagline: '$name için anında eşleşme',
      onlineCount: 0,
      accent: kAccentPalette[index % kAccentPalette.length],
    );
  },
);



