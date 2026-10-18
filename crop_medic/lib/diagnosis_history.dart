import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';

class DiagnosisHistoryEntry {
  final String id;
  final DateTime createdAt;
  final String crop;
  final String disease;
  final double confidence;
  final String lang;
  final List<String> advice;

  const DiagnosisHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.crop,
    required this.disease,
    required this.confidence,
    required this.lang,
    required this.advice,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'crop': crop,
        'disease': disease,
        'confidence': confidence,
        'lang': lang,
        'advice': advice,
      };

  factory DiagnosisHistoryEntry.fromJson(Map<String, dynamic> json) {
    return DiagnosisHistoryEntry(
      id: json['id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      crop: json['crop']?.toString() ?? '',
      disease: json['disease']?.toString() ?? '',
      confidence: ((json['confidence'] as num?) ?? 0).toDouble(),
      lang: json['lang']?.toString() ?? 'en',
      advice: (json['advice'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
    );
  }
}

class DiagnosisHistoryStore {
  static const _key = 'cropmedic_diagnosis_history_v1';
  static const _maxEntries = 40;

  static Future<List<DiagnosisHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final entries = <DiagnosisHistoryEntry>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          entries.add(DiagnosisHistoryEntry.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {
        // Ignore an individual damaged history entry rather than losing history.
      }
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  static Future<void> add(Diagnosis diagnosis, String lang) async {
    if (!diagnosis.accepted) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = await load();
    final now = DateTime.now();
    final entry = DiagnosisHistoryEntry(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      crop: diagnosis.crop,
      disease: diagnosis.isHealthy ? 'Healthy' : diagnosis.disease,
      confidence: diagnosis.confidence,
      lang: lang,
      advice: List<String>.from(diagnosis.advice),
    );
    final next = <DiagnosisHistoryEntry>[entry, ...existing].take(_maxEntries).toList();
    await prefs.setStringList(
      _key,
      next.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
