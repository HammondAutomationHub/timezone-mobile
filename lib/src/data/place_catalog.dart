import 'package:timezone/timezone.dart' as tz;

import '../models/place.dart';
import 'zone_countries.dart';

/// Searchable cities and countries backed by the IANA time zone database.
final class PlaceCatalog {
  PlaceCatalog._(this._places) {
    for (final place in _places) {
      final code = place.countryCode;
      if (code != null) _codeById[place.id] = code;
    }
  }

  final List<Place> _places;
  final Map<String, String> _codeById = {};

  /// Flag country for a saved pin. The pin id wins, so Malaysia stays Malaysia
  /// even though its clock uses the Singapore zone.
  String? countryCodeFor(String id, String ianaId) {
    return _codeById[id] ?? countryCodeForZone(ianaId);
  }

  static PlaceCatalog build() {
    final countryByIana = <String, String>{};
    final places = <Place>[];
    final seedKeys = <String>{};

    for (final seed in _seeds) {
      tz.getLocation(seed.ianaId);
      if (seed.pinId == seed.ianaId) {
        countryByIana.putIfAbsent(seed.ianaId, () => seed.country);
      }
      places.add(seed.toPlace());
      seedKeys.add('${seed.label.toLowerCase()}|${seed.ianaId}');
    }
    for (final entry in _extraCountries.entries) {
      countryByIana.putIfAbsent(entry.key, () => entry.value);
    }

    final seenZones = <String>{};
    for (final location in tz.timeZoneDatabase.locations.values) {
      final name = location.name;
      if (!_includeZone(name) || !seenZones.add(name)) continue;
      final label = _cityLabel(name);
      if (seedKeys.contains('${label.toLowerCase()}|$name')) continue;
      final country = countryByIana[name];
      places.add(
        Place(
          id: name,
          label: label,
          subtitle: country ?? _regionSubtitle(name),
          ianaId: name,
          keywords: _keywordsForCountry(country, label),
          countryCode: (country == null ? null : countryCodeForName(country)) ??
              countryCodeForZone(name),
        ),
      );
    }

    return PlaceCatalog._(places);
  }

  List<Place> get starters {
    final places = _places.where((place) => place.isStarter).toList()
      ..sort((a, b) => a.starterOrder!.compareTo(b.starterOrder!));
    return places;
  }

  /// Major cities for the add screen, skipping zones already offered as starters.
  List<Place> get popular {
    final hidden = starters.map((place) => place.id).toSet();
    final places = <Place>[];
    for (final ianaId in _popularZoneIds) {
      if (hidden.contains(ianaId)) continue;
      final place = _cityForZone(ianaId);
      if (place != null) places.add(place);
    }
    return places;
  }

  /// Best matches first. At most one result per pin.
  List<Place> search(String rawQuery, {int limit = 40}) {
    final query = _fold(rawQuery);
    if (query.isEmpty) return const [];

    final best = <String, (int, Place)>{};
    for (final place in _places) {
      final score = _score(place, query);
      if (score == null) continue;
      final current = best[place.id];
      if (current == null ||
          score < current.$1 ||
          (score == current.$1 && _prefer(place, current.$2, query) < 0)) {
        best[place.id] = (score, place);
      }
    }

    final ranked = best.values.toList()
      ..sort((a, b) {
        final byScore = a.$1.compareTo(b.$1);
        if (byScore != 0) return byScore;
        return _prefer(a.$2, b.$2, query);
      });
    return ranked.take(limit).map((entry) => entry.$2).toList();
  }

  Place? _cityForZone(String ianaId) {
    final expected = _cityLabel(ianaId).toLowerCase();
    Place? alias;
    Place? fallback;
    for (final place in _places) {
      if (place.ianaId != ianaId) continue;
      if (place.countryAlias) {
        alias ??= place;
        continue;
      }
      fallback ??= place;
      if (place.label.toLowerCase() == expected) return place;
    }
    return fallback ?? alias;
  }
}

final class _Seed {
  const _Seed({
    this.id,
    required this.label,
    required this.subtitle,
    required this.country,
    required this.ianaId,
    this.keywords = const [],
    this.starterOrder,
    this.countryAlias = true,
  });

