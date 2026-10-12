import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crop_medic/brand.dart';

void main() {
  testWidgets('CropMedic brand renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: CropMedicBrand()),
        ),
      ),
    );

    expect(find.byType(CropMedicBrand), findsOneWidget);
    expect(find.text('AI crop health assistant'), findsOneWidget);
  });
}
