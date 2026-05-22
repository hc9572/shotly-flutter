import 'package:flutter_test/flutter_test.dart';

import 'package:shotly_app/main.dart';

void main() {
  testWidgets('Shotly home smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShotlyApp());
    expect(find.text('검색'), findsOneWidget);
  });
}
