import 'package:flutter/material.dart';

import 'theme.dart';

class CropMedicMark extends StatelessWidget {
  final double size;
  const CropMedicMark({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Palette.primaryDark, Palette.primaryMid],
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.11,
            left: size * 0.08,
            child: Transform.rotate(
              angle: -0.52,
              child: Icon(
                Icons.eco_rounded,
                size: size * 0.64,
                color: const Color(0xFFE8F4E3),
              ),
            ),
          ),
          Positioned(
            top: size * 0.12,
            child: Icon(
              Icons.add_rounded,
              size: size * 0.42,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: size * 0.01,
            child: Container(
              width: size * 0.58,
              height: size * 0.11,
              decoration: BoxDecoration(
                color: Palette.gold,
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CropMedicBrand extends StatelessWidget {
  final bool compact;
  final bool showTagline;
  const CropMedicBrand({
    super.key,
    this.compact = false,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 38.0 : 50.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CropMedicMark(size: markSize),
        SizedBox(width: compact ? 9 : 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: compact ? 20 : 27,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Palette.primaryDark,
                  letterSpacing: -0.8,
                ),
                children: const [
                  TextSpan(text: 'Crop'),
                  TextSpan(
                    text: 'Medic',
                    style: TextStyle(color: Palette.primaryMid),
                  ),
                ],
              ),
            ),
            if (showTagline && !compact) ...[
              const SizedBox(height: 5),
              const Text(
                'AI crop health assistant',
                style: TextStyle(
                  color: Palette.textDim,
                  fontSize: 12.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class LanguagePill extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const LanguagePill({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  static const languages = {
    'en': 'English',
    'sn': 'Shona',
    'nd': 'Ndebele',
    'toi': 'Tonga',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: enabled ? onChanged : null,
          borderRadius: BorderRadius.circular(18),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 21),
          items: languages.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, size: 19),
                      const SizedBox(width: 7),
                      Text(entry.value),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
