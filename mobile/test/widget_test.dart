import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakhshati_mobile/widgets/brand_header.dart';

void main() {
  testWidgets('brand header renders app title and tagline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrandHeader(),
        ),
      ),
    );

    expect(find.text('Rakshati'), findsOneWidget);
    expect(find.text('Safety First'), findsOneWidget);
  });
}
