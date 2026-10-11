import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';

class ResultScreen extends StatelessWidget {
  final Uint8List image;
  final Diagnosis diagnosis;

  const ResultScreen({super.key, required this.image, required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
                children: [
                  _header(context),
                  const SizedBox(height: 18),
                  _imagePreview(),
                  const SizedBox(height: 18),
                  if (!diagnosis.accepted)
                    _RejectedResult(onRetry: () => Navigator.pop(context), diagnosis: diagnosis)
                  else
                    _AcceptedResult(diagnosis: diagnosis),
                  const SizedBox(height: 18),
                  _scanAgainButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crop check',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              Text(
                'Your photo and CropMedic result',
                style: TextStyle(color: Palette.textDim, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Palette.primarySoft,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: Palette.primary),
              SizedBox(width: 5),
              Text(
                'AI assisted',
                style: TextStyle(
                  color: Palette.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: Image.memory(image, fit: BoxFit.cover),
      ),
    );
  }

  Widget _scanAgainButton(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: () => Navigator.pop(context),
        style: FilledButton.styleFrom(
          backgroundColor: Palette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text(
          'Check another photo',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }
}

class _RejectedResult extends StatelessWidget {
  final VoidCallback onRetry;
  final Diagnosis diagnosis;

  const _RejectedResult({required this.onRetry, required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          color: const Color(0xFFFFFBF1),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBC4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: Palette.amber,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBC4),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'NO DIAGNOSIS MADE',
                  style: TextStyle(
                    color: Color(0xFF84580D),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We couldn’t verify this photo as a supported crop leaf',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                diagnosis.message ??
                    'Try again with one clear maize, tomato, potato or bell-pepper leaf.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.textDim, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Try this for a better scan',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 14),
              _RetryTip(icon: Icons.eco_rounded, text: 'Photograph one crop leaf only'),
              _RetryTip(icon: Icons.center_focus_strong_rounded, text: 'Let the leaf fill most of the frame'),
              _RetryTip(icon: Icons.wb_sunny_outlined, text: 'Use bright, even light and keep it sharp'),
              _RetryTip(icon: Icons.block_rounded, text: 'Avoid faces, hands and unrelated objects'),
            ],
          ),
        ),
      ],
    );
  }
}

class _RetryTip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RetryTip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Palette.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Palette.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

class _AcceptedResult extends StatelessWidget {
  final Diagnosis diagnosis;
  const _AcceptedResult({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final healthy = diagnosis.isHealthy;
    final statusColor = healthy ? Palette.primary : Palette.alert;
    final statusBackground = healthy
        ? Palette.primarySoft
        : const Color(0xFFFFE8E8);
    final title = healthy ? 'This leaf looks healthy' : diagnosis.disease;
    final alternatives = diagnosis.topPredictions
        .skip(1)
        .where((candidate) => candidate.confidence >= 0.01)
        .toList();

    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBackground,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          healthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          color: statusColor,
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          healthy ? 'LOOKS HEALTHY' : 'CONDITION DETECTED',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Palette.surfaceSoft,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${(diagnosis.confidence * 100).round()}% confidence',
                      style: const TextStyle(
                        color: Palette.textDim,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                diagnosis.crop,
                style: const TextStyle(
                  color: Palette.textDim,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (diagnosis.advice.isNotEmpty) ...[
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What to do next',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                for (int i = 0; i < diagnosis.advice.length; i++)
                  _AdviceRow(index: i, text: diagnosis.advice[i]),
              ],
            ),
          ),
        ],
        if (alternatives.isNotEmpty) ...[
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Other possibilities',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Useful when symptoms overlap. These are not additional diagnoses.',
                  style: TextStyle(color: Palette.textDim, fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (final candidate in alternatives)
                  _AlternativeRow(candidate: candidate),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3F0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD3E6E0)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Palette.accent),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'CropMedic is an AI field assistant. Confirm important treatment decisions with an agronomist or extension officer, especially when symptoms are severe or unusual.',
                  style: TextStyle(color: Palette.textDim, height: 1.4, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdviceRow extends StatelessWidget {
  final int index;
  final String text;
  const _AdviceRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Palette.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Palette.primaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
        ],
      ),
    );
  }
}

class _AlternativeRow extends StatelessWidget {
  final PredictionCandidate candidate;
  const _AlternativeRow({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Palette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${candidate.crop} · ${candidate.disease}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${(candidate.confidence * 100).round()}%',
            style: const TextStyle(
              color: Palette.textDim,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
