import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shotly_app/main.dart';

void main() {
  testWidgets('Shotly home smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'shotly.legalAccepted.v1': true});

    await tester.pumpWidget(const ShotlyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining(RegExp('검색|Search')), findsOneWidget);
  });
}
