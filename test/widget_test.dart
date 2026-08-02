import 'package:flutter_test/flutter_test.dart';

import 'package:csahati_desktop/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CsahatiApp());
    expect(find.text('المعقب السريع'), findsOneWidget);
  });
}