  final String? id;
  final String label;
  final String subtitle;
  final String country;
  final String ianaId;

  String get pinId => id ?? ianaId;
  final List<String> keywords;
  final int? starterOrder;
  final bool countryAlias;

  Place toPlace() {
    return Place(
      id: pinId,
      label: label,
      subtitle: subtitle,
      ianaId: ianaId,
      keywords: keywords,
      starterOrder: starterOrder,
      countryAlias: countryAlias,
      countryCode: countryCodeForName(country),
    );
  }
}

const _seeds = <_Seed>[
  _Seed(
    label: 'California',
    subtitle: 'Los Angeles',
    country: 'United States',
    ianaId: 'America/Los_Angeles',
    starterOrder: 0,
    keywords: ['los angeles', 'pacific', 'west coast', 'usa', 'united states'],
  ),
  // tzdata 2026e folded Asia/Kuala_Lumpur into Asia/Singapore. Both are
  // UTC+8 with no daylight saving. The pin id stays Asia/Kuala_Lumpur so
  // Malaysia and Singapore can be saved side by side.
  _Seed(
    id: 'Asia/Kuala_Lumpur',
    label: 'Malaysia',
    subtitle: 'Kuala Lumpur',
    country: 'Malaysia',
    ianaId: 'Asia/Singapore',
    starterOrder: 1,
    keywords: ['kuala lumpur', 'myt'],
  ),
  _Seed(
    label: 'Japan',
    subtitle: 'Tokyo',
    country: 'Japan',
    ianaId: 'Asia/Tokyo',
    starterOrder: 2,
    keywords: ['tokyo', 'jst'],
  ),
  _Seed(
    label: 'Indonesia',
    subtitle: 'Western Indonesia',
    country: 'Indonesia',
    ianaId: 'Asia/Jakarta',
    starterOrder: 3,
    keywords: ['jakarta', 'wib', 'western indonesia'],
  ),
  _Seed(
    label: 'Singapore',
    subtitle: 'Singapore',
    country: 'Singapore',
    ianaId: 'Asia/Singapore',
    starterOrder: 4,
    keywords: ['sgt'],
  ),
  _Seed(
    label: 'United Kingdom',
    subtitle: 'London',
    country: 'United Kingdom',
    ianaId: 'Europe/London',
    keywords: ['uk', 'britain', 'england', 'london'],
  ),
  _Seed(
    label: 'Ireland',
    subtitle: 'Dublin',
    country: 'Ireland',
    ianaId: 'Europe/Dublin',
    keywords: ['dublin'],
  ),
  _Seed(
    label: 'France',
    subtitle: 'Paris',
    country: 'France',
    ianaId: 'Europe/Paris',
    keywords: ['paris'],
  ),
  _Seed(
    label: 'Germany',
    subtitle: 'Berlin',
    country: 'Germany',
    ianaId: 'Europe/Berlin',
    keywords: ['berlin'],
  ),
  // Europe/Amsterdam shares Central European rules with Europe/Berlin.
  _Seed(
    id: 'Europe/Amsterdam',
    label: 'Netherlands',
    subtitle: 'Amsterdam',
    country: 'Netherlands',
    ianaId: 'Europe/Berlin',
    keywords: ['amsterdam', 'holland'],
  ),
  _Seed(
    label: 'Belgium',
    subtitle: 'Brussels',
    country: 'Belgium',
    ianaId: 'Europe/Brussels',
    keywords: ['brussels'],
  ),
  _Seed(
    label: 'Switzerland',
    subtitle: 'Zurich',
    country: 'Switzerland',
    ianaId: 'Europe/Zurich',
    keywords: ['zurich'],
  ),
  _Seed(
    label: 'Austria',
    subtitle: 'Vienna',
    country: 'Austria',
    ianaId: 'Europe/Vienna',
    keywords: ['vienna'],
  ),
  _Seed(
    label: 'Italy',
    subtitle: 'Rome',
    country: 'Italy',
    ianaId: 'Europe/Rome',
    keywords: ['rome'],
  ),
  _Seed(
    label: 'Spain',
    subtitle: 'Madrid',
    country: 'Spain',
    ianaId: 'Europe/Madrid',
    keywords: ['madrid'],
  ),
  _Seed(
    label: 'Portugal',
    subtitle: 'Lisbon',
    country: 'Portugal',
    ianaId: 'Europe/Lisbon',
    keywords: ['lisbon'],
  ),
  // Sweden, Norway, and Denmark share Central European rules with Berlin.
  _Seed(
    id: 'Europe/Stockholm',
    label: 'Sweden',
    subtitle: 'Stockholm',
    country: 'Sweden',
    ianaId: 'Europe/Berlin',
    keywords: ['stockholm'],
  ),
  _Seed(
    id: 'Europe/Oslo',
    label: 'Norway',
    subtitle: 'Oslo',
    country: 'Norway',
    ianaId: 'Europe/Berlin',
    keywords: ['oslo'],
  ),
  _Seed(
    id: 'Europe/Copenhagen',
    label: 'Denmark',
    subtitle: 'Copenhagen',
    country: 'Denmark',
    ianaId: 'Europe/Berlin',
    keywords: ['copenhagen'],
  ),
  _Seed(
    label: 'Finland',
    subtitle: 'Helsinki',
    country: 'Finland',
    ianaId: 'Europe/Helsinki',
    keywords: ['helsinki'],
  ),
  _Seed(
    label: 'Poland',
    subtitle: 'Warsaw',
    country: 'Poland',
    ianaId: 'Europe/Warsaw',
    keywords: ['warsaw'],
  ),
  _Seed(
    label: 'Czechia',
    subtitle: 'Prague',
    country: 'Czechia',
    ianaId: 'Europe/Prague',
    keywords: ['czech republic', 'prague'],
  ),
  _Seed(
    label: 'Hungary',
    subtitle: 'Budapest',
    country: 'Hungary',
    ianaId: 'Europe/Budapest',
    keywords: ['budapest'],
  ),
  _Seed(
    label: 'Greece',
    subtitle: 'Athens',
    country: 'Greece',
    ianaId: 'Europe/Athens',
    keywords: ['athens'],
  ),
  _Seed(
    label: 'Romania',
    subtitle: 'Bucharest',
    country: 'Romania',
    ianaId: 'Europe/Bucharest',
    keywords: ['bucharest'],
  ),
  _Seed(
    label: 'Ukraine',
    subtitle: 'Kyiv',
    country: 'Ukraine',
    ianaId: 'Europe/Kyiv',
    keywords: ['kiev', 'kyiv'],
  ),
  _Seed(
    label: 'Turkey',
    subtitle: 'Istanbul',
    country: 'Turkey',
    ianaId: 'Europe/Istanbul',
    keywords: ['istanbul'],
  ),
  _Seed(
    label: 'Russia',
    subtitle: 'Moscow',
    country: 'Russia',
    ianaId: 'Europe/Moscow',
    keywords: ['moscow'],
  ),
  _Seed(
    label: 'India',
    subtitle: 'Kolkata',
    country: 'India',
    ianaId: 'Asia/Kolkata',
    keywords: ['mumbai', 'delhi', 'bombay', 'new delhi', 'kolkata'],
  ),
  _Seed(
    label: 'China',
    subtitle: 'Shanghai',
    country: 'China',
    ianaId: 'Asia/Shanghai',
    keywords: ['beijing', 'peking', 'shanghai'],
  ),
  _Seed(
    label: 'South Korea',
    subtitle: 'Seoul',
    country: 'South Korea',
    ianaId: 'Asia/Seoul',
    keywords: ['korea', 'seoul'],
  ),
  _Seed(
    label: 'Taiwan',
    subtitle: 'Taipei',
    country: 'Taiwan',
    ianaId: 'Asia/Taipei',
    keywords: ['taipei'],
  ),
  _Seed(
    label: 'Hong Kong',
    subtitle: 'Hong Kong',
    country: 'Hong Kong',
    ianaId: 'Asia/Hong_Kong',
  ),
  _Seed(
    label: 'Thailand',
    subtitle: 'Bangkok',
    country: 'Thailand',
    ianaId: 'Asia/Bangkok',
    keywords: ['bangkok'],
  ),
  _Seed(
    label: 'Vietnam',
    subtitle: 'Ho Chi Minh City',
    country: 'Vietnam',
    ianaId: 'Asia/Ho_Chi_Minh',
    keywords: ['saigon', 'hanoi', 'ho chi minh'],
  ),
  _Seed(
    label: 'Philippines',
    subtitle: 'Manila',
    country: 'Philippines',
    ianaId: 'Asia/Manila',
    keywords: ['manila'],
  ),
  _Seed(
    label: 'Pakistan',
    subtitle: 'Karachi',
    country: 'Pakistan',
    ianaId: 'Asia/Karachi',
    keywords: ['karachi'],
  ),
  _Seed(
    label: 'Bangladesh',
    subtitle: 'Dhaka',
    country: 'Bangladesh',
    ianaId: 'Asia/Dhaka',
    keywords: ['dhaka'],
  ),
  _Seed(
    label: 'Sri Lanka',
    subtitle: 'Colombo',
    country: 'Sri Lanka',
    ianaId: 'Asia/Colombo',
    keywords: ['colombo'],
  ),
  _Seed(
    label: 'Nepal',
    subtitle: 'Kathmandu',
    country: 'Nepal',
    ianaId: 'Asia/Kathmandu',
    keywords: ['kathmandu'],
  ),
  _Seed(
    label: 'United Arab Emirates',
    subtitle: 'Dubai',
    country: 'United Arab Emirates',
    ianaId: 'Asia/Dubai',
    keywords: ['uae', 'dubai'],
  ),
  _Seed(
    label: 'Saudi Arabia',
    subtitle: 'Riyadh',
    country: 'Saudi Arabia',
    ianaId: 'Asia/Riyadh',
    keywords: ['riyadh'],
  ),
  _Seed(
    label: 'Israel',
    subtitle: 'Jerusalem',
    country: 'Israel',
    ianaId: 'Asia/Jerusalem',
    keywords: ['jerusalem'],
  ),
  _Seed(
    label: 'Qatar',
    subtitle: 'Doha',
    country: 'Qatar',
    ianaId: 'Asia/Qatar',
    keywords: ['doha'],
  ),
  _Seed(
    label: 'Egypt',
    subtitle: 'Cairo',
    country: 'Egypt',
    ianaId: 'Africa/Cairo',
    keywords: ['cairo'],
  ),
  _Seed(
    label: 'South Africa',
    subtitle: 'Johannesburg',
    country: 'South Africa',
    ianaId: 'Africa/Johannesburg',
    keywords: ['johannesburg'],
  ),
  _Seed(
    label: 'Nigeria',
    subtitle: 'Lagos',
    country: 'Nigeria',
    ianaId: 'Africa/Lagos',
    keywords: ['lagos'],
  ),
  _Seed(
    label: 'Kenya',
    subtitle: 'Nairobi',
    country: 'Kenya',
    ianaId: 'Africa/Nairobi',
    keywords: ['nairobi'],
  ),
  _Seed(
    label: 'Morocco',
    subtitle: 'Casablanca',
    country: 'Morocco',
    ianaId: 'Africa/Casablanca',
    keywords: ['casablanca'],
  ),
  _Seed(
    label: 'New Zealand',
    subtitle: 'Auckland',
    country: 'New Zealand',
    ianaId: 'Pacific/Auckland',
    keywords: ['auckland'],
  ),
  _Seed(
    label: 'Mexico',
    subtitle: 'Mexico City',
    country: 'Mexico',
    ianaId: 'America/Mexico_City',
    keywords: ['mexico city'],
  ),
  _Seed(
    label: 'Brazil',
    subtitle: 'Sao Paulo',
    country: 'Brazil',
    ianaId: 'America/Sao_Paulo',
    keywords: ['sao paulo'],
  ),
  _Seed(
    label: 'Argentina',
    subtitle: 'Buenos Aires',
    country: 'Argentina',
    ianaId: 'America/Argentina/Buenos_Aires',
    keywords: ['buenos aires'],
  ),
  _Seed(
    label: 'Chile',
    subtitle: 'Santiago',
    country: 'Chile',
    ianaId: 'America/Santiago',
    keywords: ['santiago'],
  ),
  _Seed(
    label: 'Colombia',
    subtitle: 'Bogota',
    country: 'Colombia',
    ianaId: 'America/Bogota',
    keywords: ['bogota'],
  ),
  _Seed(
    label: 'Peru',
    subtitle: 'Lima',
    country: 'Peru',
    ianaId: 'America/Lima',
    keywords: ['lima'],
  ),
  _Seed(
    label: 'Canada',
    subtitle: 'Toronto',
    country: 'Canada',
    ianaId: 'America/Toronto',
    keywords: ['toronto'],
  ),
  // Atlantic/Reykjavik is a link to Africa/Abidjan in tzdata 2026e.
  _Seed(
    id: 'Atlantic/Reykjavik',
    label: 'Iceland',
    subtitle: 'Reykjavik',
    country: 'Iceland',
    ianaId: 'Africa/Abidjan',
    keywords: ['reykjavik'],
  ),
  _Seed(
    label: 'Mumbai',
    subtitle: 'India',
    country: 'India',
    ianaId: 'Asia/Kolkata',
    countryAlias: false,
    keywords: ['bombay'],
  ),
  _Seed(
    label: 'Delhi',
    subtitle: 'India',
    country: 'India',
    ianaId: 'Asia/Kolkata',
    countryAlias: false,
    keywords: ['new delhi'],
  ),
  _Seed(
    label: 'Beijing',
    subtitle: 'China',
    country: 'China',
    ianaId: 'Asia/Shanghai',
    countryAlias: false,
    keywords: ['peking'],
  ),
  _Seed(
    label: 'Hanoi',
    subtitle: 'Vietnam',
    country: 'Vietnam',
    ianaId: 'Asia/Ho_Chi_Minh',
    countryAlias: false,
  ),
];

