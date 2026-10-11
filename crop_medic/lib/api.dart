import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// Set this per environment, for example:
// flutter run --dart-define=CROP_MEDIC_API_URL=http://10.0.2.2:8000
// flutter build apk --dart-define=CROP_MEDIC_API_URL=https://api.cropmedic.example
const String _configuredBaseUrl = String.fromEnvironment(
  'CROP_MEDIC_API_URL',
  defaultValue: 'http://localhost:8000',
);

String get baseUrl => _configuredBaseUrl.endsWith('/')
    ? _configuredBaseUrl.substring(0, _configuredBaseUrl.length - 1)
    : _configuredBaseUrl;

class PredictionCandidate {
  final String crop;
  final String disease;
  final double confidence;

  const PredictionCandidate({
    required this.crop,
    required this.disease,
    required this.confidence,
  });

  factory PredictionCandidate.fromJson(Map<String, dynamic> json) {
    return PredictionCandidate(
      crop: json['crop'] as String,
      disease: json['disease'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class Diagnosis {
  final String crop;
  final String disease;
  final double confidence;
  final bool lowConfidence;
  final List<String> advice;
  final List<PredictionCandidate> topPredictions;
  final bool demo;

  Diagnosis({
    required this.crop,
    required this.disease,
    required this.confidence,
    required this.lowConfidence,
    required this.advice,
    required this.topPredictions,
    required this.demo,
  });

  bool get isHealthy => disease.toLowerCase() == 'healthy';

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    final ranked = json['top_predictions'] as List<dynamic>? ?? const [];

    return Diagnosis(
      crop: json['crop'] as String,
      disease: json['disease'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      lowConfidence: json['low_confidence'] as bool,
      advice: (json['advice'] as List).map((e) => e.toString()).toList(),
      topPredictions: ranked
          .map((e) => PredictionCandidate.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
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

String _errorDetail(http.Response response) {
  try {
    final body = jsonDecode(response.body);
    if (body is Map && body['detail'] is String) {
      return body['detail'] as String;
    }
  } catch (_) {}

  if (response.statusCode == 503) {
    return 'Crop Medic diagnosis is temporarily unavailable. Please try again later.';
  }
  return 'Something went wrong. Try again.';
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
      throw ApiException(_errorDetail(response));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw ApiException('Crop Medic received an invalid response from the server.');
    }
    return Diagnosis.fromJson(body);
  } on ApiException {
    rethrow;
  } on TimeoutException {
    throw ApiException('The server took too long. Check your connection.');
  } catch (_) {
    throw ApiException("Can't reach the Crop Medic server. Check your connection.");
  }
}
