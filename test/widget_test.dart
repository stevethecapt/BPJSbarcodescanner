import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bpjs_barcodescanner/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SplashWrapper), findsOneWidget);
  });
}