const _popularZoneIds = [
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Phoenix',
  'America/Anchorage',
  'Pacific/Honolulu',
  'America/Toronto',
  'America/Vancouver',
  'Europe/London',
  'Europe/Paris',
  'Europe/Berlin',
  'Europe/Rome',
  'Europe/Madrid',
  'Europe/Moscow',
  'Asia/Dubai',
  'Asia/Kolkata',
  'Asia/Bangkok',
  'Asia/Hong_Kong',
  'Asia/Shanghai',
  'Asia/Seoul',
  'Asia/Taipei',
  'Australia/Sydney',
  'Australia/Perth',
  'Pacific/Auckland',
  'America/Mexico_City',
  'America/Sao_Paulo',
  'America/Argentina/Buenos_Aires',
  'Africa/Johannesburg',
  'Africa/Cairo',
];

const _extraCountries = {
  'America/New_York': 'United States',
  'America/Chicago': 'United States',
  'America/Detroit': 'United States',
  'America/Denver': 'United States',
  'America/Boise': 'United States',
  'America/Phoenix': 'United States',
  'America/Anchorage': 'United States',
  'America/Juneau': 'United States',
  'America/Nome': 'United States',
  'America/Adak': 'United States',
  'America/Indiana/Indianapolis': 'United States',
  'America/Kentucky/Louisville': 'United States',
  'America/North_Dakota/Center': 'United States',
  'America/Menominee': 'United States',
  'Pacific/Honolulu': 'United States',
  'America/Puerto_Rico': 'Puerto Rico',
  'America/Vancouver': 'Canada',
  'America/Edmonton': 'Canada',
  'America/Winnipeg': 'Canada',
  'America/Halifax': 'Canada',
  'America/St_Johns': 'Canada',
  'America/Regina': 'Canada',
  'America/Whitehorse': 'Canada',
  'America/Manaus': 'Brazil',
  'America/Recife': 'Brazil',
  'America/Fortaleza': 'Brazil',
  'America/Belem': 'Brazil',
  'America/Bahia': 'Brazil',
  'America/Cuiaba': 'Brazil',
  'America/Porto_Velho': 'Brazil',
  'America/Cancun': 'Mexico',
  'America/Tijuana': 'Mexico',
  'America/Monterrey': 'Mexico',
  'America/Mazatlan': 'Mexico',
  'Asia/Kuching': 'Malaysia',
  'Asia/Makassar': 'Indonesia',
  'Asia/Jayapura': 'Indonesia',
  'Asia/Pontianak': 'Indonesia',
  'Europe/Kaliningrad': 'Russia',
  'Europe/Samara': 'Russia',
  'Asia/Yekaterinburg': 'Russia',
  'Asia/Novosibirsk': 'Russia',
  'Asia/Vladivostok': 'Russia',
  'Asia/Irkutsk': 'Russia',
  'Australia/Sydney': 'Australia',
  'Australia/Melbourne': 'Australia',
  'Australia/Brisbane': 'Australia',
  'Australia/Perth': 'Australia',
  'Australia/Adelaide': 'Australia',
  'Australia/Darwin': 'Australia',
  'Australia/Hobart': 'Australia',
};

