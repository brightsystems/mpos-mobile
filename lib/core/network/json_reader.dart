class JsonReader {
  JsonReader(this._json);

  final Map<String, dynamic> _json;

  String string(String key, {String fallback = ''}) {
    final value = _json[key] ?? _json[_pascal(key)];

    return value == null ? fallback : '$value';
  }

  double number(String key, {double fallback = 0}) {
    final value = _json[key] ?? _json[_pascal(key)];

    if (value == null) {
      return fallback;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse('$value') ?? fallback;
  }

  int integer(String key, {int fallback = 0}) {
    return number(key, fallback: fallback.toDouble()).round();
  }

  bool boolean(String key, {bool fallback = false}) {
    final value = _json[key] ?? _json[_pascal(key)];

    if (value is bool) {
      return value;
    }

    return fallback;
  }

  DateTime? dateTime(String key) {
    final value = _json[key] ?? _json[_pascal(key)];

    if (value == null) {
      return null;
    }

    return DateTime.tryParse('$value');
  }

  Map<String, dynamic>? map(String key) {
    final value = _json[key] ?? _json[_pascal(key)];

    if (value is Map<String, dynamic>) {
      return value;
    }

    return null;
  }

  List<Map<String, dynamic>> listOfMaps(String key) {
    final value = _json[key] ?? _json[_pascal(key)];

    if (value is! List) {
      return [];
    }

    return value.whereType<Map<String, dynamic>>().toList();
  }

  static String _pascal(String key) {
    if (key.isEmpty) {
      return key;
    }

    return '${key[0].toUpperCase()}${key.substring(1)}';
  }
}
