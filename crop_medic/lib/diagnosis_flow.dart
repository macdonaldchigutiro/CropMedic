import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'api.dart';
import 'loading_screen.dart';
import 'result_screen.dart';
import 'unsupported_image_screen.dart';

Future<void> startDiagnosisFlow(
  BuildContext context,
  Uint8List image,
  String lang,
) async {
  final navigator = Navigator.of(context);

  navigator.push(
    MaterialPageRoute(
      builder: (_) => LoadingScreen(image: image),
      fullscreenDialog: true,
    ),
  );

  try {
    final diagnosis = await predict(image, lang);
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