const _regionNames = {
  'Africa': 'Africa',
  'America': 'Americas',
  'Antarctica': 'Antarctica',
  'Arctic': 'Arctic',
  'Asia': 'Asia',
  'Atlantic': 'Atlantic',
  'Australia': 'Australia',
  'Europe': 'Europe',
  'Indian': 'Indian Ocean',
  'Pacific': 'Pacific',
};

const _foldReplacements = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ñ': 'n',
  'ç': 'c',
  'ý': 'y',
  'ÿ': 'y',
  'ø': 'o',
  'æ': 'ae',
  'œ': 'oe',
  'ß': 'ss',
};

bool _includeZone(String name) {
  return name.contains('/') && !name.startsWith('Etc/');
}

String _cityLabel(String ianaId) {
  return ianaId.split('/').last.replaceAll('_', ' ');
}

String _regionSubtitle(String ianaId) {
  final parts = ianaId.split('/');
  if (parts.length >= 3) return parts[1].replaceAll('_', ' ');
  return _regionNames[parts.first] ?? parts.first;
}

List<String> _keywordsForCountry(String? country, String label) {
  if (country == null) return const [];
  final extras = switch (country) {
    'United States' => const ['United States', 'usa', 'us'],
    'United Kingdom' => const ['United Kingdom', 'uk', 'britain'],
    'United Arab Emirates' => const ['United Arab Emirates', 'uae'],
    _ => [country],
  };
  return [
    for (final keyword in extras)
      if (keyword.toLowerCase() != label.toLowerCase()) keyword,
  ];
}

