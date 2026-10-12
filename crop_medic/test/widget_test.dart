import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crop_medic/main.dart';

void main() {
  testWidgets('CropMedic app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const CropMedicApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
