import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// Where your Crop Medic backend (FastAPI) runs.
// Android emulator   -> http://10.0.2.2:8000
// Real phone, Wi-Fi  -> http://YOUR-PC-IP:8000
// Web / desktop      -> http://localhost:8000
// Deployed server    -> https://your-domain.com
const String baseUrl = 'http://10.0.2.2:8000';

class Diagnosis {
  final String crop;
  final String disease;
  final double confidence;
  final bool lowConfidence;
  final List<String> advice;
  final bool demo;

  Diagnosis({
    required this.crop,
    required this.disease,
    required this.confidence,
    required this.lowConfidence,
    required this.advice,
    required this.demo,
  });

  bool get isHealthy => disease.toLowerCase() == 'healthy';

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      crop: json['crop'] as String,
      disease: json['disease'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      lowConfidence: json['low_confidence'] as bool,
      advice: (json['advice'] as List).map((e) => e.toString()).toList(),
      demo: (json['demo'] as bool?) ?? false,
    );
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

Future<Diagnosis> predict(Uint8List bytes, String lang) async {
  final uri = Uri.parse('$baseUrl/api/predict?lang=$lang');
  final request = http.MultipartRequest('POST', uri);
  request.files.add(http.MultipartFile.fromBytes(
    'file',
    bytes,
    filename: 'leaf.jpg',
    contentType: MediaType('image', 'jpeg'),
  ));

  try {
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      String detail = 'Something went wrong. Try again.';
      try {
        detail = jsonDecode(response.body)['detail'] ?? detail;
      } catch (_) {}
      throw ApiException(detail);
    }
    return Diagnosis.fromJson(jsonDecode(response.body));
  } on ApiException {
    rethrow;
  } on TimeoutException {
    throw ApiException('The server took too long. Check your connection.');
  } catch (_) {
    throw ApiException("Can't reach the server. Check your connection.");
  }
}