String _fold(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune).toLowerCase();
    buffer.write(_foldReplacements[char] ?? (char == '_' ? ' ' : char));
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

int? _score(Place place, String query) {
  final label = _fold(place.label);
  final subtitle = _fold(place.subtitle);
  // Merged zones keep a historical pin id. Don't let that shared IANA name
  // surface them in an unrelated search (Malaysia should not match "Singapore").
  final iana = place.id == place.ianaId ? _fold(place.ianaId) : '';
  final keywords = place.keywords.map(_fold).toList();

  if (label == query) return 0;
  if (keywords.contains(query)) return 1;
  if (label.startsWith(query)) return 2;
  if (query.length >= 2 &&
      keywords.any((keyword) => keyword.startsWith(query))) {
    return 3;
  }
  if (query.length >= 2 && subtitle.startsWith(query)) return 4;
  if (query.length >= 2 && label.contains(query)) return 5;
  if (query.length >= 2 && subtitle.contains(query)) return 6;
  if (query.length >= 2 && keywords.any((keyword) => keyword.contains(query))) {
    return 7;
  }
  if (query.length >= 2 && iana.contains(query)) return 8;
  return null;
}

int _prefer(Place a, Place b, String query) {
  final aStarts = _fold(a.label).startsWith(query);
  final bStarts = _fold(b.label).startsWith(query);
  if (aStarts != bStarts) return aStarts ? -1 : 1;
  final byLength = a.label.length.compareTo(b.label.length);
  if (byLength != 0) return byLength;
  return a.label.compareTo(b.label);
}
