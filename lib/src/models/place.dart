/// A city or country that can be pinned, tied to one IANA time zone.
final class Place {
  const Place({
    String? id,
    required this.label,
    required this.subtitle,
    required this.ianaId,
    this.keywords = const [],
    this.starterOrder,
    this.countryAlias = false,
  }) : id = id ?? ianaId;

  /// Stable pin id. Usually the IANA id. A few places keep a historical id
  /// when this database has merged their zone into another.
  final String id;
  final String label;
  final String subtitle;

  /// Zone used to compute the clock, including daylight saving.
  final String ianaId;
  final List<String> keywords;

  /// Position in the first-launch suggestion row. Null when this is not one.
  final int? starterOrder;

  /// True when [label] is a country or region name rather than the city.
  final bool countryAlias;

  bool get isStarter => starterOrder != null;
}
