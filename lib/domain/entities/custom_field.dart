import 'package:equatable/equatable.dart';

/// A generic key-value field for non-standard C2PA data.
///
/// Custom fields can originate from vendor-specific assertions,
/// non-standard action parameters, or extra fields within known assertions.
class CustomField extends Equatable {
  final String key;
  final dynamic value;
  final String source;
  final String? parentLabel;

  const CustomField({
    required this.key,
    required this.value,
    required this.source,
    this.parentLabel,
  });

  bool get isSimple => value is String || value is num || value is bool;
  bool get isMap => value is Map;
  bool get isList => value is List;

  /// Flatten a nested Map/List into displayable key-value pairs.
  List<MapEntry<String, String>> toFlatEntries({String prefix = ''}) {
    final fullKey = prefix.isEmpty ? key : '$prefix.$key';
    if (isSimple || value == null) {
      return [MapEntry(fullKey, value?.toString() ?? 'null')];
    }
    if (isMap) {
      return _flattenMap(value as Map, fullKey);
    }
    if (isList) {
      return _flattenList(value as List, fullKey);
    }
    return [MapEntry(fullKey, value.toString())];
  }

  static List<MapEntry<String, String>> _flattenMap(
    Map map,
    String prefix,
  ) {
    final entries = <MapEntry<String, String>>[];
    for (final entry in map.entries) {
      final key = '$prefix.${entry.key}';
      if (entry.value is Map) {
        entries.addAll(_flattenMap(entry.value as Map, key));
      } else if (entry.value is List) {
        entries.addAll(_flattenList(entry.value as List, key));
      } else {
        entries.add(MapEntry(key, entry.value?.toString() ?? 'null'));
      }
    }
    return entries;
  }

  static List<MapEntry<String, String>> _flattenList(
    List list,
    String prefix,
  ) {
    final entries = <MapEntry<String, String>>[];
    for (var i = 0; i < list.length; i++) {
      final key = '$prefix[$i]';
      final item = list[i];
      if (item is Map) {
        entries.addAll(_flattenMap(item, key));
      } else if (item is List) {
        entries.addAll(_flattenList(item, key));
      } else {
        entries.add(MapEntry(key, item?.toString() ?? 'null'));
      }
    }
    return entries;
  }

  @override
  List<Object?> get props => [key, source, parentLabel];
}
