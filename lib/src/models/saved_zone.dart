import 'dart:convert';

import 'place.dart';

/// A pinned place and the text color chosen for it.
final class SavedZone {
  const SavedZone({
    String? id,
    required this.ianaId,
    required this.label,
    required this.subtitle,
    required this.colorValue,
  }) : id = id ?? ianaId;

  /// Neutral gray used until a color is chosen.
  static const defaultColorValue = 0xFFB7BCC4;

  final String id;
  final String ianaId;
  final String label;
  final String subtitle;
  final int colorValue;

  SavedZone copyWith({int? colorValue}) {
    return SavedZone(
      id: id,
      ianaId: ianaId,
      label: label,
      subtitle: subtitle,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'ianaId': ianaId,
      'label': label,
      'subtitle': subtitle,
      'color': colorValue,
    };
  }

  factory SavedZone.fromPlace(Place place) {
    return SavedZone(
      id: place.id,
      ianaId: place.ianaId,
      label: place.label,
      subtitle: place.subtitle,
      colorValue: defaultColorValue,
    );
  }

  factory SavedZone.fromJson(Map<String, dynamic> json) {
    final ianaId = json['ianaId'];
    final label = json['label'];
    final subtitle = json['subtitle'];
    if (ianaId is! String ||
        ianaId.isEmpty ||
        label is! String ||
        label.trim().isEmpty) {
      throw const FormatException('Invalid saved zone');
    }
    final color = json['color'];
    final rawId = json['id'];
    return SavedZone(
      id: rawId is String && rawId.isNotEmpty ? rawId : ianaId,
      ianaId: ianaId,
      label: label.trim(),
      subtitle: subtitle is String ? subtitle : '',
      colorValue: color is int ? color : defaultColorValue,
    );
  }
}

String encodeSavedZones(List<SavedZone> zones) {
  return jsonEncode(zones.map((zone) => zone.toJson()).toList());
}

/// Decodes a stored list. Corrupt entries are skipped. The first copy of a
/// pin id wins.
List<SavedZone> decodeSavedZones(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return const [];
  }
  if (decoded is! List) return const [];

  final zones = <SavedZone>[];
  final seen = <String>{};
  for (final item in decoded) {
    if (item is! Map) continue;
    try {
      final zone = SavedZone.fromJson(Map<String, dynamic>.from(item));
      if (seen.add(zone.id)) zones.add(zone);
    } on FormatException {
      continue;
    }
  }
  return zones;
}
