// Smoke test: build the app once to make sure the widget tree compiles
// and the routing layer wires up. This test does not exercise network
// state — the auth controller is mocked off via USE_MOCK_DATA=true.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shipnow/app/app.dart';

void main() {
  testWidgets('App boots without throwing', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const ProviderScope(child: ShipNowApp()));
      await tester.pump(const Duration(milliseconds: 100));
    });
    // No assertion needed — the test passes if the widget tree mounts.
  });
}
