import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bpjs_barcodescanner/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Gantilah 'const' menjadi instansiasi MyApp dengan isLoggedIn: false
    await tester.pumpWidget(MyApp(isLoggedIn: false));

    // Pastikan widget dengan teks '0' ada dan '1' tidak ada
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap pada ikon add dan lakukan update
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Pastikan widget dengan teks '0' tidak ada, dan '1' ada
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
