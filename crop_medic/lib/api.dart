import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
      crop: (json['crop'] as String?) ?? '',
      disease: (json['disease'] as String?) ?? '',
      confidence: ((json['confidence'] as num?) ?? 0).toDouble(),
    );
  }
}

class CropCandidate {
  final String crop;
  final double confidence;

  const CropCandidate({required this.crop, required this.confidence});

  factory CropCandidate.fromJson(Map<String, dynamic> json) {
    return CropCandidate(
      crop: (json['crop'] as String?) ?? '',
      confidence: ((json['confidence'] as num?) ?? 0).toDouble(),
    );
  }
}

class CropGuess {
  final bool accepted;
  final String crop;
  final double confidence;
  final String? message;
  final List<CropCandidate> candidates;
  final List<String> supportedCrops;
  final bool bootstrap;

  const CropGuess({
    required this.accepted,
    required this.crop,
    required this.confidence,
    required this.message,
    required this.candidates,
    required this.supportedCrops,
    required this.bootstrap,
  });

  factory CropGuess.fromJson(Map<String, dynamic> json) {
    final candidates = json['candidates'] as List<dynamic>? ?? const [];
    final supported = json['supported_crops'] as List<dynamic>? ?? const [];
    final bootstrap = (json['bootstrap'] as bool?) ?? false;
    final serverAccepted = (json['accepted'] as bool?) ?? false;
    final serverMessage = json['message'] as String?;

    // The current crop-identification endpoint is a bootstrap derived from the
    // disease model, not a dedicated crop classifier. It may suggest a crop,
    // but V1 must never auto-confirm or preselect that suggestion. The farmer
    // explicitly chooses the crop before disease diagnosis proceeds.
    return CropGuess(
      accepted: serverAccepted && !bootstrap,
      crop: (json['crop'] as String?) ?? '',
      confidence: ((json['confidence'] as num?) ?? 0).toDouble(),
      message: bootstrap
          ? 'Automatic crop identification is still being validated. Please select the crop yourself.'
          : serverMessage,
      candidates: candidates
          .map((e) => CropCandidate.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      supportedCrops: supported.map((e) => e.toString()).toList(),
      bootstrap: bootstrap,
    );
  }
}

class ApiCapabilities {
  final List<String> diagnosisSupportedCrops;
  final List<String> cropIdentificationSupportedCrops;
  final String cropIdentificationMode;
  final List<Map<String, dynamic>> cropSpecificModels;
  final List<String> languages;

  const ApiCapabilities({
    required this.diagnosisSupportedCrops,
    required this.cropIdentificationSupportedCrops,
    required this.cropIdentificationMode,
    required this.cropSpecificModels,
    required this.languages,
  });

  factory ApiCapabilities.fromJson(Map<String, dynamic> json) {
    final diagnosis = json['diagnosis_supported_crops'] as List<dynamic>? ?? const [];
    final identification = json['crop_identification_supported_crops'] as List<dynamic>? ?? const [];
    final models = json['crop_specific_models'] as List<dynamic>? ?? const [];
    final languages = json['languages'] as List<dynamic>? ?? const [];
    return ApiCapabilities(
      diagnosisSupportedCrops: diagnosis.map((e) => e.toString()).toList(),
      cropIdentificationSupportedCrops: identification.map((e) => e.toString()).toList(),
      cropIdentificationMode: (json['crop_identification_mode'] as String?) ?? '',
      cropSpecificModels: models
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      languages: languages.map((e) => e.toString()).toList(),
    );
  }
}

class Diagnosis {
  final bool accepted;
  final String crop;
  final String disease;
  final double confidence;
  final bool lowConfidence;
  final String? message;
  final List<String> advice;
  final List<PredictionCandidate> topPredictions;
  final bool demo;

  Diagnosis({
    required this.accepted,
    required this.crop,
    required this.disease,
    required this.confidence,
    required this.lowConfidence,
    required this.message,
    required this.advice,
    required this.topPredictions,
    required this.demo,
  });

  bool get isHealthy => accepted && disease.toLowerCase() == 'healthy';

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    final ranked = json['top_predictions'] as List<dynamic>? ?? const [];
    final accepted = (json['accepted'] as bool?) ?? true;

    return Diagnosis(
      accepted: accepted,
      crop: (json['crop'] as String?) ?? '',
      disease: (json['disease'] as String?) ?? '',
      confidence: ((json['confidence'] as num?) ?? 0).toDouble(),
      lowConfidence: (json['low_confidence'] as bool?) ?? !accepted,
      message: json['message'] as String?,
      advice: (json['advice'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
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

  if (response.statusCode == 429) {
    return 'Too many requests. Please wait a moment and try again.';
  }
  if (response.statusCode == 503) {
    return 'CropMedic diagnosis is temporarily unavailable. Please try again later.';
  }
  return 'Something went wrong. Try again.';
}

Future<Map<String, dynamic>> _getJson(String path) async {
  try {
    final response = await http
        .get(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(_errorDetail(response));
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw ApiException('CropMedic received an invalid response from the server.');
    }
    return body;
  } on ApiException {
    rethrow;
  } on TimeoutException {
    throw ApiException('The server took too long. Check your connection.');
  } catch (_) {
    throw ApiException("Can't reach the CropMedic server. Check your connection.");
  }
}

http.MultipartRequest _imageRequest(String path, Uint8List bytes) {
  final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
  request.files.add(http.MultipartFile.fromBytes(
    'file',
    bytes,
    filename: 'crop.jpg',
    contentType: MediaType('image', 'jpeg'),
  ));
  return request;
}

Future<Map<String, dynamic>> _sendImageRequest(http.MultipartRequest request) async {
  try {
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw ApiException(_errorDetail(response));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw ApiException('CropMedic received an invalid response from the server.');
    }
    return body;
  } on ApiException {
    rethrow;
  } on TimeoutException {
    throw ApiException('The server took too long. Check your connection.');
  } catch (_) {
    throw ApiException("Can't reach the CropMedic server. Check your connection.");
  }
}

Future<ApiCapabilities> fetchCapabilities() async {
  final body = await _getJson('/api/capabilities');
  return ApiCapabilities.fromJson(body);
}

Future<CropGuess> identifyCrop(Uint8List bytes) async {
  final request = _imageRequest('/api/identify-crop', bytes);
  final body = await _sendImageRequest(request);
  return CropGuess.fromJson(body);
}

Future<Diagnosis> predict(
  Uint8List bytes,
  String lang, {
  String? crop,
}) async {
  final params = <String, String>{'lang': lang};
  if (crop != null && crop.trim().isNotEmpty) {
    params['crop'] = crop.trim();
  }
  final uri = Uri.parse('$baseUrl/api/predict').replace(queryParameters: params);
  final request = http.MultipartRequest('POST', uri);
  request.files.add(http.MultipartFile.fromBytes(
    'file',
    bytes,
    filename: 'crop.jpg',
    contentType: MediaType('image', 'jpeg'),
  ));

  final body = await _sendImageRequest(request);
  return Diagnosis.fromJson(body);
}
