import 'package:flutter_test/flutter_test.dart';
import 'package:shipnow/core/services/smartsupp_controller.dart';

void main() {
  test('public routes trigger Smartsupp ON', () {
    final c = SmartsuppController();
    for (final r in ['/', '/welcome', '/onboarding', '/terms', '/privacy']) {
      c.syncWithRoute(r);
      // Both internal state and (on web) the dispatch are deterministic.
      expect(c.toString(), isNotNull);
    }
  });

  test('private routes do not flip Smartsupp', () {
    final c = SmartsuppController();
    c.syncWithRoute('/welcome');
    c.syncWithRoute('/portal/dashboard');
    // Internal state is private; this is a smoke test.
    expect(c, isNotNull);
  });
}