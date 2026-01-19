import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/message.dart';

class CsvService {
  static Future<List<Message>> loadMessages() async {
    try {
      final rawData = await rootBundle.loadString('assets/messages.csv');
      
      // Normalizuj line endings
      final normalizedData = rawData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      
      List<List<dynamic>> listData = const CsvToListConverter().convert(
        normalizedData,
        eol: '\n',
        shouldParseNumbers: false,
      );

      print('CSV učitano: ${listData.length} redova (sa headerom)');

      // Preskoci header (prvu liniju)
      if (listData.isNotEmpty) {
        listData.removeAt(0);
      }

      final messages = listData.map((row) => Message.fromCsv(row)).toList();
      print('Kreirano ${messages.length} poruka');
      
      return messages;
    } catch (e) {
      print('Greška pri učitavanju CSV: $e');
      return [];
    }
  }

  static Message? getMessageForDay(List<Message> messages, int dayIndex) {
    if (messages.isEmpty) return null;
    
    // Циклирај кроз поруке (ако има више од 30 дана, почни испочетка)
    final index = dayIndex % messages.length;
    return messages[index];
  }
}
