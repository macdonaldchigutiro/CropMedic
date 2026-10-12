import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'api.dart';
import 'crop_confirmation_screen.dart';
import 'loading_screen.dart';
import 'result_screen.dart';
import 'unsupported_image_screen.dart';

Future<void> startDiagnosisFlow(
  BuildContext context,
  Uint8List image,
  String lang, {
  String? presetCrop,
}) async {
  final navigator = Navigator.of(context);
  String? selectedCrop = presetCrop;

  try {
    if (selectedCrop == null) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => LoadingScreen(image: image, lang: lang),
          fullscreenDialog: true,
        ),
      );

      final guess = await identifyCrop(image);
      if (!context.mounted) return;
      if (navigator.canPop()) navigator.pop();

      selectedCrop = await navigator.push<String>(
        MaterialPageRoute(
          builder: (_) => CropConfirmationScreen(
            image: image,
            guess: guess,
            lang: lang,
          ),
          fullscreenDialog: true,
        ),
      );

      if (selectedCrop == null || !context.mounted) return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => LoadingScreen(image: image, lang: lang),
        fullscreenDialog: true,
      ),
    );

    final diagnosis = await predict(image, lang, crop: selectedCrop);
    if (!context.mounted) return;

    final next = diagnosis.accepted
        ? ResultScreen(image: image, diagnosis: diagnosis, lang: lang)
        : UnsupportedImageScreen(
            image: image,
            diagnosis: diagnosis,
            lang: lang,
          );

    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  } on ApiException catch (e) {
    if (!context.mounted) return;
    if (navigator.canPop()) navigator.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  }
}
