import 'package:flutter/services.dart';

class QuranService {
  static Map<String, String>? _quranCache;

  static Future<void> _loadQuran() async {
    if (_quranCache != null) return;

    _quranCache = {};
    final rawData = await rootBundle.loadString('assets/quran-simple.txt');
    final lines = rawData.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('|');
      if (parts.length >= 3) {
        final sura = parts[0];
        final ayet = parts[1];
        final text = parts[2];
        _quranCache!['$sura:$ayet'] = text;
      }
    }
  }

  static Future<String> getAyat(int sura, int ayet) async {
    await _loadQuran();
    return _quranCache!['$sura:$ayet'] ?? '';
  }
}
